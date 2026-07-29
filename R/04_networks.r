# =============================================================================
# 04_networks.R — Network construction, centrality, and threshold analysis
#
# Loads the LCP edge files, collapses bidirectional pairs into undirected
# edges, filters by cost threshold, and computes three centrality metrics.
# Also runs the Roman threshold sensitivity sweep (originally 02c_roman
# sensitivity.R).
#
# Input:  output/rds/siti_hell.rds
#         output/rds/siti_rom.rds
#         output/rds/lcp_hell.gpkg
#         output/rds/lcp_roman.gpkg
#         output/rds/cost_surface_rom.rds   (needed to resolve cell→site IDs)
# Output: output/rds/net_hell.rds
#         output/rds/net_rom.rds
#         output/rds/edges_hell.rds
#         output/rds/edges_rom.rds
#         output/rds/nodes_hell.rds
#         output/rds/nodes_rom.rds
#         output/tables/threshold_sweep_roman.csv
# =============================================================================

# --- Load sites --------------------------------------------------------------
siti_hell <- readRDS(rds_path("siti_hell.rds"))
siti_rom  <- readRDS(rds_path("siti_rom.rds"))

# Add integer row index used as node ID throughout (must match the original
# ordering in which LCPs were computed).
siti_hell$numero_riga <- 1:nrow(siti_hell)
siti_hell <- siti_hell %>%
  select(-any_of("id")) %>%
  rename(id = numero_riga) %>%
  select(id, everything())

siti_rom$numero_riga <- 1:nrow(siti_rom)
siti_rom <- siti_rom %>%
  select(-any_of("id")) %>%
  rename(id = numero_riga) %>%
  select(id, everything())

nodes_hell <- as.data.frame(siti_hell)
nodes_rom  <- as.data.frame(siti_rom)

# =============================================================================
# HELLENISTIC NETWORK
# =============================================================================
lcp_hell <- st_read(rds_path("lcp_hell.gpkg")) %>%
  rename(from = origin_ID, to = destination_ID) %>%
  select(from, to, everything())

lcp_hell$cost_min <- lcp_hell$cost / 60
hist(lcp_hell$cost_min,
     main = "Cost distribution — Hellenistic LCPs",
     xlab = "Cost (minutes)", breaks = 60)

edges_hell <- collapse_directional_edges(lcp_hell$from, lcp_hell$to, lcp_hell$cost_min)
message("Hellenistic edges with only 1 direction computed: ",
        sum(edges_hell$n_directions == 1))

edges_hell_filtered <- edges_hell %>% filter(cost_mean < HELL_THRESH)

net_hell <- graph_from_data_frame(d = edges_hell_filtered,
                                  vertices = nodes_hell, directed = FALSE)
V(net_hell)$degree      <- igraph::degree(net_hell)
V(net_hell)$closeness   <- igraph::closeness(net_hell)
V(net_hell)$betweenness <- igraph::betweenness(net_hell)

isolates_hell <- V(net_hell)$name[V(net_hell)$degree == 0]
message("Hellenistic isolates (", length(isolates_hell), "): ",
        paste(isolates_hell, collapse = ", "))

# =============================================================================
# ROMAN NETWORK
# =============================================================================
# The Roman LCP file stores cell indices rather than site IDs. Reconstruct a
# raster template from the cost-surface metadata to convert cell→site.
cost_surface_rom <- readRDS(rds_path("cost_surface_rom.rds"))
cs_rast_rom <- terra::rast(
  nrow = cost_surface_rom$nrow, ncol = cost_surface_rom$ncol,
  xmin = cost_surface_rom$extent[1], xmax = cost_surface_rom$extent[2],
  ymin = cost_surface_rom$extent[3], ymax = cost_surface_rom$extent[4],
  crs  = cost_surface_rom$crs
)

site_cells_rom <- data.frame(
  id   = siti_rom$id,
  cell = terra::cellFromXY(cs_rast_rom, sf::st_coordinates(siti_rom))
)
# Sanity check: no two sites may share a raster cell
if (sum(duplicated(site_cells_rom$cell)) > 0)
  warning("Duplicate raster cells detected among Roman sites — check snapping")

lcp_rom <- st_read(rds_path("lcp_roman.gpkg")) %>%
  left_join(site_cells_rom, by = c("fromCell" = "cell")) %>% rename(from = id) %>%
  left_join(site_cells_rom, by = c("toCell"   = "cell")) %>% rename(to   = id) %>%
  select(from, to, everything())

# Sanity checks on the join
if (sum(is.na(lcp_rom$from)) > 0 || sum(is.na(lcp_rom$to)) > 0)
  warning("NA values in from/to after cell-to-site join")

lcp_rom$cost_min <- lcp_rom$cost / 60
hist(lcp_rom$cost_min,
     main = "Cost distribution — Roman LCPs",
     xlab = "Cost (minutes)", breaks = 60)

edges_rom <- collapse_directional_edges(lcp_rom$from, lcp_rom$to, lcp_rom$cost_min)
message("Roman edges with only 1 direction computed: ",
        sum(edges_rom$n_directions == 1))

edges_rom_filtered <- edges_rom %>% filter(cost_mean < ROM_THRESH)

net_rom <- graph_from_data_frame(d = edges_rom_filtered,
                                 vertices = nodes_rom, directed = FALSE)
V(net_rom)$degree      <- igraph::degree(net_rom)
V(net_rom)$closeness   <- igraph::closeness(net_rom)
V(net_rom)$betweenness <- igraph::betweenness(net_rom)

isolates_rom <- V(net_rom)$name[V(net_rom)$degree == 0]
message("Roman isolates (", length(isolates_rom), "): ",
        paste(isolates_rom, collapse = ", "))

# =============================================================================
# COMPONENT ANALYSIS
# =============================================================================
for (nm in c("net_hell", "net_rom")) {
  g   <- get(nm)
  cmp <- igraph::components(g)
  cat(nm, ": n components =", cmp$no,
      "| max size =", max(cmp$csize),
      "| giant fraction =", round(max(cmp$csize) / vcount(g), 3),
      "| sizes:", paste(sort(cmp$csize, decreasing = TRUE), collapse = ","), "\n")
}

# =============================================================================
# ROMAN THRESHOLD SENSITIVITY SWEEP (originally 02c_roman sensitivity.R)
# Tests thresholds from 30 to 300 minutes to justify the 150-minute cutoff.
# =============================================================================
sweep_results <- lapply(SENSITIVITY_SEQ, function(t) {
  ef <- edges_rom %>% filter(cost_mean < t)
  g  <- graph_from_data_frame(d = ef, vertices = nodes_rom, directed = FALSE)
  cmp <- igraph::components(g)   # <- deve essere qui, ricalcolato per QUESTO g
  
  data.frame(
    threshold    = t,
    n_edges      = ecount(g),
    n_isolates   = sum(igraph::degree(g) == 0),
    pct_isolates = sum(igraph::degree(g) == 0) / vcount(g),
    mean_degree  = mean(igraph::degree(g)),
    n_components     = cmp$no,
    giant_size       = max(cmp$csize),
    giant_fraction   = max(cmp$csize) / vcount(g)
  )
}) %>% bind_rows()

print(sweep_results)

plot(sweep_results$threshold, sweep_results$pct_isolates, type = "b",
     xlab = "Threshold (min)", ylab = "Proportion isolated sites",
     main = "Roman network: threshold sensitivity")
abline(h = 0.1, col = "red", lty = 2)   # reference: 10% isolates

write.csv(sweep_results, table_path("threshold_sweep_roman.csv"), row.names = FALSE)
message("Saved threshold_sweep_roman.csv")

# Sites that remain isolated even at 300 min
g_300 <- graph_from_data_frame(
  d = edges_rom %>% filter(cost_mean < 300), vertices = nodes_rom, directed = FALSE)
stubborn_cells <- V(g_300)$name[igraph::degree(g_300) == 0]
message("Persistently isolated sites (at 300 min): ",
        paste(nodes_rom$id_sito[nodes_rom$id %in% as.integer(stubborn_cells)],
              collapse = ", "))

# =============================================================================
# SAVE
# =============================================================================
saveRDS(net_hell,            rds_path("net_hell.rds"))
saveRDS(net_rom,             rds_path("net_rom.rds"))
saveRDS(edges_hell,          rds_path("edges_hell.rds"))
saveRDS(edges_rom,           rds_path("edges_rom.rds"))
saveRDS(edges_hell_filtered, rds_path("edges_hell_filtered.rds"))
saveRDS(edges_rom_filtered,  rds_path("edges_rom_filtered.rds"))
saveRDS(nodes_hell,          rds_path("nodes_hell.rds"))
saveRDS(nodes_rom,           rds_path("nodes_rom.rds"))

# Save processed LCP sf objects (with from/to site-ID columns resolved) so
# 09_figures.R can join them to the filtered edge table without re-doing the
# cell→site mapping.
saveRDS(lcp_hell, rds_path("lcp_hell_processed.rds"))
saveRDS(lcp_rom,  rds_path("lcp_rom_processed.rds"))
message("Network objects saved.")
