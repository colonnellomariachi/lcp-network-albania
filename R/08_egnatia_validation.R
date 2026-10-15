# =============================================================================
# 08_egnatia_validation.R — LCP model validation against the Via Egnatia
#
# Validates the two cost-surface models (Tobler / wheeled transport) by
# comparing modelled LCPs against the digitised Egnatia itinerary for three
# segments between four waypoints (Dyrrachium → Clodiana → Ad Quintum → Scampis).
#
# Waypoint snapping note (originally snap_test_egnatia.R):
#   Waypoints 3 and 4 (Ad Quintum, Scampis) are snapped to the nearest point
#   on the known route before segment LCPs are computed. The snap_to_route()
#   helper is defined in R/functions/route_helpers.R.
#
# Input:  data/egnatia_itinere.gpkg
#         output/rds/cost_surface_hell.rds
#         output/rds/cost_surface_rom.rds
#         output/rds/siti_rom.rds
# Output: output/tables/egnatia_validation_segments.csv
#         output/tables/egnatia_validation_full.csv
#         output/tables/egnatia_pdi_final.csv
#         output/tables/egnatia_pdi_comparison_bug.csv
#         output/tables/egnatia_corridor_containment.csv
#         output/tables/full_route_truncated_comparison.csv
#         output/tables/pdi_geom_diagnostics.csv
#         output/tables/pdi_independent_check.csv
#         output/rds/egnatia_stitched.rds
#         output/rds/wp_snapped.rds
#         output/rds/egnatia_known_segments.rds
#         output/rds/lcp_egnatia_tobler_seg{1,2,3}.rds
#         output/rds/lcp_egnatia_wheeled_seg{1,2,3}.rds
#         output/rds/pdi_egnatia_tobler_seg{1,2,3}.rds
#         output/rds/pdi_egnatia_wheeled_seg{1,2,3}.rds
#         output/rds/lcp_egnatia_tobler_full.rds
#         output/rds/lcp_egnatia_wheeled_full.rds
#         output/rds/corr_tobler.rds
#         output/rds/corr_wheeled.rds
# =============================================================================

# --- Load data ---------------------------------------------------------------
egnatia_raw <- st_read(data_path("egnatia_itinere.gpkg")) %>%
  filter(Name == "Dyrrhachium-Scampis") %>%
  st_transform(CRS_UTM)

cs_tobler  <- readRDS(rds_path("cost_surface_hell.rds"))
cs_wheeled <- readRDS(rds_path("cost_surface_rom.rds"))
siti_rom   <- readRDS(rds_path("siti_rom.rds"))

# --- Stitch route segments ---------------------------------------------------
egnatia <- stitch_route_segments(egnatia_raw, max_gap = STITCH_MAX_GAP)
stopifnot(length(egnatia) == 1)   # must be a single LINESTRING after stitching

# Blocking: the comparison line must coincide with Itiner-e. No edge may lie
# farther than ROUTE_ON_SOURCE_TOL from one of the eight pieces (a stitching
# started from an interior piece adds a 5.4 km chord near Dyrrachium), and the
# stitched length must equal the total length of the pieces.
assert_route_on_segments(egnatia, egnatia_raw)
stopifnot("stitched route must have the length of the Itiner-e pieces" =
            abs(as.numeric(st_length(egnatia)) - sum(as.numeric(st_length(egnatia_raw)))) < 1)

# --- Waypoints (west → east) -------------------------------------------------
wp <- siti_rom %>%
  filter(id_sito %in% WAYPOINT_IDS) %>%
  distinct(id_sito, .keep_all = TRUE) %>%
  arrange(match(id_sito, WAYPOINT_IDS)) %>%
  st_transform(CRS_UTM)
stopifnot(nrow(wp) == length(WAYPOINT_IDS))

# Apply the DUR024 coordinate correction (see header note above).
st_geometry(wp)[wp$id_sito == "DUR024"] <- st_sfc(
  st_point(c(DUR024_X_FIXED, DUR024_Y_FIXED)), crs = CRS_UTM)

# Ensure the route runs Durrës → Scampis (matching waypoint west-to-east order)
coords_e <- st_coordinates(egnatia)[, 1:2]
if (as.numeric(dist(rbind(coords_e[1, ], st_coordinates(wp[1, ])))) >
    as.numeric(dist(rbind(coords_e[nrow(coords_e), ], st_coordinates(wp[1, ]))))) {
  coords_e <- coords_e[nrow(coords_e):1, ]
  egnatia  <- st_sfc(st_linestring(coords_e), crs = CRS_UTM)
}

# --- Snap waypoints 3–4 to the known route -----------------------------------
# Waypoints for intermediate stations (Ad Quintum, Scampis) may fall slightly
# off the digitised route; snapping ensures PDI computation is fair.
# (Logic originally in snap_test_egnatia.R)
wp_snapped <- wp
for (i in 3:4) {
  st_geometry(wp_snapped)[i] <- snap_to_route(wp[i, ], egnatia)
  d <- st_distance(wp[i, ], egnatia)
  cat(WAYPOINT_IDS[i], ": distance to known route before snap =",
      round(as.numeric(d)), "m\n")
}

# --- Split known route at waypoint vertices ----------------------------------
wp_vertex <- apply(st_coordinates(wp_snapped)[, 1:2], 1, function(p) {
  which.min((coords_e[, 1] - p[1])^2 + (coords_e[, 2] - p[2])^2)
})
stopifnot(!is.unsorted(wp_vertex, strictly = TRUE))

known_segments <- lapply(seq_len(length(wp_vertex) - 1), function(i) {
  st_sf(geometry = st_sfc(
    st_linestring(coords_e[wp_vertex[i]:wp_vertex[i + 1], ]),
    crs = CRS_UTM))
})

cat("Known segment lengths (m):",
    paste(round(sapply(known_segments, st_length)), collapse = ", "), "\n")
# Dyrrachium-Clodiana as in the Itiner-e table of the manuscript (63.2 km)
check_published("segment 1 length must be ~63 224 m (Itiner-e, no stitching chord)" =
                  abs(as.numeric(st_length(known_segments[[1]])) - 63224) < 5)

# --- Segment-level validation ------------------------------------------------
seg_labels <- paste(WAYPOINT_IDS[-length(WAYPOINT_IDS)],
                    WAYPOINT_IDS[-1], sep = " -> ")

results <- list()
for (cs_i in list(list(cs = cs_tobler,  lab = "tobler"),
                  list(cs = cs_wheeled, lab = "wheeled transport"))) {
  cs_tag <- if (cs_i$lab == "tobler") "tobler" else "wheeled"
  for (i in seq_along(known_segments)) {
    res <- validate_segment(
      cs_i$cs, cs_i$lab,
      wp_snapped[i, ], wp_snapped[i + 1, ],
      known_segments[[i]], seg_labels[i]
    )
    results[[length(results) + 1]] <- res
    saveRDS(res$lcp,
            rds_path(sprintf("lcp_egnatia_%s_seg%d.rds", cs_tag, i)))
    saveRDS(res$pdi_obj,
            rds_path(sprintf("pdi_egnatia_%s_seg%d.rds", cs_tag, i)))
  }
}

val_table <- bind_rows(lapply(results, `[[`, "summary"))
print(val_table)
write.csv(val_table, table_path("egnatia_validation_segments.csv"), row.names = FALSE)
message("Saved egnatia_validation_segments.csv")

# --- Persist stitched route, waypoints, and known segments
saveRDS(egnatia,        rds_path("egnatia_stitched.rds"))
saveRDS(wp_snapped,     rds_path("wp_snapped.rds"))
saveRDS(known_segments, rds_path("egnatia_known_segments.rds"))
message("Saved stitched route, waypoints, known segments, and per-segment LCPs/PDI objects.")

# --- Full-route validation ---------------------------------------------------
durres  <- wp_snapped[1, ]
elbasan <- wp_snapped[nrow(wp_snapped), ]

full_results <- bind_rows(
  validate_segment(cs_tobler,  "tobler",
                   durres, elbasan,
                   st_sf(geometry = egnatia), "full route")$summary,
  validate_segment(cs_wheeled, "wheeled transport",
                   durres, elbasan,
                   st_sf(geometry = egnatia), "full route")$summary
)
print(full_results)
write.csv(full_results, table_path("egnatia_validation_full.csv"), row.names = FALSE)
message("Saved egnatia_validation_full.csv")

# --- Full-route LCPs (recomputed to capture the $lcp object) -----------------
full_lcp_tobler  <- validate_segment(cs_tobler,  "tobler",
                                     durres, elbasan,
                                     st_sf(geometry = egnatia), "full route")$lcp
full_lcp_wheeled <- validate_segment(cs_wheeled, "wheeled transport",
                                     durres, elbasan,
                                     st_sf(geometry = egnatia), "full route")$lcp
saveRDS(full_lcp_tobler,  rds_path("lcp_egnatia_tobler_full.rds"))
saveRDS(full_lcp_wheeled, rds_path("lcp_egnatia_wheeled_full.rds"))
message("Saved full-route LCPs.")

# --- Cost corridors (for figure) ---------------------------------------------
gc()   # free the surface graph left by the last create_lcp()
corr_tobler  <- create_cost_corridor(cs_tobler,  durres, elbasan)
gc()
corr_wheeled <- create_cost_corridor(cs_wheeled, durres, elbasan)
saveRDS(corr_tobler,  rds_path("corr_tobler.rds"))
saveRDS(corr_wheeled, rds_path("corr_wheeled.rds"))
message("Saved cost corridors.")

# --- Corridor containment (Part 3) -------------------------------------------
# For each of the three known segments, compute the proportion of attested
# route length (sampled at ~100 m intervals) that falls within the lowest
# 5 %, 10 %, and 25 % of corridor cost values across the full raster.
# No interpretation — raw proportions only.
vals_w <- as.numeric(terra::values(corr_wheeled, na.rm = TRUE))
vals_t <- as.numeric(terra::values(corr_tobler,  na.rm = TRUE))
# The corridor does not depend on the comparison line: 5 % thresholds
check_published("corridor 5 % quantiles must stay 38 498.43 s (wheeled) / 24 793.14 s (Tobler)" =
                  abs(quantile(vals_w, 0.05) - 38498.4348) < 0.01 &&
                  abs(quantile(vals_t, 0.05) - 24793.1418) < 0.01)

containment_rows <- lapply(seq_along(known_segments), function(i) {
  seg   <- known_segments[[i]]
  n_pts <- max(50L, ceiling(as.numeric(sf::st_length(seg)) / 100))

  pts_mp <- sf::st_line_sample(sf::st_geometry(seg), n = n_pts)
  pts_sf <- sf::st_as_sf(sf::st_cast(pts_mp, "POINT"))
  pts_v  <- terra::vect(pts_sf)

  ext_w <- terra::extract(corr_wheeled, pts_v)[, 2]
  ext_t <- terra::extract(corr_tobler,  pts_v)[, 2]

  do.call(rbind, lapply(c(0.05, 0.10, 0.25), function(q) {
    data.frame(
      segment       = seg_labels[i],
      cost_quantile = q,
      prop_wheeled  = mean(ext_w <= quantile(vals_w, q), na.rm = TRUE),
      prop_tobler   = mean(ext_t <= quantile(vals_t, q), na.rm = TRUE)
    )
  }))
})

containment_df <- do.call(rbind, containment_rows)
print(containment_df)
write.csv(containment_df,
          table_path("egnatia_corridor_containment.csv"),
          row.names = FALSE)
message("Saved egnatia_corridor_containment.csv")

# =============================================================================
# PDI CORRECTED — using pdi_fixed() (R/functions/pdi_validation_fixed.R)
#
# The package function leastcostpath::PDI_validation() does not call
# sf::st_make_valid() before sf::st_area(), producing corrupted areas for
# self-intersecting polygons. pdi_fixed() corrects this and is the source
# of all PDI values entering the manuscript.
#
# The original (buggy) values are preserved in egnatia_validation_segments.csv
# and egnatia_validation_full.csv for comparison and Methods documentation.
# =============================================================================

# Helper: straight-line sf between two waypoints (PDI baseline)
make_straight <- function(from_pt, to_pt) {
  st_sf(geometry = st_sfc(
    st_linestring(rbind(st_coordinates(from_pt)[1, 1:2],
                        st_coordinates(to_pt)[1, 1:2])),
    crs = CRS_UTM))
}

egnatia_full_sf <- st_sf(geometry = egnatia)

# --- Per-segment corrected PDI -----------------------------------------------
seg_cases <- list(
  list(label = seg_labels[1], seg = 1, o = 1, d = 2),
  list(label = seg_labels[2], seg = 2, o = 2, d = 3),
  list(label = seg_labels[3], seg = 3, o = 3, d = 4)
)

pdi_seg_rows <- lapply(seg_cases, function(p) {
  lcp_w    <- readRDS(rds_path(sprintf("lcp_egnatia_wheeled_seg%d.rds", p$seg)))
  lcp_t    <- readRDS(rds_path(sprintf("lcp_egnatia_tobler_seg%d.rds",  p$seg)))
  straight <- make_straight(wp_snapped[p$o, ], wp_snapped[p$d, ])
  kseg     <- known_segments[[p$seg]]
  rbind(
    pdi_fixed(lcp_w,    kseg, segment = p$label, cost_function = "wheeled transport"),
    pdi_fixed(lcp_t,    kseg, segment = p$label, cost_function = "tobler"),
    pdi_fixed(straight, kseg, segment = p$label, cost_function = "straight baseline")
  )
})
pdi_seg_df <- do.call(rbind, pdi_seg_rows)

# rank within each segment (1 = smallest normalised_pdi = best fit)
pdi_seg_df$rank_within_segment <- ave(
  pdi_seg_df$normalised_pdi,
  pdi_seg_df$segment,
  FUN = function(x) rank(x, ties.method = "min")
)

# --- Full-route corrected PDI -------------------------------------------------
pdi_full_rows <- rbind(
  pdi_fixed(full_lcp_wheeled, egnatia_full_sf,
            segment = "full route", cost_function = "wheeled transport"),
  pdi_fixed(full_lcp_tobler,  egnatia_full_sf,
            segment = "full route", cost_function = "tobler"),
  pdi_fixed(make_straight(durres, elbasan), egnatia_full_sf,
            segment = "full route", cost_function = "straight baseline")
)
pdi_full_rows$rank_within_segment <- rank(pdi_full_rows$normalised_pdi,
                                          ties.method = "min")

pdi_final <- rbind(pdi_seg_df, pdi_full_rows)
print(pdi_final)
write.csv(pdi_final, table_path("egnatia_pdi_final.csv"), row.names = FALSE)
message("Saved egnatia_pdi_final.csv")

# =============================================================================
# FULL ROUTE AGAINST THE TRUNCATED COMPARISON
#
# The comparison truncated at the vertex nearest to DUR001 has the same extent
# as the three segments joined together. The stitched route starts at the
# western end of 3084 (771 m from DUR001, its nearest vertex),
# so the truncated comparison coincides with the full route (78.16 km).
# =============================================================================
trunc_info   <- truncate_route_at(coords_e, wp_snapped[1, ])
egnatia_trunc <- trunc_info$route
seg_len_sum  <- sum(vapply(known_segments, function(x) as.numeric(st_length(x)), numeric(1)))
message(sprintf("Truncated comparison: vertex %d (%.0f m from %s), length %.0f m; three segments %.0f m",
                trunc_info$vertex, trunc_info$distance, WAYPOINT_IDS[1],
                as.numeric(st_length(egnatia_trunc)), seg_len_sum))
stopifnot("truncated comparison must have the extent of the three segments" =
            abs(as.numeric(st_length(egnatia_trunc)) - seg_len_sum) < 1)
check_published("truncated comparison must be ~78 159 m (the eight Itiner-e pieces)" =
                  abs(as.numeric(st_length(egnatia_trunc)) - 78159) < 5)

TRUNC_LABEL   <- "full route (truncated)"
full_straight <- make_straight(durres, elbasan)
full_cases <- list(
  list(fn = "wheeled transport", lcp = full_lcp_wheeled),
  list(fn = "tobler",            lcp = full_lcp_tobler),
  list(fn = "straight baseline", lcp = full_straight))

pdi_trunc <- do.call(rbind, lapply(full_cases, function(k)
  pdi_fixed(k$lcp, egnatia_trunc, segment = TRUNC_LABEL, cost_function = k$fn)))
pdi_trunc$rank_within_segment <- rank(pdi_trunc$normalised_pdi, ties.method = "min")
# Sum of the three per-segment deviation areas (constrained paths), to set
# against the area of the free full-route path
pdi_trunc$sum_area_segments <- vapply(pdi_trunc$cost_function, function(fn)
  if (fn == "straight baseline") NA_real_ else
    sum(pdi_seg_df$area_selected[pdi_seg_df$cost_function == fn]), numeric(1))
pdi_trunc$area_ratio_full_vs_segments <- pdi_trunc$area_selected / pdi_trunc$sum_area_segments
# Share (%) of the modelled full route within 1 km / 5 km of the attested one
buf_trunc <- lapply(full_cases, function(k)
  buffer_validation(k$lcp, egnatia_trunc, dist = FULL_ROUTE_BUFFERS))
for (b in FULL_ROUTE_BUFFERS)
  pdi_trunc[[sprintf("pct_within_%dkm", b / 1000)]] <-
    vapply(buf_trunc, function(x) x$similarity[x$dist == b], numeric(1))
print(pdi_trunc)
write.csv(pdi_trunc, table_path("full_route_truncated_comparison.csv"), row.names = FALSE)
message("Saved full_route_truncated_comparison.csv")

# =============================================================================
# PDI DIAGNOSTICS: polygon geometry and independent sampling check
# 15 cases: 3 segments + full route (stitched) + full route (truncated),
# each for wheeled transport, Tobler and the straight baseline.
# =============================================================================
diag_cases <- c(
  unlist(lapply(seg_cases, function(p) list(
    list(seg = p$label, fn = "wheeled transport", cmp = known_segments[[p$seg]],
         lcp = readRDS(rds_path(sprintf("lcp_egnatia_wheeled_seg%d.rds", p$seg)))),
    list(seg = p$label, fn = "tobler",            cmp = known_segments[[p$seg]],
         lcp = readRDS(rds_path(sprintf("lcp_egnatia_tobler_seg%d.rds",  p$seg)))),
    list(seg = p$label, fn = "straight baseline", cmp = known_segments[[p$seg]],
         lcp = make_straight(wp_snapped[p$o, ], wp_snapped[p$d, ])))), recursive = FALSE),
  lapply(full_cases, function(k) list(seg = "full route", fn = k$fn, cmp = egnatia_full_sf, lcp = k$lcp)),
  lapply(full_cases, function(k) list(seg = TRUNC_LABEL,  fn = k$fn, cmp = egnatia_trunc,   lcp = k$lcp)))

pdi_geom <- do.call(rbind, lapply(diag_cases, function(k)
  pdi_candidate_diagnostics(k$lcp, k$cmp, segment = k$seg, cost_function = k$fn)))
pdi_indep <- do.call(rbind, lapply(diag_cases, function(k)
  pdi_sampling_check(k$lcp, k$cmp, segment = k$seg, cost_function = k$fn)))
pdi_indep <- pdi_indep[order(pdi_indep$segment, pdi_indep$cost_function), ]
rownames(pdi_indep) <- NULL

# --- Consistency (BLOCKING): the diagnostics must describe the same polygons
# as the canonical tables. area_selected, pdi and normalised_pdi must coincide
# row by row with egnatia_pdi_final.csv (and, for the truncated comparison,
# with full_route_truncated_comparison.csv).
pdi_reference <- rbind(
  pdi_final[, c("segment", "cost_function", "area_selected", "pdi", "normalised_pdi")],
  pdi_trunc[, c("segment", "cost_function", "area_selected", "pdi", "normalised_pdi")])
check_pdi_consistency <- function(tab, name) {
  m <- merge(pdi_reference, tab, by = c("segment", "cost_function"), suffixes = c("_ref", ""))
  if (nrow(m) != nrow(pdi_reference) || nrow(tab) != nrow(pdi_reference))
    stop(name, ": rows do not match the canonical PDI tables")
  for (v in c("area_selected", "pdi", "normalised_pdi")) {
    rel <- abs(m[[v]] - m[[paste0(v, "_ref")]]) / abs(m[[paste0(v, "_ref")]])
    if (any(rel > 1e-12))
      stop(sprintf("%s: %s differs from the canonical PDI tables in %d row(s), max relative difference %.3g",
                   name, v, sum(rel > 1e-12), max(rel)))
  }
  message("  OK  ", name, ": area_selected, pdi, normalised_pdi coincide with the canonical tables (",
          nrow(m), " rows)")
}
check_pdi_consistency(pdi_geom,  "pdi_geom_diagnostics.csv")
check_pdi_consistency(pdi_indep, "pdi_independent_check.csv")
stopifnot("area_sum_check must equal area_selected" =
            isTRUE(all.equal(pdi_geom$area_sum_check, pdi_geom$area_selected, tolerance = 1e-12)))

print(pdi_geom); print(pdi_indep)
write.csv(pdi_geom,  table_path("pdi_geom_diagnostics.csv"),  row.names = FALSE)
write.csv(pdi_indep, table_path("pdi_independent_check.csv"), row.names = FALSE)
message("Saved pdi_geom_diagnostics.csv and pdi_independent_check.csv")

# --- Bug-comparison table (package vs fixed) ----------------------------------
# Twelve rows: 3 segments + full route, each for wheeled transport, Tobler and
# the straight baseline. Package values come from PDI_validation() as called
# in validate_segment() (egnatia_validation_segments.csv / _full.csv).
orig_seg <- read.csv(table_path("egnatia_validation_segments.csv"),
                     stringsAsFactors = FALSE)
orig_full <- read.csv(table_path("egnatia_validation_full.csv"),
                      stringsAsFactors = FALSE)
orig_both <- rbind(orig_seg, orig_full)

orig_all <- rbind(
  data.frame(segment = orig_both$segment, cost_function = orig_both$cost_function,
             normalised_pdi_pkg = orig_both$pdi_norm, stringsAsFactors = FALSE),
  # the straight baseline does not depend on the cost function: one row per segment
  unique(data.frame(segment = orig_both$segment, cost_function = "straight baseline",
                    normalised_pdi_pkg = orig_both$pdi_norm_straight,
                    stringsAsFactors = FALSE)))
stopifnot("one package value per segment and function" =
            !any(duplicated(orig_all[, c("segment", "cost_function")])),
          nrow(orig_all) == 12L)

fixed_comp <- pdi_final[, c("segment", "cost_function", "normalised_pdi",
                            "was_valid_before", "geom_type", "n_parts")]

comparison_bug <- merge(orig_all, fixed_comp,
                        by = c("segment", "cost_function"), all = TRUE)
comparison_bug$delta_abs <- comparison_bug$normalised_pdi -
                            comparison_bug$normalised_pdi_pkg
comparison_bug$ratio_fixed_to_pkg <- comparison_bug$normalised_pdi /
                                     comparison_bug$normalised_pdi_pkg
print(comparison_bug)
message(sprintf("Corrected / package normalised PDI over %d rows: min %.3f (%s, %s), max %.3f (%s, %s)",
                nrow(comparison_bug),
                min(comparison_bug$ratio_fixed_to_pkg),
                comparison_bug$segment[which.min(comparison_bug$ratio_fixed_to_pkg)],
                comparison_bug$cost_function[which.min(comparison_bug$ratio_fixed_to_pkg)],
                max(comparison_bug$ratio_fixed_to_pkg),
                comparison_bug$segment[which.max(comparison_bug$ratio_fixed_to_pkg)],
                comparison_bug$cost_function[which.max(comparison_bug$ratio_fixed_to_pkg)]))
write.csv(comparison_bug,
          table_path("egnatia_pdi_comparison_bug.csv"),
          row.names = FALSE)
message("Saved egnatia_pdi_comparison_bug.csv")
