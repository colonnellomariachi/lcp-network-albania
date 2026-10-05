# =============================================================================
# 00_setup.R — Libraries, paths, and all global analytical parameters
#
# Every analytical choice made in this project is documented here so a reader
# can audit the full parameter space without opening individual scripts.
# =============================================================================

# --- Libraries ---------------------------------------------------------------
library(here)          # portable paths via here::here()
library(dplyr)
library(tidyr)
library(sf)
library(terra)
library(igraph)
library(leastcostpath)
library(ggplot2)
library(ggrepel)
library(patchwork)

# --- Output directories (created if absent) ----------------------------------
dir.create(here("output", "tables"), recursive = TRUE, showWarnings = FALSE)
dir.create(here("output", "images"), recursive = TRUE, showWarnings = FALSE)
dir.create(here("output", "rds"),    recursive = TRUE, showWarnings = FALSE)

# --- Coordinate reference system ---------------------------------------------
CRS_UTM <- 32634   # WGS 84 / UTM zone 34N

# --- Chronological phase windows (astronomical years; negative = BC) ---------
HELL_START <- -300   # Hellenistic window opens
ROM_BOUND  <-  -31   # Hellenistic closes / Roman opens
ROM_END    <-  450   # Roman window closes
# NOTE: The task specification listed ROM_END = 300, but the analysis scripts
# use 450; see REFACTOR_NOTES.md §1 for details.

# Minimum temporal overlap for a site to be included in a phase (years).
# One generation; prevents boundary-grazing false positives.
MIN_OVERLAP_YEARS <- 25

# --- Cost-surface parameters -------------------------------------------------
DEM_RMSE   <- 2.9          # vertical RMSE of the DEM (metres)
# add_dem_error() draws one random error per DEM cell. Until Task 10 no seed
# was set, so the cost surfaces behind the first submission cannot be
# regenerated (they are kept in archive/pre_task10_2026-10-05/rds/). From
# Task 10 the draw is seeded and 02 is reproducible.
DEM_ERROR_SEED <- 20261005
NEIGHBOURS <- 16           # raster connectivity for LCP computation

COST_FN_HELL <- "tobler"              # walking / Hellenistic network
COST_FN_ROM  <- "wheeled transport"   # cart / Roman network

# --- Network construction thresholds (minutes of travel cost) ----------------
HELL_THRESH <- 240   # edges with cost_mean >= this value are excluded
ROM_THRESH  <- 150   # edges with cost_mean >= this value are excluded

# --- Sensitivity sweep (Roman network, 02c) ----------------------------------
SENSITIVITY_SEQ <- seq(30, 300, by = 30)   # thresholds tested (minutes)

# --- Community detection (Leiden) -------------------------------------------
LEIDEN_RESOLUTION <- 1          # resolution parameter for modularity optimisation
COMMUNITY_SEED    <- 42         # random seed passed to set.seed() before cluster_leiden

# --- Null model parameters ---------------------------------------------------
N_PERM          <- 999   # permutations for both null models
NULL1_SEED      <- 1     # degree-preserving rewiring
NULL2_MAX_GAP_FRAC <- 0.5  # spatial null: discard iteration if giant < 50 % of n

# --- Egnatia validation ------------------------------------------------------
STITCH_MAX_GAP <- 200    # metres; maximum gap tolerated when stitching route segments
VAL_BUFFERS    <- c(1000, 2500, 5000, 10000)   # buffer distances for overlap metric

WAYPOINT_IDS <- c("DUR001", "DUR022", "DUR024", "DUR017")
# Dyrrachium → Clodiana → Ad Quintum → Scampis (west to east)

# DUR024 (Ad Quintum) corrected coordinates (UTM 34N).
# The original digitised position was ~1 km off the known route; the
# corrected point was derived in aggiustamento_bradaddesh.R and is now
# encoded permanently in data/sites.gpkg. See REFACTOR_NOTES.md §2.
DUR024_X_FIXED <- 417306.64305036
DUR024_Y_FIXED <- 4549673.05871444

# --- Hydrographic sensitivity (12) -------------------------------------------
# Rivers are crossing penalties, not barriers: the cost of entering a river
# cell is multiplied by each factor (moderate / strong sensitivity bounds).
HYDRO_PENALTIES <- c(5, 20)
# Author-supplied polygons of the main river courses (file name has a space).
HYDRO_POLYGON_PATH <- here("data", "river polygon.gpkg")

# --- Size / late-antique horizon sensitivity (10 Q7, 13) ---------------------
ROM_END_ALT    <- 300    # counterfactual end of the Roman window (ROM_END stays 450)
SUBSAMPLE_N    <- 999    # random 71-site subsets of the Roman networks
SUBSAMPLE_SEED <- 13

# --- Regression checks -------------------------------------------------------
# Baseline tables compared by 10_discussion_checks.R.
REGRESSION_BASELINE_DIR <- here("tests", "discussion_checks_baseline")
# FALSE: a value that differs from the published/baseline one is logged
# (regression_log) and the pipeline continues, so a full re-run on new cost
# surfaces can complete and be reviewed. TRUE: stop at the first difference.
STRICT_REGRESSION <- FALSE
regression_log <- character(0)

# --- Figure aesthetics -------------------------------------------------------
PHASE_COLS   <- c(hellenistic = "#D9A441", roman = "#3B6E8F")
SCATTER_SEED <- 42   # seed for ggrepel label placement

# --- Path helpers ------------------------------------------------------------
data_path   <- function(...) here("data",   ...)
output_path <- function(...) here("output", ...)
rds_path    <- function(...) here("output", "rds",    ...)
table_path  <- function(...) here("output", "tables", ...)
image_path  <- function(...) here("output", "images", ...)

# Source shared helper functions
source(here("R", "functions", "chronology_helpers.R"))
source(here("R", "functions", "network_helpers.R"))
source(here("R", "functions", "route_helpers.R"))
source(here("R", "functions", "pdi_validation_fixed.R"))
source(here("R", "functions", "lcp_helpers.R"))

#' Like stopifnot() with named conditions, but honours STRICT_REGRESSION.
#' Use for values that depend on the cost surfaces / networks; keep stopifnot()
#' for structural invariants.
check_published <- function(...) {
  nms <- ...names()
  for (i in seq_len(...length())) {
    # ...elt() evaluates lazily, so an error inside a condition is caught too
    ok <- isTRUE(tryCatch(all(...elt(i)), error = function(e) FALSE))
    if (ok) next
    if (STRICT_REGRESSION) stop("Regression: ", nms[i], call. = FALSE)
    message("  CHANGED  ", nms[i])
    regression_log <<- c(regression_log, nms[i])
  }
  invisible(NULL)
}
