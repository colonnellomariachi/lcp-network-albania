# =============================================================================
# 09_figures.R — Publication-quality figures
#
# Main manuscript figures (output/images/):
#   fig01_sites_dem.png              — study area overview: DEM + all sites
#   fig02_hellenistic_model.png      — Tobler cost surface | Hellenistic LCPs
#   fig03_roman_model.png            — wheeled-transport surface | Roman LCPs
#   fig04_boxplot_centrality.png     — boxplots of all centrality metrics by phase
#   fig05_centrality_maps.png        — composite geographic centrality maps
#                                      (degree / harmonic / betweenness, 3-row panel)
#   fig06_communities.png            — Leiden community partition, Roman giant component
#   fig07_scatter_dualphase.png      — scatter plot for dual-phase sites
#   fig08_threshold_sensitivity.png  — Roman network threshold sensitivity
#   fig09_egnatia_full_corridors.png — full Egnatia LCPs overlaid on cost corridors
#                                      (wheeled | Tobler, 2-panel)
#   fig10_egnatia_segments.png       — three-panel per-segment comparison (wheeled)
#
# Supplementary / legacy:
#   fig_concentration_sweep.png    — betweenness concentration vs threshold (04b)
#   fig04_networks.png             — network topology in geographic space [ex fig04]
#   fig_map_degree.png             — geographic map, degree centrality [component of fig05]
#   fig_map_harmonic.png           — geographic map, harmonic centrality [component of fig05]
#   fig_map_betweenness.png        — geographic map, normalised betweenness [component of fig05]
#
# Also produces igraph geographic layout plots for both networks
# (originally in plot_rete_geografico.R) — printed to screen only.
#
# Input:  output/tables/centrality_comparison.csv
#         output/rds/net_hell.rds
#         output/rds/net_rom.rds
#         output/rds/nodes_hell.rds
#         output/rds/nodes_rom.rds
#         output/rds/siti_hell.rds
#         output/rds/siti_rom.rds
#         output/rds/edges_hell_filtered.rds
#         output/rds/edges_rom_filtered.rds
#         output/rds/lcp_hell_processed.rds
#         output/rds/lcp_rom_processed.rds
#         output/tables/betweenness_concentration_sweep.csv
#         output/tables/threshold_sweep_roman.csv
#         output/rds/egnatia_stitched.rds
#         output/rds/wp_snapped.rds
#         output/rds/egnatia_known_segments.rds
#         output/rds/lcp_egnatia_tobler_seg{1,2,3}.rds
#         output/rds/lcp_egnatia_wheeled_seg{1,2,3}.rds
#         output/rds/lcp_egnatia_tobler_full.rds
#         output/rds/lcp_egnatia_wheeled_full.rds
#         output/rds/corr_tobler.rds
#         output/rds/corr_wheeled.rds
#         output/tables/egnatia_pdi_final.csv
# =============================================================================

library(patchwork)   # | and / operators for panel composition
library(ggspatial)   # annotation_scale()

# =============================================================================
# SHARED DATA — loaded once, reused across multiple figures
# =============================================================================

# --- Centrality table ---------------------------------------------------------
cc <- read.csv(table_path("centrality_comparison.csv"), stringsAsFactors = FALSE)
cc$phase <- factor(cc$phase, levels = c("hellenistic", "roman"))

# Normalised degree: raw degree is not comparable across networks of different size
n_nodes_per_phase <- cc %>% count(phase, name = "n")
cc <- cc %>%
  left_join(n_nodes_per_phase, by = "phase") %>%
  mutate(degree_norm = degree / (n - 1))

metric_levels <- c("degree_norm", "harmonic", "betweenness_norm")
metric_labels <- c("Degree (norm.)", "Harmonic Centrality (norm.)", "Betweenness (norm.)")

# --- Network / LCP objects ----------------------------------------------------
edges_hell_filtered <- readRDS(rds_path("edges_hell_filtered.rds"))
edges_rom_filtered  <- readRDS(rds_path("edges_rom_filtered.rds"))
lcp_hell_sf         <- readRDS(rds_path("lcp_hell_processed.rds"))
lcp_rom_sf          <- readRDS(rds_path("lcp_rom_processed.rds"))

# LCP edge layers filtered to network edges only
lcp_hell_plot <- lcp_hell_sf %>%
  inner_join(edges_hell_filtered %>% select(from, to), by = c("from", "to"))
lcp_rom_plot  <- lcp_rom_sf %>%
  inner_join(edges_rom_filtered  %>% select(from, to), by = c("from", "to"))

net_hell   <- readRDS(rds_path("net_hell.rds"))
net_rom    <- readRDS(rds_path("net_rom.rds"))
nodes_hell <- readRDS(rds_path("nodes_hell.rds"))
nodes_rom  <- readRDS(rds_path("nodes_rom.rds"))
siti_hell  <- readRDS(rds_path("siti_hell.rds"))
siti_rom   <- readRDS(rds_path("siti_rom.rds"))

# Roman sites with the four waypoints removed (used in Egnatia figures)
siti_rom_bg <- siti_rom %>% filter(!id_sito %in% WAYPOINT_IDS)

# cc as sf (for geographic centrality maps)
cc_sf <- st_as_sf(cc, coords = c("X", "Y"), crs = CRS_UTM)

# --- Shared theme and constants -----------------------------------------------
theme_fig <- theme_minimal(base_size = 10) +
  theme(axis.text        = element_text(size = 7),
        plot.title       = element_text(size = 10, face = "bold"),
        legend.key.width = unit(0.4, "cm"))
lon_breaks <- seq(19.0, 21.0, by = 0.5)

# BUG FIX: use [[ ]] to avoid inner name leaking into the element name
# (e.g. "Wheeled-transport LCP.roman") which breaks scale_colour_manual matching
egnatia_cols <- c(
  "Attested route"        = "black",
  "Wheeled-transport LCP" = PHASE_COLS[["roman"]],
  "Tobler LCP"            = PHASE_COLS[["hellenistic"]]
)

# Site-point constants shared across Egnatia figures (fig09–fig10)
SITE_LABEL <- "Roman-phase sites"
SITE_FILL  <- "grey70"
SITE_BDR   <- "grey30"
SITE_SZ    <- 1.2
SITE_STR   <- 0.25
SITE_ALPHA <- 0.75

# Human-readable waypoint labels (west → east)
wp_site_names <- c(DUR001 = "Dyrrachium", DUR022 = "Clodiana",
                   DUR024 = "Ad Quintum", DUR017 = "Scampis")

# =============================================================================
# FIG 01 — Study area overview: DEM + all archaeological sites
# =============================================================================
dem_raw   <- terra::rast(data_path("dem.tif"))
dem_agg   <- terra::aggregate(dem_raw, fact = 4)
dem_df    <- as.data.frame(dem_agg, xy = TRUE)
names(dem_df)[3] <- "elevation"

sites_all <- sf::st_read(data_path("sites.gpkg"), quiet = TRUE) %>%
  sf::st_transform(CRS_UTM)

p_fig01 <- ggplot() +
  geom_raster(data = dem_df, aes(x = x, y = y, fill = elevation)) +
  scale_fill_viridis_c(option = "mako", na.value = "transparent",
                       name = "Elevation (m)") +
  geom_sf(data = sites_all, size = 1.5, shape = 21,
          fill = "white", colour = "black", stroke = 0.4) +
  coord_sf(crs = CRS_UTM) +
  scale_x_continuous(breaks = lon_breaks) +
  labs(x = NULL, y = NULL) +
  theme_fig

ggsave(image_path("fig01_sites_dem.png"),
       p_fig01, width = 7, height = 7, dpi = 300)
message("Saved fig01_sites_dem.png")

# =============================================================================
# FIG 02 — Hellenistic model: Tobler cost surface | Hellenistic LCPs
# =============================================================================
# rasterise() converts the conductanceMatrix to SpatRaster; aggregate to 100 m
cs_hell_rast <- terra::aggregate(
  leastcostpath::rasterise(readRDS(rds_path("cost_surface_hell.rds"))), fact = 4)
cs_hell_df   <- as.data.frame(cs_hell_rast, xy = TRUE)
names(cs_hell_df)[3] <- "conductance"

p_cs_hell <- ggplot() +
  geom_raster(data = cs_hell_df, aes(x = x, y = y, fill = conductance)) +
  scale_fill_viridis_c(option = "inferno", na.value = "transparent",
                       name = "Conductance") +
  geom_sf(data = siti_hell, size = 1.2, shape = 21,
          fill = PHASE_COLS["hellenistic"], colour = "white", stroke = 0.3) +
  coord_sf(crs = CRS_UTM) +
  scale_x_continuous(breaks = lon_breaks) +
  labs(x = NULL, y = NULL, title = "(a) Tobler cost surface") +
  theme_fig

p_lcp_hell_fig <- ggplot() +
  geom_sf(data = lcp_hell_plot, colour = "grey50", linewidth = 0.2) +
  geom_sf(data = siti_hell, size = 1.5, shape = 21,
          fill = PHASE_COLS["hellenistic"], colour = "white", stroke = 0.3) +
  coord_sf(crs = CRS_UTM) +
  scale_x_continuous(breaks = lon_breaks) +
  labs(x = NULL, y = NULL, title = "(b) Hellenistic LCPs") +
  theme_fig

ggsave(image_path("fig02_hellenistic_model.png"),
       p_cs_hell | p_lcp_hell_fig, width = 10, height = 5, dpi = 300)
message("Saved fig02_hellenistic_model.png")

rm(cs_hell_rast, cs_hell_df); gc(verbose = FALSE)

# =============================================================================
# FIG 03 — Roman model: wheeled-transport cost surface | Roman LCPs
# =============================================================================
cs_rom_rast <- terra::aggregate(
  leastcostpath::rasterise(readRDS(rds_path("cost_surface_rom.rds"))), fact = 4)
cs_rom_df   <- as.data.frame(cs_rom_rast, xy = TRUE)
names(cs_rom_df)[3] <- "conductance"

p_cs_rom <- ggplot() +
  geom_raster(data = cs_rom_df, aes(x = x, y = y, fill = conductance)) +
  scale_fill_viridis_c(option = "inferno", na.value = "transparent",
                       name = "Conductance") +
  geom_sf(data = siti_rom, size = 1.2, shape = 21,
          fill = PHASE_COLS["roman"], colour = "white", stroke = 0.3) +
  coord_sf(crs = CRS_UTM) +
  scale_x_continuous(breaks = lon_breaks) +
  labs(x = NULL, y = NULL, title = "(a) Wheeled-transport cost surface") +
  theme_fig

p_lcp_rom_fig <- ggplot() +
  geom_sf(data = lcp_rom_plot, colour = "grey50", linewidth = 0.2) +
  geom_sf(data = siti_rom, size = 1.5, shape = 21,
          fill = PHASE_COLS["roman"], colour = "white", stroke = 0.3) +
  coord_sf(crs = CRS_UTM) +
  scale_x_continuous(breaks = lon_breaks) +
  labs(x = NULL, y = NULL, title = "(b) Roman LCPs") +
  theme_fig

ggsave(image_path("fig03_roman_model.png"),
       p_cs_rom | p_lcp_rom_fig, width = 10, height = 5, dpi = 300)
message("Saved fig03_roman_model.png")

rm(cs_rom_rast, cs_rom_df, dem_raw, dem_agg, dem_df); gc(verbose = FALSE)

# =============================================================================
# FIG 04 — Boxplots: centrality distributions by phase
# =============================================================================
cc_long <- cc %>%
  select(id_sito, phase, all_of(metric_levels)) %>%
  pivot_longer(-c(id_sito, phase), names_to = "metric", values_to = "value") %>%
  mutate(metric = factor(metric, levels = metric_levels, labels = metric_labels))

p_box <- ggplot(cc_long, aes(x = phase, y = value, fill = phase)) +
  geom_boxplot(outlier.shape = NA, width = 0.5, alpha = 0.85) +
  geom_jitter(width = 0.12, alpha = 0.3, size = 0.8) +
  facet_wrap(~ metric, scales = "free_y") +
  scale_fill_manual(values = PHASE_COLS) +
  labs(x = NULL, y = "Value") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "none", strip.text = element_text(face = "bold"))

print(p_box)
ggsave(image_path("fig04_boxplot_centrality.png"),
       p_box, width = 9, height = 3.5, dpi = 300)
message("Saved fig04_boxplot_centrality.png")

# Descriptive statistics + Wilcoxon tests
cc_long %>%
  group_by(metric) %>%
  summarise(
    med_hell = median(value[phase == "hellenistic"]),
    med_rom  = median(value[phase == "roman"]),
    iqr_hell = IQR(value[phase == "hellenistic"]),
    iqr_rom  = IQR(value[phase == "roman"]),
    p_wilcox = wilcox.test(value ~ phase)$p.value,
    .groups  = "drop"
  ) %>% print()

# =============================================================================
# FIG 05 — Composite centrality maps (degree / harmonic / betweenness)
#          Three rows, each row = one metric with hellenistic | roman facets
# =============================================================================
make_map <- function(metric_col, label) {
  ggplot() +
    geom_sf(data = lcp_hell_plot %>% mutate(phase = "hellenistic"),
            colour = "grey70", linewidth = 0.2) +
    geom_sf(data = lcp_rom_plot  %>% mutate(phase = "roman"),
            colour = "grey70", linewidth = 0.2) +
    geom_sf(data = cc_sf,
            aes(size = .data[[metric_col]], colour = .data[[metric_col]]),
            alpha = 0.85) +
    facet_wrap(~ phase) +
    scale_colour_viridis_c(option = "magma", direction = -1) +
    scale_size_continuous(range = c(0.8, 5)) +
    guides(size = "none") +
    labs(colour = label, x = NULL, y = NULL) +
    theme_minimal(base_size = 10) +
    theme(strip.text = element_text(face = "bold"),
          axis.text  = element_text(size = 6))
}

p_map_deg <- make_map("degree_norm",      "Degree (norm.)")
p_map_clo <- make_map("harmonic",         "Harmonic Centrality (norm.)")
p_map_btw <- make_map("betweenness_norm", "Betweenness (norm.)")

# Composite: three rows stacked vertically
p_fig05 <- (p_map_deg / p_map_clo / p_map_btw) +
  plot_layout(guides = "keep")

ggsave(image_path("fig05_centrality_maps.png"),
       p_fig05, width = 9, height = 15, dpi = 300)
message("Saved fig05_centrality_maps.png")

# =============================================================================
# FIG 06 — Leiden community partition of the Roman network's largest component
#
# Loads pre-computed objects from 06_community_detection.R.
# DO NOT re-run community detection: module labels are iteration-dependent
# and must match the manuscript numbering:
#   mod 1 (n=11), mod 2 (n=6), mod 3 (n=7, DUR102/Rromanat),
#   mod 4 (n=15, Kavaja plain), mod 5 (n=5), mod 6 (n=22, DUR054/Kryeluz)
#
# Caption:
#   Figure 6. Leiden community partition of the Roman network's largest
#   component (66 nodes, modularity 0.605). Sites outside the largest
#   component (grey) were not included in community detection. The
#   partition is descriptive of network structure; it is not statistically
#   distinguishable from a spatial null model (Section 4.3) and should not
#   be read as evidence of territorial administration.
# =============================================================================

giant_g   <- readRDS(rds_path("giant.rds"))
cl_leiden <- readRDS(rds_path("cl_leiden.rds"))

# --- Verification: module sizes must match manuscript numbering ---------------
expected_sizes <- sort(c(11L, 6L, 7L, 15L, 5L, 22L))
actual_sizes   <- sort(as.integer(table(membership(cl_leiden))))
if (!identical(actual_sizes, expected_sizes)) {
  stop(paste0(
    "Module sizes do not match expected {5, 6, 7, 11, 15, 22}.\n",
    "Actual:   ", paste(actual_sizes,   collapse = ", "), "\n",
    "Expected: ", paste(expected_sizes, collapse = ", "), "\n",
    "cl_leiden.rds may not be the object that generated the published numbers.\n",
    "Do NOT re-run community detection — investigate before proceeding."
  ))
}

# --- Build module membership table (mirrors 06_community_detection.R) ---------
mod_df <- data.frame(
  id     = as.integer(V(giant_g)$name),
  module = as.integer(membership(cl_leiden))
) %>%
  left_join(nodes_rom %>% select(id, id_sito), by = "id")

# Cross-check key site assignments against manuscript numbering
stopifnot("DUR050 must be in module 4" = mod_df$module[mod_df$id_sito == "DUR050"] == 4L)
stopifnot("DUR054 must be in module 6" = mod_df$module[mod_df$id_sito == "DUR054"] == 6L)
stopifnot("DUR102 must be in module 3" = mod_df$module[mod_df$id_sito == "DUR102"] == 3L)
message("Fig 06 module verification passed: sizes and key site assignments correct.")

# Join X/Y from centrality table (cc has X, Y for all Roman sites)
cc_rom <- cc %>% filter(phase == "roman")
mod_spatial <- mod_df %>%
  left_join(cc_rom %>% select(id_sito, X, Y, degree), by = "id_sito") %>%
  mutate(
    module_f = factor(module, levels = 1:6,
                      labels = c("1 (n=11)", "2 (n=6)",  "3 (n=7)",
                                 "4 (n=15)", "5 (n=5)",  "6 (n=22)"))
  )

# Module 4 centroid (cited in §5.3: "~4 km north of modern Kavaja")
# Derived from module 4 node coordinates — deterministic, not a Leiden output
mod4_xy <- mod_spatial %>% filter(module == 4) %>%
  summarise(X = mean(X), Y = mean(Y))
mod4_sf <- sf::st_sf(
  geometry = sf::st_sfc(
    sf::st_point(c(mod4_xy$X, mod4_xy$Y)), crs = CRS_UTM
  )
)

# Sites outside the giant component: all Roman sites absent from mod_df
giant_ids    <- mod_df$id_sito
non_giant_sf <- siti_rom %>% filter(!id_sito %in% giant_ids)
message(sprintf("Giant: %d sites | Outside giant: %d sites",
                nrow(mod_spatial), nrow(non_giant_sf)))

# Labels: key sites inside the giant (bold)
label_giant <- mod_spatial %>%
  filter(id_sito %in% c("DUR050", "DUR054", "DUR102"))

# Labels: key non-giant sites cited in §5.5 (Clodiana, Ad Quintum, Burizane)
label_nongiant <- non_giant_sf %>%
  filter(id_sito %in% c("DUR022", "DUR024", "DUR059")) %>%
  mutate(X = sf::st_coordinates(.)[, 1],
         Y = sf::st_coordinates(.)[, 2]) %>%
  sf::st_drop_geometry()

# --- DEM background (grey gradient, coarser resolution — geographic context) --
dem_raw_f06 <- terra::rast(data_path("dem.tif"))
dem_agg_f06 <- terra::aggregate(dem_raw_f06, fact = 8)
dem_df_f06  <- as.data.frame(dem_agg_f06, xy = TRUE)
names(dem_df_f06)[3] <- "elevation"
rm(dem_raw_f06, dem_agg_f06)

# --- Figure -------------------------------------------------------------------
p_fig06 <- ggplot() +
  # Subtle DEM background — same extent as fig01/02/03; grey avoids competing
  # with the six qualitative module colours
  geom_raster(data = dem_df_f06,
              aes(x = x, y = y, fill = elevation),
              show.legend = FALSE) +
  scale_fill_gradient(low = "grey97", high = "grey72",
                      na.value = "transparent",
                      guide = "none") +
  # Sites outside giant: grey hollow circles (excluded from community detection)
  geom_sf(data = non_giant_sf, shape = 21, size = 1.4,
          fill = NA, colour = "grey55", stroke = 0.4) +
  # Giant component nodes: solid circles, coloured by module (nominal palette)
  geom_point(data = mod_spatial,
             aes(x = X, y = Y, colour = module_f),
             shape = 16, size = 2.2, alpha = 0.92) +
  scale_colour_brewer(palette = "Set2", name = "Module") +
  # Module 4 centroid: cross (+) symbol, cited in §5.3
  geom_sf(data = mod4_sf, shape = 3, size = 5,
          colour = "black", stroke = 1.0,
          show.legend = FALSE) +
  # Labels: giant sites cited in text (bold)
  geom_text_repel(data    = label_giant,
                  aes(x = X, y = Y, label = id_sito),
                  size         = 2.5,
                  fontface     = "bold",
                  colour       = "black",
                  box.padding  = 0.35,
                  max.overlaps = 20,
                  seed         = COMMUNITY_SEED) +
  # Labels: non-giant sites cited in §5.5 (grey italic)
  geom_text_repel(data    = label_nongiant,
                  aes(x = X, y = Y, label = id_sito),
                  size         = 2.3,
                  fontface     = "italic",
                  colour       = "grey40",
                  box.padding  = 0.3,
                  max.overlaps = 20,
                  seed         = COMMUNITY_SEED) +
  coord_sf(crs = CRS_UTM) +
  scale_x_continuous(breaks = lon_breaks) +
  labs(x = NULL, y = NULL) +
  theme_fig +
  theme(legend.position = "right")

ggsave(image_path("fig06_communities.png"),
       p_fig06, width = 8, height = 7, dpi = 300)
message("Saved fig06_communities.png")

rm(giant_g, cl_leiden, mod_df, mod_spatial, mod4_xy, mod4_sf,
   non_giant_sf, label_giant, label_nongiant, dem_df_f06,
   giant_ids, cc_rom); gc(verbose = FALSE)

# =============================================================================
# FIG 07 — Scatter: dual-phase sites, Hellenistic vs Roman centrality
# =============================================================================
dual <- cc %>%
  select(id_sito, phase, all_of(metric_levels)) %>%
  pivot_longer(-c(id_sito, phase), names_to = "metric", values_to = "value") %>%
  pivot_wider(names_from = phase, values_from = value) %>%
  filter(!is.na(hellenistic), !is.na(roman)) %>%
  mutate(
    metric = factor(metric, levels = metric_levels, labels = metric_labels),
    delta  = roman - hellenistic
  )

p_scatter <- ggplot(dual, aes(x = hellenistic, y = roman)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey50") +
  geom_point(aes(colour = delta), size = 2.2, alpha = 0.9) +
  geom_text_repel(
    data  = dual %>% group_by(metric) %>% slice_max(abs(delta), n = 6),
    aes(label = id_sito), size = 2.4, max.overlaps = 20, seed = SCATTER_SEED
  ) +
  facet_wrap(~ metric, scales = "free") +
  scale_colour_gradient2(low = "#B2182B", mid = "grey85", high = "#2166AC",
                         midpoint = 0) +
  labs(x = "Hellenistic", y = "Roman", colour = "\u0394") +
  theme_minimal(base_size = 11) +
  theme(strip.text = element_text(face = "bold"))

print(p_scatter)
ggsave(image_path("fig07_scatter_dualphase.png"),
       p_scatter, width = 10, height = 3.8, dpi = 300)
message("Saved fig07_scatter_dualphase.png")

# Top gainers / losers per metric
dual %>%
  group_by(metric) %>%
  arrange(desc(delta)) %>%
  slice(c(1:5, (n() - 4):n())) %>%
  select(metric, id_sito, hellenistic, roman, delta) %>%
  print(n = Inf)

# Paired Wilcoxon on dual-phase sites
dual %>%
  group_by(metric) %>%
  summarise(p_paired     = wilcox.test(hellenistic, roman, paired = TRUE)$p.value,
            median_delta = median(delta), .groups = "drop") %>%
  print()

# =============================================================================
# FIG 08 — Roman network threshold sensitivity
#          Base-R plot: proportion of isolated sites vs cost threshold
# =============================================================================
sweep_results <- read.csv(table_path("threshold_sweep_roman.csv"),
                          stringsAsFactors = FALSE)

png(image_path("fig08_threshold_sensitivity.png"),
    width = 1800, height = 1200, res = 300)
plot(sweep_results$threshold, sweep_results$pct_isolates,
     type = "b",
     xlab = "Threshold (min)",
     ylab = "Proportion isolated sites",
     main = "Roman network: threshold sensitivity")
abline(h = 0.1, col = "red", lty = 2)   # reference: 10% isolates
dev.off()
message("Saved fig08_threshold_sensitivity.png")

# =============================================================================
# FIG 09 — Full Egnatia route + cost corridors
#          Two panels: (a) wheeled-transport, (b) Tobler
#          Each panel: cost corridor as background raster, full-route modelled
#          LCP (dashed) + attested route (solid) + waypoints + Roman sites
# =============================================================================
egnatia_sf       <- st_sf(geometry = readRDS(rds_path("egnatia_stitched.rds")))
lcp_full_wheeled <- readRDS(rds_path("lcp_egnatia_wheeled_full.rds"))
lcp_full_tobler  <- readRDS(rds_path("lcp_egnatia_tobler_full.rds"))
wp_snapped_sf    <- readRDS(rds_path("wp_snapped.rds"))
wp_plot          <- wp_snapped_sf %>% mutate(site_name = wp_site_names[id_sito])

corr_wheeled <- readRDS(rds_path("corr_wheeled.rds"))
corr_tobler  <- readRDS(rds_path("corr_tobler.rds"))

corr_wheeled_df <- as.data.frame(terra::aggregate(corr_wheeled, fact = 4), xy = TRUE)
corr_tobler_df  <- as.data.frame(terra::aggregate(corr_tobler,  fact = 4), xy = TRUE)
names(corr_wheeled_df)[3] <- "cost"
names(corr_tobler_df)[3]  <- "cost"

# Helper: one corridor panel with its respective full-route LCP overlaid.
# fill = corridor raster (plasma); colour = route lines + legend.
make_fig09_panel <- function(corr_df, egnatia_sf, lcp_sf, lcp_label,
                              lcp_col, wp_plot, sites_sf, title) {
  colour_vals <- c("Attested route" = "black")
  colour_vals[[lcp_label]] <- lcp_col

  ggplot() +
    geom_raster(data = corr_df, aes(x = x, y = y, fill = cost)) +
    scale_fill_viridis_c(option = "plasma", direction = -1,
                         na.value = "transparent", name = "Corridor\ncost") +
    # Sites: white fill on plasma background
    geom_sf(data = sites_sf, shape = 21,
            fill = "white", colour = "grey30",
            size = SITE_SZ, stroke = SITE_STR, alpha = 0.7) +
    # Attested route: white halo for legibility, then black line via aes
    geom_sf(data = egnatia_sf, colour = "white", linewidth = 2.5) +
    geom_sf(data = egnatia_sf,
            aes(colour = "Attested route"), linewidth = 1.1) +
    # Modelled LCP: white halo, then coloured dashed line via aes
    geom_sf(data = lcp_sf, colour = "white", linewidth = 1.8) +
    geom_sf(data = lcp_sf,
            aes(colour = lcp_label), linewidth = 0.8, linetype = "dashed") +
    scale_colour_manual(values = colour_vals, name = NULL) +
    guides(colour = guide_legend(
      override.aes = list(
        linetype  = c("solid", "dashed"),
        linewidth = c(1.1, 0.8),
        shape     = c(NA, NA)
      )
    )) +
    # Waypoints: explicit symbol + label, excluded from legend
    geom_sf(data = wp_plot, shape = 21, size = 2.8,
            fill = "white", colour = "black", stroke = 0.7,
            show.legend = FALSE) +
    geom_sf_label(data = wp_plot, aes(label = site_name),
                  size = 2.6, label.size = 0, nudge_y = 1800) +
    annotation_scale(location = "bl", unit_category = "metric") +
    coord_sf(crs = CRS_UTM) +
    scale_x_continuous(breaks = lon_breaks) +
    labs(x = NULL, y = NULL, title = title) +
    theme_fig +
    theme(legend.position = "bottom")
}

p_fig09_wheeled <- make_fig09_panel(
  corr_wheeled_df, egnatia_sf, lcp_full_wheeled,
  lcp_label = "Wheeled-transport LCP",
  lcp_col   = PHASE_COLS[["roman"]],
  wp_plot   = wp_plot, sites_sf = siti_rom_bg,
  title     = "(a) Wheeled-transport corridor"
)

p_fig09_tobler <- make_fig09_panel(
  corr_tobler_df, egnatia_sf, lcp_full_tobler,
  lcp_label = "Tobler LCP",
  lcp_col   = PHASE_COLS[["hellenistic"]],
  wp_plot   = wp_plot, sites_sf = siti_rom_bg,
  title     = "(b) Tobler corridor"
)

ggsave(image_path("fig09_egnatia_full_corridors.png"),
       (p_fig09_wheeled | p_fig09_tobler) +
         plot_layout(guides = "collect") &
         theme(legend.position = "bottom"),
       width = 14, height = 7, dpi = 300)
message("Saved fig09_egnatia_full_corridors.png")

rm(corr_wheeled, corr_tobler, corr_wheeled_df, corr_tobler_df,
   egnatia_sf, lcp_full_wheeled, lcp_full_tobler,
   wp_snapped_sf, wp_plot,
   p_fig09_wheeled, p_fig09_tobler); gc(verbose = FALSE)

# =============================================================================
# FIG 10 — Per-segment Egnatia: attested vs wheeled-transport LCP (3 panels)
# =============================================================================
# PDI verification (segment 3):
#   lcp_egnatia_wheeled_seg3.rds is computed from wp_snapped[3,]→wp_snapped[4,]
#   inside the validation loop in 08_egnatia_validation.R. The PDI recorded in
#   egnatia_validation_segments.csv was derived from the identical LCP object in
#   the same validate_segment() call. Figure and statistic are consistent.
#   The apparent visual offset (~several hundred m) coexisting with PDI_norm = 0.015
#   reflects the normalised-PDI formula: area-between-paths / straight-line
#   distance, normalised by the attested path's own detour. For a short segment
#   (~5.2 km) where both paths run roughly parallel with a narrow enclosed strip,
#   this value can be small even when the lines do not overlap spatially.
known_segs <- readRDS(rds_path("egnatia_known_segments.rds"))

# Use corrected PDI values from pdi_fixed() — not the buggy package output
val_seg <- read.csv(table_path("egnatia_pdi_final.csv"),
                    stringsAsFactors = FALSE)
pdi_wheeled <- val_seg$normalised_pdi[
  val_seg$cost_function == "wheeled transport" &
  val_seg$segment       != "full route"]

seg_titles <- c("(a) Dyrrachium\u2013Clodiana",
                "(b) Clodiana\u2013Ad Quintum",
                "(c) Ad Quintum\u2013Scampis")

wp_snapped_sf <- readRDS(rds_path("wp_snapped.rds"))
wp_plot       <- wp_snapped_sf %>% mutate(site_name = wp_site_names[id_sito])

panels_seg <- lapply(seq_along(known_segs), function(i) {
  lcp_i <- readRDS(rds_path(sprintf("lcp_egnatia_wheeled_seg%d.rds", i)))
  kseg  <- known_segs[[i]]

  bb1  <- sf::st_bbox(kseg)
  bb2  <- sf::st_bbox(lcp_i)
  xmin <- min(bb1["xmin"], bb2["xmin"])
  xmax <- max(bb1["xmax"], bb2["xmax"])
  ymin <- min(bb1["ymin"], bb2["ymin"])
  ymax <- max(bb1["ymax"], bb2["ymax"])
  pad  <- 0.06 * max(xmax - xmin, ymax - ymin)

  # Clip sites to this panel's padded extent (coordinate filter; avoids st_crop)
  cs        <- sf::st_coordinates(siti_rom_bg)
  in_panel  <- cs[, 1] >= (xmin - pad) & cs[, 1] <= (xmax + pad) &
               cs[, 2] >= (ymin - pad) & cs[, 2] <= (ymax + pad)
  sites_pan <- siti_rom_bg[in_panel, ]

  ggplot() +
    geom_sf(data = sites_pan, shape = 21, size = SITE_SZ,
            aes(fill = "Roman-phase sites"),
            colour = SITE_BDR, stroke = SITE_STR, alpha = SITE_ALPHA) +
    geom_sf(data = kseg,
            aes(colour = "Attested route"), linewidth = 0.9) +
    geom_sf(data = lcp_i,
            aes(colour = "Wheeled-transport LCP"), linewidth = 0.7) +
    scale_colour_manual(values = egnatia_cols[c("Attested route",
                                                "Wheeled-transport LCP")],
                        name = NULL) +
    scale_fill_manual(values = c("Roman-phase sites" = SITE_FILL), name = NULL) +
    guides(
      colour = guide_legend(order = 1,
        override.aes = list(linetype  = c("solid", "solid"),
                            linewidth = c(0.9, 0.7),
                            shape     = c(NA, NA))),
      fill = guide_legend(order = 2,
        override.aes = list(shape = 21, size = 3,
                            colour = SITE_BDR, stroke = SITE_STR, alpha = 1))
    ) +
    annotation_scale(location = "bl", unit_category = "metric") +
    coord_sf(crs    = CRS_UTM,
             xlim   = c(xmin - pad, xmax + pad),
             ylim   = c(ymin - pad, ymax + pad),
             expand = FALSE) +
    labs(x = NULL, y = NULL,
         title = sprintf("%s\nPDI = %.3f", seg_titles[i], pdi_wheeled[i])) +
    theme_fig +
    theme(legend.position = "bottom",
          plot.title = element_text(size = 9, face = "bold"))
})

p_fig10 <- (panels_seg[[1]] | panels_seg[[2]] | panels_seg[[3]]) +
  plot_layout(guides = "collect") &
  theme(legend.position = "bottom")

ggsave(image_path("fig10_egnatia_segments.png"),
       p_fig10, width = 14, height = 5.5, dpi = 300)
message("Saved fig10_egnatia_segments.png")

rm(known_segs, val_seg, pdi_wheeled, panels_seg, p_fig10,
   wp_snapped_sf, wp_plot)

# =============================================================================
# SUPPLEMENTARY / LEGACY FIGURES
# =============================================================================

# -------------------------------------------------------------------------
# fig_concentration_sweep.png — betweenness concentration vs threshold (04b)
# -------------------------------------------------------------------------
conc <- read.csv(table_path("betweenness_concentration_sweep.csv"),
                 stringsAsFactors = FALSE)

p_conc <- ggplot(conc, aes(threshold, top1_share, colour = phase)) +
  geom_line(linewidth = 0.8) + geom_point() +
  scale_colour_manual(values = PHASE_COLS) +
  labs(x = "Threshold (min)",
       y = "Share of total betweenness held by top node",
       colour = NULL) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom")

ggsave(image_path("fig_concentration_sweep.png"),
       p_conc, width = 7, height = 4.5, dpi = 300)
message("Saved fig_concentration_sweep.png")

# -------------------------------------------------------------------------
# ex fig04 — fig04_networks.png: network topology in geographic space
#             (straight-line edges, both phases side by side)
# -------------------------------------------------------------------------
# id = row position in siti_*, identical to the numero_riga integer
# assigned in 04_networks.R — no join needed.
hell_xy <- siti_hell %>%
  mutate(id = row_number(),
         X  = sf::st_coordinates(.)[, 1],
         Y  = sf::st_coordinates(.)[, 2]) %>%
  sf::st_drop_geometry() %>%
  select(id, id_sito, X, Y)

rom_xy <- siti_rom %>%
  mutate(id = row_number(),
         X  = sf::st_coordinates(.)[, 1],
         Y  = sf::st_coordinates(.)[, 2]) %>%
  sf::st_drop_geometry() %>%
  select(id, id_sito, X, Y)

edges_hell_xy <- edges_hell_filtered %>%
  left_join(hell_xy %>% select(id, X, Y), by = c("from" = "id")) %>%
  rename(x0 = X, y0 = Y) %>%
  left_join(hell_xy %>% select(id, X, Y), by = c("to" = "id")) %>%
  rename(x1 = X, y1 = Y)

edges_rom_xy <- edges_rom_filtered %>%
  left_join(rom_xy %>% select(id, X, Y), by = c("from" = "id")) %>%
  rename(x0 = X, y0 = Y) %>%
  left_join(rom_xy %>% select(id, X, Y), by = c("to" = "id")) %>%
  rename(x1 = X, y1 = Y)

make_net_panel <- function(edges_xy, nodes_xy, col, title) {
  ggplot() +
    geom_segment(data = edges_xy,
                 aes(x = x0, y = y0, xend = x1, yend = y1),
                 colour = "grey60", linewidth = 0.2, alpha = 0.7) +
    geom_point(data = nodes_xy, aes(x = X, y = Y),
               size = 1.8, shape = 21, fill = col,
               colour = "white", stroke = 0.3) +
    coord_equal() +
    labs(x = NULL, y = NULL, title = title) +
    theme_fig +
    theme(axis.text.x = element_text(angle = 30, hjust = 1))
}

p_net_hell <- make_net_panel(edges_hell_xy, hell_xy,
                              PHASE_COLS["hellenistic"], "Hellenistic")
p_net_rom  <- make_net_panel(edges_rom_xy,  rom_xy,
                              PHASE_COLS["roman"],       "Roman")

ggsave(image_path("fig04_networks.png"),
       p_net_hell | p_net_rom, width = 10, height = 5, dpi = 300)
message("Saved fig04_networks.png  [legacy — ex fig04]")

# -------------------------------------------------------------------------
# Individual centrality maps (components of fig05)
# -------------------------------------------------------------------------
ggsave(image_path("fig_map_degree.png"),      p_map_deg, width = 9, height = 5, dpi = 300)
ggsave(image_path("fig_map_harmonic.png"),    p_map_clo, width = 9, height = 5, dpi = 300)
ggsave(image_path("fig_map_betweenness.png"), p_map_btw, width = 9, height = 5, dpi = 300)
message("Saved individual centrality map figures (components of fig05).")

# =============================================================================
# SCREEN ONLY — igraph geographic layout plots
# Originally in plot_rete_geografico.R
# =============================================================================
coords_hell <- sf::st_coordinates(siti_hell)
# V(net_hell)$name is character; as.integer() converts to the row-index id
V(net_hell)$label <- nodes_hell$id_sito[match(as.integer(V(net_hell)$name), nodes_hell$id)]

plot(net_hell,
     layout             = coords_hell[as.integer(V(net_hell)$name), ],
     vertex.label       = V(net_hell)$label,
     vertex.size        = 5,
     vertex.label.cex   = 0.6,
     vertex.label.color = "black",
     vertex.color       = "orange",
     edge.color         = "grey60",
     main               = "Hellenistic network — geographic layout")

# ggplot version — Hellenistic
deg_lookup_hell <- data.frame(id_sito = nodes_hell$id_sito, degree = V(net_hell)$degree)
siti_hell_plot  <- siti_hell %>% left_join(deg_lookup_hell, by = "id_sito")

p_geo_hell <- ggplot() +
  geom_sf(data = lcp_hell_plot, color = "grey50", linewidth = 0.3) +
  geom_sf(data = siti_hell_plot, aes(size = degree, color = degree)) +
  geom_sf_text(data = siti_hell_plot, aes(label = id_sito),
               size = 2, nudge_y = 300) +
  scale_color_viridis_c() +
  theme_minimal() +
  labs(title = "Hellenistic network — Least Cost Paths",
       color = "Degree", size = "Degree")
print(p_geo_hell)

# ggplot version — Roman
deg_lookup_rom <- data.frame(id_sito = nodes_rom$id_sito, degree = V(net_rom)$degree)
siti_rom_plot  <- siti_rom %>% left_join(deg_lookup_rom, by = "id_sito")

p_geo_rom <- ggplot() +
  geom_sf(data = lcp_rom_plot, color = "grey50", linewidth = 0.3) +
  geom_sf(data = siti_rom_plot, aes(size = degree, color = degree)) +
  geom_sf_text(data = siti_rom_plot, aes(label = id_sito),
               size = 2, nudge_y = 300) +
  scale_color_viridis_c() +
  theme_minimal() +
  labs(title = "Roman network — Least Cost Paths",
       color = "Degree", size = "Degree")
print(p_geo_rom)

message("All figures complete.")
