# =============================================================================
# 07_null_models.R — Null model significance tests for Roman network modularity
#
# Two null models:
#   Null 1 — Configuration model: degree-preserving random rewiring (999 perms).
#             Tests whether the observed modularity exceeds what a random graph
#             with the same degree sequence would produce.
#   Null 2 — Spatial null: resample n nodes from the empirical site pool
#             (not a uniform rectangle) and connect by Euclidean distance
#             threshold calibrated to match the observed mean degree.
#             Tests whether the community structure reflects geographic
#             clustering beyond what spatial density alone would predict.
#
# Input:  output/rds/giant.rds      (saved by 06_community_detection.R)
#         output/rds/cl_leiden.rds  (saved by 06_community_detection.R)
#         output/rds/nodes_rom.rds
#         data/sites.gpkg (all site coordinates for spatial null pool)
# Output: output/tables/null_model_results.csv
# =============================================================================

# Community detection here uses unweighted graph topology, consistent with 06_community_detection.R.

# Read the giant component and Leiden partition saved by 06_community_detection.R.
# This guarantees obs_mod is identical to the value reported there and that the
# two scripts cannot silently diverge if either is edited in the future.
if (file.exists(rds_path("giant.rds")) && file.exists(rds_path("cl_leiden.rds"))) {
  giant <- readRDS(rds_path("giant.rds"))
  cl    <- readRDS(rds_path("cl_leiden.rds"))
  obs_mod <- modularity(giant, membership(cl))
} else {
  warning("giant.rds / cl_leiden.rds not found — recomputing from net_rom.rds. ",
          "Run 06_community_detection.R first to ensure consistency.")
  net_rom <- readRDS(rds_path("net_rom.rds"))
  cmp_rom <- igraph::components(net_rom)
  giant   <- induced_subgraph(net_rom,
               which(cmp_rom$membership == which.max(cmp_rom$csize)))
  set.seed(COMMUNITY_SEED)
  cl      <- cluster_leiden(giant,
                            objective_function   = "modularity",
                            resolution_parameter = LEIDEN_RESOLUTION)
  obs_mod <- modularity(giant, membership(cl))
}
cat("Observed modularity (from 06):", obs_mod, "\n")

nodes_rom <- readRDS(rds_path("nodes_rom.rds"))

# All site coordinates (pool for spatial null)
siti_raw  <- sf::st_read(data_path("sites.gpkg"), quiet = TRUE)

n_nodes <- vcount(giant)
n_edges <- ecount(giant)

# =============================================================================
# NULL 1 — Configuration model (degree-preserving rewiring)
# =============================================================================
set.seed(NULL1_SEED)
mod_null1 <- numeric(N_PERM)
for (i in seq_len(N_PERM)) {
  g_rand      <- rewire(giant, with = keeping_degseq(niter = n_edges * 10))
  mod_null1[i] <- modularity(g_rand,
                              membership(cluster_leiden(g_rand,
                                                       objective_function   = "modularity",
                                                       resolution_parameter = LEIDEN_RESOLUTION)))
}
p_null1 <- mean(mod_null1 >= obs_mod)
cat("Null 1 (degree-preserving): mean =", mean(mod_null1), " p =", p_null1, "\n")

# =============================================================================
# NULL 2 — Spatial null (resample from empirical site pool)
# =============================================================================
all_coords <- st_coordinates(
  siti_raw %>% st_transform(CRS_UTM)
)
target_mean_degree <- mean(igraph::degree(giant))

# Calibrate the Euclidean distance threshold on one sample so that the
# resulting mean degree matches the observed network.
calibrate_threshold <- function(coords, target_deg, n_sample) {
  idx <- sample(nrow(coords), n_sample)
  d   <- as.matrix(dist(coords[idx, ]))
  qs  <- quantile(d[upper.tri(d)], probs = seq(0.01, 0.3, by = 0.005))
  degs <- sapply(qs, function(q) mean(rowSums(d < q & d > 0)))
  qs[which.min(abs(degs - target_deg))]
}
eucl_thresh <- calibrate_threshold(all_coords, target_mean_degree, n_nodes)
cat("Calibrated Euclidean threshold:", round(eucl_thresh), "m\n")

mod_null2    <- numeric(N_PERM)
null2_degrees <- numeric(N_PERM)
for (i in seq_len(N_PERM)) {
  idx  <- sample(nrow(all_coords), n_nodes)
  d    <- as.matrix(dist(all_coords[idx, ]))
  adj  <- (d < eucl_thresh) & (d > 0)
  g_sp <- graph_from_adjacency_matrix(adj, mode = "undirected", diag = FALSE)
  cmp  <- components(g_sp)
  # Discard degenerate iterations where the giant component is too small
  if (max(cmp$csize) < NULL2_MAX_GAP_FRAC * n_nodes) {
    mod_null2[i]     <- NA
    null2_degrees[i] <- NA
    next
  }
  g_sp_giant       <- induced_subgraph(g_sp, which(cmp$membership == which.max(cmp$csize)))
  null2_degrees[i] <- mean(igraph::degree(g_sp_giant))
  mod_null2[i]     <- modularity(g_sp_giant,
                                 membership(cluster_leiden(g_sp_giant,
                                                          objective_function   = "modularity",
                                                          resolution_parameter = LEIDEN_RESOLUTION)))
}
mod_null2_valid <- mod_null2[!is.na(mod_null2)]
p_null2 <- mean(mod_null2_valid >= obs_mod)
cat("Null 2 (spatial, n valid =", length(mod_null2_valid), "): mean =",
    mean(mod_null2_valid), " p =", p_null2, "\n")

# --- Degree calibration check ------------------------------------------------
cat("Null 2 mean degree: mean =", mean(null2_degrees, na.rm = TRUE),
    " sd =", sd(null2_degrees, na.rm = TRUE),
    " (target:", target_mean_degree, ")\n")
hist(null2_degrees, breaks = 30,
     main = "Spatial null: mean degree distribution",
     xlab = "Mean degree")
abline(v = target_mean_degree, col = "red", lwd = 2)

# --- Summary plot ------------------------------------------------------------
hist(mod_null2_valid, breaks = 30,
     main = "Spatial null: modularity distribution",
     xlab = "Modularity",
     xlim = range(c(mod_null2_valid, obs_mod)))
abline(v = obs_mod, col = "red", lwd = 2)
legend("topright",
       legend = sprintf("Observed = %.3f", obs_mod),
       col = "red", lty = 1)

# --- Write results -----------------------------------------------------------
null_results <- data.frame(
  model        = c("null1_degree_preserving", "null2_spatial"),
  observed_mod = obs_mod,
  null_mean    = c(mean(mod_null1), mean(mod_null2_valid)),
  null_n_valid = c(N_PERM, length(mod_null2_valid)),
  p_value      = c(p_null1, p_null2)
)
write.csv(null_results, table_path("null_model_results.csv"), row.names = FALSE)
message("Saved null_model_results.csv")
