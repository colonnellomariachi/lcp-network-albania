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
