# =============================================================================
# 13_size_horizon_sensitivity.R — Is the lower Roman betweenness concentration
#   an effect of network size or of the late-antique horizon?
#
# Two checks on the constant-function comparisons of 11 (H-T vs R-T,
# H-W vs R-W):
#   2a  Roman network restricted to the sites that pass the 25-year criterion
#       with the window 31 BC – AD 300 (ROM_END_ALT) → R300-T, R300-W
#   2b  Size: 999 random subsets of n_hell (71) sites from each Roman network
#       (R-T, R-W, R300-T, R300-W); position of the Hellenistic value within
#       the subsample distribution
#
# NO NEW LCPs. An edge exists between two sites when their pairwise travel
# cost (mean of the two directions) is below a fixed threshold; neither the
# cost (single-source shortest path on the cost surface) nor the threshold
# depends on which other sites are in the set. A network restricted to a
# subset of sites is therefore exactly the induced subgraph of the full
# network. This is verified below (blocking) before anything is computed.
#
# ROM_END itself is not changed: ROM_END_ALT = 300 is a counterfactual.
#
# Input:  output/rds/net_hell.rds, net_rom.rds        (H-T, R-W; 04)
#         output/rds/net_hw.rds, net_rt.rds           (H-W, R-T; 11)
#         output/rds/edges_{hell,rom,hw,rt}.rds, nodes_{hell,rom}.rds
#         data/sites.gpkg
# Output: output/tables/sens_rom300_composition.csv
#         output/tables/sens_rom300_concentration.csv
#         output/tables/sens_rom300_tests.csv
#         output/tables/sens_rom300_upland_centres.csv
#         output/tables/sens_subsample_distributions.csv
#         output/tables/sens_summary.md
# =============================================================================

UPLAND_IDS_S <- c("DUR032", "DUR053", "DUR015", "DUR025")   # Dorez, Mliku,
                                                            # Zgerdesh, Shenlliu
SENS_MEASURES <- c(top1_share = "quota 1° nodo", gini = "Gini",
                   freeman_centralization = "Freeman",
                   median_betweenness = "betweenness mediana")

nodes_hell <- readRDS(rds_path("nodes_hell.rds"))
nodes_rom  <- readRDS(rds_path("nodes_rom.rds"))
with_centrality <- function(g) induced_site_network(g, V(g)$id_sito)
nets <- list("H-T" = with_centrality(readRDS(rds_path("net_hell.rds"))),
             "H-W" = readRDS(rds_path("net_hw.rds")),
             "R-T" = readRDS(rds_path("net_rt.rds")),
             "R-W" = with_centrality(readRDS(rds_path("net_rom.rds"))))
hell_ids <- nodes_hell$id_sito
rom_ids  <- nodes_rom$id_sito
dual_ids <- intersect(hell_ids, rom_ids)
n_hell   <- length(hell_ids)

# ---------------------------------------------------------------------------
# Preliminary verification (BLOCKING): edges do not depend on the site set
# ---------------------------------------------------------------------------
# (1) Construction: collapse_directional_edges() averages the two directions
#     of each pair; the filter is cost_mean < a constant from 00_setup.R.
#     No normalisation of costs and no relative threshold anywhere in
#     04_networks.r / build_cell_network().
# (2) Empirical: the same pairs computed within two different site sets on the
#     same surface have identical costs, and the Hellenistic and Roman
#     networks restricted to the dual-phase sites are the same graph.
pair_tab <- function(edges, nodes) {
  a <- nodes$id_sito[match(edges$from, nodes$id)]
  b <- nodes$id_sito[match(edges$to,   nodes$id)]
  d <- data.frame(key = paste(pmin(a, b), pmax(a, b)), cost_mean = edges$cost_mean,
                  stringsAsFactors = FALSE)
  d[a %in% dual_ids & b %in% dual_ids, ]
}
edge_keys <- function(g) {
  e <- igraph::as_data_frame(g, "edges")
  a <- V(g)$id_sito[match(e$from, V(g)$name)]; b <- V(g)$id_sito[match(e$to, V(g)$name)]
  sort(paste(pmin(a, b), pmax(a, b)))
}
indep <- do.call(rbind, lapply(list(
  list(fn = "tobler",  h = "edges_hell.rds", r = "edges_rt.rds",  gh = "H-T", gr = "R-T"),
  list(fn = "wheeled", h = "edges_hw.rds",   r = "edges_rom.rds", gh = "H-W", gr = "R-W")),
  function(x) {
    m <- merge(pair_tab(readRDS(rds_path(x$h)), nodes_hell),
               pair_tab(readRDS(rds_path(x$r)), nodes_rom), by = "key")
    data.frame(cost_function = x$fn, n_dual_pairs = nrow(m),
               n_expected = choose(length(dual_ids), 2),
               max_abs_cost_diff_min = max(abs(m$cost_mean.x - m$cost_mean.y)),
               same_induced_graph = identical(
                 edge_keys(induced_site_network(nets[[x$gh]], dual_ids)),
                 edge_keys(induced_site_network(nets[[x$gr]], dual_ids))))
  }))
print(indep)
if (any(indep$n_dual_pairs != indep$n_expected) ||
    any(indep$max_abs_cost_diff_min > 1e-9) || !all(indep$same_induced_graph))
  stop("Edge construction depends on the site set: induced subgraphs are not ",
       "valid restricted networks. Stopping (Task 10, Step 2 preliminary check).")
message("[13] Preliminary check passed: pairwise costs and edges are independent of the site set.")

# ---------------------------------------------------------------------------
# 2a — Roman network with ROM_END_ALT
# ---------------------------------------------------------------------------
sites_d <- sf::st_drop_geometry(sf::st_read(data_path("sites.gpkg"), quiet = TRUE))
in_rom_alt <- vapply(seq_len(nrow(sites_d)), function(i)
  isTRUE(site_in_window(as.list(sites_d[i, ]), CHRONO_DICT, "id_sito", ROM_BOUND, ROM_END_ALT)),
  logical(1))
in_rom_std <- vapply(seq_len(nrow(sites_d)), function(i)
  isTRUE(site_in_window(as.list(sites_d[i, ]), CHRONO_DICT, "id_sito", ROM_BOUND, ROM_END)),
  logical(1))
stopifnot("chronology must reproduce the Roman site set" =
            setequal(sites_d$id_sito[in_rom_std], rom_ids))
rom300_ids <- intersect(rom_ids, sites_d$id_sito[in_rom_alt])
dropped    <- setdiff(rom_ids, rom300_ids)
dual300    <- intersect(dual_ids, rom300_ids)
message(sprintf("[13] R300: %d sites (%d Roman - %d late-antique-only); dual-phase with Hellenistic: %d",
                length(rom300_ids), length(rom_ids), length(dropped), length(dual300)))

nets[["R300-T"]] <- induced_site_network(nets[["R-T"]], rom300_ids)
nets[["R300-W"]] <- induced_site_network(nets[["R-W"]], rom300_ids)
net_meta <- data.frame(
  network  = names(nets),
  site_set = c("hellenistic", "hellenistic", "roman (ROM_END 450)", "roman (ROM_END 450)",
               "roman (ROM_END 300)", "roman (ROM_END 300)"),
  cost_fn  = c(COST_FN_HELL, COST_FN_ROM, COST_FN_HELL, COST_FN_ROM, COST_FN_HELL, COST_FN_ROM),
  threshold = c(HELL_THRESH, ROM_THRESH, HELL_THRESH, ROM_THRESH, HELL_THRESH, ROM_THRESH),
  stringsAsFactors = FALSE)

composition <- do.call(rbind, lapply(names(nets), function(k) composition_row(nets[[k]], k)))
names(composition)[1] <- "network"
composition <- merge(net_meta, composition, by = "network", sort = FALSE)
write.csv(composition, table_path("sens_rom300_composition.csv"), row.names = FALSE)

conc_full <- function(g, k) {
  r <- concentration_row(g, k); names(r)[1] <- "network"
  r$median_betweenness <- median(igraph::betweenness(g, normalized = TRUE))
  r
}
concentration <- do.call(rbind, lapply(names(nets), function(k) conc_full(nets[[k]], k)))
concentration <- merge(net_meta, concentration, by = "network", sort = FALSE)
write.csv(concentration, table_path("sens_rom300_concentration.csv"), row.names = FALSE)

cent <- do.call(rbind, lapply(names(nets), function(k) centrality_table(nets[[k]], k)))
names(cent)[1] <- "network"

upland <- do.call(rbind, lapply(names(nets), function(k) {
  ct <- cent[cent$network == k, ]
  r  <- ct[match(UPLAND_IDS_S, ct$id_sito), ]
  data.frame(network = k, id_sito = UPLAND_IDS_S,
             localita = sites_d$localita[match(UPLAND_IDS_S, sites_d$id_sito)],
             present = UPLAND_IDS_S %in% ct$id_sito,
             degree = r$degree, betweenness_norm = r$betweenness_norm,
             rank_betweenness = r$rank_betweenness, rank_degree = r$rank_degree,
             n_network = vcount(nets[[k]]),
             pct_rank_betweenness = r$rank_betweenness / vcount(nets[[k]]),
             in_giant = r$in_giant, row.names = NULL, stringsAsFactors = FALSE)
}))
write.csv(upland, table_path("sens_rom300_upland_centres.csv"), row.names = FALSE)

# Tests: same as 11 (Mann-Whitney on all sites; paired Wilcoxon and Spearman
# on the dual-phase sites present in both networks)
METRICS <- c("degree_norm", "harmonic", "betweenness_norm")
test_pair <- function(a, b, pair_ids) {
  A <- cent[cent$network == a, ]; B <- cent[cent$network == b, ]
  rows <- list()
  add <- function(test, metric, stat_name, stat, p, va = NA, vb = NA, n_pairs = NA)
    rows[[length(rows) + 1]] <<- data.frame(
      comparison = paste(a, "vs", b), network_a = a, network_b = b, test = test,
      metric = metric, statistic_name = stat_name, statistic = unname(stat),
      p_value = unname(p), n_a = nrow(A), n_b = nrow(B), n_pairs = n_pairs,
      value_a = unname(va), value_b = unname(vb), stringsAsFactors = FALSE)
  for (m in METRICS) {
    mw <- wilcox.test(A[[m]], B[[m]], exact = FALSE)
    add("mann_whitney", m, "W", mw$statistic, mw$p.value, median(A[[m]]), median(B[[m]]))
    pa <- A[match(pair_ids, A$id_sito), m]; pb <- B[match(pair_ids, B$id_sito), m]
    wx <- wilcox.test(pa, pb, paired = TRUE, exact = FALSE)
    add("wilcoxon_paired_dual", m, "V", wx$statistic, wx$p.value, median(pa), median(pb), length(pair_ids))
    sp <- suppressWarnings(cor.test(pa, pb, method = "spearman", exact = FALSE))
    add("spearman_dual", m, "rho", sp$estimate, sp$p.value, n_pairs = length(pair_ids))
  }
  ca <- concentration[concentration$network == a, ]; cb <- concentration[concentration$network == b, ]
  for (m in c("top1_share", "ratio_1st_2nd", "top5_share", "gini", "freeman_centralization"))
    add("concentration_difference", m, "b_minus_a", cb[[m]] - ca[[m]], NA, ca[[m]], cb[[m]])
  do.call(rbind, rows)
}
tests <- rbind(
  test_pair("H-T", "R300-T", dual300),
  test_pair("H-W", "R300-W", dual300),
  test_pair("H-T", "R-T", dual_ids),      # reference: full Roman network (as in 11)
  test_pair("H-W", "R-W", dual_ids))
write.csv(tests, table_path("sens_rom300_tests.csv"), row.names = FALSE)

# ---------------------------------------------------------------------------
# 2b — Size control: random subsets of n_hell sites
# ---------------------------------------------------------------------------
subsample_measures <- function(g, size, n, seed) {
  set.seed(seed)
  ids <- V(g)$id_sito
  t(vapply(seq_len(n), function(i) {
    sub <- igraph::induced_subgraph(g, which(ids %in% sample(ids, size)))
    b   <- igraph::betweenness(sub, normalized = TRUE)
    c(top1_share = if (sum(b) > 0) max(b) / sum(b) else NA_real_,
      gini = gini(b),
      freeman_centralization =
        igraph::centr_betw(sub, directed = FALSE, normalized = TRUE)$centralization,
      median_betweenness = median(b))
  }, numeric(4)))
}
full_measures <- function(k) unlist(concentration[concentration$network == k, names(SENS_MEASURES)])

sub_spec <- data.frame(network = c("R-T", "R-W", "R300-T", "R300-W"),
                       hell    = c("H-T", "H-W", "H-T", "H-W"), stringsAsFactors = FALSE)
subsample <- do.call(rbind, lapply(seq_len(nrow(sub_spec)), function(i) {
  k <- sub_spec$network[i]; h <- sub_spec$hell[i]; g <- nets[[k]]
  if (vcount(g) <= n_hell) {
    message("[13] ", k, ": ", vcount(g), " sites <= ", n_hell, " — no subsampling")
    return(data.frame(network = k, hellenistic_network = h, measure = names(SENS_MEASURES),
                      n_sites_network = vcount(g), subsample_size = NA, n_subsamples = 0,
                      n_valid = 0, full_network_value = full_measures(k),
                      sub_median = NA, sub_q025 = NA, sub_q975 = NA,
                      hellenistic_value = full_measures(h), hellenistic_percentile = NA,
                      hellenistic_outside_95 = NA, row.names = NULL, stringsAsFactors = FALSE))
  }
  # same seed for every network: R-T and R-W (same vertex order) get the same
  # 999 site subsets, as do R300-T and R300-W
  S  <- subsample_measures(g, n_hell, SUBSAMPLE_N, SUBSAMPLE_SEED)
  hv <- full_measures(h)
  do.call(rbind, lapply(names(SENS_MEASURES), function(m) {
    x <- S[, m]; x <- x[!is.na(x)]
    q <- quantile(x, c(0.025, 0.5, 0.975), names = FALSE)
    data.frame(network = k, hellenistic_network = h, measure = m,
               n_sites_network = vcount(g), subsample_size = n_hell,
               n_subsamples = SUBSAMPLE_N, n_valid = length(x),
               full_network_value = full_measures(k)[[m]],
               sub_median = q[2], sub_q025 = q[1], sub_q975 = q[3],
               hellenistic_value = hv[[m]],
               hellenistic_percentile = 100 * mean(x <= hv[[m]]),
               hellenistic_outside_95 = hv[[m]] < q[1] | hv[[m]] > q[3],
               stringsAsFactors = FALSE)
  }))
}))
write.csv(subsample, table_path("sens_subsample_distributions.csv"), row.names = FALSE)

# ---------------------------------------------------------------------------
# 2c — Reading (numbers only)
# ---------------------------------------------------------------------------
cv <- function(k, m) concentration[[m]][concentration$network == k]
f3 <- function(x) ifelse(is.na(x), "NA", formatC(x, format = "f", digits = 3))
f4 <- function(x) ifelse(is.na(x), "NA", formatC(x, format = "f", digits = 4))
CONC3 <- c("top1_share", "gini", "freeman_centralization")

lower <- sapply(CONC3, function(m) c(T = cv("R300-T", m) < cv("H-T", m),
                                     W = cv("R300-W", m) < cv("H-W", m)))
q1_answer <- if (all(lower)) "**Sì**" else if (!any(lower)) "**No**" else "**Parzialmente**"
q1_lines <- sapply(CONC3, function(m) sprintf(
  "| %s | %s | %s | %s | %s | %s | %s | %s | %s |", SENS_MEASURES[[m]],
  f3(cv("H-T", m)), f3(cv("R300-T", m)), ifelse(lower["T", m], "sì", "no"), f3(cv("R-T", m)),
  f3(cv("H-W", m)), f3(cv("R300-W", m)), ifelse(lower["W", m], "sì", "no"), f3(cv("R-W", m))))

sub_main <- subsample[subsample$network %in% c("R-T", "R-W"), ]
q2_answer <- if (all(sub_main$hellenistic_outside_95)) "**Sì**" else
             if (!any(sub_main$hellenistic_outside_95)) "**No**" else "**Parzialmente**"
sub_lines <- function(d) sprintf(
  "| %s | %s | %d | %s | %s | %s – %s | %s (%s) | %.1f | %s |",
  d$network, SENS_MEASURES[d$measure], d$n_sites_network, f4(d$full_network_value),
  f4(d$sub_median), f4(d$sub_q025), f4(d$sub_q975), f4(d$hellenistic_value),
  d$hellenistic_network, d$hellenistic_percentile,
  ifelse(is.na(d$hellenistic_outside_95), "n/d", ifelse(d$hellenistic_outside_95, "sì", "no")))
sub_head <- c("| rete | misura | n siti | valore rete intera | mediana sottocampioni | 2,5 % – 97,5 % | valore ellenistico | percentile | fuori dall'intervallo |",
              "|---|---|---|---|---|---|---|---|---|")
tq <- function(a, b, test, m) tests[tests$network_a == a & tests$network_b == b &
                                    tests$test == test & tests$metric == m, ]
test_lines <- unlist(lapply(METRICS, function(m) sapply(
  list(c("H-T", "R300-T"), c("H-W", "R300-W")), function(p) {
    mw <- tq(p[1], p[2], "mann_whitney", m); wx <- tq(p[1], p[2], "wilcoxon_paired_dual", m)
    sp <- tq(p[1], p[2], "spearman_dual", m)
    sprintf("| %s | %s vs %s | %s → %s | %s | %s → %s | %s | %s (p=%s) |", m, p[1], p[2],
            f4(mw$value_a), f4(mw$value_b), format.pval(mw$p_value, digits = 2),
            f4(wx$value_a), f4(wx$value_b), format.pval(wx$p_value, digits = 2),
            f3(sp$statistic), format.pval(sp$p_value, digits = 2))
  })))
up_lines <- sapply(UPLAND_IDS_S, function(sid) {
  g <- function(k) { r <- upland[upland$network == k & upland$id_sito == sid, ]
    if (!r$present) "assente" else sprintf("%d/%d (%s)", r$rank_betweenness, r$n_network, f4(r$betweenness_norm)) }
  sprintf("| %s | %s | %s | %s | %s | %s | %s |", sid, g("H-T"), g("R300-T"), g("R-T"),
          g("H-W"), g("R300-W"), g("R-W"))
})
comp_lines <- apply(composition, 1, function(r) sprintf(
  "| %s | %s | %s | %s | %s | %s | %s | %s |", r[["network"]], trimws(r[["n_nodes"]]),
  trimws(r[["n_edges"]]), f3(as.numeric(r[["density"]])), trimws(r[["median_degree"]]),
  trimws(r[["n_isolates"]]), trimws(r[["n_components"]]),
  sprintf("%s (%.1f %%)", trimws(r[["giant_size"]]), as.numeric(r[["giant_pct"]]))))

md <- c(
  "# Task 10 — Sensibilità a dimensione e orizzonte tardoantico",
  "",
  sprintf("Generato da `R/13_size_horizon_sensitivity.R` il %s. Solo numeri, nessuna interpretazione.", Sys.Date()),
  "",
  "## Verifica preliminare",
  "",
  sprintf("Nessun passaggio della costruzione degli archi dipende dall'insieme dei siti (media delle due direzioni per coppia, soglia assoluta). Controllo empirico sulle coppie fra i %d siti dual-phase: %s. Tutte le reti ristrette sono quindi sottografi indotti; nessun LCP ricalcolato.",
          length(dual_ids),
          paste(sprintf("%s — %d coppie, scarto massimo di costo %.2g min, sottografo indotto identico: %s",
                        indep$cost_function, indep$n_dual_pairs, indep$max_abs_cost_diff_min,
                        ifelse(indep$same_induced_graph, "sì", "no")), collapse = "; ")),
  "",
  "## Rete romana con ROM_END = 300",
  "",
  sprintf("Siti che superano il criterio dei %d anni con la finestra %d/%d: **%d** (= %d − %d). Siti dual-phase presenti anche nella rete ellenistica: %d (su %d).",
          MIN_OVERLAP_YEARS, ROM_BOUND, ROM_END_ALT, length(rom300_ids), length(rom_ids),
          length(dropped), length(dual300), length(dual_ids)),
  "",
  sprintf("Siti esclusi: %s.", paste(sort(dropped), collapse = ", ")),
  "",
  "| rete | nodi | archi | densità | grado mediano | isolati | componenti | gigante |",
  "|---|---|---|---|---|---|---|---|",
  comp_lines,
  "",
  "## 1. La concentrazione della betweenness resta più bassa nella rete romana di quella ellenistica, a funzione costante, quando la rete romana è ristretta a ROM_END = 300?",
  "",
  paste0(q1_answer, "."),
  "",
  "| misura | H-T | R300-T | più bassa (T) | R-T (rif.) | H-W | R300-W | più bassa (W) | R-W (rif.) |",
  "|---|---|---|---|---|---|---|---|---|",
  q1_lines,
  "",
  sprintf("Nodo di testa: H-T %s, R300-T %s, R-T %s; H-W %s, R300-W %s, R-W %s.",
          cv("H-T", "top_node"), cv("R300-T", "top_node"), cv("R-T", "top_node"),
          cv("H-W", "top_node"), cv("R300-W", "top_node"), cv("R-W", "top_node")),
  "",
  sprintf("Test sulle centralità per sito (Mann-Whitney su tutti i siti; Wilcoxon appaiato e Spearman sui %d dual-phase presenti in entrambe le reti):", length(dual300)),
  "",
  "| metrica | confronto | mediane (tutti) | p MW | mediane (dual) | p Wilcoxon | ρ Spearman (dual) |",
  "|---|---|---|---|---|---|---|",
  test_lines,
  "",
  "Centri d'altura — rank di betweenness / n (betweenness normalizzata):",
  "",
  "| sito | H-T | R300-T | R-T | H-W | R300-W | R-W |",
  "|---|---|---|---|---|---|---|",
  up_lines,
  "",
  sprintf("## 2. Il valore ellenistico cade fuori dall'intervallo 2,5–97,5 %% dei sottocampioni romani di %d siti, per ciascuna misura e ciascuna funzione?", n_hell),
  "",
  paste0(q2_answer, sprintf(" (R-T e R-W: %d misure su %d fuori dall'intervallo).",
                            sum(sub_main$hellenistic_outside_95), nrow(sub_main))),
  "",
  sprintf("%d sottoinsiemi casuali di %d siti per rete, seed %d (stessi sottoinsiemi per le due funzioni). Percentile = quota di sottocampioni con valore ≤ quello ellenistico.",
          SUBSAMPLE_N, n_hell, SUBSAMPLE_SEED),
  "",
  sub_head,
  sub_lines(sub_main),
  "",
  sprintf("Stesso sottocampionamento sulle reti ristrette a ROM_END = 300. Attenzione: con %d siti i sottoinsiemi di %d sono al più %s distinti (%s), quindi la distribuzione misura solo l'effetto di togliere %d sito/i e l'intervallo è per costruzione stretto.",
          length(rom300_ids), n_hell,
          format(choose(length(rom300_ids), n_hell), big.mark = ".", scientific = FALSE),
          if (length(rom300_ids) - n_hell == 1) "leave-one-out" else "pochi siti rimossi",
          length(rom300_ids) - n_hell),
  "",
  sub_head,
  sub_lines(subsample[subsample$network %in% c("R300-T", "R300-W"), ])
)
writeLines(md, table_path("sens_summary.md"), useBytes = TRUE)
message("Saved sens_rom300_*.csv, sens_subsample_distributions.csv, sens_summary.md")
