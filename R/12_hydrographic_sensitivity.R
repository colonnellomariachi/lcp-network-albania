# =============================================================================
# 12_hydrographic_sensitivity.R — River-crossing penalty sensitivity
#
# Reviewer 1 asks how watercourses affect the networks. The river layer is the
# author-supplied polygon layer of the main river courses (HYDRO_POLYGON_PATH,
# data/river polygon.gpkg). It replaces the OSM lines buffered by 25 m used in
# Task 9 (data/hydro/, no longer read by any script).
#
# Rivers are NOT absolute barriers (no data on fords/bridges): the cost of
# entering a river cell is multiplied by each factor in HYDRO_PENALTIES
# (×5 moderate, ×20 strong). Implemented by dividing the columns of the
# conductance matrix (moves INTO river cells) by the factor. A DEM cell is a
# river cell if its centre falls inside a river polygon. Everything else —
# surfaces, site sets, thresholds, network construction — is the main pipeline
# (lcp_helpers.R, network_helpers.R). No site is moved.
#
# Networks: H-T and R-W (priority) and, if listed in HYDRO_CELLS, H-W and R-T
# (factorial cells from 11). Each is compared with its unpenalised counterpart.
#
# Input:  data/river polygon.gpkg, data/dem.tif, data/sites.gpkg
#         output/rds/cost_surface_{hell,rom}.rds, siti_*.rds, nodes_*.rds
#         output/rds/lcp_hell.gpkg, lcp_roman.gpkg (unpenalised H-T, R-W)
#         output/rds/lcp_hell_wheeled.gpkg, lcp_rom_tobler.gpkg (from 11)
# Output: output/rds/lcp_hydro_{ht,rw,hw,rt}_x{5,20}.gpkg   [SLOW ~25 min each]
#         output/rds/net_hydro_{ht,rw,hw,rt}_x{5,20}.rds
#         output/tables/hydro_sensitivity.csv
#         output/tables/hydro_upland_centres.csv
#         output/tables/hydro_sites_in_rivers.csv
#         output/tables/hydro_source.md
#         output/images/qc/hydro_rivers_selected.png
# =============================================================================

HYDRO_CELLS  <- c("H-T", "R-W", "H-W", "R-T")   # priority order
UPLAND_IDS_H <- c("DUR032", "DUR053", "DUR015", "DUR025", "DUR003")
TOP_N_OVERLAP <- 10
HYDRO_TASK9_CELLS <- 42825   # river cells of the Task 9 layer (OSM lines + 25 m)

dir.create(image_path("qc"), showWarnings = FALSE, recursive = TRUE)

cell_spec <- data.frame(
  cell      = c("H-T", "R-W", "H-W", "R-T"),
  tag       = c("ht", "rw", "hw", "rt"),
  site_set  = c("hellenistic", "roman", "hellenistic", "roman"),
  cs_file   = c("cost_surface_hell.rds", "cost_surface_rom.rds",
                "cost_surface_rom.rds", "cost_surface_hell.rds"),
  strategy  = c("fete", "loop", "fete", "loop"),
  threshold = c(HELL_THRESH, ROM_THRESH, ROM_THRESH, HELL_THRESH),
  base_gpkg = c("lcp_hell.gpkg", "lcp_roman.gpkg",
                "lcp_hell_wheeled.gpkg", "lcp_rom_tobler.gpkg"),
  stringsAsFactors = FALSE
)
cell_spec <- cell_spec[match(HYDRO_CELLS, cell_spec$cell), ]

# ---------------------------------------------------------------------------
# 1. River polygons: checks (blocking) → union → raster cells
# ---------------------------------------------------------------------------
if (!file.exists(HYDRO_POLYGON_PATH))
  stop("River polygon layer not found: ", HYDRO_POLYGON_PATH)

riv_raw <- sf::st_read(HYDRO_POLYGON_PATH, quiet = TRUE)
riv_types <- unique(as.character(sf::st_geometry_type(riv_raw)))
if (!all(riv_types %in% c("POLYGON", "MULTIPOLYGON")))
  stop("River layer must be POLYGON / MULTIPOLYGON; found: ",
       paste(riv_types, collapse = ", "))

riv_info <- list(
  file       = basename(HYDRO_POLYGON_PATH),
  layer      = sf::st_layers(HYDRO_POLYGON_PATH)$name[1],
  n          = nrow(riv_raw),
  types      = paste(riv_types, collapse = ", "),
  fields     = paste(setdiff(names(riv_raw), attr(riv_raw, "sf_column")), collapse = ", "),
  epsg_in    = sf::st_crs(riv_raw)$epsg
)
riv <- if (isTRUE(riv_info$epsg_in == CRS_UTM)) riv_raw else sf::st_transform(riv_raw, CRS_UTM)
riv_info$reprojected <- !isTRUE(riv_info$epsg_in == CRS_UTM)
riv_info$area_km2_in <- sum(as.numeric(sf::st_area(riv))) / 1e6

# Validity (same class of defect that corrupted the PDI): repair, re-check, stop
invalid <- !sf::st_is_valid(riv)
invalid[is.na(invalid)] <- TRUE
riv_info$n_invalid <- sum(invalid)
if (any(invalid)) {
  sf::st_geometry(riv)[invalid] <- sf::st_make_valid(sf::st_geometry(riv)[invalid])
  still <- !sf::st_is_valid(riv); still[is.na(still)] <- TRUE
  if (any(still))
    stop(sum(still), " river polygon(s) still invalid after st_make_valid()")
}
riv_info$area_km2_valid <- sum(as.numeric(sf::st_area(riv))) / 1e6

# Overlaps: union so no area (and no cell) is counted twice
ov <- sf::st_overlaps(riv)
riv_info$n_overlap_pairs <- sum(lengths(ov)) / 2
riv_union <- sf::st_make_valid(sf::st_union(sf::st_geometry(riv)))
stopifnot(all(sf::st_is_valid(riv_union)),
          all(as.character(sf::st_geometry_type(riv_union)) %in% c("POLYGON", "MULTIPOLYGON")))
riv_info$area_km2_union <- sum(as.numeric(sf::st_area(riv_union))) / 1e6

message(sprintf("River polygons: %d %s, EPSG %s, %.2f km² (union %.2f km²), %d invalid repaired, %d overlapping pairs",
                riv_info$n, riv_info$types, riv_info$epsg_in, riv_info$area_km2_in,
                riv_info$area_km2_union, riv_info$n_invalid, riv_info$n_overlap_pairs))

# Rasterise on the DEM grid; cell centre inside a polygon (terra default,
# no touches = TRUE)
dem <- terra::rast(data_path("dem.tif"))
river_r <- terra::rasterize(terra::vect(riv_union), dem, field = 1, background = NA)
stopifnot(terra::compareGeom(river_r, dem))
river_all   <- which(!is.na(terra::values(river_r, mat = FALSE)))
river_cells <- river_all[!is.na(terra::values(dem, mat = FALSE)[river_all])]
cell_km2 <- prod(terra::res(dem)) / 1e6
riv_info$n_cells        <- length(river_cells)
riv_info$n_cells_nodata <- length(river_all) - length(river_cells)
message("River cells: ", length(river_cells), " (", round(length(river_cells) * cell_km2, 1),
        " km²); Task 9 layer: ", HYDRO_TASK9_CELLS, " (",
        round(HYDRO_TASK9_CELLS * cell_km2, 1), " km²)")

# Sites inside a river polygon / on a river cell (positions = gpkg geometry).
# Not a stop criterion: listed because it must be declared in Methods. Moves
# INTO such a cell are penalised; moves out of it are not.
sites_all <- sf::st_read(data_path("sites.gpkg"), quiet = TRUE) %>% sf::st_transform(CRS_UTM)
in_poly <- lengths(sf::st_intersects(sites_all, riv_union)) > 0
on_cell <- terra::cellFromXY(dem, sf::st_coordinates(sites_all)) %in% river_cells
hell_ids <- readRDS(rds_path("siti_hell.rds"))$id_sito
rom_ids  <- readRDS(rds_path("siti_rom.rds"))$id_sito
sites_in_rivers <- data.frame(
  id_sito = sites_all$id_sito, localita = sites_all$localita,
  inside_polygon = in_poly, on_river_cell = on_cell,
  in_hellenistic_network = sites_all$id_sito %in% hell_ids,
  in_roman_network       = sites_all$id_sito %in% rom_ids,
  penalty_on_site_cell = ifelse(on_cell, paste0("x", paste(HYDRO_PENALTIES, collapse = " / x"),
                                                " on moves into the cell"), "none"),
  stringsAsFactors = FALSE)[in_poly | on_cell, ]
rownames(sites_in_rivers) <- NULL
write.csv(sites_in_rivers, table_path("hydro_sites_in_rivers.csv"), row.names = FALSE)
message("Sites inside a river polygon or on a river cell: ", nrow(sites_in_rivers),
        if (nrow(sites_in_rivers)) paste0(" (", paste(sites_in_rivers$id_sito, collapse = ", "), ")") else "")

# ---------------------------------------------------------------------------
# 2. Penalised LCPs [SLOW]
# ---------------------------------------------------------------------------
apply_hydro_penalty <- function(cs, cells, factor) {
  M <- cs$conductanceMatrix
  stopifnot(inherits(M, "dgCMatrix"))
  f <- rep(1, ncol(M)); f[cells] <- 1 / factor
  M@x <- M@x * f[rep.int(seq_len(ncol(M)), diff(M@p))]   # scale columns
  cs$conductanceMatrix <- M
  cs
}

hydro_gpkg <- function(tag, k) rds_path(sprintf("lcp_hydro_%s_x%d.gpkg", tag, k))

for (i in seq_len(nrow(cell_spec))) for (k in HYDRO_PENALTIES) {
  sp  <- cell_spec[i, ]
  out <- hydro_gpkg(sp$tag, k)
  if (file.exists(out)) next
  message(sprintf("[12] %s ×%d — computing LCPs", sp$cell, k))
  cs <- apply_hydro_penalty(readRDS(rds_path(sp$cs_file)), river_cells, k)
  site_file <- c(hellenistic = "siti_hell.rds", roman = "siti_rom.rds")[[sp$site_set]]
  run_lcp_set(readRDS(rds_path(site_file)), cs, sp$strategy, out,
              sprintf("%s x%d", sp$cell, k))
  rm(cs); gc(verbose = FALSE)
}

# ---------------------------------------------------------------------------
# 3. Networks and metrics vs unpenalised
# ---------------------------------------------------------------------------
cs_meta <- local({
  cs <- readRDS(rds_path("cost_surface_rom.rds"))
  m  <- cs[c("nrow", "ncol", "extent", "crs")]; rm(cs); gc(verbose = FALSE); m
})
siti  <- list(hellenistic = readRDS(rds_path("siti_hell.rds")),
              roman       = readRDS(rds_path("siti_rom.rds")))
nodes <- list(hellenistic = readRDS(rds_path("nodes_hell.rds")),
              roman       = readRDS(rds_path("nodes_rom.rds")))

rows <- list(); upl <- list()
for (i in seq_len(nrow(cell_spec))) {
  sp <- cell_spec[i, ]
  base <- build_cell_network(
    resolve_lcp_site_ids(sf::st_read(rds_path(sp$base_gpkg), quiet = TRUE),
                         siti[[sp$site_set]], cs_meta),
    nodes[[sp$site_set]], sp$threshold)$net
  b0 <- igraph::betweenness(base, normalized = TRUE)
  top0 <- head(V(base)$id_sito[order(-b0, V(base)$id_sito)], TOP_N_OVERLAP)

  for (k in c(1, HYDRO_PENALTIES)) {
    if (k == 1) g <- base else {
      g <- build_cell_network(
        resolve_lcp_site_ids(sf::st_read(hydro_gpkg(sp$tag, k), quiet = TRUE),
                             siti[[sp$site_set]], cs_meta),
        nodes[[sp$site_set]], sp$threshold)$net
      saveRDS(g, rds_path(sprintf("net_hydro_%s_x%d.rds", sp$tag, k)))
    }
    b <- igraph::betweenness(g, normalized = TRUE)
    b_al <- b[match(V(base)$id_sito, V(g)$id_sito)]
    top <- head(V(g)$id_sito[order(-b, V(g)$id_sito)], TOP_N_OVERLAP)
    rows[[length(rows) + 1]] <- cbind(
      data.frame(network = sp$cell, penalty = k, stringsAsFactors = FALSE),
      composition_row(g, sp$cell)[, -1],
      concentration_row(g, sp$cell)[, -1],
      data.frame(
        edges_lost_vs_base = ecount(base) - length(intersect(
          igraph::as_ids(E(base)), igraph::as_ids(E(g)))),
        top10_overlap_vs_base = length(intersect(top, top0)),
        top10 = paste(top, collapse = ";"),
        spearman_betweenness_vs_base =
          suppressWarnings(cor(b0, b_al, method = "spearman")),
        stringsAsFactors = FALSE))
    ct <- centrality_table(g, sp$cell)
    upl[[length(upl) + 1]] <- data.frame(
      network = sp$cell, penalty = k, id_sito = UPLAND_IDS_H,
      present = UPLAND_IDS_H %in% ct$id_sito,
      ct[match(UPLAND_IDS_H, ct$id_sito),
         c("degree", "betweenness_norm", "rank_betweenness", "rank_degree", "in_giant")],
      n_cell = vcount(g), row.names = NULL, stringsAsFactors = FALSE)
  }
}
hydro <- do.call(rbind, rows)
hydro_upl <- do.call(rbind, upl)
write.csv(hydro,     table_path("hydro_sensitivity.csv"),   row.names = FALSE)
write.csv(hydro_upl, table_path("hydro_upland_centres.csv"), row.names = FALSE)
print(hydro[, c("network", "penalty", "n_edges", "n_isolates", "n_components",
                "giant_pct", "top1_share", "gini", "freeman_centralization",
                "top_node", "top10_overlap_vs_base", "spearman_betweenness_vs_base")],
      digits = 3)

# ---------------------------------------------------------------------------
# 4. QC map and source documentation
# ---------------------------------------------------------------------------
p_riv <- ggplot() +
  geom_sf(data = sf::st_sf(geometry = riv_union), fill = "#3B6E8F", colour = "#3B6E8F",
          linewidth = 0.2) +
  geom_sf(data = sites_all, size = 0.6, colour = "grey20") +
  geom_sf(data = sites_all[in_poly | on_cell, ], size = 1.8, shape = 21,
          colour = "red", fill = NA) +
  labs(title = "QC — river polygons used for the crossing penalty",
       subtitle = sprintf("%s: %d polygons, %.1f km²; %d river cells; red = sites inside a polygon / on a river cell (%d)",
                          riv_info$file, riv_info$n, riv_info$area_km2_union,
                          riv_info$n_cells, nrow(sites_in_rivers))) +
  theme_minimal(base_size = 8)
ggsave(image_path("qc", "hydro_rivers_selected.png"), p_riv, width = 8, height = 8, dpi = 150)

name_tab <- if ("NAME" %in% names(riv)) {
  d <- data.frame(name = riv$NAME, km2 = as.numeric(sf::st_area(riv)) / 1e6) %>%
    dplyr::group_by(name) %>%
    dplyr::summarise(n = dplyr::n(), km2 = sum(km2), .groups = "drop") %>%
    dplyr::arrange(dplyr::desc(km2))
  c("| NAME | poligoni | km² |", "|---|---|---|",
    sprintf("| %s | %d | %.2f |", d$name, d$n, d$km2))
} else "Il layer non ha un campo NAME."
site_tab <- if (nrow(sites_in_rivers)) c(
  "| sito | località | dentro un poligono | su cella fluviale | rete ellenistica | rete romana | penalità sulla cella |",
  "|---|---|---|---|---|---|---|",
  sprintf("| %s | %s | %s | %s | %s | %s | %s |", sites_in_rivers$id_sito,
          sites_in_rivers$localita,
          ifelse(sites_in_rivers$inside_polygon, "sì", "no"),
          ifelse(sites_in_rivers$on_river_cell, "sì", "no"),
          ifelse(sites_in_rivers$in_hellenistic_network, "sì", "no"),
          ifelse(sites_in_rivers$in_roman_network, "sì", "no"),
          ifelse(sites_in_rivers$on_river_cell,
                 paste0("×", paste(HYDRO_PENALTIES, collapse = " / ×"), " in ingresso"), "nessuna"))
) else "Nessun sito cade dentro un poligono fluviale o su una cella fluviale."

src <- c(
  "# Fonte del layer idrografico",
  "",
  sprintf("Generato da `R/12_hydrographic_sensitivity.R` il %s.", Sys.Date()),
  "",
  "## Layer",
  "",
  sprintf("- File: `data/%s` (layer `%s`), poligoni delle aree dei corsi dei fiumi principali, prodotto dall'autore. Sostituisce le linee OSM con buffer di 25 m del Task 9.",
          riv_info$file, riv_info$layer),
  sprintf("- Elementi: %d; geometria: %s; campi: %s.", riv_info$n, riv_info$types, riv_info$fields),
  sprintf("- CRS: EPSG:%s%s.", riv_info$epsg_in,
          if (riv_info$reprojected) sprintf(" — riproiettato in EPSG:%d", CRS_UTM) else " (nessuna riproiezione)"),
  sprintf("- Area totale: %.2f km².", riv_info$area_km2_in),
  sprintf("- Validità (`sf::st_is_valid`): %d elementi invalidi su %d%s.", riv_info$n_invalid, riv_info$n,
          if (riv_info$n_invalid > 0) sprintf("; corretti con `st_make_valid()`, area totale %.4f → %.4f km² (%+.4f)",
                                              riv_info$area_km2_in, riv_info$area_km2_valid,
                                              riv_info$area_km2_valid - riv_info$area_km2_in) else ""),
  sprintf("- Sovrapposizioni: %d coppie di poligoni sovrapposti; i poligoni sono uniti (`st_union`) prima della rasterizzazione; area dell'unione %.2f km².",
          riv_info$n_overlap_pairs, riv_info$area_km2_union),
  "",
  "## Elementi per nome",
  "",
  name_tab,
  "",
  "## Rasterizzazione e trattamento",
  "",
  "- Griglia del DEM (stessa estensione, risoluzione e allineamento). Una cella è fluviale se il suo centro cade dentro un poligono (`terra::rasterize` predefinito, senza `touches = TRUE`).",
  sprintf("- Celle fluviali: %d (%.1f km²)%s. Task 9 (linee OSM + buffer 25 m, `touches = TRUE`): %d celle (%.1f km²).",
          riv_info$n_cells, riv_info$n_cells * cell_km2,
          if (riv_info$n_cells_nodata > 0) sprintf("; altre %d celle dentro i poligoni sono NoData nel DEM e restano non attraversabili", riv_info$n_cells_nodata) else "",
          HYDRO_TASK9_CELLS, HYDRO_TASK9_CELLS * cell_km2),
  sprintf("- Penalità di attraversamento: costo di ingresso in una cella fluviale × %s (colonne della matrice di conduttanza divise per il fattore). Nessuna barriera assoluta, nessuna cella NoData aggiunta.",
          paste(HYDRO_PENALTIES, collapse = " e ×")),
  "- Nessun sito viene spostato: la pipeline si ferma se un sito cade su NoData.",
  "",
  "## Siti dentro i poligoni fluviali (da dichiarare in Methods)",
  "",
  "Posizioni dalla geometria di `data/sites.gpkg`. Per un sito su cella fluviale la penalità si applica ai passi che entrano nella sua cella, non a quelli che ne escono.",
  "",
  site_tab,
  "",
  "## File non più usati",
  "",
  "- `data/hydro/osm_rivers_raw.json`, `data/hydro/rivers_main.gpkg` (Task 9, linee OSM): non letti da nessuno script.",
  "- `waterbodies.gpkg` nella radice del progetto: non letto da nessuno script."
)
writeLines(src, table_path("hydro_source.md"), useBytes = TRUE)
message("Saved hydro_sensitivity.csv, hydro_upland_centres.csv, hydro_sites_in_rivers.csv, hydro_source.md")
