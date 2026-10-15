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
#         output/tables/module_summary.csv
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

# --- Module summary -----------------------------------------------------------
# Per module: size; median and maximum distance of the members from the
# module centroid (mean of member coordinates, as the cross of fig06);
# composition by tipo_sito / def_sito; member with the highest R-W
# betweenness; where the centroid lies (nearest member and the modern
# municipality, comune, most frequent among the members), so that modules can
# be described by place rather than by number.
site_lab  <- read_site_labels()
siti_rom  <- readRDS(rds_path("siti_rom.rds"))
rom_xy    <- data.frame(id_sito = siti_rom$id_sito, sf::st_coordinates(siti_rom))
mod_sites <- mod_df %>%
  select(id_sito, module) %>%
  left_join(rom_xy, by = "id_sito") %>%
  left_join(site_lab, by = "id_sito") %>%
  left_join(cc_df %>% filter(phase == "roman") %>% select(id_sito, betweenness_norm),
            by = "id_sito")
stopifnot("module members without coordinates or betweenness" =
            !anyNA(mod_sites[, c("X", "Y", "betweenness_norm")]))

count_str <- function(x) {
  t <- sort(table(x), decreasing = TRUE)
  paste(sprintf("%s %d", names(t), as.integer(t)), collapse = "; ")
}
module_summary <- do.call(rbind, lapply(sort(unique(mod_sites$module)), function(m) {
  d   <- mod_sites[mod_sites$module == m, ]
  cx  <- mean(d$X); cy <- mean(d$Y)
  r   <- sqrt((d$X - cx)^2 + (d$Y - cy)^2) / 1000
  ll  <- sf::st_coordinates(sf::st_transform(sf::st_sfc(sf::st_point(c(cx, cy)), crs = CRS_UTM), 4326))
  top <- d[order(-d$betweenness_norm, d$id_sito)[1], ]
  nr  <- d[which.min(r), ]
  com <- sort(table(d$comune), decreasing = TRUE)
  tipo_n <- vapply(TIPO_EN[1:4], function(t) sum(d$tipo_en == t, na.rm = TRUE), integer(1))
  cbind(
    data.frame(module = m, n_sites = nrow(d),
               radius_median_km = median(r), radius_max_km = max(r),
               centroid_x = cx, centroid_y = cy,
               centroid_lon = ll[1, 1], centroid_lat = ll[1, 2],
               centroid_nearest_site = nr$id_sito, centroid_nearest_toponym = nr$toponym,
               centroid_nearest_comune = nr$comune, centroid_nearest_dist_km = min(r),
               main_comune = names(com)[1], main_comune_n = as.integer(com[1]),
               stringsAsFactors = FALSE),
    setNames(as.data.frame(as.list(tipo_n)), paste0("n_", gsub(" ", "_", names(tipo_n)))),
    data.frame(tipo_composition = count_str(d$tipo_en),
               def_composition  = count_str(d$def_en),
               top_btw_site = top$id_sito, top_btw_toponym = top$toponym,
               top_btw_def_sito = top$def_en, top_btw_betweenness_norm = top$betweenness_norm,
               members = paste(sort(d$id_sito), collapse = ";"),
               stringsAsFactors = FALSE))
}))
rownames(module_summary) <- NULL
stopifnot("module sizes must sum to the giant component" =
            sum(module_summary$n_sites) == vcount(giant))
print(module_summary)
write.csv(module_summary, table_path("module_summary.csv"), row.names = FALSE)
message("Saved module_summary.csv")

# --- Save --------------------------------------------------------------------
saveRDS(giant, rds_path("giant.rds"))
saveRDS(cl,    rds_path("cl_leiden.rds"))
message("Saved giant.rds and cl_leiden.rds")
