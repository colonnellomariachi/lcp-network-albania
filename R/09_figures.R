# =============================================================================
# 09_figures.R — Publication-quality figures
#
# Main manuscript figures (output/images/):
#   fig01_sites_dem.png              — study area overview: DEM + all 143 sites,
#                                      locator inset (Adriatic, Brindisi–Durrës)
#   fig02_networks_tobler.png        — Tobler networks: (a) H-T | (b) R-T
#   fig03_networks_wheeled.png       — wheeled-transport networks: (a) H-W | (b) R-W
#   fig04_boxplot_centrality.png     — four cells: (a) degree / harmonic boxplots,
#                                      (b) Lorenz curves of betweenness
#   fig05_centrality_maps.png        — betweenness maps of the four cells (2 × 2)
#   fig06_communities.png            — Leiden community partition, Roman giant component
#   fig07_scatter_dualphase.png      — betweenness of the 46 dual-phase sites,
#                                      Hellenistic vs Roman (Tobler | wheeled)
#   fig08_threshold_sensitivity.png  — Roman network threshold sensitivity
#   fig09_egnatia_full_corridors.png — full Egnatia LCPs overlaid on cost corridors
#                                      (wheeled | Tobler, 2-panel)
#   fig10_egnatia_segments.png       — three-panel per-segment comparison
#                                      (attested route, wheeled and Tobler LCPs)
#
# QC only (output/images/qc/; H-T | R-W, the confounded comparison — not for
# the supplement):
#   fig_map_{degree,harmonic,betweenness}.png — geographic centrality maps [ex fig05]
#
# fig02–fig05 and fig07 read the objects / tables of 11 (net_hw, net_rt,
# factorial_*.csv): in run_all.R this script runs after 11. No figure of the
# manuscript (fig01–fig10) carries DUR codes: labels are toponyms, checked by
# assert_no_dur_labels().
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
#         output/rds/net_hw.rds, net_rt.rds
#         output/tables/factorial_composition.csv
#         rnaturalearth / rnaturalearthhires (Natural Earth 1:10m, public domain)
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

# --- Four factorial cells (written by 11; fig04, fig05, fig07) ----------------
FACT_CELLS <- c("H-T", "H-W", "R-T", "R-W")
fc <- read.csv(table_path("factorial_centrality_long.csv"), stringsAsFactors = FALSE)
fc$phase   <- factor(ifelse(substr(fc$cell, 1, 1) == "H", "Hellenistic", "Roman"),
                     levels = c("Hellenistic", "Roman"))
fc$cost_fn <- factor(ifelse(substr(fc$cell, 3, 3) == "T", "Tobler", "Wheeled transport"),
                     levels = c("Tobler", "Wheeled transport"))
fc$cell    <- factor(fc$cell, levels = FACT_CELLS)
site_lab   <- read_site_labels()
fc$toponym <- site_lab$toponym[match(fc$id_sito, site_lab$id_sito)]
site_xy_all <- rbind(data.frame(id_sito = siti_hell$id_sito, sf::st_coordinates(siti_hell)),
                     data.frame(id_sito = siti_rom$id_sito,  sf::st_coordinates(siti_rom)))
site_xy_all <- site_xy_all[!duplicated(site_xy_all$id_sito), ]
fc <- merge(fc, site_xy_all, by = "id_sito")
fact_conc  <- read.csv(table_path("factorial_concentration.csv"), stringsAsFactors = FALSE)
fact_top10 <- read.csv(table_path("factorial_top10_location.csv"), stringsAsFactors = FALSE)
fact_tests <- read.csv(table_path("factorial_tests.csv"), stringsAsFactors = FALSE)
# Cost-function colours: as in the Egnatia figures (Tobler gold, wheeled blue)
COSTFN_COLS <- c("Tobler" = PHASE_COLS[["hellenistic"]],
                 "Wheeled transport" = PHASE_COLS[["roman"]])

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

# Manuscript figures are labelled with toponyms, never with site codes
# (read_site_labels() falls back to id_sito when a site has no toponym).
assert_no_dur_labels <- function(labels, fig) {
  bad <- unique(grep("DUR[0-9]", as.character(labels), value = TRUE))
  if (length(bad))
    stop(fig, ": site codes used as labels: ", paste(bad, collapse = ", "))
  invisible(TRUE)
}

# =============================================================================
# FIG 01 — Study area overview: DEM + all archaeological sites
# =============================================================================
dem_raw   <- terra::rast(data_path("dem.tif"))
dem_agg   <- terra::aggregate(dem_raw, fact = 4)
dem_df    <- as.data.frame(dem_agg, xy = TRUE)
names(dem_df)[3] <- "elevation"

sites_all <- sf::st_read(data_path("sites.gpkg"), quiet = TRUE) %>%
  sf::st_transform(CRS_UTM)
stopifnot("fig01: sites.gpkg must hold 143 sites, all with a geometry" =
            nrow(sites_all) == 143L && !any(sf::st_is_empty(sites_all)))
site_key <- sprintf("Archaeological sites (n = %d)", nrow(sites_all))

p_fig01_main <- ggplot() +
  geom_raster(data = dem_df, aes(x = x, y = y, fill = elevation)) +
  scale_fill_viridis_c(option = "mako", na.value = "transparent",
                       name = "Elevation (m)") +
  geom_sf(data = sites_all, aes(shape = site_key), size = 1.5,
          fill = "white", colour = "black", stroke = 0.4) +
  scale_shape_manual(values = setNames(21, site_key), name = NULL) +
  coord_sf(crs = CRS_UTM) +
  scale_x_continuous(breaks = lon_breaks) +
  labs(x = NULL, y = NULL) +
  theme_fig +
  guides(fill = guide_colourbar(order = 1), shape = guide_legend(order = 2))

# Locator inset: Adriatic and western Balkans. Boundaries: Natural Earth
# Admin-0 countries, 1:10m (rnaturalearthhires; public domain).
INSET_LON <- c(15.6, 23.6)
INSET_LAT <- c(38.9, 43.3)
ne_countries_sf <- rnaturalearth::ne_countries(scale = "large", continent = "Europe",
                                               returnclass = "sf")
dem_ext   <- as.vector(terra::ext(dem_raw))   # xmin, xmax, ymin, ymax
study_box <- sf::st_bbox(c(xmin = dem_ext[["xmin"]], ymin = dem_ext[["ymin"]],
                           xmax = dem_ext[["xmax"]], ymax = dem_ext[["ymax"]]),
                         crs = sf::st_crs(CRS_UTM)) %>%
  sf::st_as_sfc() %>% sf::st_segmentize(1000) %>% sf::st_transform(4326)
inset_towns <- data.frame(name = c("Brindisi", "Durrës"),
                          lon  = c(17.9417, 19.4565), lat = c(40.6327, 41.3231),
                          hjust = c(0.5, 1.15), vjust = c(-0.9, 0.5))
inset_countries <- data.frame(name = c("ITALY", "ALBANIA", "GREECE", "NORTH\nMACEDONIA"),
                              lon  = c(16.4, 20.15, 21.9, 21.6), lat = c(40.15, 40.3, 39.5, 41.65))

p_fig01_inset <- ggplot() +
  geom_sf(data = ne_countries_sf, fill = "grey92", colour = "grey55", linewidth = 0.15) +
  geom_sf(data = study_box, fill = NA, colour = "red", linewidth = 0.6) +
  geom_text(data = inset_countries, aes(x = lon, y = lat, label = name),
            size = 1.7, colour = "grey40", lineheight = 0.85) +
  annotate("text", x = 17.3, y = 42.35, label = "Adriatic\nSea", size = 1.8,
           fontface = "italic", colour = "steelblue4", lineheight = 0.85) +
  geom_point(data = inset_towns, aes(x = lon, y = lat), size = 0.9) +
  geom_text(data = inset_towns, aes(x = lon, y = lat, label = name,
                                    hjust = hjust, vjust = vjust), size = 2) +
  coord_sf(crs = 4326, xlim = INSET_LON, ylim = INSET_LAT, expand = FALSE) +
  theme_void() +
  theme(panel.background = element_rect(fill = "aliceblue", colour = NA),
        panel.border     = element_rect(fill = NA, colour = "grey20", linewidth = 0.4))

p_fig01 <- p_fig01_main +
  # outside the map frame, under the legends: no site is covered
  inset_element(p_fig01_inset, left = 0.70, bottom = 0.06, right = 0.995, top = 0.31,
                align_to = "full")

ggsave(image_path("fig01_sites_dem.png"),
       p_fig01, width = 7, height = 7, dpi = 300)
message("Saved fig01_sites_dem.png (", nrow(sites_all), " sites, locator inset)")

rm(dem_raw, dem_agg, dem_df, ne_countries_sf, study_box); gc(verbose = FALSE)

# =============================================================================
# FIG 02 / FIG 03 — Networks at constant cost function
#   fig02: Tobler, (a) H-T | (b) R-T;  fig03: wheeled transport, (a) H-W | (b) R-W
# The former fig02/fig03 (cost surface | LCPs of H-T and R-W) showed the
# confounded comparison abandoned by the factorial design and are replaced.
# All four panels share extent (all 119 sites of either phase), symbology and
# scale. Edges are straight lines between connected sites (as in fig05); nodes
# are coloured by component: largest component in the cost-function colour,
# other components dark grey, sites without edges as hollow circles. Only
# Dyrrachium is labelled. Edge, component and isolate counts are checked
# against factorial_composition.csv (written by 11).
# =============================================================================
fact_comp <- read.csv(table_path("factorial_composition.csv"), stringsAsFactors = FALSE)
cell_nets <- list("H-T" = net_hell, "R-T" = readRDS(rds_path("net_rt.rds")),
                  "H-W" = readRDS(rds_path("net_hw.rds")), "R-W" = net_rom)
NODE_CLASSES <- c("Largest component", "Other components", "Sites without edges")

net_cell_layers <- function(k) {
  g   <- cell_nets[[k]]
  nd  <- if (substr(k, 1, 1) == "H") nodes_hell else nodes_rom
  ids <- nd$id_sito[match(as.integer(V(g)$name), nd$id)]
  cmp <- igraph::components(g)
  deg <- igraph::degree(g)
  cls <- ifelse(deg == 0, NODE_CLASSES[3],
                ifelse(cmp$membership == which.max(cmp$csize), NODE_CLASSES[1], NODE_CLASSES[2]))
  xy  <- site_xy_all[match(ids, site_xy_all$id_sito), c("X", "Y")]
  el  <- igraph::ends(g, E(g), names = FALSE)

  # Check (blocking): the panel reproduces factorial_composition.csv
  ref     <- fact_comp[fact_comp$cell == k, ]
  ref_iso <- if (is.na(ref$isolates) || !nzchar(ref$isolates)) character(0) else
    strsplit(ref$isolates, ";")[[1]]
  ok <- c(nodes      = vcount(g) == ref$n_nodes,
          edges      = ecount(g) == ref$n_edges,
          components = cmp$no == ref$n_components,
          giant      = max(cmp$csize) == ref$giant_size,
          isolates   = sum(deg == 0) == ref$n_isolates &&
                       setequal(ids[deg == 0], ref_iso),
          coords     = !anyNA(ids) && !anyNA(xy))
  if (!all(ok))
    stop("fig02/03 (", k, "): panel differs from factorial_composition.csv: ",
         paste(names(ok)[!ok], collapse = ", "))

  list(nodes = data.frame(id_sito = ids, X = xy$X, Y = xy$Y,
                          class = factor(cls, levels = NODE_CLASSES)),
       edges = data.frame(x = xy$X[el[, 1]], y = xy$Y[el[, 1]],
                          xend = xy$X[el[, 2]], yend = xy$Y[el[, 2]]),
       ref = ref)
}
net_cells <- lapply(setNames(names(cell_nets), names(cell_nets)), net_cell_layers)
message("fig02/03: edges, components and isolates of the four panels match ",
        "factorial_composition.csv")

# Common extent: all sites of either phase, 3 km margin
NET_PAD  <- 3000
NET_XLIM <- range(site_xy_all$X) + c(-NET_PAD, NET_PAD)
NET_YLIM <- range(site_xy_all$Y) + c(-NET_PAD, NET_PAD)

make_net_cell_panel <- function(k, col, title) {
  L   <- net_cells[[k]]
  dyr <- L$nodes[L$nodes$id_sito == "DUR001", ]
  dyr$label <- wp_site_names[["DUR001"]]
  assert_no_dur_labels(dyr$label, "fig02/03")
  ggplot() +
    geom_segment(data = L$edges, aes(x = x, y = y, xend = xend, yend = yend),
                 colour = "grey82", linewidth = 0.15) +
    geom_point(data = L$nodes[order(L$nodes$class, decreasing = TRUE), ],
               aes(x = X, y = Y, fill = class), shape = 21, size = 1.7,
               colour = "grey15", stroke = 0.35, show.legend = TRUE) +
    geom_text_repel(data = dyr, aes(x = X, y = Y, label = label),
                    size = 2.6, fontface = "bold", nudge_x = -2500, nudge_y = -9000,
                    min.segment.length = 0, seed = SCATTER_SEED) +
    scale_fill_manual(values = setNames(c(col, "grey25", "transparent"), NODE_CLASSES),
                      limits = NODE_CLASSES, drop = FALSE, name = NULL) +
    guides(fill = guide_legend(override.aes = list(size = 2.6))) +
    annotation_scale(location = "bl", unit_category = "metric") +
    coord_sf(crs = CRS_UTM, xlim = NET_XLIM, ylim = NET_YLIM, expand = FALSE) +
    scale_x_continuous(breaks = lon_breaks) +
    labs(x = NULL, y = NULL, title = title,
         subtitle = sprintf("%d sites, %d edges (< %d min), %d component%s, %d without edges",
                            L$ref$n_nodes, L$ref$n_edges, L$ref$threshold, L$ref$n_components,
                            if (L$ref$n_components == 1) "" else "s", L$ref$n_isolates)) +
    theme_fig +
    theme(plot.subtitle = element_text(size = 8))
}

save_net_fig <- function(file, ka, kb, col, ta, tb) {
  p <- (make_net_cell_panel(ka, col, ta) | make_net_cell_panel(kb, col, tb)) +
    plot_layout(guides = "collect") & theme(legend.position = "bottom")
  ggsave(image_path(file), p, width = 10, height = 5.8, dpi = 300)
  message("Saved ", file)
}
save_net_fig("fig02_networks_tobler.png", "H-T", "R-T", COSTFN_COLS[["Tobler"]],
             "(a) Hellenistic sites, Tobler (H-T)", "(b) Roman sites, Tobler (R-T)")
save_net_fig("fig03_networks_wheeled.png", "H-W", "R-W", COSTFN_COLS[["Wheeled transport"]],
             "(a) Hellenistic sites, wheeled transport (H-W)",
             "(b) Roman sites, wheeled transport (R-W)")

rm(cell_nets, net_cells); gc(verbose = FALSE)

# =============================================================================
# FIG 04 — Four factorial cells: (a) degree and harmonic centrality,
#          (b) Lorenz curves of betweenness
# =============================================================================
cc_long <- cc %>%
  select(id_sito, phase, all_of(metric_levels)) %>%
  pivot_longer(-c(id_sito, phase), names_to = "metric", values_to = "value") %>%
  mutate(metric = factor(metric, levels = metric_levels, labels = metric_labels))

fc_box <- fc %>%
  select(cell, phase, cost_fn, id_sito, degree_norm, harmonic) %>%
  pivot_longer(c(degree_norm, harmonic), names_to = "metric", values_to = "value") %>%
  mutate(metric = factor(metric, levels = c("degree_norm", "harmonic"),
                         labels = c("Degree (norm.)", "Harmonic Centrality (norm.)")))

p_fig04a <- ggplot(fc_box, aes(x = cell, y = value)) +
  # legend shown once, by panel (b): same colours and line types
  geom_boxplot(aes(fill = cost_fn, linetype = phase),
               outlier.shape = NA, width = 0.55, alpha = 0.85, show.legend = FALSE) +
  geom_point(position = position_jitter(width = 0.12, seed = JITTER_SEED),
             alpha = 0.3, size = 0.6) +
  facet_wrap(~ metric, scales = "free_y") +
  scale_fill_manual(values = COSTFN_COLS, name = "Cost function") +
  scale_linetype_manual(values = c(Hellenistic = "solid", Roman = "dashed"), name = "Phase") +
  labs(x = NULL, y = "Value", title = "(a) Degree and harmonic centrality") +
  theme_fig +
  theme(strip.text = element_text(face = "bold"))

# Lorenz curves: sites ordered from least to most central
lorenz <- fc %>%
  group_by(cell, phase, cost_fn) %>%
  arrange(betweenness_norm, .by_group = TRUE) %>%
  summarise(x = c(0, seq_len(n()) / n()),
            y = c(0, cumsum(betweenness_norm) / sum(betweenness_norm)),
            .groups = "drop")
# Check: the Gini of the trapezoidal Lorenz curve equals the Gini of
# factorial_concentration.csv (same formula, gini() in network_helpers.R)
lorenz_gini <- lorenz %>% group_by(cell) %>%
  summarise(g = 1 - sum(diff(x) * (head(y, -1) + tail(y, -1))), .groups = "drop")
stopifnot("fig04b: Lorenz curves must reproduce the Gini of factorial_concentration.csv" =
            isTRUE(all.equal(lorenz_gini$g[match(fact_conc$cell, lorenz_gini$cell)],
                             fact_conc$gini, tolerance = 1e-10)))

p_fig04b <- ggplot(lorenz, aes(x = x, y = y)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dotted", colour = "grey50") +
  geom_line(aes(colour = cost_fn, linetype = phase), linewidth = 0.7) +
  scale_colour_manual(values = COSTFN_COLS, name = "Cost function") +
  scale_linetype_manual(values = c(Hellenistic = "solid", Roman = "dashed"), name = "Phase") +
  coord_equal() +
  labs(x = "Cumulative share of sites (least to most central)",
       y = "Cumulative share of betweenness",
       title = "(b) Lorenz curves of betweenness") +
  theme_fig

p_fig04 <- (p_fig04a | p_fig04b) +
  plot_layout(widths = c(1.6, 1), guides = "collect")
ggsave(image_path("fig04_boxplot_centrality.png"),
       p_fig04, width = 11, height = 4.5, dpi = 300)
message("Saved fig04_boxplot_centrality.png (four cells; Lorenz Gini checked)")

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

# (p_map_* are saved below to images/qc/ as single maps of the two published
# networks; fig05 itself is the four-cell betweenness map that follows.)

# FIG 05 — Betweenness maps of the four factorial cells (rows: phase;
#          columns: cost function). One colour / size scale and one extent
#          for all panels; ten highest-betweenness nodes ringed; upland
#          centres and Hamallaj labelled with their toponyms.
cell_edges <- list("H-T" = list(e = edges_hell_filtered,                     n = nodes_hell),
                   "H-W" = list(e = readRDS(rds_path("edges_hw_filtered.rds")), n = nodes_hell),
                   "R-T" = list(e = readRDS(rds_path("edges_rt_filtered.rds")), n = nodes_rom),
                   "R-W" = list(e = edges_rom_filtered,                      n = nodes_rom))
edge_seg <- do.call(rbind, lapply(names(cell_edges), function(k) {
  e  <- cell_edges[[k]]$e; n <- cell_edges[[k]]$n
  ia <- n$id_sito[match(e$from, n$id)]; ib <- n$id_sito[match(e$to, n$id)]
  a  <- site_xy_all[match(ia, site_xy_all$id_sito), ]; b <- site_xy_all[match(ib, site_xy_all$id_sito), ]
  data.frame(cell = k, x = a$X, y = a$Y, xend = b$X, yend = b$Y)
}))
edge_seg$phase   <- factor(ifelse(substr(edge_seg$cell, 1, 1) == "H", "Hellenistic", "Roman"),
                           levels = levels(fc$phase))
edge_seg$cost_fn <- factor(ifelse(substr(edge_seg$cell, 3, 3) == "T", "Tobler", "Wheeled transport"),
                           levels = levels(fc$cost_fn))
stopifnot("fig05: edge counts must match factorial_composition.csv" = {
  comp <- read.csv(table_path("factorial_composition.csv"))
  all(table(edge_seg$cell)[comp$cell] == comp$n_edges)
})

top10_fig <- fc %>% group_by(cell) %>%
  arrange(desc(betweenness_norm), id_sito, .by_group = TRUE) %>% slice_head(n = 10) %>% ungroup()
stopifnot("fig05: ringed nodes must be the top-10 of factorial_top10_location.csv" =
            all(vapply(FACT_CELLS, function(k)
              setequal(top10_fig$id_sito[top10_fig$cell == k],
                       fact_top10$id_sito[fact_top10$cell == k & fact_top10$row_type == "site"]),
              logical(1))))
focus_fig <- fc %>% filter(id_sito %in% names(FOCUS_TOPONYMS))
assert_no_dur_labels(focus_fig$toponym, "fig05")

p_fig05 <- ggplot() +
  geom_segment(data = edge_seg, aes(x = x, y = y, xend = xend, yend = yend),
               colour = "grey80", linewidth = 0.12) +
  geom_point(data = fc %>% arrange(betweenness_norm),
             aes(x = X, y = Y, size = betweenness_norm, colour = betweenness_norm),
             alpha = 0.9) +
  geom_point(data = top10_fig, aes(x = X, y = Y), shape = 21, size = 4.2,
             colour = "black", fill = NA, stroke = 0.6) +
  geom_text_repel(data = focus_fig, aes(x = X, y = Y, label = toponym),
                  size = 2.4, fontface = "bold", box.padding = 0.4,
                  min.segment.length = 0, max.overlaps = 20, seed = SCATTER_SEED) +
  facet_grid(phase ~ cost_fn) +
  scale_colour_viridis_c(option = "magma", direction = -1, name = "Betweenness\n(norm.)") +
  scale_size_continuous(range = c(0.6, 5), guide = "none") +
  coord_sf(crs = CRS_UTM) +
  scale_x_continuous(breaks = lon_breaks) +
  labs(x = NULL, y = NULL) +
  theme_fig +
  theme(strip.text = element_text(face = "bold"))

ggsave(image_path("fig05_centrality_maps.png"),
       p_fig05, width = 9, height = 9.5, dpi = 300)
message("Saved fig05_centrality_maps.png (four-cell betweenness maps)")

# =============================================================================
# FIG 06 — Leiden community partition of the Roman network's largest component
#
# Loads the objects written by 06_community_detection.R. Module numbers and
# sizes are read from the partition, not hard-coded: the legend reports the
# modules actually found. The centroid marked with a cross is that of the
# module containing DUR050 (Kavaja plain).
#
# Caption:
#   Figure 6. Leiden community partition of the Roman network's largest
#   component (node count and modularity: see 06 / null_model_results.csv).
#   Sites outside the largest
#   component (grey) were not included in community detection. The
#   partition is descriptive of network structure; it is not statistically
#   distinguishable from a spatial null model (Section 4.3) and should not
#   be read as evidence of territorial administration.
# =============================================================================

giant_g   <- readRDS(rds_path("giant.rds"))
cl_leiden <- readRDS(rds_path("cl_leiden.rds"))

# --- Build module membership table (mirrors 06_community_detection.R) ---------
mod_df <- data.frame(
  id     = as.integer(V(giant_g)$name),
  module = as.integer(membership(cl_leiden))
) %>%
  left_join(nodes_rom %>% select(id, id_sito), by = "id")

mod_n <- table(mod_df$module)
message("Fig 06: ", length(mod_n), " modules, sizes ",
        paste(sprintf("%s (n=%d)", names(mod_n), as.integer(mod_n)), collapse = ", "))

# Module names (explicit correspondence, legend order = module number).
# Blocking check: sizes and members equal module_summary.csv (written by 06).
MODULE_NAMES <- data.frame(
  module = 1:5,
  area   = c("Durrës hinterland", "Karinë–Rrogozhinë", "Kavaja plain",
             "Manëz–Rubjek", "Luz i Vogël–Fushë Qerret"),
  n      = c(18L, 6L, 15L, 5L, 22L),
  stringsAsFactors = FALSE
)
mod_summary <- read.csv(table_path("module_summary.csv"), stringsAsFactors = FALSE)
stopifnot(
  "fig06: module numbers must match module_summary.csv" =
    setequal(MODULE_NAMES$module, mod_summary$module) &&
    setequal(MODULE_NAMES$module, as.integer(names(mod_n))),
  "fig06: module sizes must match module_summary.csv" =
    all(MODULE_NAMES$n == mod_summary$n_sites[match(MODULE_NAMES$module, mod_summary$module)]) &&
    all(MODULE_NAMES$n == as.integer(mod_n[as.character(MODULE_NAMES$module)])),
  "fig06: module members must match module_summary.csv" =
    all(vapply(MODULE_NAMES$module, function(m)
      setequal(mod_df$id_sito[mod_df$module == m],
               strsplit(mod_summary$members[mod_summary$module == m], ";")[[1]]),
      logical(1)))
)
MODULE_NAMES$label <- sprintf("%s (%d)", MODULE_NAMES$area, MODULE_NAMES$n)

# Join X/Y from centrality table (cc has X, Y for all Roman sites)
cc_rom <- cc %>% filter(phase == "roman")
mod_spatial <- mod_df %>%
  left_join(cc_rom %>% select(id_sito, X, Y, degree), by = "id_sito") %>%
  mutate(module_f = factor(module, levels = MODULE_NAMES$module,
                           labels = MODULE_NAMES$label))

# Centroid of the module containing DUR050 (cited in §5.3: "~4 km north of
# modern Kavaja"; module 4 in the first submission)
mod_kavaja <- mod_df$module[mod_df$id_sito == "DUR050"]
stopifnot("fig06: the cross must mark the Kavaja plain module" =
            MODULE_NAMES$area[MODULE_NAMES$module == mod_kavaja] == "Kavaja plain")
mod4_xy <- mod_spatial %>% filter(module == mod_kavaja) %>%
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

# Toponyms instead of site codes (ancient names for the road stations)
fig06_label <- function(ids) ifelse(ids %in% names(wp_site_names), wp_site_names[ids],
                                    site_lab$toponym[match(ids, site_lab$id_sito)])
label_giant$label    <- fig06_label(label_giant$id_sito)
label_nongiant$label <- fig06_label(label_nongiant$id_sito)
assert_no_dur_labels(c(label_giant$label, label_nongiant$label), "fig06")

# --- DEM background (grey gradient, coarser resolution — geographic context) --
dem_raw_f06 <- terra::rast(data_path("dem.tif"))
dem_agg_f06 <- terra::aggregate(dem_raw_f06, fact = 8)
dem_df_f06  <- as.data.frame(dem_agg_f06, xy = TRUE)
names(dem_df_f06)[3] <- "elevation"
rm(dem_raw_f06, dem_agg_f06)

# --- Figure -------------------------------------------------------------------
FIG06_SYMBOLS <- c("Other Roman sites", "Centroid, Kavaja plain module")
p_fig06 <- ggplot() +
  # Subtle DEM background — same extent as fig01/02/03; grey avoids competing
  # with the qualitative module colours
  geom_raster(data = dem_df_f06,
              aes(x = x, y = y, fill = elevation),
              show.legend = FALSE) +
  scale_fill_gradient(low = "grey97", high = "grey72",
                      na.value = "transparent",
                      guide = "none") +
  # Sites outside giant: grey hollow circles (excluded from community detection)
  geom_sf(data = non_giant_sf, aes(shape = FIG06_SYMBOLS[1]), size = 1.4,
          fill = NA, colour = "grey55", stroke = 0.4) +
  # Giant component nodes: solid circles, coloured by module (nominal palette)
  geom_point(data = mod_spatial,
             aes(x = X, y = Y, colour = module_f),
             shape = 16, size = 2.2, alpha = 0.92) +
  scale_colour_brewer(palette = "Set2", name = "Module",
                      guide = guide_legend(order = 1)) +
  # Centroid of DUR050's module: cross (+) symbol, cited in §5.3
  geom_sf(data = mod4_sf, aes(shape = FIG06_SYMBOLS[2]), size = 5,
          colour = "black", stroke = 1.0) +
  scale_shape_manual(values = setNames(c(21, 3), FIG06_SYMBOLS), breaks = FIG06_SYMBOLS,
                     name = NULL,
                     guide = guide_legend(order = 2, override.aes = list(
                       size = c(1.6, 3.5), colour = c("grey55", "black"),
                       stroke = c(0.5, 1), fill = NA))) +
  # Labels: giant sites cited in text (bold)
  geom_text_repel(data    = label_giant,
                  aes(x = X, y = Y, label = label),
                  size         = 2.5,
                  fontface     = "bold",
                  colour       = "black",
                  box.padding  = 0.35,
                  max.overlaps = 20,
                  seed         = COMMUNITY_SEED) +
  # Labels: non-giant sites cited in §5.5 (grey italic)
  geom_text_repel(data    = label_nongiant,
                  aes(x = X, y = Y, label = label),
                  size         = 2.3,
                  fontface     = "italic",
                  colour       = "grey40",
                  box.padding  = 0.3,
                  max.overlaps = 20,
                  seed         = COMMUNITY_SEED) +
  annotation_scale(location = "bl", unit_category = "metric") +
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

# FIG 07 \u2014 betweenness of the 46 dual-phase sites, Hellenistic vs Roman, at
# constant cost function (Tobler: H-T vs R-T; wheeled transport: H-W vs R-W)
dual_fc <- fc %>%
  filter(dual_phase) %>%
  select(id_sito, toponym, phase, cost_fn, betweenness_norm) %>%
  pivot_wider(names_from = phase, values_from = betweenness_norm)
stopifnot("fig07: 46 dual-phase sites per panel" =
            all(table(dual_fc$cost_fn) == 46), !anyNA(dual_fc[, c("Hellenistic", "Roman")]))
rho_fig07 <- dual_fc %>% group_by(cost_fn) %>%
  summarise(rho = cor(Hellenistic, Roman, method = "spearman"), .groups = "drop")
rho_ref <- fact_tests$statistic[fact_tests$test == "spearman_dual" &
                                  fact_tests$metric == "betweenness_norm"]
names(rho_ref) <- fact_tests$comparison[fact_tests$test == "spearman_dual" &
                                          fact_tests$metric == "betweenness_norm"]
stopifnot("fig07: rho must equal factorial_tests.csv" =
            isTRUE(all.equal(rho_fig07$rho, unname(rho_ref[c("H-T vs R-T", "H-W vs R-W")]))))
rho_fig07$label <- sprintf("\u03c1 = %.2f", rho_fig07$rho)

# Labels: the upland centres / Hamallaj present in both phases, plus the
# three sites farthest from the diagonal in each panel (square-root scale)
lab_fig07 <- dual_fc %>% group_by(cost_fn) %>%
  mutate(dev = abs(sqrt(Roman) - sqrt(Hellenistic))) %>%
  filter(id_sito %in% names(FOCUS_TOPONYMS) | rank(-dev, ties.method = "first") <= 3) %>%
  ungroup()
assert_no_dur_labels(lab_fig07$toponym, "fig07")
# In the wheeled panel Dorez, Mliku and Shenlliu sit on the origin
# (zero betweenness in H-W and R-W) and Zgerdesh just above it. Their labels
# are pulled to the right in a column, with leader segments.
lab07_origin <- lab_fig07$cost_fn == "Wheeled transport" &
  lab_fig07$Hellenistic == 0 & lab_fig07$Roman < 0.005

p_scatter <- ggplot(dual_fc, aes(x = Hellenistic, y = Roman)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey50") +
  geom_point(aes(fill = cost_fn), shape = 21, colour = "grey20", stroke = 0.3,
             size = 2.2, alpha = 0.9, show.legend = FALSE) +
  geom_text_repel(data = lab_fig07[!lab07_origin, ], aes(label = toponym), size = 2.4,
                  min.segment.length = 0, max.overlaps = 20, seed = SCATTER_SEED) +
  geom_text_repel(data = lab_fig07[lab07_origin, ], aes(label = toponym), size = 2.4,
                  nudge_x = 0.12, nudge_y = 0.03, direction = "y", hjust = 0,
                  box.padding = 0.35, point.padding = 0.2, force = 2,
                  segment.colour = "grey35", segment.size = 0.3,
                  min.segment.length = 0, max.overlaps = Inf, seed = SCATTER_SEED) +
  # (-Inf / Inf positions are lost on the square-root scale)
  geom_text(data = rho_fig07, aes(x = 0, y = max(dual_fc$Roman), label = label),
            hjust = 0, vjust = 1, size = 3.4, inherit.aes = FALSE) +
  facet_wrap(~ cost_fn) +
  scale_fill_manual(values = COSTFN_COLS) +
  scale_x_sqrt() + scale_y_sqrt() +
  labs(x = "Betweenness (norm.), Hellenistic network (square-root scale)",
       y = "Betweenness (norm.), Roman network (square-root scale)") +
  theme_fig +
  theme(strip.text = element_text(face = "bold"))

ggsave(image_path("fig07_scatter_dualphase.png"),
       p_scatter, width = 9, height = 4.6, dpi = 300)
message("Saved fig07_scatter_dualphase.png (rho ", paste(rho_fig07$label, collapse = ", "), ")")

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
#          (R-W): two series on one proportion axis —
#          sites without edges and sites in the largest component — with the
#          10 % selection criterion and the selected threshold (ROM_THRESH)
# =============================================================================
sweep_results <- read.csv(table_path("threshold_sweep_roman.csv"),
                          stringsAsFactors = FALSE)
FIG08_SERIES <- c(pct_isolates   = "Sites without edges",
                  giant_fraction = "Sites in the largest component")
sweep_long <- sweep_results %>%
  select(threshold, all_of(names(FIG08_SERIES))) %>%
  pivot_longer(-threshold, names_to = "series", values_to = "prop") %>%
  mutate(series = factor(FIG08_SERIES[series], levels = FIG08_SERIES))

# Check (blocking): values at the selected threshold
at_sel <- sweep_results[sweep_results$threshold == ROM_THRESH, ]
stopifnot("fig08: at 150 min the two series must be 0.053 and 0.702" =
            nrow(at_sel) == 1L &&
            round(at_sel$pct_isolates, 3) == 0.053 &&
            round(at_sel$giant_fraction, 3) == 0.702)

p_fig08 <- ggplot(sweep_long, aes(x = threshold, y = prop, colour = series, shape = series)) +
  geom_hline(yintercept = 0.10, linetype = "dashed", colour = "grey40", linewidth = 0.4) +
  geom_vline(xintercept = ROM_THRESH, linetype = "dotted", colour = "grey20", linewidth = 0.5) +
  annotate("text", x = max(sweep_results$threshold), y = 0.10,
           label = "Selection criterion (< 10% without edges)",
           hjust = 1, vjust = -0.6, size = 2.6, colour = "grey30") +
  annotate("text", x = ROM_THRESH, y = 1,
           label = sprintf("Selected threshold (%d min)", ROM_THRESH),
           hjust = -0.05, vjust = 1, size = 2.6, colour = "grey20") +
  geom_line(linewidth = 0.6) +
  geom_point(size = 1.8, fill = "white", stroke = 0.6) +
  scale_colour_manual(values = setNames(c("grey25", PHASE_COLS[["roman"]]), FIG08_SERIES),
                      name = NULL) +
  scale_shape_manual(values = setNames(c(21, 16), FIG08_SERIES), name = NULL) +
  scale_x_continuous(breaks = sweep_results$threshold) +
  scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
  labs(x = "Threshold (min)", y = "Proportion of sites") +
  theme_fig +
  theme(legend.position = "bottom")

ggsave(image_path("fig08_threshold_sensitivity.png"),
       p_fig08, width = 6, height = 4, dpi = 300)
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

# Corridor as percentage cost above the optimum,
# 100 * (cell / min(corridor) - 1), minimum over all non-NA cells of the full
# resolution corridor; colour scale capped at CORR_CAP_PCT (cells above it take
# the top colour). Isoline at the 5 % quantile of the corridor values, the same
# thresholds as the containment analysis of 08 (38 498.43 s wheeled,
# 24 793.14 s Tobler); blocking check of its position above the optimum.
CORR_CAP_PCT <- 25
CORR_Q       <- 0.05
corr_prep <- function(corr, q_ref, pct_ref) {
  v    <- as.numeric(terra::values(corr, na.rm = TRUE))
  vmin <- min(v)
  q    <- unname(quantile(v, CORR_Q))
  if (abs(q - q_ref) > 0.01 || abs(100 * (q / vmin - 1) - pct_ref) > 0.1)
    stop(sprintf("fig09: 5%% isoline at %.2f s = %.2f%% above optimum (expected %.2f s, %.1f%%)",
                 q, 100 * (q / vmin - 1), q_ref, pct_ref))
  df <- as.data.frame(terra::aggregate(corr, fact = 4), xy = TRUE)
  names(df)[3] <- "cost"
  df$pct <- 100 * (df$cost / vmin - 1)
  iso <- sf::st_as_sf(terra::as.contour(corr, levels = q))
  sf::st_crs(iso) <- sf::st_crs(CRS_UTM)
  message(sprintf("fig09: optimum %.1f s; 5%% quantile %.2f s = %.2f%% above optimum",
                  vmin, q, 100 * (q / vmin - 1)))
  list(df = df, iso = iso)
}
corr_w <- corr_prep(corr_wheeled, 38498.4348, 2.4)
corr_t <- corr_prep(corr_tobler,  24793.1418, 4.5)

ISO_LABEL <- "Cheapest 5% of corridor"

# Helper: one corridor panel with its respective full-route LCP overlaid.
# fill = corridor raster (plasma); colour = route lines + isoline + legend.
make_fig09_panel <- function(corr, egnatia_sf, lcp_sf, lcp_label,
                              lcp_col, wp_plot, sites_sf, title) {
  colour_vals <- c("Attested route" = "black")
  colour_vals[[lcp_label]] <- lcp_col
  colour_vals[[ISO_LABEL]] <- "grey10"

  ggplot() +
    geom_raster(data = corr$df, aes(x = x, y = y, fill = pct)) +
    scale_fill_viridis_c(option = "plasma", direction = -1,
                         limits = c(0, CORR_CAP_PCT), oob = scales::squish,
                         breaks = seq(0, CORR_CAP_PCT, 5),
                         labels = c(seq(0, CORR_CAP_PCT - 5, 5),
                                    paste0("≥", CORR_CAP_PCT)),
                         na.value = "transparent", name = "Cost above\noptimum (%)") +
    guides(fill = guide_colourbar(order = 2, barwidth = unit(4.5, "cm"),
                                  barheight = unit(0.35, "cm"))) +
    # 5 % isoline (under the routes)
    geom_sf(data = corr$iso, aes(colour = ISO_LABEL), linewidth = 0.5,
            linetype = "dotted") +
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
    scale_colour_manual(values = colour_vals, breaks = names(colour_vals), name = NULL) +
    guides(colour = guide_legend(
      order = 1,
      override.aes = list(
        linetype  = c("solid", "dashed", "dotted"),
        linewidth = c(1.1, 0.8, 0.6),
        shape     = c(NA, NA, NA)
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
  corr_w, egnatia_sf, lcp_full_wheeled,
  lcp_label = "Wheeled-transport LCP",
  lcp_col   = PHASE_COLS[["roman"]],
  wp_plot   = wp_plot, sites_sf = siti_rom_bg,
  title     = "(a) Wheeled-transport corridor"
)

p_fig09_tobler <- make_fig09_panel(
  corr_t, egnatia_sf, lcp_full_tobler,
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

rm(corr_wheeled, corr_tobler, corr_w, corr_t,
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

# Use corrected PDI values from pdi_fixed() — not the buggy package output.
# Values matched by segment key (waypoint pairs), not by row order.
val_seg  <- read.csv(table_path("egnatia_pdi_final.csv"), stringsAsFactors = FALSE)
seg_keys <- paste(head(WAYPOINT_IDS, -1), "->", tail(WAYPOINT_IDS, -1))
pdi_wheeled <- val_seg$normalised_pdi[val_seg$cost_function == "wheeled transport"][
  match(seg_keys, val_seg$segment[val_seg$cost_function == "wheeled transport"])]
stopifnot("fig10: one wheeled PDI per segment" =
            length(pdi_wheeled) == length(known_segs) && !anyNA(pdi_wheeled))

seg_titles <- c("(a) Dyrrachium–Clodiana",
                "(b) Clodiana–Ad Quintum",
                "(c) Ad Quintum–Scampis")

wp_snapped_sf <- readRDS(rds_path("wp_snapped.rds"))
wp_plot       <- wp_snapped_sf %>% mutate(site_name = wp_site_names[id_sito])
wp_plot       <- wp_plot[match(WAYPOINT_IDS, wp_plot$id_sito), ]
wp_xy         <- data.frame(id_sito = wp_plot$id_sito, site_name = wp_plot$site_name,
                            sf::st_coordinates(wp_plot))
assert_no_dur_labels(wp_xy$site_name, "fig10")

SEG_COLS <- egnatia_cols[c("Attested route", "Wheeled-transport LCP", "Tobler LCP")]
# Scale bars in km: ggspatial switches to km when the bar is >= 1600 m, so
# the width hint is raised on narrow panels
SCALE_MIN_M <- 1800

panels_seg <- lapply(seq_along(known_segs), function(i) {
  lcp_i  <- readRDS(rds_path(sprintf("lcp_egnatia_wheeled_seg%d.rds", i)))
  lcp_ti <- readRDS(rds_path(sprintf("lcp_egnatia_tobler_seg%d.rds", i)))
  kseg   <- known_segs[[i]]
  wp_i   <- wp_xy[i + 0:1, ]

  bbs  <- lapply(list(kseg, lcp_i, lcp_ti), sf::st_bbox)
  xmin <- min(sapply(bbs, `[`, "xmin")); xmax <- max(sapply(bbs, `[`, "xmax"))
  ymin <- min(sapply(bbs, `[`, "ymin")); ymax <- max(sapply(bbs, `[`, "ymax"))
  pad  <- 0.06 * max(xmax - xmin, ymax - ymin)
  width_m    <- (xmax - xmin) + 2 * pad
  scale_hint <- max(0.25, SCALE_MIN_M / width_m)
  stopifnot("fig10: scale bar would cover most of the panel" = scale_hint <= 0.6)

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
    geom_sf(data = lcp_ti,
            aes(colour = "Tobler LCP"), linewidth = 0.7, linetype = "dashed") +
    # Waypoints at the ends of the segment
    geom_point(data = wp_i, aes(x = X, y = Y), shape = 21, size = 2.6,
               fill = "white", colour = "black", stroke = 0.7) +
    geom_label_repel(data = wp_i, aes(x = X, y = Y, label = site_name),
                     size = 2.6, label.size = 0, fill = alpha("white", 0.85),
                     box.padding = 0.5, min.segment.length = 0,
                     seed = SCATTER_SEED) +
    scale_colour_manual(values = SEG_COLS, breaks = names(SEG_COLS), name = NULL) +
    scale_fill_manual(values = c("Roman-phase sites" = SITE_FILL), name = NULL) +
    guides(
      colour = guide_legend(order = 1,
        override.aes = list(linetype  = c("solid", "solid", "dashed"),
                            linewidth = c(0.9, 0.7, 0.7),
                            shape     = c(NA, NA, NA))),
      fill = guide_legend(order = 2,
        override.aes = list(shape = 21, size = 3,
                            colour = SITE_BDR, stroke = SITE_STR, alpha = 1))
    ) +
    annotation_scale(location = "bl", unit_category = "metric",
                     width_hint = scale_hint) +
    coord_sf(crs    = CRS_UTM,
             xlim   = c(xmin - pad, xmax + pad),
             ylim   = c(ymin - pad, ymax + pad),
             expand = FALSE) +
    labs(x = NULL, y = NULL,
         title = sprintf("%s · normalised PDI %.2f%%", seg_titles[i], pdi_wheeled[i])) +
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
   wp_snapped_sf, wp_plot, wp_xy)

# =============================================================================
# QC FIGURES (output/images/qc/, not in the manuscript)
# =============================================================================

# -------------------------------------------------------------------------
# Individual centrality maps of the two published networks (ex fig05)
# -------------------------------------------------------------------------
# QC only: H-T | R-W is the confounded comparison, not for the supplement
ggsave(image_path("qc", "fig_map_degree.png"),      p_map_deg, width = 9, height = 5, dpi = 300)
ggsave(image_path("qc", "fig_map_harmonic.png"),    p_map_clo, width = 9, height = 5, dpi = 300)
ggsave(image_path("qc", "fig_map_betweenness.png"), p_map_btw, width = 9, height = 5, dpi = 300)
message("Saved individual centrality map figures to images/qc/ (H-T | R-W, ex fig05).")

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
