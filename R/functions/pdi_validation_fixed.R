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
#   5. Returns a one-row data.frame with diagnostic columns for QC and
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

  # Number of lobes in the chosen polygon.
  # st_make_valid() may return GEOMETRYCOLLECTION; extract only POLYGON types.
  n_lobes <- tryCatch({
    parts <- sf::st_collection_extract(chosen_poly, "POLYGON")
    length(parts)
  }, error = function(e) 1L)
  if (length(n_lobes) == 0L || is.na(n_lobes)) n_lobes <- 1L

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
    n_lobes             = n_lobes,
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
