# =============================================================================
# tests/rerun_diff_report.R — previous run vs current run, manuscript quantities
#
# Computes every quantity cited in the manuscript with the SAME code on two
# sets of pipeline outputs and writes output/tables/rerun_diff_report.md:
#   previous = archive/pre_task10_2026-10-05/{rds,tables}  (first submission
#              + Task 9; unseeded cost surfaces; DUR103 snapped by the code
#              and unresolved in 04)
#   current  = output/{rds,tables}
# For the Roman network a third reference is computed: the previous LCPs with
# DUR103's cell resolved — i.e. the change expected from the DUR103 fix alone,
# before any effect of the regenerated (seeded) cost surfaces.
#
# Not part of run_all.R. Usage (project root):
#   Rscript tests/rerun_diff_report.R
# =============================================================================

library(here)
suppressMessages(source(here("R", "00_setup.R")))

PREV <- here("archive", "pre_task10_2026-10-05")
CUR  <- Sys.getenv("RERUN_CUR", here("output"))      # override only for testing
OUT  <- Sys.getenv("RERUN_OUT", here("output", "tables", "rerun_diff_report.md"))
DUR103 <- "DUR103"

dirs <- list(prev = list(rds = file.path(PREV, "rds"), tab = file.path(PREV, "tables")),
             cur  = list(rds = file.path(CUR,  "rds"), tab = file.path(CUR,  "tables")))

sites_attr <- sf::st_drop_geometry(sf::st_read(data_path("sites.gpkg"), quiet = TRUE)) %>%
  dplyr::mutate(def_sito = iconv(def_sito, "latin1", "UTF-8", sub = "?"),
                tipo_sito = iconv(tipo_sito, "latin1", "UTF-8", sub = "?"))

fmt <- function(x) {
  if (is.null(x) || length(x) == 0) return("—")
  if (is.character(x) || is.logical(x) || is.factor(x)) return(as.character(x))
  ifelse(is.na(x), "NA", ifelse(abs(x - round(x)) < 1e-9 & abs(x) < 1e7,
                                formatC(x, format = "d", big.mark = ""),
                                formatC(x, format = "g", digits = 5)))
}
same <- function(a, b) {
  if (is.numeric(a) && is.numeric(b)) isTRUE(all.equal(a, b, tolerance = 1e-9))
  else identical(as.character(a), as.character(b))
}
# one row of a comparison table
qrow <- function(section, quantity, prev, cur, expected = NULL)
  data.frame(section = section, quantity = quantity, prev = fmt(prev), cur = fmt(cur),
             # informative rows ("—" before) count as changed only if something is listed
             changed = if (identical(fmt(prev), "—")) !fmt(cur) %in% c("nessuno", "—")
                       else !same(prev, cur),
             expected = if (is.null(expected)) "" else fmt(expected),
             as_expected = if (is.null(expected)) NA else same(expected, cur),
             stringsAsFactors = FALSE)

# ---------------------------------------------------------------------------
# Quantities from one set of outputs
# ---------------------------------------------------------------------------
net_quantities <- function(g, label) {
  comp <- composition_row(g, label); conc <- concentration_row(g, label)
  list(
    "nodi" = comp$n_nodes, "archi" = comp$n_edges, "densità" = comp$density,
    "grado mediano (tutti i nodi)" = comp$median_degree,
    "isolati (n)" = comp$n_isolates, "isolati (elenco)" = comp$isolates,
    "componenti" = comp$n_components, "componente gigante (nodi)" = comp$giant_size,
    "componente gigante (%)" = comp$giant_pct,
    "betweenness: quota 1° nodo" = conc$top1_share,
    "betweenness: rapporto 1°/2°" = conc$ratio_1st_2nd,
    "betweenness: quota primi 5" = conc$top5_share,
    "betweenness: Gini" = conc$gini,
    "betweenness: Freeman" = conc$freeman_centralization,
    "betweenness: nodo di testa" = conc$top_node,
    "betweenness: secondo nodo" = conc$second_node)
}

centrality_quantities <- function(cc) {
  h <- cc[cc$phase == "hellenistic", ]; r <- cc[cc$phase == "roman", ]
  h$degree_norm <- h$degree / (nrow(h) - 1); r$degree_norm <- r$degree / (nrow(r) - 1)
  dual <- intersect(h$id_sito, r$id_sito)
  out <- list("siti dual-phase (n)" = length(dual))
  for (m in c("degree", "degree_norm", "harmonic", "betweenness_norm")) {
    mw <- wilcox.test(h[[m]], r[[m]], exact = FALSE)
    ph <- h[match(dual, h$id_sito), m]; pr <- r[match(dual, r$id_sito), m]
    wx <- wilcox.test(ph, pr, paired = TRUE, exact = FALSE)
    sp <- suppressWarnings(cor.test(ph, pr, method = "spearman", exact = FALSE))
    out[[paste(m, "— mediana ellenistica")]] <- median(h[[m]])
    out[[paste(m, "— mediana romana")]]      <- median(r[[m]])
    out[[paste(m, "— Mann-Whitney W")]]      <- unname(mw$statistic)
    out[[paste(m, "— Mann-Whitney p")]]      <- mw$p.value
    out[[paste(m, "— dual: mediana ellenistica")]] <- median(ph)
    out[[paste(m, "— dual: mediana romana")]]      <- median(pr)
    out[[paste(m, "— dual: Wilcoxon appaiato V")]] <- unname(wx$statistic)
    out[[paste(m, "— dual: Wilcoxon appaiato p")]] <- wx$p.value
    out[[paste(m, "— dual: Spearman rho")]]        <- unname(sp$estimate)
    out[[paste(m, "— dual: Spearman p")]]          <- sp$p.value
  }
  # spatial dispersion of the top ten nodes by betweenness
  for (ph in c("hellenistic", "roman")) {
    d <- cc[cc$phase == ph, ]
    t10 <- d[order(-d$betweenness_norm, d$id_sito), ][1:10, ]
    out[[paste("primi 10 per betweenness,", ph, "— elenco")]] <- paste(t10$id_sito, collapse = ";")
    out[[paste("primi 10 per betweenness,", ph, "— dev. std. X (m)")]] <- sd(t10$X)
    out[[paste("primi 10 per betweenness,", ph, "— estensione Y (m)")]] <- diff(range(t10$Y))
  }
  # Kruskal-Wallis by typology
  for (ph in c("roman", "hellenistic")) {
    d <- merge(cc[cc$phase == ph, ], sites_attr[, c("id_sito", "tipo_sito", "def_sito")], by = "id_sito")
    for (v in c("tipo_sito", "def_sito")) {
      kw <- kruskal.test(d$betweenness_norm, factor(d[[v]]))
      lab <- sprintf("Kruskal-Wallis betweenness ~ %s, %s", v, ph)
      out[[paste(lab, "— categorie")]] <- length(unique(d[[v]]))
      out[[paste(lab, "— chi²")]] <- unname(kw$statistic)
      out[[paste(lab, "— p")]] <- kw$p.value
    }
  }
  out
}

community_quantities <- function(d) {
  giant <- readRDS(file.path(d$rds, "giant.rds")); cl <- readRDS(file.path(d$rds, "cl_leiden.rds"))
  mem <- igraph::membership(cl)
  nm <- read.csv(file.path(d$tab, "null_model_results.csv"))
  list("componente gigante (nodi)" = igraph::vcount(giant),
       "componente gigante (archi)" = igraph::ecount(giant),
       "moduli (n)" = length(unique(mem)),
       "modularità" = igraph::modularity(giant, mem),
       "dimensioni dei moduli (ordinate)" = paste(sort(as.integer(table(mem)), decreasing = TRUE), collapse = ","),
       "null 1 (degree-preserving): media" = nm$null_mean[1], "null 1: p" = nm$p_value[1],
       "null 2 (spaziale): media" = nm$null_mean[2], "null 2: n validi" = nm$null_n_valid[2],
       "null 2: p" = nm$p_value[2])
}

# DUR103 degree at each sweep threshold, from the unfiltered Roman edges
dur103_sweep <- function(edges, nodes) {
  id <- nodes$id[nodes$id_sito == DUR103]
  resolved <- any(edges$from == id | edges$to == id, na.rm = TRUE)
  sapply(SENSITIVITY_SEQ, function(t) {
    if (!resolved) return("isolato (archi non risolti in 04)")
    k <- sum((edges$from == id | edges$to == id) & edges$cost_mean < t, na.rm = TRUE)
    if (k == 0) "isolato" else paste0("grado ", k)
  })
}

compare_lists <- function(section, a, b, expected = NULL) {
  keys <- union(names(a), names(b))
  do.call(rbind, lapply(keys, function(k)
    qrow(section, k, a[[k]], b[[k]], if (!is.null(expected)) expected[[k]] else NULL)))
}

# Generic cell-by-cell comparison of two CSV tables
compare_csv <- function(file, key = NULL, cols = NULL, section = file) {
  fa <- file.path(dirs$prev$tab, file); fb <- file.path(dirs$cur$tab, file)
  if (!file.exists(fa) || !file.exists(fb))
    return(qrow(section, "file", if (file.exists(fa)) "presente" else "assente",
                if (file.exists(fb)) "presente" else "assente"))
  a <- read.csv(fa, stringsAsFactors = FALSE); b <- read.csv(fb, stringsAsFactors = FALSE)
  ka <- if (is.null(key)) as.character(seq_len(nrow(a))) else do.call(paste, c(a[key], sep = " | "))
  kb <- if (is.null(key)) as.character(seq_len(nrow(b))) else do.call(paste, c(b[key], sep = " | "))
  cs <- if (is.null(cols)) setdiff(union(names(a), names(b)), key) else cols
  rows <- list()
  for (k in union(ka, kb)) for (cn in cs) {
    va <- if (k %in% ka && cn %in% names(a)) a[[cn]][match(k, ka)] else NULL
    vb <- if (k %in% kb && cn %in% names(b)) b[[cn]][match(k, kb)] else NULL
    rows[[length(rows) + 1]] <- qrow(section, paste0(if (is.null(key)) paste("riga", k) else k, " — ", cn), va, vb)
  }
  do.call(rbind, rows)
}

# ---------------------------------------------------------------------------
# Load both states
# ---------------------------------------------------------------------------
load_state <- function(d) list(
  net_hell = readRDS(file.path(d$rds, "net_hell.rds")),
  net_rom  = readRDS(file.path(d$rds, "net_rom.rds")),
  edges_hell = readRDS(file.path(d$rds, "edges_hell.rds")),
  edges_rom  = readRDS(file.path(d$rds, "edges_rom.rds")),
  nodes_hell = readRDS(file.path(d$rds, "nodes_hell.rds")),
  nodes_rom  = readRDS(file.path(d$rds, "nodes_rom.rds")),
  siti_hell  = readRDS(file.path(d$rds, "siti_hell.rds")),
  siti_rom   = readRDS(file.path(d$rds, "siti_rom.rds")),
  cc = read.csv(file.path(d$tab, "centrality_comparison.csv"), stringsAsFactors = FALSE))
P <- load_state(dirs$prev); C <- load_state(dirs$cur)

# Previous Roman network with DUR103 resolved (expected effect of the fix alone)
exp_rw <- local({
  lcp <- sf::st_drop_geometry(sf::st_read(file.path(dirs$prev$rds, "lcp_roman.gpkg"), quiet = TRUE))
  dem <- terra::rast(data_path("dem.tif"))
  cells <- data.frame(id = seq_len(nrow(P$siti_rom)),
                      cell = terra::cellFromXY(dem, sf::st_coordinates(P$siti_rom)))
  orphan <- setdiff(unique(lcp$fromCell), cells$cell)
  stopifnot(length(orphan) == 1)
  cells <- rbind(cells, data.frame(id = which(P$siti_rom$id_sito == DUR103), cell = orphan))
  lcp$from <- cells$id[match(lcp$fromCell, cells$cell)]
  lcp$to   <- cells$id[match(lcp$toCell,   cells$cell)]
  build_cell_network(lcp, P$nodes_rom, ROM_THRESH)
})

# ---------------------------------------------------------------------------
# Sections
# ---------------------------------------------------------------------------
S <- list()

# 0. inputs
moved <- local({
  a <- rbind(P$siti_hell[, "id_sito"], P$siti_rom[, "id_sito"]); a <- a[!duplicated(a$id_sito), ]
  b <- rbind(C$siti_hell[, "id_sito"], C$siti_rom[, "id_sito"]); b <- b[!duplicated(b$id_sito), ]
  d <- as.numeric(sf::st_distance(a, b[match(a$id_sito, b$id_sito), ], by_element = TRUE))
  data.frame(id_sito = a$id_sito, moved_m = d)[d > 0.01, ]
})
S$inputs <- rbind(
  qrow("Dati di ingresso", "siti ellenistici (n)", nrow(P$siti_hell), nrow(C$siti_hell)),
  qrow("Dati di ingresso", "siti romani (n)", nrow(P$siti_rom), nrow(C$siti_rom)),
  qrow("Dati di ingresso", "stessi siti ellenistici", TRUE, setequal(P$siti_hell$id_sito, C$siti_hell$id_sito)),
  qrow("Dati di ingresso", "stessi siti romani", TRUE, setequal(P$siti_rom$id_sito, C$siti_rom$id_sito)),
  qrow("Dati di ingresso", "siti con coordinate cambiate", "—",
       if (nrow(moved)) paste(sprintf("%s (%.0f m)", moved$id_sito, moved$moved_m), collapse = "; ") else "nessuno"))

# 1. pairwise costs and edge flips
cost_cmp <- function(ea, eb, na, nb, thr, label) {
  key <- function(e, n) paste(pmin(n$id_sito[match(e$from, n$id)], n$id_sito[match(e$to, n$id)]),
                              pmax(n$id_sito[match(e$from, n$id)], n$id_sito[match(e$to, n$id)]))
  ea <- ea[!is.na(ea$from) & !is.na(ea$to), ]
  a <- data.frame(key = key(ea, na), prev = ea$cost_mean); b <- data.frame(key = key(eb, nb), cur = eb$cost_mean)
  m <- merge(a, b, by = "key"); rel <- (m$cur - m$prev) / m$prev
  gained <- m$key[m$prev >= thr & m$cur < thr]; lost <- m$key[m$prev < thr & m$cur >= thr]
  near <- abs(m$prev - thr) / thr
  list(rows = rbind(
    qrow(label, "coppie confrontabili (n)", nrow(m), nrow(m)),
    qrow(label, "costo: variazione relativa mediana (%)", 0, 100 * median(rel)),
    qrow(label, "costo: |variazione relativa| mediana (%)", 0, 100 * median(abs(rel))),
    qrow(label, "costo: |variazione relativa| massima (%)", 0, 100 * max(abs(rel))),
    qrow(label, sprintf("archi sotto soglia (%d min) fra le coppie confrontabili", thr), sum(m$prev < thr), sum(m$cur < thr)),
    qrow(label, "archi guadagnati (coppie)", "—", if (length(gained)) paste(gained, collapse = "; ") else "nessuno"),
    qrow(label, "archi persi (coppie)", "—", if (length(lost)) paste(lost, collapse = "; ") else "nessuno"),
    qrow(label, "distanza relativa dalla soglia delle coppie che cambiano stato: massimo (%)", "—",
         if (length(c(gained, lost))) 100 * max(near[m$key %in% c(gained, lost)]) else "—")),
    gained = gained, lost = lost)
}
cost_ht <- cost_cmp(P$edges_hell, C$edges_hell, P$nodes_hell, C$nodes_hell, HELL_THRESH,
                    "Costi a coppie e archi — H-T (Tobler)")
cost_rw <- cost_cmp(P$edges_rom, C$edges_rom, P$nodes_rom, C$nodes_rom, ROM_THRESH,
                    "Costi a coppie e archi — R-W (ruota; coppie senza DUR103, non risolto nella run precedente)")
S$costs <- rbind(cost_ht$rows, cost_rw$rows)

# 2. composition + concentration
S$ht <- compare_lists("Rete ellenistica H-T", net_quantities(P$net_hell, "H-T"), net_quantities(C$net_hell, "H-T"))
S$rw <- compare_lists("Rete romana R-W", net_quantities(P$net_rom, "R-W"), net_quantities(C$net_rom, "R-W"),
                      expected = net_quantities(exp_rw$net, "R-W"))

# 3. centralities, tests, dispersion, Kruskal-Wallis
S$cent <- compare_lists("Centralità, test, dispersione spaziale, Kruskal-Wallis",
                        centrality_quantities(P$cc), centrality_quantities(C$cc))

# 4. community detection and null models
S$comm <- compare_lists("Community detection e null model (gigante romana)",
                        community_quantities(dirs$prev), community_quantities(dirs$cur))
S$comm_type <- compare_csv("community_by_sitetype.csv", key = "module",
                           section = "community_by_sitetype.csv")

# 5. threshold sweep (Roman) + DUR103 state
sw_a <- read.csv(file.path(dirs$prev$tab, "threshold_sweep_roman.csv"))
sw_b <- read.csv(file.path(dirs$cur$tab,  "threshold_sweep_roman.csv"))
sw_e <- do.call(rbind, lapply(SENSITIVITY_SEQ, function(t) {
  g <- igraph::graph_from_data_frame(exp_rw$edges[exp_rw$edges$cost_mean < t, ], vertices = P$nodes_rom, directed = FALSE)
  cmp <- igraph::components(g)
  data.frame(threshold = t, n_edges = igraph::ecount(g), n_isolates = sum(igraph::degree(g) == 0),
             pct_isolates = mean(igraph::degree(g) == 0), mean_degree = mean(igraph::degree(g)),
             n_components = cmp$no, giant_size = max(cmp$csize),
             giant_fraction = max(cmp$csize) / igraph::vcount(g))
}))
d103 <- list(prev = dur103_sweep(P$edges_rom, P$nodes_rom), cur = dur103_sweep(C$edges_rom, C$nodes_rom),
             exp = dur103_sweep(exp_rw$edges, P$nodes_rom))
S$sweep <- do.call(rbind, lapply(seq_along(SENSITIVITY_SEQ), function(i) {
  t <- SENSITIVITY_SEQ[i]
  rbind(do.call(rbind, lapply(setdiff(names(sw_a), "threshold"), function(cn)
    qrow("threshold_sweep_roman.csv", sprintf("%d min — %s", t, cn),
         sw_a[[cn]][sw_a$threshold == t], sw_b[[cn]][sw_b$threshold == t], sw_e[[cn]][sw_e$threshold == t]))),
    qrow("threshold_sweep_roman.csv", sprintf("%d min — stato di %s", t, DUR103),
         d103$prev[i], d103$cur[i], d103$exp[i]))
}))

# 6. remaining tables, cell by cell
S$conc_sweep <- compare_csv("betweenness_concentration_sweep.csv", key = c("phase", "threshold"))
S$egn <- rbind(
  compare_csv("egnatia_pdi_final.csv", key = c("segment", "cost_function")),
  compare_csv("egnatia_validation_segments.csv", key = c("cost_function", "segment")),
  compare_csv("egnatia_validation_full.csv", key = c("cost_function", "segment")),
  compare_csv("egnatia_corridor_containment.csv", key = c("segment", "cost_quantile")),
  compare_csv("egnatia_pdi_comparison_bug.csv", key = c("segment", "cost_function")))
S$disc <- rbind(
  compare_csv("q1_post146_hellenistic.csv", key = "id_sito"),
  compare_csv("q3_top10_betweenness_hellenistic.csv", cols = c("id_sito", "betweenness_norm", "degree", "post_146")),
  compare_csv("q4_post146_distance_egnatia.csv", key = "id_sito", cols = "dist_egnatia_m"),
  compare_csv("q5_upland_centres_dates.csv", key = "id_sito"),
  compare_csv("q6_stations_dates.csv", key = "id_sito"),
  compare_csv("q7_late_antique_horizon.csv", key = "id_sito",
              cols = c("in_roman_end300", "degree", "betweenness_norm", "rank_betweenness", "isolate", "late_antique_only")),
  compare_csv("road_stations_check.csv", key = "id_sito",
              cols = c("betweenness_norm", "degree", "harmonic", "median_mansio", "median_minor_settlement")),
  compare_csv("station_modules.csv", key = "id_sito", cols = c("module", "n_members", "betweenness_norm", "degree")),
  compare_csv("station_network_roles.csv", key = "id_sito",
              cols = c("module", "n_members_module", "degree", "n_neighbours", "n_intra", "n_inter",
                       "n_not_in_giant", "prop_inter", "inter_modules", "role")))
nb <- function(d) { x <- read.csv(file.path(d$tab, "station_neighbors.csv"), stringsAsFactors = FALSE)
  tapply(x$neighbor, x$source, function(v) paste(sort(v), collapse = ";")) }
nb_a <- nb(dirs$prev); nb_b <- nb(dirs$cur)
S$disc <- rbind(S$disc, do.call(rbind, lapply(union(names(nb_a), names(nb_b)), function(k)
  qrow("station_neighbors.csv", paste(k, "— vicini"), nb_a[[k]], nb_b[[k]]))))

S$fact <- rbind(
  compare_csv("factorial_composition.csv", key = "cell",
              cols = c("n_nodes", "n_edges", "density", "median_degree", "n_isolates", "isolates",
                       "n_components", "giant_size", "giant_pct")),
  compare_csv("factorial_concentration.csv", key = "cell",
              cols = c("top1_share", "ratio_1st_2nd", "top5_share", "gini", "freeman_centralization", "top_node")),
  compare_csv("factorial_upland_centres.csv", key = c("cell", "row_type", "id_sito"),
              cols = c("present", "degree", "betweenness_norm", "rank_betweenness", "in_giant",
                       "btw_max", "btw_max_site", "degree_median")),
  compare_csv("factorial_tests.csv", key = c("comparison", "test", "metric"),
              cols = c("statistic", "p_value", "value_a", "value_b")))

# 7. hydrography: OSM lines (Task 9) vs polygon layer
S$hydro <- rbind(
  compare_csv("hydro_sensitivity.csv", key = c("network", "penalty"),
              cols = c("n_edges", "edges_lost_vs_base", "n_isolates", "isolates", "n_components", "giant_pct",
                       "top1_share", "gini", "freeman_centralization", "top_node",
                       "top10_overlap_vs_base", "spearman_betweenness_vs_base"),
              section = "Sensibilità idrografica: layer OSM vs layer poligonale — hydro_sensitivity.csv"),
  compare_csv("hydro_upland_centres.csv", key = c("network", "penalty", "id_sito"),
              cols = c("degree", "betweenness_norm", "rank_betweenness", "in_giant"),
              section = "Sensibilità idrografica: layer OSM vs layer poligonale — hydro_upland_centres.csv"))

# ---------------------------------------------------------------------------
# Expected changes stated in the Task 10 brief
# ---------------------------------------------------------------------------
gq <- function(g) { cr <- composition_row(g, ""); c(cr$n_edges, cr$n_isolates, cr$n_components, cr$giant_size) }
net_rt_cur <- readRDS(file.path(dirs$cur$rds, "net_rt.rds"))
brief <- data.frame(
  rete = c(rep("R-W", 4), rep("R-T", 4)),
  quantita = rep(c("archi", "isolati", "componenti", "componente gigante (nodi)"), 2),
  atteso_dalla_consegna = c(350, 5, 13, 66, 1554, 0, 1, 94),
  precedente_con_DUR103_risolto = c(gq(exp_rw$net), rep(NA, 4)),
  nuovo = c(gq(C$net_rom), gq(net_rt_cur)))
brief$conforme <- brief$atteso_dalla_consegna == brief$nuovo
ht_identical <- identical(sort(igraph::as_ids(igraph::E(P$net_hell))), sort(igraph::as_ids(igraph::E(C$net_hell))))
giant_same <- local({
  a <- readRDS(file.path(dirs$prev$rds, "giant.rds")); b <- readRDS(file.path(dirs$cur$rds, "giant.rds"))
  ek <- function(g) { e <- igraph::as_data_frame(g, "edges")
    ia <- igraph::V(g)$id_sito[match(e$from, igraph::V(g)$name)]; ib <- igraph::V(g)$id_sito[match(e$to, igraph::V(g)$name)]
    sort(paste(pmin(ia, ib), pmax(ia, ib))) }
  c(nodes = setequal(igraph::V(a)$id_sito, igraph::V(b)$id_sito), edges = identical(ek(a), ek(b)))
})

# ---------------------------------------------------------------------------
# Write report
# ---------------------------------------------------------------------------
all_rows <- do.call(rbind, S)
md_table <- function(d, with_expected = FALSE) {
  yn <- function(x) ifelse(is.na(x), "", ifelse(x, "sì", "no"))
  esc <- function(x) gsub("|", "\\|", x, fixed = TRUE)
  if (with_expected)
    c("| quantità | precedente | atteso (precedente + DUR103 risolto) | nuovo | variato | come atteso |",
      "|---|---|---|---|---|---|",
      sprintf("| %s | %s | %s | %s | %s | %s |", esc(d$quantity), esc(d$prev), esc(d$expected), esc(d$cur),
              yn(d$changed), yn(d$as_expected)))
  else
    c("| quantità | precedente | nuovo | variato |", "|---|---|---|---|",
      sprintf("| %s | %s | %s | %s |", esc(d$quantity), esc(d$prev), esc(d$cur), yn(d$changed)))
}
section_md <- function(d, title = NULL) {
  out <- character(0)
  for (s in unique(d$section)) {
    x <- d[d$section == s, ]
    out <- c(out, sprintf("### %s", s), "",
             sprintf("%d valori, %d variati.", nrow(x), sum(x$changed)), "",
             md_table(x, with_expected = any(x$expected != "")), "")
  }
  out
}
summary_tab <- do.call(rbind, lapply(unique(all_rows$section), function(s) {
  x <- all_rows[all_rows$section == s, ]
  data.frame(s = s, n = nrow(x), ch = sum(x$changed))
}))
reg_log <- if (file.exists(file.path(dirs$cur$tab, "regression_log.txt")))
  readLines(file.path(dirs$cur$tab, "regression_log.txt")) else "(regression_log.txt non trovato)"

md <- c(
  "# Rapporto di confronto — run completa (Task 10)",
  "",
  sprintf("Generato da `tests/rerun_diff_report.R` il %s.", Sys.Date()),
  "",
  "- **precedente**: `archive/pre_task10_2026-10-05/` (prima sottomissione + Task 9: superfici di costo senza seed, DUR103 spostato dal codice e non risolto in `04`).",
  sprintf("- **nuovo**: `output/`, da `run_all.R` eseguito per intero in una sessione R nuova (`00`–`13`), con superfici di costo rigenerate (`DEM_ERROR_SEED = %s`), coordinate dei siti dal dato sorgente e nessuno spostamento automatico.", DEM_ERROR_SEED),
  "- I valori sono calcolati con lo stesso codice sui due insiemi di output. \"variato\" = differenza oltre una tolleranza relativa di 1e-9.",
  "",
  "## Due cause di variazione",
  "",
  "1. **DUR103** recupera i propri archi (nessuno spostamento, celle risolte in `04`). L'effetto atteso di questa sola correzione è nella colonna \"atteso\" delle tabelle della rete romana (rete precedente con DUR103 risolto).",
  "2. **Superfici di costo rigenerate con seed** (decisione dell'autore, Task 10): l'errore casuale del DEM è una nuova estrazione, quindi tutti i costi a coppie cambiano di poco e le coppie vicine alla soglia possono cambiare stato. Questo effetto non era fra i cambiamenti attesi della consegna; è quantificato nella sezione \"Costi a coppie e archi\".",
  "",
  "## Cambiamenti attesi dalla consegna",
  "",
  "| rete | quantità | atteso dalla consegna | precedente con DUR103 risolto | nuovo | conforme |",
  "|---|---|---|---|---|---|",
  sprintf("| %s | %s | %s | %s | %s | %s |", brief$rete, brief$quantita, brief$atteso_dalla_consegna,
          ifelse(is.na(brief$precedente_con_DUR103_risolto), "—", brief$precedente_con_DUR103_risolto),
          brief$nuovo, ifelse(brief$conforme, "sì", "**no**")),
  "",
  sprintf("- Rete ellenistica H-T: insieme degli archi %s rispetto alla run precedente.",
          if (ht_identical) "**identico**" else "**cambiato**"),
  sprintf("- Componente gigante di R-W: stessi nodi %s; stessi archi %s.",
          ifelse(giant_same[["nodes"]], "sì", "**no**"), ifelse(giant_same[["edges"]], "sì", "**no**")),
  "",
  "## Riepilogo per sezione",
  "",
  "| sezione | valori | variati |", "|---|---|---|",
  sprintf("| %s | %d | %d |", gsub("|", "\\|", summary_tab$s, fixed = TRUE), summary_tab$n, summary_tab$ch),
  "",
  "## Differenze registrate dalla pipeline (`regression_log.txt`)",
  "",
  if (length(reg_log)) paste("-", reg_log) else "Nessuna.",
  "",
  "## Dati di ingresso e costi", "", section_md(rbind(S$inputs, S$costs)),
  "## Composizione e concentrazione delle reti", "", section_md(rbind(S$ht, S$rw)),
  "## Centralità per fase, test, dispersione spaziale, Kruskal-Wallis", "", section_md(S$cent),
  "## Community detection e null model", "", section_md(rbind(S$comm, S$comm_type)),
  "## Sweep di soglia", "", section_md(rbind(S$sweep, S$conc_sweep)),
  "## Via Egnatia", "", section_md(S$egn),
  "## Tabelle di `10_discussion_checks.R`", "", section_md(S$disc),
  "## Tabelle di `11` (disegno fattoriale)", "", section_md(S$fact),
  "## Sensibilità idrografica: layer OSM vs layer poligonale", "",
  "Gli output di `12` cambiano per costruzione (layer idrografico nuovo, oltre alle superfici rigenerate): non sono valori inattesi. \"precedente\" = Task 9, linee OSM con buffer di 25 m (42.825 celle); \"nuovo\" = poligoni di `data/river polygon.gpkg` (vedi `hydro_source.md`).", "",
  section_md(S$hydro)
)
writeLines(md, OUT, useBytes = TRUE)
saveRDS(all_rows, file.path(tempdir(), "rerun_diff_rows.rds"))
message("Saved ", OUT, " — ", nrow(all_rows), " values, ", sum(all_rows$changed), " changed")
