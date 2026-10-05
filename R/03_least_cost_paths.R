# =============================================================================
# 03_least_cost_paths.R — Least-cost path computation (both networks)
#
# Two code paths are provided and documented below. The active path for each
# network is selected by the USE_FETE_* flags.
#
# CODE PATH A — create_FETE_lcps()
#   Computes all from-every-to-every (FETE) paths in one call. Fast and
#   memory-efficient for smaller site sets. Used for the Hellenistic network.
#
# CODE PATH B — manual loop with create_lcp()
#   Iterates over each origin in turn, releasing memory after each batch.
#   Used as a workaround when the Roman site set is large enough to exhaust
#   available RAM with the FETE call. Results are combined at the end.
#   See REFACTOR_NOTES.md §3 for the memory context.
#
# Input:  output/rds/cost_surface_hell.rds
#         output/rds/cost_surface_rom.rds
#         output/rds/siti_hell.rds
#         output/rds/siti_rom.rds
# Output: output/rds/lcp_hell.gpkg
#         output/rds/lcp_roman.gpkg
#
# Expected runtime: 30–90 minutes for the FETE calls; longer for the loop.
# =============================================================================

USE_FETE_HELL <- TRUE   # FALSE → use manual loop for Hellenistic network
USE_FETE_ROM  <- FALSE  # FALSE → use manual loop (memory workaround) for Roman

# --- Load inputs -------------------------------------------------------------
siti_hell       <- readRDS(rds_path("siti_hell.rds"))
siti_rom        <- readRDS(rds_path("siti_rom.rds"))
cost_surface_hell <- readRDS(rds_path("cost_surface_hell.rds"))
cost_surface_rom  <- readRDS(rds_path("cost_surface_rom.rds"))

# --- Snap non-traversable sites to nearest valid cost-surface cell -----------
# snap_non_traversable(), compute_lcps_fete() and compute_lcps_loop() live in
# R/functions/lcp_helpers.R (shared with 11_cost_function_factorial.R).
valid_pts <- sf::st_as_sf(terra::as.points(
  terra::rast(data_path("dem.tif")), na.rm = TRUE))

siti_hell <- snap_non_traversable(siti_hell, cost_surface_hell, valid_pts,
                                  "Hellenistic")
siti_rom  <- snap_non_traversable(siti_rom,  cost_surface_rom,  valid_pts,
                                  "Roman")

# =============================================================================
# HELLENISTIC LCPs
# =============================================================================
if (USE_FETE_HELL) {
  # --- CODE PATH A: single FETE call (Hellenistic) ---------------------------
  message("Computing Hellenistic LCPs via create_FETE_lcps()...")
  lcp_hell <- compute_lcps_fete(cost_surface_hell, siti_hell)

} else {
  # --- CODE PATH B: manual loop (Hellenistic) --------------------------------
  message("Computing Hellenistic LCPs via manual loop...")
  lcp_hell <- compute_lcps_loop(cost_surface_hell, siti_hell, "Hellenistic")
}

st_write(lcp_hell, rds_path("lcp_hell.gpkg"), delete_dsn = TRUE)
message("Saved lcp_hell.gpkg")
gc()

# =============================================================================
# ROMAN LCPs
# =============================================================================
if (USE_FETE_ROM) {
  # --- CODE PATH A: single FETE call (Roman) ---------------------------------
  message("Computing Roman LCPs via create_FETE_lcps()...")
  lcp_roman <- compute_lcps_fete(cost_surface_rom, siti_rom)

} else {
  # --- CODE PATH B: manual loop (Roman) — default, see header ---------------
  message("Computing Roman LCPs via manual loop (memory workaround)...")
  lcp_roman <- compute_lcps_loop(cost_surface_rom, siti_rom, "Roman")
}

st_write(lcp_roman, rds_path("lcp_roman.gpkg"), delete_dsn = TRUE)
message("Saved lcp_roman.gpkg")
gc()
