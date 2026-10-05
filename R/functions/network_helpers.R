# =============================================================================
# functions/network_helpers.R
# Shared helpers for network construction and centrality.
# =============================================================================

#' Collapse directional edge pairs into undirected edges
#'
#' LCP computation produces two rows per site pair (i→j and j→i). This
#' function averages the two cost values into one undirected edge.
#'
#' @param from  Integer or character vector of origin node IDs.
#' @param to    Integer or character vector of destination node IDs.
#' @param cost  Numeric vector of travel costs (same length as from/to).
#' @return  data.frame with columns: from, to, cost_mean, n_directions.
#'          n_directions == 1 means only one direction was computed (flag for
#'          inspection).
collapse_directional_edges <- function(from, to, cost) {
  data.frame(
    from = from, to = to, cost = cost,
    pair_from = pmin(from, to), pair_to = pmax(from, to)
  ) %>%
    group_by(pair_from, pair_to) %>%
    summarise(cost_mean    = mean(cost, na.rm = TRUE),
              n_directions = n(), .groups = "drop") %>%
    rename(from = pair_from, to = pair_to)
}

#' Build an undirected igraph network from a filtered edge table
#'
#' @param edges     data.frame with columns from, to, cost_mean (at minimum).
#' @param nodes     data.frame of node attributes; first column must be the
#'                  node ID that matches edges$from / edges$to.
#' @param threshold Travel-cost threshold: edges with cost_mean >= threshold
#'                  are excluded.
#' @return  An igraph graph object with vertex attributes degree, closeness,
#'          and betweenness already computed.
build_network <- function(edges, nodes, threshold) {
  ef <- edges %>% filter(cost_mean < threshold)
  g  <- graph_from_data_frame(d = ef, vertices = nodes, directed = FALSE)
  V(g)$degree      <- igraph::degree(g)
  V(g)$closeness   <- igraph::closeness(g)
  V(g)$betweenness <- igraph::betweenness(g)
  g
}

# -----------------------------------------------------------------------------
# Factorial / sensitivity helpers (11_cost_function_factorial.R,
# 12_hydrographic_sensitivity.R)
# -----------------------------------------------------------------------------

# Gini coefficient — identical to 04b
gini <- function(x) {
  x <- sort(x[!is.na(x)])
  n <- length(x)
  if (sum(x) == 0) return(NA_real_)
  sum((2 * seq_len(n) - n - 1) * x) / (n * sum(x))
}

# Network from resolved LCPs: 04 (collapse → threshold → graph) + 05 metrics
build_cell_network <- function(lcp, nodes, threshold) {
  lcp$cost_min <- lcp$cost / 60
  edges <- collapse_directional_edges(lcp$from, lcp$to, lcp$cost_min)
  ef    <- edges %>% filter(cost_mean < threshold)
  if (any(is.na(ef$from) | is.na(ef$to)))
    stop("Unresolved (NA) site IDs survive the threshold filter")
  g <- graph_from_data_frame(d = ef, vertices = nodes, directed = FALSE)
  V(g)$degree           <- igraph::degree(g)
  V(g)$closeness        <- igraph::closeness(g)
  V(g)$betweenness      <- igraph::betweenness(g)
  V(g)$harmonic         <- igraph::harmonic_centrality(g, normalized = TRUE)
  V(g)$betweenness_norm <- igraph::betweenness(g, normalized = TRUE)
  list(edges = edges, edges_filtered = ef, net = g)
}

composition_row <- function(g, cell) {
  deg <- igraph::degree(g)
  cmp <- igraph::components(g)
  data.frame(
    cell          = cell,
    n_nodes       = vcount(g),
    n_edges       = ecount(g),
    density       = edge_density(g),
    median_degree = median(deg),
    median_degree_non_isolates = median(deg[deg > 0]),
    n_isolates    = sum(deg == 0),
    isolates      = paste(sort(V(g)$id_sito[deg == 0]), collapse = ";"),
    n_components  = cmp$no,
    giant_size    = max(cmp$csize),
    giant_pct     = 100 * max(cmp$csize) / vcount(g),
    stringsAsFactors = FALSE
  )
}

centrality_table <- function(g, cell) {
  n  <- vcount(g)
  df <- data.frame(
    cell             = cell,
    id_sito          = V(g)$id_sito,
    degree           = V(g)$degree,
    degree_norm      = V(g)$degree / (n - 1),
    harmonic         = V(g)$harmonic,
    betweenness_norm = V(g)$betweenness_norm,
    stringsAsFactors = FALSE
  )
  cmp <- igraph::components(g)
  df$in_giant         <- cmp$membership == which.max(cmp$csize)
  df$rank_degree      <- rank(-df$degree_norm,      ties.method = "min")
  df$rank_harmonic    <- rank(-df$harmonic,         ties.method = "min")
  df$rank_betweenness <- rank(-df$betweenness_norm, ties.method = "min")
  df$n_cell           <- n
  df
}

concentration_row <- function(g, cell) {
  b  <- igraph::betweenness(g, normalized = TRUE)
  bs <- sort(b, decreasing = TRUE)
  data.frame(
    cell            = cell,
    top1_share      = if (sum(bs) > 0) bs[1] / sum(bs) else NA_real_,
    ratio_1st_2nd   = if (bs[2] > 0) bs[1] / bs[2] else NA_real_,
    top5_share      = if (sum(bs) > 0) sum(bs[1:5]) / sum(bs) else NA_real_,
    gini            = gini(b),
    freeman_centralization =
      igraph::centr_betw(g, directed = FALSE, normalized = TRUE)$centralization,
    top_node        = V(g)$id_sito[which.max(b)],
    top_node_betweenness = max(b),
    second_node     = V(g)$id_sito[order(-b)[2]],
    stringsAsFactors = FALSE
  )
}

#' Induced subgraph on a set of sites, with centralities recomputed
#'
#' Edges are defined pair by pair (pairwise travel cost vs a fixed threshold),
#' so the network restricted to a subset of sites is the induced subgraph of
#' the full network. Vertex centrality attributes are recomputed on it.
induced_site_network <- function(g, ids) {
  sub <- igraph::induced_subgraph(g, which(V(g)$id_sito %in% ids))
  V(sub)$degree           <- igraph::degree(sub)
  V(sub)$closeness        <- igraph::closeness(sub)
  V(sub)$betweenness      <- igraph::betweenness(sub)
  V(sub)$harmonic         <- igraph::harmonic_centrality(sub, normalized = TRUE)
  V(sub)$betweenness_norm <- igraph::betweenness(sub, normalized = TRUE)
  sub
}
