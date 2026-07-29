# =============================================================================
# 06_community_detection.R — Leiden community detection (Roman giant component)
#
# Extracts the giant component of the Roman network, runs Leiden modularity
# clustering, cross-tabulates communities with site type, and tests whether
# betweenness varies by site type.
#
# Community detection is run on the UNWEIGHTED graph topology (site adjacency
# under the cost-distance threshold), not on a cost-weighted variant.  This is
# deliberate: the unweighted partition is directly comparable to both null
# models in 07_null_models.R, which also operate on the unweighted giant.
#
# Input:  output/rds/net_rom.rds
#         output/rds/nodes_rom.rds
#         data/sites.gpkg        (for tipo_sito site-type labels)
#         output/tables/centrality_comparison.csv
# Output: output/rds/giant.rds
#         output/rds/cl_leiden.rds
#         output/tables/community_by_sitetype.csv
# =============================================================================

net_rom    <- readRDS(rds_path("net_rom.rds"))
nodes_rom  <- readRDS(rds_path("nodes_rom.rds"))

# sites.gpkg is the authoritative source for site attributes (including tipo_sito).
# st_drop_geometry() strips the spatial column so downstream joins stay tabular.
siti_raw <- sf::st_read(data_path("sites.gpkg"), quiet = TRUE) %>%
  sf::st_drop_geometry()

# --- Giant component ---------------------------------------------------------
cmp   <- igraph::components(net_rom)
giant <- induced_subgraph(net_rom,
                          which(cmp$membership == which.max(cmp$csize)))

# --- Leiden clustering -------------------------------------------------------
set.seed(COMMUNITY_SEED)
cl <- cluster_leiden(giant,
                     objective_function  = "modularity",
                     resolution_parameter = LEIDEN_RESOLUTION)

cat("Leiden result: n modules =", length(unique(membership(cl))),
    " | modularity =", modularity(giant, membership(cl)), "\n")
print(table(membership(cl)))

# --- Community × site-type cross-table ---------------------------------------
mod_df <- data.frame(
  id     = as.integer(V(giant)$name),
  module = as.integer(membership(cl))
) %>%
  left_join(nodes_rom %>% select(id, id_sito), by = "id") %>%
  left_join(siti_raw  %>% select(id_sito, tipo_sito), by = "id_sito")

community_table <- mod_df %>%
  count(module, tipo_sito) %>%
  tidyr::pivot_wider(names_from = tipo_sito, values_from = n, values_fill = 0)

print(community_table, width = Inf)

write.csv(community_table, table_path("community_by_sitetype.csv"), row.names = FALSE)
message("Saved community_by_sitetype.csv")

# Membership list by community
split(mod_df$id_sito, mod_df$module)

# --- Betweenness by site type (Roman, Kruskal-Wallis) ------------------------
cc_df  <- read.csv(table_path("centrality_comparison.csv"), stringsAsFactors = FALSE)
r_data <- cc_df %>%
  filter(phase == "roman") %>%
  left_join(siti_raw %>% select(id_sito, tipo_sito), by = "id_sito")

r_data %>%
  group_by(tipo_sito) %>%
  summarise(n        = n(),
            btw_med  = median(betweenness_norm),
            btw_max  = max(betweenness_norm),
            deg_med  = median(degree)) %>%
  arrange(desc(btw_med)) %>%
  print()

kruskal.test(betweenness_norm ~ tipo_sito, data = r_data)

r_data %>%
  slice_max(betweenness_norm, n = 15) %>%
  select(id_sito, tipo_sito, degree, betweenness_norm) %>%
  print()

# --- Save --------------------------------------------------------------------
saveRDS(giant, rds_path("giant.rds"))
saveRDS(cl,    rds_path("cl_leiden.rds"))
message("Saved giant.rds and cl_leiden.rds")
