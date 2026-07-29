# =============================================================================
# 04b_betweenness_concentration_sweep.R — Betweenness concentration across
#   cost-distance thresholds
#
# For each threshold in THRESH_SEQ, rebuilds both networks and computes four
# concentration metrics on the normalised betweenness distribution:
#   top1_share    — fraction of total betweenness held by the single top node
#   ratio_1st_2nd — ratio of the top node to the second-highest node
#   top5_share    — fraction held by the five highest-betweenness nodes
#   gini          — Gini coefficient (0 = perfectly even, 1 = fully concentrated)
#
# A focused comparison at the two analysis thresholds (150 and 240 min) is
# also printed to the console.
#
# Input:  output/rds/edges_hell.rds
#         output/rds/edges_rom.rds
#         output/rds/nodes_hell.rds
#         output/rds/nodes_rom.rds
# Output: output/tables/betweenness_concentration_sweep.csv
# =============================================================================

edges_hell <- readRDS(rds_path("edges_hell.rds"))
edges_rom  <- readRDS(rds_path("edges_rom.rds"))
nodes_hell <- readRDS(rds_path("nodes_hell.rds"))
nodes_rom  <- readRDS(rds_path("nodes_rom.rds"))

# Gini coefficient of a distribution (0 = perfectly even, 1 = fully concentrated)
gini <- function(x) {
  x <- sort(x[!is.na(x)])
  n <- length(x)
  if (sum(x) == 0) return(NA_real_)
  sum((2 * seq_len(n) - n - 1) * x) / (n * sum(x))
}

concentration_at <- function(edges, nodes, t, phase) {
  ef <- edges %>% filter(cost_mean < t)
  g  <- graph_from_data_frame(d = ef, vertices = nodes, directed = FALSE)
  b  <- igraph::betweenness(g, normalized = TRUE)
  bs <- sort(b, decreasing = TRUE)
  data.frame(
    phase          = phase,
    threshold      = t,
    n_edges        = ecount(g),
    density        = edge_density(g),
    top1_share     = if (sum(bs) > 0) bs[1] / sum(bs) else NA_real_,
    ratio_1st_2nd  = if (bs[2] > 0) bs[1] / bs[2] else NA_real_,
    top5_share     = if (sum(bs) > 0) sum(bs[1:5]) / sum(bs) else NA_real_,
    gini           = gini(b)
  )
}

THRESH_SEQ <- seq(90, 300, by = 30)

conc <- bind_rows(
  lapply(THRESH_SEQ, function(t) concentration_at(edges_hell, nodes_hell, t, "hellenistic")),
  lapply(THRESH_SEQ, function(t) concentration_at(edges_rom,  nodes_rom,  t, "roman"))
)

print(conc, digits = 3)
write.csv(conc, table_path("betweenness_concentration_sweep.csv"), row.names = FALSE)
message("Saved betweenness_concentration_sweep.csv")

# --- Focused comparison at the two analysis thresholds -----------------------
cat("\n--- Comparison at analysis thresholds ---\n")
conc %>% filter(threshold %in% c(150, 240)) %>%
  select(phase, threshold, density, top1_share, ratio_1st_2nd, gini) %>%
  arrange(threshold, phase) %>%
  print(digits = 3)
