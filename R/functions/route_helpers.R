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
#' The chain is grown greedily from a starting piece. Every piece, in both
#' orientations, is tried as the start and the chain with the smallest total
#' gap is kept: a chain started from an interior piece (for example the
#' first row, 3083) has to jump back across the route to
#' reach the pieces it left behind, which added a straight 5.4 km chord near
#' Dyrrachium. Started from one of the two ends, the chain follows the pieces
#' in geographic order.
#'
#' @param segs     sf object with LINESTRING (or castable to LINESTRING) rows.
#' @param max_gap  Maximum gap in metres before a warning is issued.
#' @return  An sfc object of length 1 containing the stitched LINESTRING.
stitch_route_segments <- function(segs, max_gap = STITCH_MAX_GAP) {
  segs        <- suppressWarnings(st_cast(segs, "LINESTRING"))
  coords_list <- lapply(seq_len(nrow(segs)), function(i) st_coordinates(segs[i, ])[, 1:2])

  chain_from <- function(first, flip) {
    ordered   <- coords_list[[first]]
    if (flip) ordered <- ordered[nrow(ordered):1, ]
    remaining <- setdiff(seq_along(coords_list), first)
    gaps      <- numeric(0)
    pieces    <- first
    while (length(remaining) > 0) {
      tail_pt <- ordered[nrow(ordered), ]
      dists <- sapply(remaining, function(i) {
        c1 <- coords_list[[i]]
        min(sqrt(sum((tail_pt - c1[1, ])^2)),
            sqrt(sum((tail_pt - c1[nrow(c1), ])^2)))
      })
      nxt     <- remaining[which.min(dists)]
      c1      <- coords_list[[nxt]]
      d_start <- sqrt(sum((tail_pt - c1[1, ])^2))
      d_end   <- sqrt(sum((tail_pt - c1[nrow(c1), ])^2))
      if (d_end < d_start) c1 <- c1[nrow(c1):1, ]   # flip so route continues forward
      ordered   <- rbind(ordered, c1)
      gaps      <- c(gaps, min(dists))
      pieces    <- c(pieces, nxt)
      remaining <- setdiff(remaining, nxt)
    }
    list(coords = ordered, gaps = gaps, pieces = pieces)
  }

  chains <- unlist(lapply(seq_along(coords_list), function(i)
    list(chain_from(i, FALSE), chain_from(i, TRUE))), recursive = FALSE)
  best <- chains[[which.min(vapply(chains, function(x) sum(x$gaps), numeric(1)))]]
  for (k in which(best$gaps > max_gap))
    warning(sprintf("Gap of %.0f m before segment %d exceeds max_gap (%d m)",
                    best$gaps[k], best$pieces[k + 1], max_gap))
  st_sfc(st_linestring(best$coords), crs = st_crs(segs))
}

#' Blocking check: every edge of a stitched route lies on a source piece
#'
#' The route is densified (vertices every `step` m) and every vertex must be
#' within `tol` m of one of the source pieces; an edge added by the stitching
#' (a chord between pieces) fails. Stops with the offending length otherwise.
#'
#' @param route  sfc / sf LINESTRING (the stitched route).
#' @param segs   sf with the source pieces.
#' @return  Invisibly, the maximum distance (m) of the route from the pieces.
assert_route_on_segments <- function(route, segs, tol = ROUTE_ON_SOURCE_TOL, step = 10) {
  dense <- st_segmentize(st_geometry(route), dfMaxLength = step)
  xy    <- st_coordinates(dense)[, 1:2]
  pts   <- st_as_sf(as.data.frame(xy), coords = c("X", "Y"), crs = st_crs(segs))
  d     <- apply(st_distance(pts, segs), 1, function(x) min(as.numeric(x)))
  off   <- d > tol
  if (any(off)) {
    edge_off <- off[-1] & off[-length(off)]
    stop(sprintf(paste("Stitched route leaves the source pieces: %d of %d densified vertices",
                       "farther than %g m (max %.0f m, about %.0f m of route)"),
                 sum(off), length(off), tol, max(d),
                 sum(sqrt(rowSums(diff(xy)^2))[edge_off])), call. = FALSE)
  }
  invisible(max(d))
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
  # create_lcp() builds an igraph of the whole surface (tens of GB) that R's
  # collector does not see; free the one left by the previous call first.
  gc()
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
