# =============================================================================
# 05_centrality.R — Centrality metric extraction and export
#
# Computes harmonic centrality and normalised betweenness for both networks
# and writes the combined table used by all downstream analysis and figures.
#
# Input:  output/rds/net_hell.rds
#         output/rds/net_rom.rds
#         output/rds/nodes_hell.rds
#         output/rds/nodes_rom.rds
#         output/rds/siti_hell.rds
#         output/rds/siti_rom.rds
# Output: output/tables/centrality_comparison.csv
# =============================================================================

net_hell   <- readRDS(rds_path("net_hell.rds"))
net_rom    <- readRDS(rds_path("net_rom.rds"))
nodes_hell <- readRDS(rds_path("nodes_hell.rds"))
nodes_rom  <- readRDS(rds_path("nodes_rom.rds"))
siti_hell  <- readRDS(rds_path("siti_hell.rds"))
siti_rom   <- readRDS(rds_path("siti_rom.rds"))

# --- Compute metrics ---------------------------------------------------------
V(net_hell)$harmonic          <- igraph::harmonic_centrality(net_hell, normalized = TRUE)
V(net_hell)$betweenness_norm  <- igraph::betweenness(net_hell, normalized = TRUE)
V(net_hell)$degree            <- igraph::degree(net_hell)

V(net_rom)$harmonic           <- igraph::harmonic_centrality(net_rom, normalized = TRUE)
V(net_rom)$betweenness_norm   <- igraph::betweenness(net_rom, normalized = TRUE)
V(net_rom)$degree             <- igraph::degree(net_rom)

# --- Build export data frames ------------------------------------------------
export_hell <- data.frame(
  id_sito          = nodes_hell$id_sito[match(V(net_hell)$name, nodes_hell$id)],
  phase            = "hellenistic",
  degree           = V(net_hell)$degree,
  harmonic         = V(net_hell)$harmonic,
  betweenness_norm = V(net_hell)$betweenness_norm,
  degree_raw       = V(net_hell)$degree,
  sf::st_coordinates(siti_hell)[match(V(net_hell)$name, nodes_hell$id), ]
)

export_rom <- data.frame(
  id_sito          = nodes_rom$id_sito[match(V(net_rom)$name, nodes_rom$id)],
  phase            = "roman",
  degree           = V(net_rom)$degree,
  harmonic         = V(net_rom)$harmonic,
  betweenness_norm = V(net_rom)$betweenness_norm,
  degree_raw       = V(net_rom)$degree,
  sf::st_coordinates(siti_rom)[match(V(net_rom)$name, nodes_rom$id), ]
)

centrality_df <- rbind(export_hell, export_rom)

# --- Write -------------------------------------------------------------------
write.csv(centrality_df, table_path("centrality_comparison.csv"), row.names = FALSE)
message("Saved centrality_comparison.csv (",
        nrow(centrality_df), " rows)")
