# =============================================================================
# 07_null_models.R — Null model significance tests for Roman network modularity
#
# Two null models:
#   Null 1 — Configuration model: degree-preserving random rewiring (999 perms).
#             Tests whether the observed modularity exceeds what a random graph
#             with the same degree sequence would produce.
#   Null 2 — Spatial null: resample n nodes from the empirical site pool
#             (not a uniform rectangle) and connect by a Euclidean distance
#             threshold calibrated, for each draw, to match the observed
#             mean degree.
#             Tests whether the community structure reflects geographic
#             clustering beyond what spatial density alone would predict.
#
# Input:  output/rds/giant.rds      (saved by 06_community_detection.R)
#         output/rds/cl_leiden.rds  (saved by 06_community_detection.R)
#         output/rds/nodes_rom.rds
#         data/sites.gpkg (all site coordinates for spatial null pool)
# Output: output/tables/null_model_results.csv
#         output/tables/null_model_stability.csv
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
#
# Each draw samples n_nodes sites from the whole corpus and connects them by a
# Euclidean distance threshold. The threshold is calibrated FOR EACH DRAW: it
# is the candidate distance (quantiles 1 %–30 % of the pairwise distances of
# that sample, step 0.5 %) whose mean degree is closest to the mean degree
# observed in the Roman giant component. Calibrating the threshold once, on a
# single random sample, and applying it to all draws would make the p-value
# depend on that one sample (0.015–0.181 over 30 seeds).
# Everything else is unchanged: sample size, number of draws, unweighted
# Leiden with the same resolution, validity criterion, own seed.
# =============================================================================
all_coords <- st_coordinates(
  siti_raw %>% st_transform(CRS_UTM)
)
target_mean_degree <- mean(igraph::degree(giant))

# Threshold for one sample: candidate quantile with mean degree closest to target
calibrate_threshold <- function(d, target_deg) {
  qs   <- quantile(d[upper.tri(d)], probs = seq(0.01, 0.3, by = 0.005))
  degs <- sapply(qs, function(q) mean(rowSums(d < q & d > 0)))
  unname(qs[which.min(abs(degs - target_deg))])
}

#' One complete spatial null (N_PERM draws) under a given seed.
#' Returns a data.frame with one row per draw.
spatial_null <- function(seed) {
  set.seed(seed)
  out <- data.frame(modularity = rep(NA_real_, N_PERM), threshold_m = NA_real_,
                    degree_sample = NA_real_, degree_giant = NA_real_,
                    giant_size = NA_integer_)
  for (i in seq_len(N_PERM)) {
    idx  <- sample(nrow(all_coords), n_nodes)
    d    <- as.matrix(dist(all_coords[idx, ]))
    thr  <- calibrate_threshold(d, target_mean_degree)
    adj  <- (d < thr) & (d > 0)
    g_sp <- graph_from_adjacency_matrix(adj, mode = "undirected", diag = FALSE)
    cmp  <- components(g_sp)
    out$threshold_m[i]   <- thr
    out$degree_sample[i] <- mean(igraph::degree(g_sp))
    out$giant_size[i]    <- max(cmp$csize)
    # Discard degenerate iterations where the giant component is too small
    if (max(cmp$csize) < NULL2_MAX_GAP_FRAC * n_nodes) next
    g_sp_giant          <- induced_subgraph(g_sp, which(cmp$membership == which.max(cmp$csize)))
    out$degree_giant[i] <- mean(igraph::degree(g_sp_giant))
    out$modularity[i]   <- modularity(g_sp_giant,
                                      membership(cluster_leiden(g_sp_giant,
                                                               objective_function   = "modularity",
                                                               resolution_parameter = LEIDEN_RESOLUTION)))
  }
  out
}
summarise_null <- function(x, seed) {
  v <- x$modularity[!is.na(x$modularity)]
  data.frame(seed = seed, observed_mod = obs_mod, null_mean = mean(v), null_sd = sd(v),
             null_n_valid = length(v), p_value = mean(v >= obs_mod),
             observed_mean_degree = target_mean_degree,
             null_degree_mean = mean(x$degree_sample), null_degree_sd = sd(x$degree_sample),
             null_degree_min = min(x$degree_sample), null_degree_max = max(x$degree_sample),
             null_giant_degree_mean = mean(x$degree_giant, na.rm = TRUE),
             null_giant_size_mean = mean(x$giant_size),
             threshold_m_mean = mean(x$threshold_m), threshold_m_min = min(x$threshold_m),
             threshold_m_max = max(x$threshold_m))
}

# --- Result under the declared seed (the one cited in the text) --------------
null2    <- spatial_null(NULL2_SEED)
null2_s  <- summarise_null(null2, NULL2_SEED)
mod_null2_valid <- null2$modularity[!is.na(null2$modularity)]
p_null2  <- null2_s$p_value
cat("Null 2 (spatial, per-draw calibration, n valid =", null2_s$null_n_valid, "): mean =",
    null2_s$null_mean, " sd =", null2_s$null_sd, " p =", p_null2, "\n")
cat("Null 2 mean degree of the sampled networks: mean =", null2_s$null_degree_mean,
    " sd =", null2_s$null_degree_sd, " range =", null2_s$null_degree_min, "-",
    null2_s$null_degree_max, " (observed:", target_mean_degree, ")\n")
if (null2_s$null_n_valid < 900)
  stop("Spatial null: only ", null2_s$null_n_valid, " valid draws out of ", N_PERM,
       " (giant component below ", NULL2_MAX_GAP_FRAC, " of the sample)")

# --- Summary plots -----------------------------------------------------------
hist(null2$degree_sample, breaks = 30,
     main = "Spatial null: mean degree distribution",
     xlab = "Mean degree")
abline(v = target_mean_degree, col = "red", lwd = 2)
hist(mod_null2_valid, breaks = 30,
     main = "Spatial null: modularity distribution",
     xlab = "Modularity",
     xlim = range(c(mod_null2_valid, obs_mod)))
abline(v = obs_mod, col = "red", lwd = 2)
legend("topright",
       legend = sprintf("Observed = %.3f", obs_mod),
       col = "red", lty = 1)

# --- Stability over seeds (documentation only) --------------------------------
# The whole spatial null is repeated under NULL2_STABILITY_SEEDS. The value to
# cite is the one of NULL2_SEED above; these runs only document how much p
# moves with the seed.
null2_stability <- do.call(rbind, lapply(NULL2_STABILITY_SEEDS, function(sd0)
  summarise_null(spatial_null(sd0), sd0)))
null2_stability$declared_seed <- null2_stability$seed == NULL2_SEED
cat("Null 2 stability over", nrow(null2_stability), "seeds: p min =", min(null2_stability$p_value),
    " median =", median(null2_stability$p_value), " max =", max(null2_stability$p_value),
    " | p < 0.05 in", sum(null2_stability$p_value < 0.05), "\n")
write.csv(null2_stability, table_path("null_model_stability.csv"), row.names = FALSE)
message("Saved null_model_stability.csv")

# --- Write results -----------------------------------------------------------
null_results <- data.frame(
  model        = c("null1_degree_preserving", "null2_spatial"),
  observed_mod = obs_mod,
  null_mean    = c(mean(mod_null1), null2_s$null_mean),
  null_sd      = c(sd(mod_null1),   null2_s$null_sd),
  null_n_valid = c(N_PERM, null2_s$null_n_valid),
  p_value      = c(p_null1, p_null2),
  observed_mean_degree = target_mean_degree,
  # degree-preserving rewiring keeps every degree: mean degree is the observed one
  null_degree_mean = c(target_mean_degree, null2_s$null_degree_mean),
  null_degree_sd   = c(0, null2_s$null_degree_sd),
  null_degree_min  = c(target_mean_degree, null2_s$null_degree_min),
  null_degree_max  = c(target_mean_degree, null2_s$null_degree_max)
)
write.csv(null_results, table_path("null_model_results.csv"), row.names = FALSE)
message("Saved null_model_results.csv")
