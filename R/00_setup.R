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
# NOTE: the Roman window closes at AD 450, so that late-antique sites overlapping
# AD 300–450 enter the Roman network; 13 tests the alternative closure at AD 300
# (ROM_END_ALT).

# Minimum temporal overlap for a site to be included in a phase (years).
# One generation; prevents boundary-grazing false positives.
MIN_OVERLAP_YEARS <- 25

# --- Cost-surface parameters -------------------------------------------------
# The cost surfaces are computed from the DEM as it is. No random vertical
# error is added (leastcostpath::add_dem_error() is not used): the
# networks compared here differ by cost function and site set, and the
# workflow is kept free of any stochastic component.
NEIGHBOURS <- 16           # raster connectivity for LCP computation

COST_FN_HELL <- "tobler"              # walking / Hellenistic network
COST_FN_ROM  <- "wheeled transport"   # cart / Roman network

# --- Network construction thresholds (minutes of travel cost) ----------------
HELL_THRESH <- 240   # edges with cost_mean >= this value are excluded
ROM_THRESH  <- 150   # edges with cost_mean >= this value are excluded

# --- Sensitivity sweep (Roman network, 02c) ----------------------------------
SENSITIVITY_SEQ <- seq(30, 300, by = 30)   # thresholds tested (minutes)

# --- Betweenness concentration sweep (04b; four factorial cells in 11) -------
CONC_SWEEP_SEQ <- seq(90, 300, by = 30)    # thresholds tested (minutes)

# --- Community detection (Leiden) -------------------------------------------
LEIDEN_RESOLUTION <- 1          # resolution parameter for modularity optimisation
COMMUNITY_SEED    <- 42         # random seed passed to set.seed() before cluster_leiden

# --- Null model parameters ---------------------------------------------------
N_PERM          <- 999   # permutations for both null models
NULL1_SEED      <- 1     # degree-preserving rewiring
NULL2_SEED      <- 2     # spatial null: own seed, so 07 gives the same result
                         # whether or not the degree-preserving null ran first
NULL2_STABILITY_SEEDS <- 1:30   # spatial null repeated under these seeds to
                                # document the stability of p (not to choose it)
NULL2_MAX_GAP_FRAC <- 0.5  # spatial null: discard iteration if giant < 50 % of n

# --- Egnatia validation ------------------------------------------------------
STITCH_MAX_GAP <- 200    # metres; maximum gap tolerated when stitching route segments
ROUTE_ON_SOURCE_TOL <- 1  # metres; every edge of the stitched route must lie within this
                          # distance of an Itiner-e piece (no chords added by the stitching)
VAL_BUFFERS    <- c(1000, 2500, 5000, 10000)   # buffer distances for overlap metric

# Spacing (m) of the points sampled on the attested route for the independent
# check of the PDI (mean distance to the modelled path), and buffer distances
# for the share of the full modelled route close to the attested one.
PDI_SAMPLE_SPACING  <- 200
FULL_ROUTE_BUFFERS  <- c(1000, 5000)

WAYPOINT_IDS <- c("DUR001", "DUR022", "DUR024", "DUR017")
# Dyrrachium → Clodiana → Ad Quintum → Scampis (west to east)

# DUR024 (Ad Quintum) corrected coordinates (UTM 34N).
# The original digitised position was ~1 km off the known route; the
# corrected point is encoded permanently in data/sites.gpkg.
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
# Baseline tables of the deterministic run: tests/baseline_v2/ for the
# tables written up to 10, tests/baseline_v2/after_10/ for those of 11-13.
REGRESSION_BASELINE_DIR <- here("tests", "baseline_v2")
# TRUE: a table or checked value that differs from the baseline stops the
# pipeline. Set to FALSE only to let a deliberate re-run complete and log the
# differences (regression_log, output/tables/regression_log.txt).
STRICT_REGRESSION <- TRUE
regression_log <- character(0)

# --- Figure aesthetics -------------------------------------------------------
PHASE_COLS   <- c(hellenistic = "#D9A441", roman = "#3B6E8F")
SCATTER_SEED <- 42   # seed for ggrepel label placement
JITTER_SEED  <- 42   # seed for the jittered points of fig04 (appearance only)

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
source(here("R", "functions", "site_helpers.R"))

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

#' Compare regenerated tables with the baseline CSV files in `dir`
#'
#' Every *.csv in `dir` must exist in output/tables/ and be all.equal()
#' (tolerance 1e-8). Differences stop the pipeline when STRICT_REGRESSION is
#' TRUE, otherwise they are logged in regression_log.
regression_check <- function(dir) {
  if (!dir.exists(dir)) {
    message("Regression check skipped: ", dir, " not found.")
    return(invisible(NULL))
  }
  files <- sort(list.files(dir, pattern = "[.]csv$", full.names = TRUE))
  message("--- Regression check against ", dir, " (", length(files), " files) ---")
  for (f in files) {
    fname <- basename(f)
    new_path <- table_path(fname)
    result <- if (!file.exists(new_path)) "regenerated file missing" else
      all.equal(read.csv(f, stringsAsFactors = FALSE),
                read.csv(new_path, stringsAsFactors = FALSE), tolerance = 1e-8)
    if (isTRUE(result)) { message("  OK  ", fname); next }
    if (STRICT_REGRESSION)
      stop(sprintf("Regression mismatch in %s: %s", fname,
                   paste(result, collapse = " | ")), call. = FALSE)
    message("  DIFF ", fname, ": ", paste(head(result, 3), collapse = " | "))
    regression_log <<- c(regression_log, paste("baseline:", fname))
  }
  invisible(NULL)
}
