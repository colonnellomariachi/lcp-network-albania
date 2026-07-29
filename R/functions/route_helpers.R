# =============================================================================
# functions/route_helpers.R
# Shared helpers for Egnatia route validation.
# =============================================================================

#' Stitch disconnected route segments into one ordered LINESTRING
#'
#' st_line_merge() only joins segments that touch exactly. Digitised route
#' pieces often have small gaps at junctions, so this function stitches by
#' nearest endpoint rather than requiring exact topological connection.
#'
#' @param segs     sf object with LINESTRING (or castable to LINESTRING) rows.
#' @param max_gap  Maximum gap in metres before a warning is issued.
#' @return  An sfc object of length 1 containing the stitched LINESTRING.
stitch_route_segments <- function(segs, max_gap = STITCH_MAX_GAP) {
  segs        <- st_cast(segs, "LINESTRING")
  remaining   <- seq_len(nrow(segs))
  coords_list <- lapply(remaining, function(i) st_coordinates(segs[i, ])[, 1:2])

  ordered   <- coords_list[[1]]
  remaining <- setdiff(remaining, 1)

  while (length(remaining) > 0) {
    tail_pt <- ordered[nrow(ordered), ]
    dists <- sapply(remaining, function(i) {
      c1 <- coords_list[[i]]
      min(sqrt(sum((tail_pt - c1[1, ])^2)),
          sqrt(sum((tail_pt - c1[nrow(c1), ])^2)))
    })
    nxt <- remaining[which.min(dists)]
    if (min(dists) > max_gap) {
      warning(sprintf("Gap of %.0f m before segment %d exceeds max_gap (%d m)",
                      min(dists), nxt, max_gap))
    }
    c1      <- coords_list[[nxt]]
    d_start <- sqrt(sum((tail_pt - c1[1, ])^2))
    d_end   <- sqrt(sum((tail_pt - c1[nrow(c1), ])^2))
    if (d_end < d_start) c1 <- c1[nrow(c1):1, ]   # flip so route continues forward
    ordered   <- rbind(ordered, c1)
    remaining <- setdiff(remaining, nxt)
  }
  st_sfc(st_linestring(ordered), crs = st_crs(segs))
}

#' Snap a point to the nearest location on a route LINESTRING
#'
#' @param pt     sf point (single feature).
#' @param route  sfc or sf LINESTRING.
#' @return  sfc containing the snapped point on the route.
snap_to_route <- function(pt, route) {
  nearest_pt <- st_nearest_points(pt, route) %>% st_cast("POINT")
  nearest_pt[2]   # second point is the location on the route
}

#' Build a straight-line sf object between two points (baseline for PDI)
#'
#' @param from  sf point (single feature).
#' @param to    sf point (single feature).
#' @return  sf data.frame with one LINESTRING row.
straight_line <- function(from, to) {
  st_sf(geometry = st_sfc(
    st_linestring(rbind(st_coordinates(from)[1, 1:2],
                        st_coordinates(to)[1, 1:2])),
    crs = CRS_UTM))
}

#' Validate one LCP segment against a known route segment
#'
#' Computes PDI (Path Distance Index) and buffer overlap for a modelled LCP
#' versus the corresponding portion of the known Egnatia route.
#'
#' @param cs          Cost-surface object (leastcostpath format).
#' @param cs_label    Character label for the cost function (printed in output).
#' @param from        sf point: origin waypoint.
#' @param to          sf point: destination waypoint.
#' @param known_seg   sf LINESTRING: the reference route segment.
#' @param seg_label   Character label for the segment (printed in output).
#' @param buffers     Numeric vector of buffer distances (metres).
#' @return  Named list: $lcp (sf object) and $summary (one-row data.frame).
validate_segment <- function(cs, cs_label, from, to, known_seg, seg_label,
                             buffers = VAL_BUFFERS) {
  lcp      <- create_lcp(cs, origin = from, destination = to, cost_distance = TRUE)
  pdi      <- PDI_validation(lcp = lcp, comparison = known_seg)
  pdi_base <- PDI_validation(lcp = straight_line(from, to), comparison = known_seg)
  buf      <- buffer_validation(lcp, known_seg, dist = buffers)

  list(
    lcp     = lcp,
    pdi_obj = pdi,
    summary = data.frame(
      cost_function      = cs_label,
      segment            = seg_label,
      pdi                = as.numeric(pdi$pdi),
      pdi_norm           = as.numeric(pdi$normalised_pdi),
      pdi_norm_straight  = as.numeric(pdi_base$normalised_pdi),
      buffer_1km         = buf$similarity[buf$dist == 1000],
      buffer_5km         = buf$similarity[buf$dist == 5000]
    )
  )
}
