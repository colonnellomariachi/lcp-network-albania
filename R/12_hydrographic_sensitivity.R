# =============================================================================
# 12_hydrographic_sensitivity.R — River-crossing penalty sensitivity
#
# Reviewer 1 asks how watercourses affect the networks. No hydrographic layer
# was kept in the project (the earlier mask was removed and its source is not
# recoverable); with the author's authorisation an OpenStreetMap snapshot of
# waterway=river was downloaded (data/hydro/osm_rivers_raw.json; source,
# query and selection in output/tables/hydro_source.md).
#
# Rivers are NOT absolute barriers (no data on fords/bridges): the cost of
# entering a river cell is multiplied by each factor in HYDRO_PENALTIES
# (×5 moderate, ×20 strong). Implemented by dividing the columns of the
# conductance matrix (moves INTO river cells) by the factor. Everything else —
# surfaces, snapping, site sets, thresholds, network construction — is the
# published pipeline (lcp_helpers.R, network_helpers.R).
#
# Networks: H-T and R-W (published, priority) and, if listed in HYDRO_CELLS,
# H-W and R-T (factorial cells from 11). Each is compared with its
# unpenalised counterpart.
#
# Input:  data/hydro/osm_rivers_raw.json, data/dem.tif
#         output/rds/cost_surface_{hell,rom}.rds, siti_*.rds, nodes_*.rds
#         output/rds/lcp_hell.gpkg, lcp_roman.gpkg (unpenalised H-T, R-W)
#         output/rds/lcp_hell_wheeled.gpkg, lcp_rom_tobler.gpkg (from 11)
# Output: data/hydro/rivers_main.gpkg
#         output/rds/lcp_hydro_{ht,rw,hw,rt}_x{5,20}.gpkg   [SLOW ~25 min each]
#         output/rds/net_hydro_{ht,rw,hw,rt}_x{5,20}.rds
#         output/tables/hydro_sensitivity.csv
#         output/tables/hydro_upland_centres.csv
#         output/tables/hydro_source.md
#         output/images/qc/hydro_rivers_selected.png
# =============================================================================

HYDRO_CELLS <- c("H-T", "R-W", "H-W", "R-T")   # priority order
UPLAND_IDS_H <- c("DUR032", "DUR053", "DUR015", "DUR025", "DUR003")
TOP_N_OVERLAP <- 10

hydro_dir <- data_path("hydro")
osm_json  <- file.path(hydro_dir, "osm_rivers_raw.json")
if (!file.exists(osm_json))
  stop("Missing ", osm_json, " — see output/tables/hydro_source.md for the query.")

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
# 1. River layer: OSM snapshot → selected main rivers → raster cells
# ---------------------------------------------------------------------------
osm <- jsonlite::fromJSON(osm_json, simplifyVector = FALSE)
tag <- function(e, k) if (!is.null(e$tags[[k]])) e$tags[[k]] else NA_character_
rivers_all <- sf::st_sf(
  osm_id   = vapply(osm$elements, function(e) as.character(e$id), ""),
  name     = vapply(osm$elements, tag, "", "name"),
  wikidata = vapply(osm$elements, tag, "", "wikidata"),
  geometry = sf::st_sfc(lapply(osm$elements, function(e)
    sf::st_linestring(do.call(rbind, lapply(e$geometry, function(p) c(p$lon, p$lat))))),
    crs = 4326)) %>%
  sf::st_transform(CRS_UTM)

dem <- terra::rast(data_path("dem.tif"))
rivers_all <- suppressWarnings(sf::st_intersection(rivers_all, sf::st_as_sfc(sf::st_bbox(dem))))
rivers_all$length_km <- as.numeric(sf::st_length(rivers_all)) / 1000
rivers_all$included  <- !is.na(rivers_all$name) & rivers_all$name %in% HYDRO_RIVER_NAMES
stopifnot("every HYDRO_RIVER_NAMES entry must exist in the snapshot" =
            all(HYDRO_RIVER_NAMES %in% rivers_all$name))

rivers <- rivers_all[rivers_all$included, ]
sf::st_write(rivers, file.path(hydro_dir, "rivers_main.gpkg"), delete_dsn = TRUE, quiet = TRUE)

river_r <- terra::rasterize(terra::vect(sf::st_buffer(rivers, HYDRO_BUFFER_M)),
                            dem, field = 1, touches = TRUE, background = NA)
river_cells <- which(!is.na(terra::values(river_r, mat = FALSE)) &
                     !is.na(terra::values(dem, mat = FALSE)))
message("River cells: ", length(river_cells), " (",
        round(length(river_cells) * prod(terra::res(dem)) / 1e6, 1), " km²)")

# Sites falling in a river cell (their outgoing moves are not penalised)
sites_all <- sf::st_read(data_path("sites.gpkg"), quiet = TRUE) %>%
  sf::st_drop_geometry() %>%
  dplyr::filter(!is.na(jx), !is.na(Sy)) %>%
  sf::st_as_sf(coords = c("jx", "Sy"), crs = CRS_UTM)
site_in_river <- sites_all$id_sito[terra::cellFromXY(dem, sf::st_coordinates(sites_all)) %in% river_cells]

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
origin_cells <- function(x) sort(unique(x$fromCell))

rows <- list(); upl <- list()
for (i in seq_len(nrow(cell_spec))) {
  sp <- cell_spec[i, ]
  base_raw <- sf::st_read(rds_path(sp$base_gpkg), quiet = TRUE)
  base <- build_cell_network(resolve_lcp_site_ids(base_raw, siti[[sp$site_set]], cs_meta),
                             nodes[[sp$site_set]], sp$threshold)$net
  b0 <- igraph::betweenness(base, normalized = TRUE)
  top0 <- head(V(base)$id_sito[order(-b0, V(base)$id_sito)], TOP_N_OVERLAP)

  for (k in c(1, HYDRO_PENALTIES)) {
    if (k == 1) { g <- base; dur103_same <- TRUE } else {
      raw <- sf::st_read(hydro_gpkg(sp$tag, k), quiet = TRUE)
      # Same site positions as the unpenalised run (only DUR103 snapped,
      # to the same pixel)
      dur103_same <- identical(origin_cells(raw), origin_cells(base_raw))
      stopifnot("origin cells must match the unpenalised run" = dur103_same)
      g <- build_cell_network(resolve_lcp_site_ids(raw, siti[[sp$site_set]], cs_meta),
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
        origin_cells_as_base = dur103_same,
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
  geom_sf(data = rivers_all[!rivers_all$included, ], colour = "grey75", linewidth = 0.3) +
  geom_sf(data = rivers, aes(colour = name), linewidth = 0.7) +
  geom_sf(data = sites_all, size = 0.6, colour = "grey20") +
  labs(title = "QC — OSM rivers: selected (colour) vs excluded (grey)", colour = NULL) +
  theme_minimal(base_size = 8)
ggsave(image_path("qc", "hydro_rivers_selected.png"), p_riv, width = 8, height = 8, dpi = 150)

inc <- rivers_all %>% sf::st_drop_geometry() %>%
  dplyr::group_by(name = ifelse(is.na(name), "(senza nome)", name), included) %>%
  dplyr::summarise(n_ways = dplyr::n(), km = round(sum(length_km), 1),
                   wikidata = paste(unique(na.omit(wikidata)), collapse = ","),
                   .groups = "drop") %>%
  dplyr::arrange(dplyr::desc(included), dplyr::desc(km))
md_tab <- function(d) c("| nome | way OSM | km nell'area | wikidata |", "|---|---|---|---|",
                        sprintf("| %s | %d | %.1f | %s |", d$name, d$n_ways, d$km, d$wikidata))
src <- c(
  "# Fonte del layer idrografico (Parte 2, Task 9)",
  "",
  sprintf("Generato da `R/12_hydrographic_sensitivity.R` il %s.", Sys.Date()),
  "",
  "## Fonte",
  "",
  "- **OpenStreetMap**, elementi `waterway=river` (way), © OpenStreetMap contributors, licenza ODbL 1.0.",
  sprintf("- Snapshot del database OSM: %s; scaricato il 2026-10-03 tramite Overpass API (mirror `overpass.private.coffee`; `overpass-api.de` non disponibile per sovraccarico).", osm$osm3s$timestamp_osm_base),
  "- Query: `[out:json][timeout:180];way[\"waterway\"=\"river\"](40.80,19.10,41.80,20.50);out geom tags;`",
  "- File salvato: `data/hydro/osm_rivers_raw.json`; selezione: `data/hydro/rivers_main.gpkg` (EPSG:32634).",
  "- Il layer usato in passato per la maschera non è presente nel progetto e non è stato recuperato. `waterbodies.gpkg` (fornito dall'autore) contiene solo poligoni di laghi e invasi (molti artificiali, XX secolo), senza linee fluviali, e non è stato usato.",
  "- Il tracciato è moderno (alvei canalizzati/rettificati, specie nella piana costiera): va dichiarato come approssimazione dei corsi antichi.",
  "",
  "## Elementi inclusi",
  "",
  "Aste principali di Ishëm, Erzen e Shkumbin e i tre fiumi dalla cui confluenza nasce l'Ishëm (Tërkuzë, Tirana, Zeza). OSM non distingue un rango gerarchico fra i `waterway=river`, quindi la selezione è per nome (`HYDRO_RIVER_NAMES` in `00_setup.R`).",
  "",
  md_tab(inc[inc$included, ]),
  "",
  "## Elementi esclusi (presenti nell'estensione del DEM)",
  "",
  md_tab(inc[!inc$included, ]),
  "",
  "## Trattamento",
  "",
  sprintf("- Linee bufferizzate di %d m e rasterizzate sulla griglia del DEM (25 m, `touches = TRUE`): %d celle fluviali (%.1f km²). Fascia ≥ 2 celle, quindi non scavalcabile con un passo a 16 vicini.",
          HYDRO_BUFFER_M, length(river_cells), length(river_cells) * prod(terra::res(dem)) / 1e6),
  sprintf("- Penalità di attraversamento: costo di ingresso in una cella fluviale × %s (colonne della matrice di conduttanza divise per il fattore). Nessuna barriera assoluta, nessuna cella NoData aggiunta.",
          paste(HYDRO_PENALTIES, collapse = " e ×")),
  sprintf("- Siti che cadono in una cella fluviale: %s.",
          if (length(site_in_river)) paste(sort(site_in_river), collapse = ", ") else "nessuno"),
  "",
  "## DUR103 (Capo Rodon)",
  "",
  sprintf("- La penalità non crea celle NoData, quindi la regola di spostamento è la stessa della pipeline pubblicata: DUR103 cade in una cella NoData (mare, non fiume; distanza dal fiume selezionato più vicino %.0f m) e viene spostato di un pixel (73 m, cella 3143022), come nelle reti senza penalità. Nessun altro sito viene spostato.",
          min(as.numeric(sf::st_distance(sites_all[sites_all$id_sito == "DUR103", ], rivers)))),
  sprintf("- Celle di origine degli LCP penalizzati identiche a quelle della corrispondente rete senza penalità in tutti i casi: %s.",
          if (all(hydro$origin_cells_as_base)) "sì" else "NO"),
  "- Nelle reti romane (output del loop) DUR103 resta isolato per lo stesso artefatto di `04` documentato in `factorial_dur103_sensitivity.csv`; il confronto con la rete senza penalità è quindi omogeneo."
)
writeLines(src, table_path("hydro_source.md"), useBytes = TRUE)
message("Saved hydro_sensitivity.csv, hydro_upland_centres.csv, hydro_source.md")
