# =============================================================================
# functions/lcp_helpers.R
# Least-cost path computation shared by 03_least_cost_paths.R and
# 11_cost_function_factorial.R. Moved here verbatim from 03 so the factorial
# cells are computed with exactly the same calls as the published networks.
# =============================================================================

#' Snap non-traversable sites to the nearest valid cost-surface cell
#'
#' Tests each site individually against its cost surface; any that fail
#' check_locations() are moved to the nearest valid DEM pixel.
#' (DUR103 was the original known offender; this generalises the fix.)
#' `valid_pts` is either an sf of valid DEM cell centres (03) or the DEM as a
#' SpatRaster, in which case valid points are taken locally around each site.
#'
#' Matrix must be loaded before the first check_locations() call: otherwise
#' the S4 subsetting of the dgCMatrix fails in a fresh session and, if every
#' error were treated as "non-traversable", the first site tested (DUR001)
#' would be snapped spuriously. Only the two location errors raised by
#' check_locations() count as failures; anything else stops.
snap_non_traversable <- function(sites, cost_surface, valid_pts, label) {
  loadNamespace("Matrix")
  location_error <- "not traversable|outside the extent"
  bad_idx <- which(vapply(seq_len(nrow(sites)), function(i) {
    res <- tryCatch(leastcostpath::check_locations(cost_surface, sites[i, ]),
                    error = function(e) e)
    if (inherits(res, "error") && !grepl(location_error, conditionMessage(res)))
      stop("check_locations() failed for ", sites$id_sito[i], ": ",
           conditionMessage(res))
    inherits(res, "error")
  }, logical(1)))

  if (length(bad_idx) == 0) {
    message(label, ": all sites traversable, no snapping needed")
    return(sites)
  }

  message(label, ": snapping ", length(bad_idx), " site(s) — ",
          paste(sites$id_sito[bad_idx], collapse = ", "))

  for (i in bad_idx) {
    pts <- if (inherits(valid_pts, "SpatRaster"))
      local_valid_pts(valid_pts, sites[i, ]) else valid_pts
    new_geom <- sf::st_geometry(pts[sf::st_nearest_feature(sites[i, ], pts), ])
    sf::st_geometry(sites)[i] <- new_geom
  }
  sites
}

#' Valid DEM cell centres in a window around one site
#'
#' Same nearest valid pixel as terra::as.points() on the whole DEM, but only
#' over a window that is widened until it contains a valid cell farther than
#' the nearest one from the window edge (so the global nearest is inside).
local_valid_pts <- function(dem, site, start = 500) {
  xy <- sf::st_coordinates(site)[1, ]
  r  <- start
  repeat {
    win <- terra::crop(dem, terra::ext(xy[1] - r, xy[1] + r, xy[2] - r, xy[2] + r))
    pts <- sf::st_as_sf(terra::as.points(win, na.rm = TRUE))
    if (nrow(pts) > 0) {
      dmin <- min(as.numeric(sf::st_distance(site, pts)))
      if (dmin <= r) return(pts)
    }
    r <- r * 2
  }
}

#' CODE PATH A — all from-every-to-every LCPs in one call
#' Returns sf with origin_ID, destination_ID (row indices of `sites`), cost (s).
compute_lcps_fete <- function(cost_surface, sites) {
  create_FETE_lcps(cost_surface, sites, cost_distance = TRUE)
}

#' CODE PATH B — manual loop over origins (memory workaround)
#' Returns sf with fromCell, toCell (raster cell indices), cost (s).
compute_lcps_loop <- function(cost_surface, sites, label = "") {
  site_ids <- sites$id_sito
  lcp_list <- vector("list", length(site_ids))

  for (i in seq_along(site_ids)) {
    origin      <- sites[i, ]
    destination <- sites[-i, ]
    lcp_list[[i]] <- tryCatch(
      create_lcp(x = cost_surface, origin = origin,
                 destination = destination,
                 cost_distance = TRUE, check_locations = FALSE),
      error = function(e) {
        message("FAILED: ", site_ids[i], " -> ", conditionMessage(e))
        NULL
      }
    )
    rm(origin, destination); gc(verbose = FALSE)
    if (i %% 5 == 0) message(label, " ", i, "/", length(site_ids), " completed")
  }
  failed <- site_ids[sapply(lcp_list, is.null)]
  if (length(failed)) message("Failed origins: ", paste(failed, collapse = ", "))
  do.call(rbind, lcp_list[!sapply(lcp_list, is.null)])
}

#' Graph engine — same computation as create_lcp(), graph built once
#'
#' leastcostpath::create_lcp() (v2.0.13) rebuilds the igraph object from the
#' conductance matrix at every call and runs one Dijkstra for the paths plus
#' one Dijkstra per destination for the costs (~4 min per origin on this DEM).
#' This reproduces its steps — directed graph from the conductance matrix,
#' weights 1/conductance, igraph shortest_paths() + distances() with
#' algorithm = "dijkstra", mode = "out" — but builds the graph once per
#' surface and gets all costs of an origin from a single distances() call.
#' Output columns match create_lcp() (geometry, costFunction, fromCell,
#' toCell, cost) plus origin_ID / destination_ID when schema = "fete", with
#' the same row filters as create_FETE_lcps(). Equivalence is checked in 11
#' against the published dual-phase pair costs.
compute_lcps_graph <- function(cost_surface, sites, schema = c("fete", "loop"),
                               label = "") {
  schema <- match.arg(schema)
  cs_rast <- terra::rast(
    nrow = cost_surface$nrow, ncol = cost_surface$ncol,
    xmin = cost_surface$extent[1], xmax = cost_surface$extent[2],
    ymin = cost_surface$extent[3], ymax = cost_surface$extent[4],
    crs  = cost_surface$crs)
  cells <- terra::cellFromXY(cs_rast, sf::st_coordinates(sites))
  g <- igraph::graph_from_adjacency_matrix(cost_surface$conductanceMatrix,
                                           mode = "directed", weighted = TRUE)
  igraph::E(g)$weight <- 1 / igraph::E(g)$weight
  n <- length(cells)
  out <- vector("list", n)
  for (i in seq_len(n)) {
    to_cells <- cells[-i]
    sp   <- igraph::shortest_paths(g, from = cells[i], to = to_cells,
                                   mode = "out", algorithm = "dijkstra")
    cost <- igraph::distances(g, v = cells[i], to = to_cells,
                              mode = "out", algorithm = "dijkstra")[1, ]
    geoms <- lapply(sp$vpath, function(v)
      sf::st_linestring(terra::xyFromCell(cs_rast, as.integer(v))))
    lcp <- sf::st_sf(geometry = sf::st_sfc(geoms, crs = cost_surface$crs))
    lcp$costFunction <- cost_surface$costFunction
    lcp$fromCell     <- cells[i]
    lcp$toCell       <- to_cells
    lcp$cost         <- unname(cost)
    if (schema == "fete") {
      lcp$origin_ID      <- i
      lcp$destination_ID <- seq_len(n)[-i]
    }
    out[[i]] <- lcp[!is.na(sf::st_is_valid(lcp)), ]
    if (i %% 10 == 0) message(label, " ", i, "/", n, " origins")
  }
  lcp <- do.call(rbind, out)
  if (schema == "fete") lcp <- lcp[!sf::st_is_empty(lcp), ]
  rownames(lcp) <- NULL
  rm(g); gc(verbose = FALSE)
  lcp
}

#' Snap + compute + save one LCP set on a saved cost surface (03 workflow)
#'
#' @param sites     sf points (siti_hell / siti_rom as saved by 01).
#' @param cs_file   Path to a saved leastcostpath cost surface (.rds).
#' @param strategy  "fete" (CODE PATH A) or "loop" (CODE PATH B).
#' @param out_gpkg  Output GeoPackage for the raw LCPs.
#' @param label     Label for progress messages.
#' @param engine    "graph" (compute_lcps_graph, same result, much faster) or
#'                  "leastcostpath" (the 03 calls verbatim).
#' @return The LCP sf object (invisibly).
run_lcp_set <- function(sites, cs_file, strategy = c("fete", "loop"),
                        out_gpkg, label, engine = c("graph", "leastcostpath")) {
  strategy <- match.arg(strategy)
  engine   <- match.arg(engine)
  # cs_file: path to a saved surface, or a cost-surface object (e.g. with a
  # hydrographic penalty applied in 12)
  cs <- if (is.character(cs_file)) readRDS(cs_file) else cs_file
  # Pass the DEM itself: valid points are extracted locally around each
  # non-traversable site (same nearest pixel as the full as.points() in 03).
  sites <- snap_non_traversable(sites, cs, terra::rast(data_path("dem.tif")), label)
  lcp <- if (engine == "graph")  compute_lcps_graph(cs, sites, strategy, label)
         else if (strategy == "fete") compute_lcps_fete(cs, sites)
         else                    compute_lcps_loop(cs, sites, label)
  sf::st_write(lcp, out_gpkg, delete_dsn = TRUE, quiet = TRUE)
  message(label, ": saved ", basename(out_gpkg), " (", nrow(lcp), " paths)")
  invisible(lcp)
}

#' Resolve raw LCPs to integer site IDs (04_networks.r logic)
#'
#' FETE output carries origin_ID / destination_ID (row indices of the site
#' table). Loop output carries fromCell / toCell only; these are matched to
#' the site cells computed from the UNSNAPPED coordinates on a raster template
#' rebuilt from the cost-surface metadata, exactly as in 04. A site snapped in
#' 03 therefore stays unresolved (NA) — this is the published behaviour
#' (DUR103 in the Roman network). With fix_snapped = TRUE, unresolved cells
#' are assigned to the nearest site within snap_tol metres (sensitivity only).
#'
#' @param lcp      sf from compute_lcps_fete() / compute_lcps_loop().
#' @param sites    sf points in LCP computation order (id = row number).
#' @param cs_meta  List with nrow, ncol, extent, crs (a cost surface works).
#' @return data.frame with from, to, cost (geometry dropped).
resolve_lcp_site_ids <- function(lcp, sites, cs_meta,
                                 fix_snapped = FALSE, snap_tol = 100) {
  lcp <- sf::st_drop_geometry(lcp)
  if ("origin_ID" %in% names(lcp)) {
    return(lcp %>% rename(from = origin_ID, to = destination_ID) %>%
             select(from, to, everything()))
  }
  tmpl <- terra::rast(
    nrow = cs_meta$nrow, ncol = cs_meta$ncol,
    xmin = cs_meta$extent[1], xmax = cs_meta$extent[2],
    ymin = cs_meta$extent[3], ymax = cs_meta$extent[4],
    crs  = cs_meta$crs)
  site_cells <- data.frame(
    id   = seq_len(nrow(sites)),
    cell = terra::cellFromXY(tmpl, sf::st_coordinates(sites)))
  if (fix_snapped) {
    orphan <- setdiff(unique(c(lcp$fromCell, lcp$toCell)), site_cells$cell)
    for (oc in orphan) {
      pt <- sf::st_sfc(sf::st_point(terra::xyFromCell(tmpl, oc)[1, ]),
                       crs = sf::st_crs(sites))
      d  <- as.numeric(sf::st_distance(pt, sites))
      if (min(d) <= snap_tol) {
        message("resolve_lcp_site_ids: cell ", oc, " -> ",
                sites$id_sito[which.min(d)], " (", round(min(d)), " m)")
        site_cells <- rbind(site_cells,
                            data.frame(id = which.min(d), cell = oc))
      }
    }
  }
  lcp %>%
    left_join(site_cells, by = c("fromCell" = "cell")) %>% rename(from = id) %>%
    left_join(site_cells, by = c("toCell"   = "cell")) %>% rename(to   = id) %>%
    select(from, to, everything())
}
