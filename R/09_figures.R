# =============================================================================
# 09_figures.R — Publication-quality figures
#
# Produces twelve figures saved to output/images/:
#   fig_boxplot_centrality.png     — boxplots of all metrics by phase
#   fig_scatter_dualphase.png      — scatter plot for dual-phase sites
#   fig_map_degree.png             — geographic maps, degree centrality
#   fig_map_harmonic.png           — geographic maps, harmonic centrality
#   fig_map_betweenness.png        — geographic maps, normalised betweenness
#   fig01_sites_dem.png            — study area overview: DEM + all sites
#   fig02_hellenistic_model.png    — Tobler cost surface | Hellenistic LCPs
#   fig03_roman_model.png          — wheeled-transport surface | Roman LCPs
#   fig04_networks.png             — network topology in geographic space
#   fig_concentration_sweep.png    — betweenness concentration vs threshold (04b)
#   fig05_egnatia_full.png         — attested + both full-route LCPs + waypoints
#   fig06_egnatia_segments.png     — three-panel per-segment comparison (wheeled)
#   fig07_cost_corridors.png       — wheeled & Tobler cost corridors + attested route
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
#         output/rds/lcp_hell.gpkg
#         output/rds/lcp_roman.gpkg
#         output/tables/betweenness_concentration_sweep.csv
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

# --- Load centrality table ---------------------------------------------------
cc <- read.csv(table_path("centrality_comparison.csv"), stringsAsFactors = FALSE)
cc$phase <- factor(cc$phase, levels = c("hellenistic", "roman"))

# Normalised degree: raw degree is not comparable across networks of different size
n_nodes_per_phase <- cc %>% count(phase, name = "n")
cc <- cc %>%
  left_join(n_nodes_per_phase, by = "phase") %>%
  mutate(degree_norm = degree / (n - 1))

metric_levels <- c("degree_norm", "harmonic", "betweenness_norm")
metric_labels <- c("Degree (norm.)", "Harmonic Centrality (norm.)", "Betweenness (norm.)")

# =============================================================================
# 1. BOXPLOTS — distribution by metric and phase
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
ggsave(image_path("fig_boxplot_centrality.png"),
       p_box, width = 9, height = 3.5, dpi = 300)

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
# 2. SCATTER — dual-phase sites: Hellenistic vs Roman centrality
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
ggsave(image_path("fig_scatter_dualphase.png"),
       p_scatter, width = 10, height = 3.8, dpi = 300)

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
# 3. GEOGRAPHIC MAPS — nodes sized/coloured by centrality
# =============================================================================
cc_sf <- st_as_sf(cc, coords = c("X", "Y"), crs = CRS_UTM)

# LCP edge layers for map overlays (filtered to network edges only).
# Use the processed RDS objects (with from/to as integer site IDs) rather than
# re-reading the raw gpkg files which use origin_ID/destination_ID or cell indices.
edges_hell_filtered <- readRDS(rds_path("edges_hell_filtered.rds"))
edges_rom_filtered  <- readRDS(rds_path("edges_rom_filtered.rds"))
lcp_hell_sf         <- readRDS(rds_path("lcp_hell_processed.rds"))
lcp_rom_sf          <- readRDS(rds_path("lcp_rom_processed.rds"))

lcp_hell_plot <- lcp_hell_sf %>%
  inner_join(edges_hell_filtered %>% select(from, to), by = c("from", "to"))
lcp_rom_plot  <- lcp_rom_sf %>%
  inner_join(edges_rom_filtered  %>% select(from, to), by = c("from", "to"))

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

ggsave(image_path("fig_map_degree.png"),      p_map_deg, width = 9, height = 5, dpi = 300)
ggsave(image_path("fig_map_harmonic.png"),    p_map_clo, width = 9, height = 5, dpi = 300)
ggsave(image_path("fig_map_betweenness.png"), p_map_btw, width = 9, height = 5, dpi = 300)
message("Saved map figures.")

# =============================================================================
# 4. IGRAPH GEOGRAPHIC LAYOUT PLOTS (screen only)
# Originally plot_rete_geografico.R
# =============================================================================
# lcp_hell_plot / lcp_rom_plot already defined above
net_hell   <- readRDS(rds_path("net_hell.rds"))
net_rom    <- readRDS(rds_path("net_rom.rds"))
nodes_hell <- readRDS(rds_path("nodes_hell.rds"))
nodes_rom  <- readRDS(rds_path("nodes_rom.rds"))
siti_hell  <- readRDS(rds_path("siti_hell.rds"))
siti_rom   <- readRDS(rds_path("siti_rom.rds"))

coords_hell <- sf::st_coordinates(siti_hell)
# V(net_hell)$name is character; as.integer() converts to the row-index id
V(net_hell)$label <- nodes_hell$id_sito[match(as.integer(V(net_hell)$name), nodes_hell$id)]

plot(net_hell,
     layout            = coords_hell[as.integer(V(net_hell)$name), ],
     vertex.label      = V(net_hell)$label,
     vertex.size       = 5,
     vertex.label.cex  = 0.6,
     vertex.label.color = "black",
     vertex.color      = "orange",
     edge.color        = "grey60",
     main              = "Hellenistic network — geographic layout")

# ggplot version — Hellenistic
# siti_hell (from rds) has no id column; join via id_sito instead
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

# =============================================================================
# 5. NEW FIGURES: STUDY AREA, COST MODELS, NETWORKS
# =============================================================================
library(patchwork)   # | operator for panel composition

# Shared theme and axis breaks for new figures
theme_fig <- theme_minimal(base_size = 10) +
  theme(axis.text        = element_text(size = 7),
        plot.title       = element_text(size = 10, face = "bold"),
        legend.key.width = unit(0.4, "cm"))
lon_breaks <- seq(19.0, 21.0, by = 0.5)

# -------------------------------------------------------------------------
# FIG 01 — Study area overview: DEM + all archaeological sites
# -------------------------------------------------------------------------
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

# -------------------------------------------------------------------------
# FIG 02 — Hellenistic model: Tobler cost surface | Hellenistic LCPs
# -------------------------------------------------------------------------
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

# -------------------------------------------------------------------------
# FIG 03 — Roman model: wheeled-transport cost surface | Roman LCPs
# -------------------------------------------------------------------------
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

# -------------------------------------------------------------------------
# FIG 04 — Network topology in geographic space (straight-line edges)
# -------------------------------------------------------------------------
# id = row position in siti_*, which is identical to the numero_riga integer
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
message("Saved fig04_networks.png")

# -------------------------------------------------------------------------
# FIG 05 — Betweenness concentration sweep (04b output)
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

# =============================================================================
# 6. VIA EGNATIA FIGURES (fig05 – fig07)
# =============================================================================
library(ggspatial)   # annotation_scale()

# Human-readable waypoint labels (west → east)
wp_site_names <- c(DUR001 = "Dyrrachium", DUR022 = "Clodiana",
                   DUR024 = "Ad Quintum", DUR017 = "Scampis")

# BUG FIX: single-bracket indexing carries the inner name ("roman", "hellenistic")
# into the element name, producing "Wheeled-transport LCP.roman" etc., which
# breaks scale_colour_manual matching. Use [[ ]] to strip the inner name.
egnatia_cols <- c(
  "Attested route"        = "black",
  "Wheeled-transport LCP" = PHASE_COLS[["roman"]],
  "Tobler LCP"            = PHASE_COLS[["hellenistic"]]
)

# Site-point constants shared across fig05–fig07
SITE_LABEL <- "Roman-phase sites"
SITE_FILL  <- "grey70"   # fill (fig05/06, light background)
SITE_BDR   <- "grey30"   # point border (fig05/06)
SITE_SZ    <- 1.2
SITE_STR   <- 0.25
SITE_ALPHA <- 0.75

# Roman-phase sites with the four waypoints removed to avoid double-plotting
siti_rom_bg <- siti_rom %>% filter(!id_sito %in% WAYPOINT_IDS)

# -------------------------------------------------------------------------
# FIG 05 — Full route: attested vs both modelled LCPs + waypoints + sites
# -------------------------------------------------------------------------
egnatia_sf       <- st_sf(geometry = readRDS(rds_path("egnatia_stitched.rds")))
lcp_full_tobler  <- readRDS(rds_path("lcp_egnatia_tobler_full.rds"))
lcp_full_wheeled <- readRDS(rds_path("lcp_egnatia_wheeled_full.rds"))
wp_snapped_sf    <- readRDS(rds_path("wp_snapped.rds"))
wp_plot          <- wp_snapped_sf %>%
  mutate(site_name = wp_site_names[id_sito])

p_fig05 <- ggplot() +
  # Sites beneath routes (fill aesthetic; colour aesthetic reserved for routes)
  geom_sf(data = siti_rom_bg, shape = 21, size = SITE_SZ,
          aes(fill = "Roman-phase sites"),
          colour = SITE_BDR, stroke = SITE_STR, alpha = SITE_ALPHA) +
  # Routes
  geom_sf(data = egnatia_sf,
          aes(colour = "Attested route"), linewidth = 0.9) +
  geom_sf(data = lcp_full_wheeled,
          aes(colour = "Wheeled-transport LCP"), linewidth = 0.7) +
  geom_sf(data = lcp_full_tobler,
          aes(colour = "Tobler LCP"), linewidth = 0.7, linetype = "dashed") +
  scale_colour_manual(values = egnatia_cols, name = NULL) +
  scale_fill_manual(values   = c("Roman-phase sites" = SITE_FILL), name = NULL) +
  guides(
    colour = guide_legend(order = 1,
      override.aes = list(linetype  = c("solid", "solid", "dashed"),
                          linewidth = c(0.9, 0.7, 0.7),
                          shape     = c(NA, NA, NA))),
    fill = guide_legend(order = 2,
      override.aes = list(shape = 21, size = 3,
                          colour = SITE_BDR, stroke = SITE_STR, alpha = 1))
  ) +
  # Waypoints: larger symbol + label, suppressed from legend
  geom_sf(data = wp_plot, shape = 21, size = 2.8,
          fill = "white", colour = "black", stroke = 0.7,
          show.legend = FALSE) +
  geom_sf_label(data = wp_plot, aes(label = site_name),
                size = 2.6, label.size = 0, nudge_y = 1800) +
  annotation_scale(location = "bl", unit_category = "metric") +
  coord_sf(crs = CRS_UTM) +
  scale_x_continuous(breaks = lon_breaks) +
  labs(x = NULL, y = NULL) +
  theme_fig +
  theme(legend.position = "bottom")

ggsave(image_path("fig05_egnatia_full.png"),
       p_fig05, width = 8, height = 7, dpi = 300)
message("Saved fig05_egnatia_full.png")

rm(egnatia_sf, lcp_full_tobler, lcp_full_wheeled, wp_snapped_sf, wp_plot)

# -------------------------------------------------------------------------
# FIG 06 — Per-segment: attested vs wheeled-transport LCP (3 panels)
# -------------------------------------------------------------------------
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

p_fig06 <- (panels_seg[[1]] | panels_seg[[2]] | panels_seg[[3]]) +
  plot_layout(guides = "collect") &
  theme(legend.position = "bottom")

ggsave(image_path("fig06_egnatia_segments.png"),
       p_fig06, width = 14, height = 5.5, dpi = 300)
message("Saved fig06_egnatia_segments.png")

rm(known_segs, val_seg, pdi_wheeled, panels_seg, p_fig06)

# -------------------------------------------------------------------------
# FIG 07 — Cost corridors: wheeled-transport and Tobler, attested route overlaid
# -------------------------------------------------------------------------
# The raster fill scale occupies the fill aesthetic, so sites use colour.
# Route: white halo (fixed) + black line (aes) so it reads against plasma
# AND the legend swatch is visible on a white legend background.
corr_wheeled <- readRDS(rds_path("corr_wheeled.rds"))
corr_tobler  <- readRDS(rds_path("corr_tobler.rds"))
egnatia_sf   <- st_sf(geometry = readRDS(rds_path("egnatia_stitched.rds")))

corr_wheeled_df <- as.data.frame(terra::aggregate(corr_wheeled, fact = 4), xy = TRUE)
corr_tobler_df  <- as.data.frame(terra::aggregate(corr_tobler,  fact = 4), xy = TRUE)
names(corr_wheeled_df)[3] <- "cost"
names(corr_tobler_df)[3]  <- "cost"

make_corridor_panel <- function(df, route_sf, sites_sf, title) {
  ggplot() +
    geom_raster(data = df, aes(x = x, y = y, fill = cost)) +
    scale_fill_viridis_c(option = "plasma", direction = -1,
                         na.value = "transparent",
                         name = "Corridor\ncost") +
    # Sites: white-filled circle with dark outline; colour aes gives legend entry
    geom_sf(data = sites_sf, shape = 21,
            aes(colour = "Roman-phase sites"),
            fill = "white", size = SITE_SZ + 0.3, stroke = 0.4, alpha = 0.85) +
    # Route: white halo for plasma legibility, then black line for legend
    geom_sf(data = route_sf, colour = "white", linewidth = 2.2) +
    geom_sf(data = route_sf, aes(colour = "Attested route"), linewidth = 1.1) +
    scale_colour_manual(
      values = c("Attested route" = "black", "Roman-phase sites" = "black"),
      breaks = c("Attested route", "Roman-phase sites"),
      name   = NULL
    ) +
    guides(colour = guide_legend(
      override.aes = list(
        linetype  = c("solid",  "blank"),
        linewidth = c(1.1,      0),
        shape     = c(NA,       21),
        fill      = c(NA,       "white"),
        size      = c(NA,       3),
        stroke    = c(NA,       0.5)
      )
    )) +
    coord_sf(crs = CRS_UTM) +
    scale_x_continuous(breaks = lon_breaks) +
    labs(x = NULL, y = NULL, title = title) +
    theme_fig
}

p_corr_wheeled <- make_corridor_panel(
  corr_wheeled_df, egnatia_sf, siti_rom_bg, "(a) Wheeled-transport corridor")
p_corr_tobler  <- make_corridor_panel(
  corr_tobler_df,  egnatia_sf, siti_rom_bg, "(b) Tobler corridor")

ggsave(image_path("fig07_cost_corridors.png"),
       (p_corr_wheeled | p_corr_tobler) +
         plot_layout(guides = "collect") &
         theme(legend.position = "bottom"),
       width = 12, height = 5, dpi = 300)
message("Saved fig07_cost_corridors.png")

rm(corr_wheeled, corr_tobler, egnatia_sf,
   corr_wheeled_df, corr_tobler_df); gc(verbose = FALSE)

message("All figures complete.")
