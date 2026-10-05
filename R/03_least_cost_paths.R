# =============================================================================
# 03_least_cost_paths.R — Least-cost path computation (both networks)
#
# All pairwise LCPs between the sites of each phase, on that phase's cost
# surface. Paths and costs are computed by compute_lcps_graph()
# (R/functions/lcp_helpers.R), which performs the same computation as
# leastcostpath::create_lcp() but builds the routing graph once per surface
# (~25 min per network instead of ~5 h; verified identical in Task 9).
#
# The two networks keep the output schemas of the first submission, which
# 04_networks.r expects:
#   Hellenistic — "fete" schema (origin_ID / destination_ID), as produced by
#                 create_FETE_lcps()
#   Roman       — "loop" schema (fromCell / toCell only), as produced by the
#                 manual create_lcp() loop
#
# Sites are never moved: a site on a NoData DEM cell or on a non-traversable
# cost-surface cell stops the script (coordinates are fixed in the source
# data by the author).
#
# Input:  output/rds/cost_surface_hell.rds
#         output/rds/cost_surface_rom.rds
#         output/rds/siti_hell.rds
#         output/rds/siti_rom.rds
# Output: output/rds/lcp_hell.gpkg
#         output/rds/lcp_roman.gpkg
#
# Expected runtime: ~25 minutes per network.
# =============================================================================

siti_hell <- readRDS(rds_path("siti_hell.rds"))
siti_rom  <- readRDS(rds_path("siti_rom.rds"))

# =============================================================================
# HELLENISTIC LCPs
# =============================================================================
message("Computing Hellenistic LCPs...")
run_lcp_set(siti_hell, rds_path("cost_surface_hell.rds"), "fete",
            rds_path("lcp_hell.gpkg"), "Hellenistic")
gc()

# =============================================================================
# ROMAN LCPs
# =============================================================================
message("Computing Roman LCPs...")
run_lcp_set(siti_rom, rds_path("cost_surface_rom.rds"), "loop",
            rds_path("lcp_roman.gpkg"), "Roman")
gc()
