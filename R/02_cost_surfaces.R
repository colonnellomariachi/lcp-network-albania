# =============================================================================
# 02_cost_surfaces.R — DEM loading and cost-surface creation
#
# Creates two cost surfaces from the DEM:
#   - Tobler (walking speed)  → used for the Hellenistic network
#   - Wheeled transport       → used for the Roman network
#
# The DEM error is propagated via add_dem_error() before computing gradients.
# Both surfaces are large objects (~1.5 GB each as RDS); they are saved to
# output/rds/ so downstream scripts can load them without recomputing.
#
# Input:  data/dem.tif
# Output: output/rds/cost_surface_hell.rds   (Tobler)
#         output/rds/cost_surface_rom.rds    (wheeled transport)
#
# Expected runtime: ~10–20 minutes depending on machine.
# =============================================================================

# --- DEM ---------------------------------------------------------------------
dem <- rast(data_path("dem.tif"))
dem <- add_dem_error(x = dem, rmse = DEM_RMSE, type = "u")

# --- Cost surfaces -----------------------------------------------------------
message("Computing Tobler (Hellenistic) cost surface...")
cost_surface_hell <- leastcostpath::create_slope_cs(
  dem,
  cost_function = COST_FN_HELL,
  neighbours    = NEIGHBOURS
)
saveRDS(cost_surface_hell, rds_path("cost_surface_hell.rds"))
message("Saved cost_surface_hell.rds")
gc()

message("Computing wheeled-transport (Roman) cost surface...")
cost_surface_rom <- leastcostpath::create_slope_cs(
  dem,
  cost_function = COST_FN_ROM,
  neighbours    = NEIGHBOURS
)
saveRDS(cost_surface_rom, rds_path("cost_surface_rom.rds"))
message("Saved cost_surface_rom.rds")
gc()
