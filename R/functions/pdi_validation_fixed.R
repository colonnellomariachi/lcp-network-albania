# =============================================================================
# functions/pdi_validation_fixed.R
#
# Local corrected replacement for leastcostpath::PDI_validation().
# The package function (v 2.0.13) calls sf::st_area() on a potentially
# self-intersecting polygon without first calling sf::st_make_valid().
# Under GEOS 3.13 the signed-area algorithm returns near-zero (or wrong)
# values for figure-eight polygons, and the corrupted areas propagate into
# which.min so the wrong candidate can be selected.
#
# This function:
#   1. Replicates the two-candidate construction exactly as in the source.
#   2. Calls sf::st_make_valid() on BOTH candidates before any area
#      computation, so which.min operates on valid areas.
#   3. Sums the areas of all POLYGON components of the (possibly MULTI)
#      result — rather than taking the first geometry — so multi-lobe
#      polygons are handled correctly.
#   4. Computes max_distance exactly as the source does: Euclidean distance
#      between first and last vertex of `comparison` (not the waypoints).
#   5. Returns a one-row data.frame with diagnostic columns (geometry type and
#      number of parts of the chosen polygon, both candidate areas) for QC and
#      Methods documentation.
#
# Usage (mirrors validate_segment signature, adds segment/cost_function labels):
#   pdi_fixed(lcp_sf, known_seg_sf, segment = "seg label",
#             cost_function = "wheeled transport")
#
# Acceptance test (run inline): normalised_pdi == area_selected / max_distance^2 * 100
# =============================================================================

pdi_fixed <- function(lcp, comparison,
                      segment       = NA_character_,
                      cost_function = NA_character_) {

  stopifnot(inherits(lcp,        c("sf", "sfc")),
            inherits(comparison, c("sf", "sfc")))

  # ---- 1. Build both candidate polygons (exact replication of source) -------
  lcps <- list(lcp, sf::st_reverse(lcp))

  candidate_polys <- lapply(lcps, function(x) {
    # Force endpoints to match comparison endpoints (as source does)
    x$geometry[[1]][1L, ]                    <- comparison$geometry[[1]][1L, ]
    x$geometry[[1]][nrow(x$geometry[[1]]), ] <-
      comparison$geometry[[1]][nrow(comparison$geometry[[1]]), ]

    ring <- rbind(sf::st_coordinates(sf::st_reverse(x)),
                  sf::st_coordinates(comparison))
    poly <- sf::st_polygon(list(ring))
    sf::st_sfc(poly, crs = sf::st_crs(comparison))
  })

  # ---- 2. Record validity before any fix ------------------------------------
  was_valid_1 <- sf::st_is_valid(candidate_polys[[1]])
  was_valid_2 <- sf::st_is_valid(candidate_polys[[2]])
  was_valid_before <- isTRUE(was_valid_1) && isTRUE(was_valid_2)

  # ---- 3. Apply st_make_valid() to BOTH before area computation -------------
  valid_1 <- sf::st_make_valid(candidate_polys[[1]])
  valid_2 <- sf::st_make_valid(candidate_polys[[2]])

  # ---- 4. Sum areas of all components (handles MULTIPOLYGON) ----------------
  safe_area <- function(geom) {
    a <- tryCatch(as.numeric(sf::st_area(geom)), error = function(e) 0)
    if (length(a) == 0L || all(is.na(a))) 0 else sum(a, na.rm = TRUE)
  }
  area_1 <- safe_area(valid_1)
  area_2 <- safe_area(valid_2)

  # ---- 5. Select smaller candidate (which.min on VALID areas) ---------------
  chosen_idx  <- which.min(c(area_1, area_2))
  area_selected <- min(area_1, area_2)
  chosen_poly <- list(valid_1, valid_2)[[chosen_idx]]

  # Real geometry of the chosen polygon after st_make_valid(): its type and the
  # number of POLYGON parts (where the two lines cross, a MULTIPOLYGON with
  # several parts). An earlier column, "n_lobes", was computed as the length
  # of a one-element sfc and was therefore always 1.
  geom_type <- as.character(sf::st_geometry_type(chosen_poly))
  n_parts   <- length(suppressWarnings(
    sf::st_cast(sf::st_collection_extract(chosen_poly, "POLYGON"), "POLYGON")))

  # ---- 6. max_distance: first-to-last vertex of comparison (as source) ------
  comp_coords <- comparison$geometry[[1]]
  max_distance <- as.numeric(
    sf::st_distance(
      sf::st_point(comp_coords[1L, ]),
      sf::st_point(comp_coords[nrow(comp_coords), ]),
      which = "Euclidean"
    )
  )

  # ---- 7. PDI metrics --------------------------------------------------------
  pdi           <- area_selected / max_distance
  normalised_pdi <- (pdi / max_distance) * 100

  # ---- 8. Acceptance test (not a stop — prints a warning if tolerance fails) -
  expected <- area_selected / max_distance^2 * 100
  if (abs(normalised_pdi - expected) > 1e-8) {
    warning(sprintf(
      "pdi_fixed: normalised_pdi (%.10g) != area/maxd^2*100 (%.10g); diff = %.2e",
      normalised_pdi, expected, normalised_pdi - expected))
  }

  # ---- 9. Line crossings (intersection points between lcp and comparison) ----
  xings <- tryCatch(
    sf::st_intersection(sf::st_geometry(lcp), sf::st_geometry(comparison)),
    error = function(e) NULL
  )
  n_crossings <- if (is.null(xings) || length(xings) == 0L) 0L else {
    pts <- tryCatch(
      sf::st_cast(xings, "POINT", warn = FALSE),
      error = function(e) NULL
    )
    if (is.null(pts) || length(pts) == 0L) 0L else length(pts)
  }
  if (length(n_crossings) == 0L) n_crossings <- 0L

  data.frame(
    segment             = segment,
    cost_function       = cost_function,
    geom_type           = geom_type,
    n_parts             = n_parts,
    area_candidate_1    = area_1,
    area_candidate_2    = area_2,
    area_selected       = area_selected,
    max_distance        = max_distance,
    pdi                 = pdi,
    normalised_pdi      = normalised_pdi,
    was_valid_before    = was_valid_before,
    n_crossings         = n_crossings,
    stringsAsFactors    = FALSE
  )
}


# =============================================================================
# Diagnostics of the corrected PDI.
# The three functions below reproduce, digit for digit, the tables
# pdi_geom_diagnostics.csv, pdi_independent_check.csv and
# full_route_truncated_comparison.csv of 28 July 2026 when run on the objects
# of the first submission (the original ad-hoc scripts were never committed).
# =============================================================================

#' The two candidate PDI polygons after st_make_valid() (as in pdi_fixed())
pdi_candidate_polygons <- function(lcp, comparison) {
  lapply(list(lcp, sf::st_reverse(lcp)), function(x) {
    x$geometry[[1]][1L, ] <- comparison$geometry[[1]][1L, ]
    x$geometry[[1]][nrow(x$geometry[[1]]), ] <-
      comparison$geometry[[1]][nrow(comparison$geometry[[1]]), ]
    ring <- rbind(sf::st_coordinates(sf::st_reverse(x)),
                  sf::st_coordinates(comparison))
    sf::st_make_valid(sf::st_sfc(sf::st_polygon(list(ring)),
                                 crs = sf::st_crs(comparison)))
  })
}

#' Geometry diagnostics of BOTH candidate PDI polygons after st_make_valid()
#'
#' Reports, for each candidate, the geometry type and the number of POLYGON
#' parts, which candidate is chosen, and the sum of the areas of the chosen
#' polygon's parts (area_sum_check). pdi / normalised_pdi are computed from
#' area_selected as in pdi_fixed().
#'
#' Note on the table of 28 July 2026: its columns geom_class ("XY") and
#' n_lobes (1) were the coordinate-dimension class of the sfg and the length
#' of a one-element sfc, i.e. constants. Where the two lines cross,
#' st_make_valid() returns a MULTIPOLYGON with several parts; geom_type_* and
#' n_parts_* report that. Areas were and are the sum over all parts.
pdi_candidate_diagnostics <- function(lcp, comparison,
                                      segment = NA_character_,
                                      cost_function = NA_character_) {
  cand   <- pdi_candidate_polygons(lcp, comparison)
  parts  <- lapply(cand, function(g)
    suppressWarnings(sf::st_cast(sf::st_collection_extract(g, "POLYGON"), "POLYGON")))
  areas  <- vapply(cand, function(g) sum(as.numeric(sf::st_area(g))), numeric(1))
  chosen <- which.min(areas)
  cc     <- comparison$geometry[[1]]
  max_distance <- as.numeric(sf::st_distance(sf::st_point(cc[1L, ]),
                                             sf::st_point(cc[nrow(cc), ]),
                                             which = "Euclidean"))
  data.frame(
    segment = segment, cost_function = cost_function,
    geom_type_cand1 = as.character(sf::st_geometry_type(cand[[1]])),
    geom_type_cand2 = as.character(sf::st_geometry_type(cand[[2]])),
    n_parts_cand1 = length(parts[[1]]), n_parts_cand2 = length(parts[[2]]),
    chosen = chosen,
    area_candidate_1 = areas[1], area_candidate_2 = areas[2],
    area_selected  = min(areas),
    area_sum_check = sum(as.numeric(sf::st_area(parts[[chosen]]))),
    largest_part_share = max(as.numeric(sf::st_area(parts[[chosen]]))) / min(areas),
    max_distance   = max_distance,
    pdi            = min(areas) / max_distance,
    normalised_pdi = (min(areas) / max_distance / max_distance) * 100,
    stringsAsFactors = FALSE)
}

#' Independent check of the PDI by sampling
#'
#' Points are sampled on the comparison (attested) line every `spacing`
#' metres; the mean and maximum distance from the points to the modelled path
#' are compared with the PDI (area / straight-line distance), which has the
#' same unit and should be of the same order.
pdi_sampling_check <- function(lcp, comparison,
                               segment = NA_character_,
                               cost_function = NA_character_,
                               spacing = PDI_SAMPLE_SPACING) {
  pts <- sf::st_cast(sf::st_line_sample(sf::st_geometry(comparison),
                                        density = 1 / spacing), "POINT")
  d   <- as.numeric(sf::st_distance(pts, sf::st_geometry(lcp)))
  pf  <- suppressWarnings(pdi_fixed(lcp, comparison, segment, cost_function))
  data.frame(
    segment = segment, cost_function = cost_function,
    n_sample_pts       = length(pts),
    mean_dist_to_lcp_m = round(mean(d), 1),
    max_dist_to_lcp_m  = round(max(d), 1),
    area_selected      = pf$area_selected,
    pdi                = pf$pdi,
    normalised_pdi     = pf$normalised_pdi,
    pdi_rounded        = round(pf$pdi, 1),
    mean_vs_pdi_diff   = round(round(mean(d), 1) - round(pf$pdi, 1), 1),
    stringsAsFactors = FALSE)
}

#' Attested route truncated at the vertex nearest to a point
#'
#' The digitised Egnatia does not start at DUR001; its first vertices run away
#' from it. Truncating at the vertex nearest to DUR001 gives a comparison line
#' with the same extent as the three segments joined together.
#' @return list(route = sf LINESTRING, vertex = index, distance = metres)
truncate_route_at <- function(route_coords, pt, crs = CRS_UTM) {
  xy <- sf::st_coordinates(pt)[1, 1:2]
  d  <- sqrt((route_coords[, 1] - xy[1])^2 + (route_coords[, 2] - xy[2])^2)
  i  <- which.min(d)
  list(route = sf::st_sf(geometry = sf::st_sfc(
         sf::st_linestring(route_coords[i:nrow(route_coords), ]), crs = crs)),
       vertex = i, distance = d[i])
}
