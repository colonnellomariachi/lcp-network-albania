# =============================================================================
# functions/lcp_helpers.R
# Least-cost path computation shared by 03_least_cost_paths.R,
# 11_cost_function_factorial.R and 12_hydrographic_sensitivity.R.
#
# No site is ever moved by the code. Site coordinates are managed by the
# author in data/sites.gpkg; a site on a NoData DEM cell, outside the DEM, or
# on a non-traversable cost-surface cell stops the pipeline (Task 10).
# =============================================================================

#' Blocking check: every site must fall on a valid DEM cell
#'
#' @param sites sf points with an id_sito column.
#' @param dem   SpatRaster (data/dem.tif).
#' @param label Label for the error message.
assert_sites_on_dem <- function(sites, dem, label = "sites") {
  xy   <- sf::st_coordinates(sf::st_transform(sites, terra::crs(dem)))
  cell <- terra::cellFromXY(dem, xy)
  val  <- rep(NA_real_, length(cell))
  val[!is.na(cell)] <- terra::extract(dem, cell[!is.na(cell)])[, 1]
  bad <- is.na(cell) | is.na(val)
  if (any(bad))
    stop(label, ": ", sum(bad), " site(s) outside the DEM or on a NoData cell — ",
         paste(sites$id_sito[bad], collapse = ", "),
         ". Fix the coordinates in data/sites.gpkg; sites are not moved by the code.",
         call. = FALSE)
  dup <- duplicated(cell)
  if (any(dup))
    stop(label, ": sites sharing a DEM cell — ",
         paste(sites$id_sito[cell %in% cell[dup]], collapse = ", "), call. = FALSE)
  invisible(TRUE)
}

#' Blocking check: every site must be traversable on the cost surface
#'
#' Matrix must be loaded before the first check_locations() call: otherwise
#' the S4 subsetting of the dgCMatrix fails in a fresh session.
assert_sites_traversable <- function(sites, cost_surface, label = "sites") {
  loadNamespace("Matrix")
  bad <- vapply(seq_len(nrow(sites)), function(i) {
    res <- tryCatch(leastcostpath::check_locations(cost_surface, sites[i, ]),
                    error = function(e) e)
    if (inherits(res, "error") &&
        !grepl("not traversable|outside the extent", conditionMessage(res)))
      stop("check_locations() failed for ", sites$id_sito[i], ": ",
           conditionMessage(res))
    inherits(res, "error")
  }, logical(1))
  if (any(bad))
    stop(label, ": ", sum(bad), " site(s) not traversable on the cost surface — ",
         paste(sites$id_sito[bad], collapse = ", "),
         ". Fix the coordinates in data/sites.gpkg; sites are not moved by the code.",
         call. = FALSE)
  invisible(TRUE)
}

#' CODE PATH A (package) — all from-every-to-every LCPs in one call
#' Returns sf with origin_ID, destination_ID (row indices of `sites`), cost (s).
compute_lcps_fete <- function(cost_surface, sites) {
  create_FETE_lcps(cost_surface, sites, cost_distance = TRUE)
}

#' CODE PATH B (package) — manual loop over origins (memory workaround)
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
#' the same row filters as create_FETE_lcps(). Verified identical to
#' create_lcp() (costs, geometries, cells) in Task 9.
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

#' Check + compute + save one LCP set on a cost surface (03 workflow)
#'
#' @param sites     sf points (siti_hell / siti_rom as saved by 01).
#' @param cs_file   Path to a saved leastcostpath cost surface (.rds), or a
#'                  cost-surface object (e.g. with a hydrographic penalty).
#' @param strategy  Output schema: "fete" (origin_ID / destination_ID) or
#'                  "loop" (fromCell / toCell only).
#' @param out_gpkg  Output GeoPackage for the raw LCPs.
#' @param label     Label for progress messages.
#' @param engine    "graph" (compute_lcps_graph, same result, much faster) or
#'                  "leastcostpath" (package calls).
#' @return The LCP sf object (invisibly).
run_lcp_set <- function(sites, cs_file, strategy = c("fete", "loop"),
                        out_gpkg, label, engine = c("graph", "leastcostpath")) {
  strategy <- match.arg(strategy)
  engine   <- match.arg(engine)
  cs <- if (is.character(cs_file)) readRDS(cs_file) else cs_file
  assert_sites_on_dem(sites, terra::rast(data_path("dem.tif")), label)
  assert_sites_traversable(sites, cs, label)
  lcp <- if (engine == "graph")  compute_lcps_graph(cs, sites, strategy, label)
         else if (strategy == "fete") compute_lcps_fete(cs, sites)
         else                    compute_lcps_loop(cs, sites, label)
  sf::st_write(lcp, out_gpkg, delete_dsn = TRUE, quiet = TRUE)
  message(label, ": saved ", basename(out_gpkg), " (", nrow(lcp), " paths)")
  invisible(lcp)
}

#' Resolve raw LCPs to integer site IDs (04_networks.r logic)
#'
#' FETE-schema output carries origin_ID / destination_ID (row indices of the
#' site table). Loop-schema output carries fromCell / toCell only; these are
#' matched to the site cells on a raster template rebuilt from the
#' cost-surface metadata, exactly as in 04. Since no site is moved, every cell
#' must resolve: an unresolved cell stops.
#'
#' @param lcp      sf from compute_lcps_*().
#' @param sites    sf points in LCP computation order (id = row number).
#' @param cs_meta  List with nrow, ncol, extent, crs (a cost surface works).
#' @return data.frame with from, to, cost (geometry dropped).
resolve_lcp_site_ids <- function(lcp, sites, cs_meta) {
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
  out <- lcp %>%
    left_join(site_cells, by = c("fromCell" = "cell")) %>% rename(from = id) %>%
    left_join(site_cells, by = c("toCell"   = "cell")) %>% rename(to   = id) %>%
    select(from, to, everything())
  if (anyNA(out$from) || anyNA(out$to))
    stop("LCP cells that do not match any site cell: ",
         sum(is.na(out$from)) + sum(is.na(out$to)), " rows", call. = FALSE)
  out
}
