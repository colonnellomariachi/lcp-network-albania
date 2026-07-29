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
