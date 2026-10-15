# =============================================================================
# 11_cost_function_factorial.R — 2×2 design: site set × cost function
#
# Reviewer response (JAMT): the published design pairs each phase with its own
# cost function (Hellenistic–Tobler, Roman–wheeled), confounding site
# distribution with mode of transport. This script crosses the two factors:
#
#   cell  sites              cost function        threshold   status
#   H-T   Hellenistic (71)   Tobler               240 min     published
#   R-W   Roman (94)         wheeled transport    150 min     published
#   H-W   Hellenistic (71)   wheeled transport    150 min     new
#   R-T   Roman (94)         Tobler               240 min     new
#
# Each cost function keeps its own threshold on both site sets. All other
# parameters come from 00_setup.R. The two diagonal cells are rebuilt from the
# saved LCPs and must coincide with the objects written by 04/05/04b (Step 1,
# blocking): this guarantees that the new cells are built exactly like the
# pipeline networks. The new cells use run_lcp_set() (lcp_helpers.R) with the
# same output schema as their site set. No site is moved: a site on
# NoData stops the pipeline.
#
# Input:  output/rds/{siti,nodes,net,edges}_{hell,rom}*.rds
#         output/rds/lcp_hell.gpkg, lcp_roman.gpkg
#         output/rds/cost_surface_{hell,rom}.rds
#         output/tables/centrality_comparison.csv
#         output/tables/betweenness_concentration_sweep.csv
# Output: output/rds/lcp_hell_wheeled.gpkg, lcp_rom_tobler.gpkg   [SLOW]
#         output/rds/lcp_hw_processed.rds, lcp_rt_processed.rds
#         output/rds/edges_hw{,_filtered}.rds, edges_rt{,_filtered}.rds
#         output/rds/net_hw.rds, net_rt.rds
#         output/tables/factorial_composition.csv
#         output/tables/factorial_centrality_long.csv
#         output/tables/factorial_concentration.csv
#         output/tables/factorial_threshold_sweep.csv
#         output/tables/factorial_upland_centres.csv
#         output/tables/factorial_persistence.csv
#         output/tables/factorial_tests.csv
#         output/tables/factorial_lcp_consistency.csv
#         output/tables/typology_by_cell.csv, top15_composition_by_cell.csv
#         output/tables/factorial_harmonic_degree.csv, factorial_top10_location.csv
#         output/tables/colocated_sites.csv
#         output/tables/factorial_summary.md
#         output/images/qc/factorial_betweenness_distributions.png
#
# Expected runtime: ~1–3 h when the two new LCP sets are absent; < 1 min
# afterwards (saved LCPs are reused).
# =============================================================================

# ---------------------------------------------------------------------------
# 0. Local constants and helpers
# ---------------------------------------------------------------------------

UPLAND_IDS_F  <- c("DUR032", "DUR053", "DUR015", "DUR025")   # Dorez, Mliku,
                                                              # Zgerdesh, Shenlliu
UPLAND_REF_ID <- "DUR003"                                    # Hamallaj
FORTIFIED_DEF <- "centro fortificato"
TOP_N_OVERLAP <- 10

CELLS <- data.frame(
  cell      = c("H-T", "R-W", "H-W", "R-T"),
  site_set  = c("hellenistic", "roman", "hellenistic", "roman"),
  cost_fn   = c(COST_FN_HELL, COST_FN_ROM, COST_FN_ROM, COST_FN_HELL),
  threshold = c(HELL_THRESH, ROM_THRESH, ROM_THRESH, HELL_THRESH),
  status    = c("published", "published", "new", "new"),
  stringsAsFactors = FALSE
)

dir.create(image_path("qc"), showWarnings = FALSE, recursive = TRUE)

# gini(), build_cell_network(), composition_row(), centrality_table() and
# concentration_row() are in R/functions/network_helpers.R (shared with 12).

# ---------------------------------------------------------------------------
# 1. Inputs
# ---------------------------------------------------------------------------

siti_hell  <- readRDS(rds_path("siti_hell.rds"))
siti_rom   <- readRDS(rds_path("siti_rom.rds"))
nodes_hell <- readRDS(rds_path("nodes_hell.rds"))
nodes_rom  <- readRDS(rds_path("nodes_rom.rds"))
stopifnot(identical(nodes_hell$id_sito, siti_hell$id_sito),
          identical(nodes_rom$id_sito,  siti_rom$id_sito))

dual_ids <- intersect(siti_hell$id_sito, siti_rom$id_sito)
stopifnot("n_dual must be 46" = length(dual_ids) == 46L)

sites_attr <- sf::st_read(data_path("sites.gpkg"), quiet = TRUE) %>%
  sf::st_drop_geometry() %>%
  dplyr::mutate(def_sito = iconv(def_sito, "latin1", "UTF-8", sub = "?")) %>%
  dplyr::select(id_sito, def_sito, localita)

# Cost-surface grid metadata (both surfaces share the DEM grid)
cs_meta <- local({
  cs <- readRDS(rds_path("cost_surface_rom.rds"))
  m  <- cs[c("nrow", "ncol", "extent", "crs")]
  rm(cs); gc(verbose = FALSE); m
})
cs_meta_hell <- local({
  cs <- readRDS(rds_path("cost_surface_hell.rds"))
  m  <- cs[c("nrow", "ncol", "extent", "crs")]
  rm(cs); gc(verbose = FALSE); m
})
stopifnot("Tobler and wheeled surfaces must share the grid" =
            isTRUE(all.equal(cs_meta, cs_meta_hell)))

# ===========================================================================
# STEP 1 — Regression on the diagonal (BLOCKING)
# ===========================================================================
message("\n[11] Step 1 — diagonal regression (H-T, R-W)")

lcp_ht <- resolve_lcp_site_ids(st_read(rds_path("lcp_hell.gpkg"),  quiet = TRUE),
                               siti_hell, cs_meta)
lcp_rw <- resolve_lcp_site_ids(st_read(rds_path("lcp_roman.gpkg"), quiet = TRUE),
                               siti_rom,  cs_meta)

cell_ht <- build_cell_network(lcp_ht, nodes_hell, HELL_THRESH)
cell_rw <- build_cell_network(lcp_rw, nodes_rom,  ROM_THRESH)

# (a) edge tables identical to the 04 objects
edge_key <- function(e) as.data.frame(e[order(e$from, e$to), c("from", "to", "cost_mean", "n_directions")])
reg_edges <- c(
  ht_all      = isTRUE(all.equal(edge_key(cell_ht$edges),
                                 edge_key(readRDS(rds_path("edges_hell.rds"))))),
  ht_filtered = isTRUE(all.equal(edge_key(cell_ht$edges_filtered),
                                 edge_key(readRDS(rds_path("edges_hell_filtered.rds"))))),
  rw_all      = isTRUE(all.equal(edge_key(cell_rw$edges),
                                 edge_key(readRDS(rds_path("edges_rom.rds"))))),
  rw_filtered = isTRUE(all.equal(edge_key(cell_rw$edges_filtered),
                                 edge_key(readRDS(rds_path("edges_rom_filtered.rds")))))
)
# (b) graphs isomorphic-by-name to net_hell / net_rom
same_graph <- function(a, b) {
  ea <- igraph::as_data_frame(a, "edges")[, c("from", "to")]
  eb <- igraph::as_data_frame(b, "edges")[, c("from", "to")]
  k  <- function(e) sort(paste(pmin(as.integer(e$from), as.integer(e$to)),
                               pmax(as.integer(e$from), as.integer(e$to))))
  identical(sort(V(a)$name), sort(V(b)$name)) && identical(k(ea), k(eb))
}
reg_graph <- c(ht = same_graph(cell_ht$net, readRDS(rds_path("net_hell.rds"))),
               rw = same_graph(cell_rw$net, readRDS(rds_path("net_rom.rds"))))

comp_ht <- composition_row(cell_ht$net, "H-T")
comp_rw <- composition_row(cell_rw$net, "R-W")

# (d) per-site centralities vs centrality_comparison.csv
cc <- read.csv(table_path("centrality_comparison.csv"), stringsAsFactors = FALSE)
cc_check <- function(g, phase) {
  ref <- cc[cc$phase == phase, c("id_sito", "degree", "harmonic", "betweenness_norm")]
  new <- data.frame(id_sito = V(g)$id_sito, degree = as.integer(V(g)$degree),
                    harmonic = V(g)$harmonic,
                    betweenness_norm = V(g)$betweenness_norm,
                    stringsAsFactors = FALSE)
  ref <- ref[order(ref$id_sito), ]; new <- new[order(new$id_sito), ]
  rownames(ref) <- rownames(new) <- NULL
  all.equal(ref, new)
}
reg_cc <- c(ht = isTRUE(cc_check(cell_ht$net, "hellenistic")),
            rw = isTRUE(cc_check(cell_rw$net, "roman")))

# (e) concentration vs betweenness_concentration_sweep.csv (04b)
sweep <- read.csv(table_path("betweenness_concentration_sweep.csv"))
conc_ht <- concentration_row(cell_ht$net, "H-T")
conc_rw <- concentration_row(cell_rw$net, "R-W")
sw <- function(ph, t) sweep[sweep$phase == ph & sweep$threshold == t, ]
reg_conc <- c(
  ht = isTRUE(all.equal(unlist(conc_ht[c("top1_share", "ratio_1st_2nd", "top5_share", "gini")]),
                        unlist(sw("hellenistic", HELL_THRESH)[c("top1_share", "ratio_1st_2nd", "top5_share", "gini")]),
                        check.attributes = FALSE)),
  rw = isTRUE(all.equal(unlist(conc_rw[c("top1_share", "ratio_1st_2nd", "top5_share", "gini")]),
                        unlist(sw("roman", ROM_THRESH)[c("top1_share", "ratio_1st_2nd", "top5_share", "gini")]),
                        check.attributes = FALSE))
)

regression <- c(edges = reg_edges, graph = reg_graph,
                centrality = reg_cc, concentration = reg_conc)
print(regression)
if (!all(regression)) {
  print(rbind(comp_ht, comp_rw))
  stop("STEP 1 FAILED — diagonal does not reproduce the 04/05 networks: ",
       paste(names(regression)[!regression], collapse = ", "),
       ". New cells would not be comparable; stopping.")
}
message("Step 1 passed: H-T and R-W coincide with the 04/05 objects (",
        length(regression), " checks).")

# ===========================================================================
# STEP 2 — New cells: H-W and R-T
# ===========================================================================
message("\n[11] Step 2 — new cells (H-W, R-T)")

gpkg_hw <- rds_path("lcp_hell_wheeled.gpkg")
gpkg_rt <- rds_path("lcp_rom_tobler.gpkg")

# [SLOW] computed only if absent. Full recomputation (no reuse of dual-phase
# pairs); same functions and strategy as 03 for each site set.
if (!file.exists(gpkg_hw))
  run_lcp_set(siti_hell, rds_path("cost_surface_rom.rds"),  "fete", gpkg_hw, "H-W")
if (!file.exists(gpkg_rt))
  run_lcp_set(siti_rom,  rds_path("cost_surface_hell.rds"), "loop", gpkg_rt, "R-T")

raw_hw <- st_read(gpkg_hw, quiet = TRUE)
raw_rt <- st_read(gpkg_rt, quiet = TRUE)

lcp_hw <- resolve_lcp_site_ids(raw_hw, siti_hell, cs_meta)
lcp_rt <- resolve_lcp_site_ids(raw_rt, siti_rom,  cs_meta)
stopifnot("H-W must have n*(n-1) paths" = nrow(lcp_hw) == nrow(siti_hell) * (nrow(siti_hell) - 1L),
          "R-T must have n*(n-1) paths" = nrow(lcp_rt) == nrow(siti_rom)  * (nrow(siti_rom)  - 1L))

cell_hw <- build_cell_network(lcp_hw, nodes_hell, ROM_THRESH)
cell_rt <- build_cell_network(lcp_rt, nodes_rom,  HELL_THRESH)

# --- Consistency of LCP parameters -----------------------------------------
# Dual-phase pairs were computed with both functions in the published
# networks. Recomputed costs must match exactly if the new cells used the same
# surfaces, snapping and options: H-W vs R-W (wheeled), R-T vs H-T (Tobler).
pair_costs <- function(edges, nodes) {
  e <- edges[!is.na(edges$from) & !is.na(edges$to), ]
  a <- nodes$id_sito[match(e$from, nodes$id)]
  b <- nodes$id_sito[match(e$to,   nodes$id)]
  data.frame(key = paste(pmin(a, b), pmax(a, b)), cost_mean = e$cost_mean,
             both_dual = a %in% dual_ids & b %in% dual_ids,
             stringsAsFactors = FALSE)
}
consistency_row <- function(new, ref, label) {
  m <- merge(new[new$both_dual, ], ref[ref$both_dual, ], by = "key",
             suffixes = c("_new", "_published"))
  data.frame(comparison = label, n_dual_pairs = nrow(m),
             max_abs_diff_min = max(abs(m$cost_mean_new - m$cost_mean_published)),
             n_identical = sum(m$cost_mean_new == m$cost_mean_published))
}
lcp_consistency <- rbind(
  consistency_row(pair_costs(cell_hw$edges, nodes_hell),
                  pair_costs(cell_rw$edges, nodes_rom), "H-W vs R-W (wheeled)"),
  consistency_row(pair_costs(cell_rt$edges, nodes_rom),
                  pair_costs(cell_ht$edges, nodes_hell), "R-T vs H-T (Tobler)")
)
print(lcp_consistency)
write.csv(lcp_consistency, table_path("factorial_lcp_consistency.csv"), row.names = FALSE)
if (any(lcp_consistency$max_abs_diff_min > 1e-6))
  warning("Recomputed dual-phase LCP costs differ from the published ones — ",
          "check cost surfaces / snapping before using the new cells.")

saveRDS(lcp_hw,                 rds_path("lcp_hw_processed.rds"))
saveRDS(lcp_rt,                 rds_path("lcp_rt_processed.rds"))
saveRDS(cell_hw$edges,          rds_path("edges_hw.rds"))
saveRDS(cell_rt$edges,          rds_path("edges_rt.rds"))
saveRDS(cell_hw$edges_filtered, rds_path("edges_hw_filtered.rds"))
saveRDS(cell_rt$edges_filtered, rds_path("edges_rt_filtered.rds"))
saveRDS(cell_hw$net,            rds_path("net_hw.rds"))
saveRDS(cell_rt$net,            rds_path("net_rt.rds"))

nets <- list("H-T" = cell_ht$net, "R-W" = cell_rw$net,
             "H-W" = cell_hw$net, "R-T" = cell_rt$net)

# ===========================================================================
# STEP 3 — Metrics per cell
# ===========================================================================
message("\n[11] Step 3 — metrics per cell")

# 3.1 Composition
composition <- do.call(rbind, lapply(names(nets), function(k) composition_row(nets[[k]], k)))
composition <- merge(CELLS, composition, by = "cell", sort = FALSE)
write.csv(composition, table_path("factorial_composition.csv"), row.names = FALSE)

# 3.2 Per-site centrality (long)
cent_long <- do.call(rbind, lapply(names(nets), function(k) centrality_table(nets[[k]], k)))
cent_long$dual_phase <- cent_long$id_sito %in% dual_ids
write.csv(cent_long, table_path("factorial_centrality_long.csv"), row.names = FALSE)

# 3.3 Betweenness concentration
concentration <- do.call(rbind, lapply(names(nets), function(k) concentration_row(nets[[k]], k)))
concentration <- merge(CELLS[, c("cell", "site_set", "cost_fn", "threshold")],
                       concentration, by = "cell", sort = FALSE)
write.csv(concentration, table_path("factorial_concentration.csv"), row.names = FALSE)

# 3.3b Threshold sweep of the four cells: the saved pairwise costs
# (collapsed edges, all pairs) filtered at each threshold of CONC_SWEEP_SEQ,
# as in 04b. Same measures as factorial_concentration.csv, plus edges,
# density and the share of nodes with zero betweenness.
cell_edges <- list("H-T" = list(e = cell_ht$edges, n = nodes_hell),
                   "R-W" = list(e = cell_rw$edges, n = nodes_rom),
                   "H-W" = list(e = cell_hw$edges, n = nodes_hell),
                   "R-T" = list(e = cell_rt$edges, n = nodes_rom))
threshold_sweep <- do.call(rbind, lapply(names(cell_edges), function(k)
  do.call(rbind, lapply(CONC_SWEEP_SEQ, function(t) {
    ef <- cell_edges[[k]]$e %>% filter(cost_mean < t)
    if (any(is.na(ef$from) | is.na(ef$to)))
      stop("Unresolved (NA) site IDs survive the threshold filter in ", k)
    g  <- graph_from_data_frame(d = ef, vertices = cell_edges[[k]]$n, directed = FALSE)
    cr <- concentration_row(g, k)
    data.frame(cell = k, site_set = CELLS$site_set[CELLS$cell == k],
               cost_fn = CELLS$cost_fn[CELLS$cell == k], threshold = t,
               n_nodes = vcount(g), n_edges = ecount(g), density = edge_density(g),
               top1_share = cr$top1_share, top5_share = cr$top5_share, gini = cr$gini,
               freeman_centralization = cr$freeman_centralization,
               zero_share = mean(igraph::betweenness(g, normalized = TRUE) == 0),
               top_node = cr$top_node, stringsAsFactors = FALSE)
  }))))

# Consistency (BLOCKING): H-T / R-W rows reproduce 04b at every threshold, and
# each cell at its own threshold reproduces factorial_concentration.csv
sw_cols <- c("n_edges", "density", "top1_share", "top5_share", "gini")
for (k in c("H-T", "R-W")) {
  a <- threshold_sweep[threshold_sweep$cell == k, c("threshold", sw_cols)]
  b <- sweep[sweep$phase == if (k == "H-T") "hellenistic" else "roman", c("threshold", sw_cols)]
  stopifnot("threshold sweep must reproduce betweenness_concentration_sweep.csv" =
              isTRUE(all.equal(a, b, check.attributes = FALSE)))
}
own <- merge(threshold_sweep, CELLS[, c("cell", "threshold")], by = c("cell", "threshold"))
own <- own[match(concentration$cell, own$cell), ]
stopifnot("threshold sweep must reproduce factorial_concentration.csv" =
            isTRUE(all.equal(own[, c("top1_share", "top5_share", "gini", "freeman_centralization")],
                             concentration[, c("top1_share", "top5_share", "gini", "freeman_centralization")],
                             check.attributes = FALSE)))
write.csv(threshold_sweep, table_path("factorial_threshold_sweep.csv"), row.names = FALSE)
message("Saved factorial_threshold_sweep.csv")

# 3.4 Upland centres + fortified-centre category statistics
focus_ids <- c(UPLAND_IDS_F, UPLAND_REF_ID)
upland <- do.call(rbind, lapply(names(nets), function(k) {
  ct  <- cent_long[cent_long$cell == k, ]
  cmp <- igraph::components(nets[[k]])
  do.call(rbind, lapply(focus_ids, function(sid) {
    r <- ct[ct$id_sito == sid, ]
    present <- nrow(r) == 1L
    data.frame(
      cell = k, row_type = "site", id_sito = sid,
      localita = sites_attr$localita[sites_attr$id_sito == sid],
      present  = present,
      degree           = if (present) r$degree           else NA_real_,
      betweenness_norm = if (present) r$betweenness_norm else NA_real_,
      rank_betweenness = if (present) r$rank_betweenness else NA_real_,
      rank_degree      = if (present) r$rank_degree      else NA_real_,
      n_cell           = vcount(nets[[k]]),
      pct_rank_betweenness = if (present) r$rank_betweenness / vcount(nets[[k]]) else NA_real_,
      in_giant         = if (present) r$in_giant         else NA,
      component_size   = if (present)
        cmp$csize[cmp$membership[V(nets[[k]])$id_sito == sid]] else NA_real_,
      n_category = NA_integer_, btw_max = NA_real_, btw_max_site = NA_character_,
      btw_median = NA_real_, degree_median = NA_real_,
      stringsAsFactors = FALSE)
  }))
}))
fortified <- do.call(rbind, lapply(names(nets), function(k) {
  ct <- merge(cent_long[cent_long$cell == k, ], sites_attr, by = "id_sito")
  f  <- ct[!is.na(ct$def_sito) & ct$def_sito == FORTIFIED_DEF, ]
  data.frame(
    cell = k, row_type = "category", id_sito = NA_character_,
    localita = FORTIFIED_DEF, present = NA,
    degree = NA_real_, betweenness_norm = NA_real_, rank_betweenness = NA_real_,
    rank_degree = NA_real_, n_cell = vcount(nets[[k]]),
    pct_rank_betweenness = NA_real_, in_giant = NA, component_size = NA_real_,
    n_category    = nrow(f),
    btw_max       = max(f$betweenness_norm),
    btw_max_site  = f$id_sito[which.max(f$betweenness_norm)],
    btw_median    = median(f$betweenness_norm),
    degree_median = median(f$degree),
    stringsAsFactors = FALSE)
}))
upland_tab <- rbind(upland, fortified)
write.csv(upland_tab, table_path("factorial_upland_centres.csv"), row.names = FALSE)

# 3.5 Decomposition by site persistence: sites present in both phases (dual)
#     vs sites present only in the phase of the cell
persistence <- do.call(rbind, lapply(names(nets), function(k) {
  ct  <- cent_long[cent_long$cell == k, ]
  top <- head(ct$id_sito[order(-ct$betweenness_norm, ct$id_sito)], TOP_N_OVERLAP)
  only_lab <- if (CELLS$site_set[CELLS$cell == k] == "hellenistic") "hellenistic only" else "roman only"
  grp <- list("both phases" = ct$dual_phase, only = !ct$dual_phase, "all sites" = rep(TRUE, nrow(ct)))
  names(grp)[2] <- only_lab
  do.call(rbind, lapply(names(grp), function(g) {
    x <- ct[grp[[g]], ]
    data.frame(cell = k, group = g, n_sites = nrow(x), share_sites = nrow(x) / nrow(ct),
               share_betweenness = sum(x$betweenness_norm) / sum(ct$betweenness_norm),
               median_betweenness = median(x$betweenness_norm),
               median_degree = median(x$degree),
               n_zero_betweenness = sum(x$betweenness_norm == 0),
               share_zero_betweenness = mean(x$betweenness_norm == 0),
               n_in_top10 = sum(x$id_sito %in% top),
               stringsAsFactors = FALSE)
  }))
}))
write.csv(persistence, table_path("factorial_persistence.csv"), row.names = FALSE)

# ===========================================================================
# STEP 4 — Comparisons
# ===========================================================================
message("\n[11] Step 4 — comparisons")

METRICS <- c("degree_norm", "harmonic", "betweenness_norm")
getc <- function(k) cent_long[cent_long$cell == k, ]

test_row <- function(type, a, b, test, metric, stat_name, stat, p, n_a, n_b,
                     n_pairs = NA, est_a = NA, est_b = NA, note = NA) {
  data.frame(comparison_type = type, comparison = paste(a, "vs", b),
             cell_a = a, cell_b = b, test = test, metric = metric,
             statistic_name = stat_name, statistic = unname(stat),
             p_value = unname(p), n_a = n_a, n_b = n_b, n_pairs = n_pairs,
             value_a = unname(est_a), value_b = unname(est_b), note = note,
             stringsAsFactors = FALSE)
}

upland_rank_rows <- function(type, a, b) {
  ua <- upland[upland$cell == a, ]; ub <- upland[upland$cell == b, ]
  do.call(rbind, lapply(focus_ids, function(sid) {
    ra <- ua[ua$id_sito == sid, ]; rb <- ub[ub$id_sito == sid, ]
    test_row(type, a, b, "upland_rank_change", sid, "delta_rank_betweenness",
             rb$rank_betweenness - ra$rank_betweenness, NA,
             ra$n_cell, rb$n_cell, NA, ra$rank_betweenness, rb$rank_betweenness,
             note = sprintf("pct_rank %.3f -> %.3f; degree %s -> %s",
                            ra$pct_rank_betweenness, rb$pct_rank_betweenness,
                            ra$degree, rb$degree))
  }))
}

concentration_diff_rows <- function(type, a, b) {
  ca <- concentration[concentration$cell == a, ]
  cb <- concentration[concentration$cell == b, ]
  do.call(rbind, lapply(c("top1_share", "gini", "freeman_centralization",
                          "top5_share", "ratio_1st_2nd"), function(m)
    test_row(type, a, b, "concentration_difference", m, "b_minus_a",
             cb[[m]] - ca[[m]], NA, NA, NA, NA, ca[[m]], cb[[m]],
             note = paste("top node", ca$top_node, "->", cb$top_node))))
}

diachronic <- function(a, b) {   # a = Hellenistic cell, b = Roman cell
  A <- getc(a); B <- getc(b)
  rows <- list()
  for (m in METRICS) {
    mw <- wilcox.test(A[[m]], B[[m]], exact = FALSE)
    rows[[length(rows) + 1]] <- test_row("diachronic", a, b, "mann_whitney", m,
      "W", mw$statistic, mw$p.value, nrow(A), nrow(B), NA,
      median(A[[m]]), median(B[[m]]), "values = medians")
    pa <- A[match(dual_ids, A$id_sito), m]; pb <- B[match(dual_ids, B$id_sito), m]
    wx <- wilcox.test(pa, pb, paired = TRUE, exact = FALSE)
    rows[[length(rows) + 1]] <- test_row("diachronic", a, b, "wilcoxon_paired_dual", m,
      "V", wx$statistic, wx$p.value, length(pa), length(pb), length(dual_ids),
      median(pa), median(pb), "46 dual-phase sites; values = medians")
    sp <- suppressWarnings(cor.test(pa, pb, method = "spearman", exact = FALSE))
    rows[[length(rows) + 1]] <- test_row("diachronic", a, b, "spearman_dual", m,
      "rho", sp$estimate, sp$p.value, length(pa), length(pb), length(dual_ids),
      note = "46 dual-phase sites")
  }
  rbind(do.call(rbind, rows),
        concentration_diff_rows("diachronic", a, b),
        upland_rank_rows("diachronic", a, b))
}

synchronic <- function(a, b) {   # same site set, different cost function
  A <- getc(a); B <- getc(b)
  B <- B[match(A$id_sito, B$id_sito), ]
  rows <- lapply(METRICS, function(m) {
    sp <- suppressWarnings(cor.test(A[[m]], B[[m]], method = "spearman", exact = FALSE))
    test_row("synchronic", a, b, "spearman_same_sites", m, "rho",
             sp$estimate, sp$p.value, nrow(A), nrow(B), nrow(A))
  })
  top_a <- head(A$id_sito[order(-A$betweenness_norm, A$id_sito)], TOP_N_OVERLAP)
  top_b <- head(B$id_sito[order(-B$betweenness_norm, B$id_sito)], TOP_N_OVERLAP)
  common <- intersect(top_a, top_b)
  rows[[length(rows) + 1]] <- test_row("synchronic", a, b, "top10_betweenness_overlap",
    "betweenness_norm", "n_common", length(common), NA, nrow(A), nrow(B),
    note = paste0("common: ", paste(sort(common), collapse = ";"),
                  " | only ", a, ": ", paste(setdiff(top_a, top_b), collapse = ";"),
                  " | only ", b, ": ", paste(setdiff(top_b, top_a), collapse = ";")))
  rbind(do.call(rbind, rows),
        concentration_diff_rows("synchronic", a, b),
        upland_rank_rows("synchronic", a, b))
}

tests <- rbind(
  diachronic("H-T", "R-T"),
  diachronic("H-W", "R-W"),
  diachronic("H-T", "R-W"),            # original diagonal, for reference (Step 5.3)
  synchronic("H-T", "H-W"),
  synchronic("R-T", "R-W")
)
tests$comparison_type[tests$cell_a == "H-T" & tests$cell_b == "R-W"] <- "diagonal_reference"
write.csv(tests, table_path("factorial_tests.csv"), row.names = FALSE)

# ===========================================================================
# STEP 4b — Site typology, harmonic vs degree, top-10 location, co-located
#           sites
# ===========================================================================
message("\n[11] Step 4b — typology, harmonic/degree, top-10 location, co-located sites")

site_lab  <- read_site_labels()
site_xy   <- rbind(data.frame(id_sito = siti_hell$id_sito, sf::st_coordinates(siti_hell)),
                   data.frame(id_sito = siti_rom$id_sito,  sf::st_coordinates(siti_rom)))
site_xy   <- site_xy[!duplicated(site_xy$id_sito), ]
cent_lab  <- merge(merge(cent_long, site_lab, by = "id_sito"), site_xy, by = "id_sito")
stopifnot("every cell node needs labels and coordinates" = nrow(cent_lab) == nrow(cent_long))
top_n_of <- function(ct, n) head(ct[order(-ct$betweenness_norm, ct$id_sito), ], n)

# 4b.1 Betweenness by site category: Kruskal-Wallis + per-category statistics.
# Two levels: tipo_sito (functional category) and def_sito (site definition).
# Sites without a label at the level are excluded (DUR143 has no tipo_sito);
# NA is never a level.
TYPO_LEVELS <- c(tipo_sito = "tipo_en", def_sito = "def_en")
typology <- do.call(rbind, lapply(CELLS$cell, function(k) do.call(rbind, lapply(names(TYPO_LEVELS), function(lv) {
  ct  <- cent_lab[cent_lab$cell == k & !is.na(cent_lab[[lv]]), ]
  grp <- ct[[TYPO_LEVELS[[lv]]]]
  kw  <- kruskal.test(ct$betweenness_norm, factor(grp))
  kw_row <- data.frame(cell = k, level = lv, row_type = "kruskal_wallis",
                       category_en = "(all)", category_orig = "(all)",
                       n_sites = nrow(ct), n_categories = length(unique(grp)),
                       statistic = unname(kw$statistic), df = unname(kw$parameter),
                       p_value = kw$p.value,
                       btw_median = NA_real_, btw_max = NA_real_,
                       btw_max_site = NA_character_, btw_max_toponym = NA_character_,
                       degree_median = NA_real_, stringsAsFactors = FALSE)
  cats <- names(sort(table(grp), decreasing = TRUE))
  cat_rows <- do.call(rbind, lapply(cats, function(cg) {
    d <- ct[grp == cg, ]
    m <- d[order(-d$betweenness_norm, d$id_sito)[1], ]
    data.frame(cell = k, level = lv, row_type = "category",
               category_en = cg, category_orig = d[[lv]][1],
               n_sites = nrow(d), n_categories = NA_integer_,
               statistic = NA_real_, df = NA_real_, p_value = NA_real_,
               btw_median = median(d$betweenness_norm), btw_max = max(d$betweenness_norm),
               btw_max_site = m$id_sito, btw_max_toponym = m$toponym,
               degree_median = median(d$degree), stringsAsFactors = FALSE)
  }))
  rbind(kw_row, cat_rows)
}))))
stopifnot("tipo_sito: four functional categories in every cell" =
            all(typology$n_categories[typology$row_type == "kruskal_wallis" &
                                        typology$level == "tipo_sito"] == 4))
write.csv(typology, table_path("typology_by_cell.csv"), row.names = FALSE)

# 4b.2 Composition of the 15 nodes with the highest betweenness
TOP_N_COMPOSITION <- 15
top15 <- do.call(rbind, lapply(CELLS$cell, function(k) {
  ct  <- cent_lab[cent_lab$cell == k, ]
  top <- top_n_of(ct, TOP_N_COMPOSITION)
  # ties across the cut-off would make the composition depend on id order
  tie <- sum(ct$betweenness_norm == min(top$betweenness_norm)) >
         sum(top$betweenness_norm == min(top$betweenness_norm))
  do.call(rbind, lapply(names(TYPO_LEVELS), function(lv) {
    col  <- TYPO_LEVELS[[lv]]
    cats <- names(sort(table(top[[col]]), decreasing = TRUE))
    data.frame(cell = k, level = lv, category_en = cats,
               n_top15 = as.integer(table(top[[col]])[cats]),
               n_in_cell = vapply(cats, function(cg) sum(ct[[col]] == cg), integer(1)),
               share_top15 = as.integer(table(top[[col]])[cats]) / TOP_N_COMPOSITION,
               top15_sites = vapply(cats, function(cg)
                 paste(top$id_sito[top[[col]] == cg], collapse = ";"), character(1)),
               min_btw_top15 = min(top$betweenness_norm), tie_at_cutoff = tie,
               stringsAsFactors = FALSE, row.names = NULL)
  }))
}))
write.csv(top15, table_path("top15_composition_by_cell.csv"), row.names = FALSE)

# 4b.3 Spearman correlation between degree and harmonic centrality
harm_deg <- do.call(rbind, lapply(CELLS$cell, function(k) {
  ct <- cent_long[cent_long$cell == k, ]
  sp <- suppressWarnings(cor.test(ct$degree, ct$harmonic, method = "spearman", exact = FALSE))
  data.frame(cell = k, n_nodes = nrow(ct), rho_degree_harmonic = unname(sp$estimate),
             p_value = sp$p.value, stringsAsFactors = FALSE)
}))
check_published("Spearman degree-harmonic: 0.995 / 0.994 / 0.970 / 0.961 (H-T / R-T / H-W / R-W)" =
  isTRUE(all.equal(round(harm_deg$rho_degree_harmonic[match(c("H-T", "R-T", "H-W", "R-W"), harm_deg$cell)], 3),
                   c(0.995, 0.994, 0.970, 0.961))))
write.csv(harm_deg, table_path("factorial_harmonic_degree.csv"), row.names = FALSE)

# 4b.4 Location of the ten nodes with the highest betweenness
top10_loc <- do.call(rbind, lapply(CELLS$cell, function(k) {
  top <- top_n_of(cent_lab[cent_lab$cell == k, ], TOP_N_OVERLAP)
  sites <- data.frame(cell = k, row_type = "site", rank = seq_len(nrow(top)),
                      id_sito = top$id_sito, toponym = top$toponym, def_sito = top$def_en,
                      betweenness_norm = top$betweenness_norm,
                      x_utm = top$X, y_utm = top$Y,
                      east_median_km = NA_real_, east_sd_km = NA_real_,
                      ew_extent_km = NA_real_, ns_extent_km = NA_real_, stringsAsFactors = FALSE)
  summ <- data.frame(cell = k, row_type = "summary", rank = NA_integer_,
                     id_sito = NA_character_, toponym = NA_character_, def_sito = NA_character_,
                     betweenness_norm = NA_real_, x_utm = NA_real_, y_utm = NA_real_,
                     east_median_km = median(top$X) / 1000, east_sd_km = sd(top$X) / 1000,
                     ew_extent_km = diff(range(top$X)) / 1000,
                     ns_extent_km = diff(range(top$Y)) / 1000, stringsAsFactors = FALSE)
  rbind(sites, summ)
}))
ts <- top10_loc[top10_loc$row_type == "summary", ]
ts <- ts[match(c("H-T", "R-T", "H-W", "R-W"), ts$cell), ]
check_published("top-10 easting median / sd (km): 378.2/5.6, 389.5/9.2, 375.9/4.7, 377.5/3.6" =
  isTRUE(all.equal(round(ts$east_median_km, 1), c(378.2, 389.5, 375.9, 377.5))) &&
  isTRUE(all.equal(round(ts$east_sd_km, 1), c(5.6, 9.2, 4.7, 3.6))))
write.csv(top10_loc, table_path("factorial_top10_location.csv"), row.names = FALSE)

# 4b.5 Co-located Hellenistic sites: pairs within COLOCATED_DIST of each other
COLOCATED_DIST <- 250   # m
dmat <- sf::st_distance(siti_hell)
pairs <- which(upper.tri(dmat) & as.numeric(dmat) <= COLOCATED_DIST, arr.ind = TRUE)
colocated <- data.frame(
  id_a = siti_hell$id_sito[pairs[, 1]], id_b = siti_hell$id_sito[pairs[, 2]],
  distance_m = as.numeric(dmat[pairs]), stringsAsFactors = FALSE)
colocated <- colocated[order(colocated$distance_m), ]
lab_of <- function(ids, col) site_lab[[col]][match(ids, site_lab$id_sito)]
colocated$toponym_a  <- lab_of(colocated$id_a, "toponym")
colocated$toponym_b  <- lab_of(colocated$id_b, "toponym")
colocated$def_sito_a <- lab_of(colocated$id_a, "def_en")
colocated$def_sito_b <- lab_of(colocated$id_b, "def_en")
colocated$both_roman <- colocated$id_a %in% siti_rom$id_sito & colocated$id_b %in% siti_rom$id_sito
rownames(colocated) <- NULL
message(sprintf("Co-located Hellenistic sites (<= %d m): %d pairs, %d distinct sites (%s)",
                COLOCATED_DIST, nrow(colocated), length(unique(c(colocated$id_a, colocated$id_b))),
                paste(sort(unique(c(colocated$id_a, colocated$id_b))), collapse = ", ")))
write.csv(colocated, table_path("colocated_sites.csv"), row.names = FALSE)

# ---------------------------------------------------------------------------
# QC figure — betweenness distributions (rank-size), four panels
# ---------------------------------------------------------------------------
qc_df <- cent_long %>%
  group_by(cell) %>%
  arrange(desc(betweenness_norm), .by_group = TRUE) %>%
  mutate(rank = row_number()) %>% ungroup() %>%
  left_join(CELLS[, c("cell", "site_set", "cost_fn")], by = "cell") %>%
  mutate(site_set = factor(site_set, c("hellenistic", "roman"),
                           c("Hellenistic sites (71)", "Roman sites (94)")),
         cost_fn  = factor(cost_fn, c(COST_FN_HELL, COST_FN_ROM),
                           c("Tobler (240 min)", "Wheeled transport (150 min)")),
         upland   = id_sito %in% focus_ids)
qc_lab <- concentration %>%
  left_join(CELLS[, c("cell", "site_set", "cost_fn")], by = c("cell", "site_set", "cost_fn")) %>%
  mutate(site_set = factor(site_set, c("hellenistic", "roman"),
                           c("Hellenistic sites (71)", "Roman sites (94)")),
         cost_fn  = factor(cost_fn, c(COST_FN_HELL, COST_FN_ROM),
                           c("Tobler (240 min)", "Wheeled transport (150 min)")),
         label = sprintf("%s  top1 %.2f | Gini %.2f | Freeman %.3f\ntop: %s",
                         cell, top1_share, gini, freeman_centralization, top_node))
p_qc <- ggplot(qc_df, aes(rank, betweenness_norm)) +
  geom_col(aes(fill = site_set), width = 0.85, show.legend = FALSE) +
  geom_point(data = filter(qc_df, upland), colour = "black", size = 1.2) +
  ggrepel::geom_text_repel(data = filter(qc_df, upland, betweenness_norm > 0),
                           aes(label = id_sito), size = 2.2, seed = SCATTER_SEED,
                           min.segment.length = 0) +
  geom_text(data = qc_lab, aes(x = Inf, y = Inf, label = label),
            hjust = 1.02, vjust = 1.2, size = 2.4, inherit.aes = FALSE) +
  scale_fill_manual(values = c(PHASE_COLS[["hellenistic"]], PHASE_COLS[["roman"]])) +
  facet_grid(site_set ~ cost_fn) +
  labs(x = "Rank (by normalised betweenness)", y = "Normalised betweenness",
       title = "QC — betweenness distributions, 2×2 factorial (black = upland centres + DUR003)") +
  theme_minimal(base_size = 9)
ggsave(image_path("qc", "factorial_betweenness_distributions.png"),
       p_qc, width = 10, height = 6.5, dpi = 150)

# ===========================================================================
# STEP 5 — Reading of results (numbers only)
# ===========================================================================
message("\n[11] Step 5 — summary")

cv  <- function(k, m) concentration[[m]][concentration$cell == k]
f3  <- function(x) formatC(x, format = "f", digits = 3)
f4  <- function(x) formatC(x, format = "f", digits = 4)
CONC_M <- c(top1_share = "top-1 share", gini = "Gini",
            freeman_centralization = "Freeman centralisation")

# Q1 — concentration decrease Hellenistic -> Roman at constant function
q1_rows <- sapply(names(CONC_M), function(m)
  c(T = cv("R-T", m) < cv("H-T", m), W = cv("R-W", m) < cv("H-W", m)))
q1_lines <- sapply(names(CONC_M), function(m) sprintf(
  "| %s | %s | %s | %s | %s | %s | %s |", CONC_M[[m]],
  f3(cv("H-T", m)), f3(cv("R-T", m)), ifelse(q1_rows["T", m], "sì", "no"),
  f3(cv("H-W", m)), f3(cv("R-W", m)), ifelse(q1_rows["W", m], "sì", "no")))
q1_answer <- if (all(q1_rows)) "**Sì**" else if (!any(q1_rows)) "**No**" else "**Parzialmente**"

# Q2 — upland centres lose position at constant function?
ur <- function(k, sid) upland[upland$cell == k & upland$id_sito == sid, ]
# "sì" = worse percentile rank in b than in a; "pari (0)" = betweenness 0 in
# both cells (tied-rank percentiles are not comparable); "assente" = site
# not in one of the two networks.
loss_code <- function(a, b, sid) {
  ra <- ur(a, sid); rb <- ur(b, sid)
  if (!ra$present || !rb$present) return("assente")
  if (ra$betweenness_norm == 0 && rb$betweenness_norm == 0) return("pari (0)")
  # one side zero: the value decides (tied-zero percentiles are arbitrary)
  if (ra$betweenness_norm == 0) return("no")
  if (rb$betweenness_norm == 0) return("sì")
  if (rb$pct_rank_betweenness > ra$pct_rank_betweenness) "sì" else "no"
}
q2_lines <- sapply(focus_ids, function(sid) {
  g <- function(k) { r <- ur(k, sid)
    if (!r$present) "assente" else
      sprintf("%d/%d (%s)", r$rank_betweenness, r$n_cell, f4(r$betweenness_norm)) }
  sprintf("| %s | %s | %s | %s | %s | %s | %s | %s | %s |", sid,
          g("H-T"), g("R-T"), loss_code("H-T", "R-T", sid),
          g("H-W"), g("R-W"), loss_code("H-W", "R-W", sid),
          loss_code("H-T", "H-W", sid), loss_code("R-T", "R-W", sid))
})
loss_T <- sapply(UPLAND_IDS_F, function(s) loss_code("H-T", "R-T", s))
loss_W <- sapply(UPLAND_IDS_F, function(s) loss_code("H-W", "R-W", s))
fmt_loss <- function(l) sprintf("%d/4 perdono (%s); %d pari a betweenness 0 (%s); %d migliorano (%s)",
  sum(l == "sì"), paste(names(l)[l == "sì"], collapse = ", "),
  sum(l == "pari (0)"), paste(names(l)[l == "pari (0)"], collapse = ", "),
  sum(l == "no"), paste(names(l)[l == "no"], collapse = ", "))

# Q3 — share of the diagonal contrast found at constant function
q3_lines <- sapply(names(CONC_M), function(m) {
  d_diag <- cv("R-W", m) - cv("H-T", m)
  d_T    <- cv("R-T", m) - cv("H-T", m)
  d_W    <- cv("R-W", m) - cv("H-W", m)
  sprintf("| %s | %s | %s (%s %%) | %s (%s %%) | %s | %s |", CONC_M[[m]], f3(d_diag),
          f3(d_T), formatC(100 * d_T / d_diag, format = "f", digits = 0),
          f3(d_W), formatC(100 * d_W / d_diag, format = "f", digits = 0),
          f3(cv("H-W", m) - cv("H-T", m)), f3(cv("R-W", m) - cv("R-T", m)))
})
tq <- function(a, b, test, m) tests[tests$cell_a == a & tests$cell_b == b &
                                    tests$test == test & tests$metric == m, ]
q3_tests <- unlist(lapply(METRICS, function(m) sapply(
  list(c("H-T", "R-W"), c("H-T", "R-T"), c("H-W", "R-W")), function(p) {
    mw <- tq(p[1], p[2], "mann_whitney", m); wx <- tq(p[1], p[2], "wilcoxon_paired_dual", m)
    sp <- tq(p[1], p[2], "spearman_dual", m)
    sprintf("| %s | %s vs %s | %s → %s | %s | %s → %s | %s | %s (p=%s) |", m, p[1], p[2],
            f4(mw$value_a), f4(mw$value_b), format.pval(mw$p_value, digits = 2),
            f4(wx$value_a), f4(wx$value_b), format.pval(wx$p_value, digits = 2),
            f3(sp$statistic), format.pval(sp$p_value, digits = 2))
  })))

comp_lines <- apply(composition, 1, function(r) sprintf(
  "| %s | %s | %s | %s | %s | %s | %s | %s | %s |", r[["cell"]], r[["n_nodes"]],
  r[["n_edges"]], f3(as.numeric(r[["density"]])), r[["median_degree"]],
  r[["n_isolates"]], r[["n_components"]],
  sprintf("%s (%.1f %%)", r[["giant_size"]], as.numeric(r[["giant_pct"]])),
  gsub(";", ", ", r[["isolates"]])))

md <- c(
  "# Disegno fattoriale 2×2: lettura dei risultati",
  "",
  sprintf("Generato da `R/11_cost_function_factorial.R` il %s. Solo numeri, nessuna interpretazione.", Sys.Date()),
  "",
  "## Controllo di regressione (Step 1)",
  "",
  sprintf("H-T e R-W ricostruite dagli LCP salvati coincidono con gli oggetti di `04`/`05`: %d/%d verifiche superate (archi, grafo, centralità per sito vs `centrality_comparison.csv`, concentrazione vs `betweenness_concentration_sweep.csv`).",
          sum(regression), length(regression)),
  "",
  sprintf("Coerenza degli LCP nuovi (coppie fra i 46 siti dual-phase, costo medio in minuti): %s.",
          paste(sprintf("%s — %d coppie, scarto massimo %.2g min", lcp_consistency$comparison,
                        lcp_consistency$n_dual_pairs, lcp_consistency$max_abs_diff_min), collapse = "; ")),
  "",
  "## Composizione",
  "",
  "| cella | nodi | archi | densità | grado mediano | isolati | componenti | gigante | isolati (elenco) |",
  "|---|---|---|---|---|---|---|---|---|",
  comp_lines,
  "",
  "## 1. La concentrazione della betweenness diminuisce dall'ellenistico al romano in entrambi i confronti a funzione costante?",
  "",
  paste0(q1_answer, "."),
  "",
  "| metrica | H-T | R-T | cala (T) | H-W | R-W | cala (W) |",
  "|---|---|---|---|---|---|---|",
  q1_lines,
  "",
  sprintf("Nodo di testa: H-T %s, R-T %s, H-W %s, R-W %s.",
          cv("H-T", "top_node"), cv("R-T", "top_node"), cv("H-W", "top_node"), cv("R-W", "top_node")),
  "",
  "## 2. I centri d'altura perdono posizione dall'ellenistico al romano in entrambi i confronti a funzione costante, o solo quando cambia la funzione?",
  "",
  sprintf("Rank percentile di betweenness, ellenistico → romano a funzione costante. Tobler: %s. Trasporto su ruota: %s.",
          fmt_loss(loss_T), fmt_loss(loss_W)),
  "",
  "Rank di betweenness / n (betweenness normalizzata). Rank a pari merito = minimo del gruppo, quindi tutti i nodi a betweenness 0 condividono il primo rank del gruppo a zero; per questo i casi a 0 in entrambe le celle sono marcati \"pari (0)\" e, se solo una delle due è 0, decide il valore (0 → positivo = non perde). Negli altri casi decide il rank percentile.",
  "",
  "| sito | H-T | R-T | perde (T) | H-W | R-W | perde (W) | perde H-T→H-W | perde R-T→R-W |",
  "|---|---|---|---|---|---|---|---|---|",
  q2_lines,
  "",
  "## 3. Quanta parte del contrasto della diagonale originale (H-T vs R-W) si ritrova nei confronti a funzione costante?",
  "",
  "Differenze di concentrazione (romano − ellenistico) e quota rispetto alla diagonale; ultime due colonne = effetto della funzione a fase costante (W − T).",
  "",
  "| metrica | Δ diagonale (R-W − H-T) | Δ Tobler (R-T − H-T) | Δ ruota (R-W − H-W) | H-W − H-T | R-W − R-T |",
  "|---|---|---|---|---|---|",
  q3_lines,
  "",
  "Test sulle centralità per sito (mediane; Mann-Whitney su tutti i siti, Wilcoxon appaiato e Spearman sui 46 dual-phase):",
  "",
  "| metrica | confronto | mediane (tutti) | p MW | mediane (dual) | p Wilcoxon | ρ Spearman (dual) |",
  "|---|---|---|---|---|---|---|",
  q3_tests
)
writeLines(md, table_path("factorial_summary.md"), useBytes = TRUE)
message("Saved factorial_*.csv, factorial_summary.md and qc/factorial_betweenness_distributions.png")
