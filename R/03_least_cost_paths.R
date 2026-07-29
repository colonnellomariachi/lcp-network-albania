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
# Tests each site individually against its cost surface; any that fail
# check_locations() are moved to the nearest valid DEM pixel.
# (DUR103 was the original known offender; this generalises the fix.)
snap_non_traversable <- function(sites, cost_surface, valid_pts, label) {
  bad_idx <- which(vapply(seq_len(nrow(sites)), function(i) {
    inherits(
      tryCatch(leastcostpath::check_locations(cost_surface, sites[i, ]),
               error = function(e) e),
      "error")
  }, logical(1)))

  if (length(bad_idx) == 0) {
    message(label, ": all sites traversable, no snapping needed")
    return(sites)
  }

  message(label, ": snapping ", length(bad_idx), " site(s) — ",
          paste(sites$id_sito[bad_idx], collapse = ", "))

  for (i in bad_idx) {
    new_geom <- sf::st_geometry(
      valid_pts[sf::st_nearest_feature(sites[i, ], valid_pts), ])
    sf::st_geometry(sites)[i] <- new_geom
  }
  sites
}

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
  lcp_hell <- create_FETE_lcps(cost_surface_hell, siti_hell, cost_distance = TRUE)

} else {
  # --- CODE PATH B: manual loop (Hellenistic) --------------------------------
  message("Computing Hellenistic LCPs via manual loop...")
  site_ids_hell <- siti_hell$id_sito
  lcp_list_hell <- vector("list", length(site_ids_hell))

  for (i in seq_along(site_ids_hell)) {
    origin      <- siti_hell[i, ]
    destination <- siti_hell[-i, ]
    lcp_list_hell[[i]] <- tryCatch(
      create_lcp(x = cost_surface_hell, origin = origin,
                 destination = destination,
                 cost_distance = TRUE, check_locations = FALSE),
      error = function(e) {
        message("FAILED: ", site_ids_hell[i], " -> ", conditionMessage(e))
        NULL
      }
    )
    rm(origin, destination); gc(verbose = FALSE)
    if (i %% 5 == 0) message(i, "/", length(site_ids_hell), " completed")
  }
  failed_hell <- site_ids_hell[sapply(lcp_list_hell, is.null)]
  if (length(failed_hell)) message("Failed origins: ", paste(failed_hell, collapse = ", "))
  lcp_hell <- do.call(rbind, lcp_list_hell[!sapply(lcp_list_hell, is.null)])
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
  lcp_roman <- create_FETE_lcps(cost_surface_rom, siti_rom, cost_distance = TRUE)

} else {
  # --- CODE PATH B: manual loop (Roman) — default, see header ---------------
  message("Computing Roman LCPs via manual loop (memory workaround)...")
  site_ids_rom <- siti_rom$id_sito
  lcp_list_rom <- vector("list", length(site_ids_rom))

  for (i in seq_along(site_ids_rom)) {
    origin      <- siti_rom[i, ]
    destination <- siti_rom[-i, ]
    lcp_list_rom[[i]] <- tryCatch(
      create_lcp(x = cost_surface_rom, origin = origin,
                 destination = destination,
                 cost_distance = TRUE, check_locations = FALSE),
      error = function(e) {
        message("FAILED: ", site_ids_rom[i], " -> ", conditionMessage(e))
        NULL
      }
    )
    rm(origin, destination); gc(verbose = FALSE)
    if (i %% 5 == 0) message(i, "/", length(site_ids_rom), " completed")
  }
  failed_rom <- site_ids_rom[sapply(lcp_list_rom, is.null)]
  if (length(failed_rom)) message("Failed origins: ", paste(failed_rom, collapse = ", "))
  lcp_roman <- do.call(rbind, lcp_list_rom[!sapply(lcp_list_rom, is.null)])
}

st_write(lcp_roman, rds_path("lcp_roman.gpkg"), delete_dsn = TRUE)
message("Saved lcp_roman.gpkg")
gc()
