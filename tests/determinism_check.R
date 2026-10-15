# =============================================================================
# tests/determinism_check.R — are the cost surfaces and the R-W network
# reproduced bit for bit?
#
# Run in a FRESH R session after run_all.R. Recomputes, with the pipeline
# code, (1) both cost surfaces from the DEM and (2) all pairwise least-cost
# paths of the Roman wheeled-transport network (R-W), then compares them with
# the objects written by the run:
#   - conductance matrices            identical()
#   - LCP costs and cells             identical()   (lcp_roman.gpkg)
#   - collapsed edge table            identical()   (edges_rom.rds)
#   - edges below the threshold       identical()   (edges_rom_filtered.rds)
# Any difference means an uncontrolled source of randomness: the script stops.
#
# Not part of run_all.R (~45 min). Usage (project root):
#   Rscript tests/determinism_check.R
# Output: output/tables/determinism_check.md
# =============================================================================

library(here)
suppressMessages(source(here("R", "00_setup.R")))
loadNamespace("Matrix")
t0 <- Sys.time()
res <- list()
chk <- function(name, ok, detail = "") {
  res[[length(res) + 1]] <<- data.frame(check = name, identical = isTRUE(ok), detail = detail,
                                        stringsAsFactors = FALSE)
  message(if (isTRUE(ok)) "  OK    " else "  DIFF  ", name, if (nzchar(detail)) paste0(" — ", detail) else "")
}

# --- 1. Cost surfaces (same calls as 02_cost_surfaces.R) ---------------------
dem <- rast(data_path("dem.tif"))
cmp_surface <- function(cost_fn, file) {
  new <- leastcostpath::create_slope_cs(dem, cost_function = cost_fn, neighbours = NEIGHBOURS)
  old <- readRDS(rds_path(file))
  A <- new$conductanceMatrix; B <- old$conductanceMatrix
  chk(sprintf("%s: matrice di conduttanza (struttura: dim, i, p)", file),
      identical(dim(A), dim(B)) && identical(A@i, B@i) && identical(A@p, B@p),
      sprintf("%d valori non nulli", length(A@x)))
  chk(sprintf("%s: matrice di conduttanza (valori)", file), identical(A@x, B@x),
      if (identical(A@x, B@x)) "" else sprintf("max |diff| = %g", max(abs(A@x - B@x))))
  meta <- setdiff(names(new), "conductanceMatrix")
  chk(sprintf("%s: metadati", file), identical(new[meta], old[meta]))
  rm(old, A, B); gc(verbose = FALSE)
  new
}
message("Recomputing the Tobler surface...")
cs_t <- cmp_surface(COST_FN_HELL, "cost_surface_hell.rds"); rm(cs_t); gc(verbose = FALSE)
message("Recomputing the wheeled-transport surface...")
cs_w <- cmp_surface(COST_FN_ROM, "cost_surface_rom.rds")

# --- 2. R-W cost matrix and edges (same calls as 03 / 04) --------------------
message("Recomputing the R-W least-cost paths on the recomputed surface...")
siti_rom <- readRDS(rds_path("siti_rom.rds"))
assert_sites_traversable(siti_rom, cs_w, "R-W")
lcp_new <- compute_lcps_graph(cs_w, siti_rom, "loop", "R-W check")
lcp_old <- sf::st_read(rds_path("lcp_roman.gpkg"), quiet = TRUE)
chk("lcp_roman.gpkg: numero di percorsi", nrow(lcp_new) == nrow(lcp_old), sprintf("%d", nrow(lcp_new)))
chk("lcp_roman.gpkg: celle di origine e destinazione",
    identical(as.numeric(lcp_new$fromCell), as.numeric(lcp_old$fromCell)) &&
    identical(as.numeric(lcp_new$toCell), as.numeric(lcp_old$toCell)))
chk("lcp_roman.gpkg: costi (secondi)", identical(lcp_new$cost, lcp_old$cost),
    if (identical(lcp_new$cost, lcp_old$cost)) "" else
      sprintf("max |diff| = %g s", max(abs(lcp_new$cost - lcp_old$cost))))
chk("lcp_roman.gpkg: geometrie dei percorsi",
    isTRUE(all.equal(sf::st_coordinates(lcp_new), sf::st_coordinates(lcp_old),
                     tolerance = 0, check.attributes = FALSE)))

cs_meta <- cs_w[c("nrow", "ncol", "extent", "crs")]
net_new <- build_cell_network(resolve_lcp_site_ids(lcp_new, siti_rom, cs_meta),
                              readRDS(rds_path("nodes_rom.rds")), ROM_THRESH)
ek <- function(e) as.data.frame(e[order(e$from, e$to), c("from", "to", "cost_mean", "n_directions")])
e_old <- readRDS(rds_path("edges_rom.rds")); f_old <- readRDS(rds_path("edges_rom_filtered.rds"))
chk("edges_rom.rds: coppie e costo medio (min)",
    identical(ek(net_new$edges)$cost_mean, ek(e_old)$cost_mean) &&
    identical(ek(net_new$edges)[, 1:2], ek(e_old)[, 1:2]), sprintf("%d coppie", nrow(e_old)))
chk("edges_rom_filtered.rds: archi sotto soglia",
    identical(ek(net_new$edges_filtered)[, 1:2], ek(f_old)[, 1:2]) &&
    identical(ek(net_new$edges_filtered)$cost_mean, ek(f_old)$cost_mean),
    sprintf("%d archi", nrow(f_old)))
cc <- read.csv(table_path("centrality_comparison.csv"), stringsAsFactors = FALSE)
cc <- cc[cc$phase == "roman", ]
g <- net_new$net
chk("centrality_comparison.csv (romano): grado e betweenness per sito",
    isTRUE(all.equal(cc$betweenness_norm[match(V(g)$id_sito, cc$id_sito)], V(g)$betweenness_norm)) &&
    identical(as.integer(cc$degree[match(V(g)$id_sito, cc$id_sito)]), as.integer(V(g)$degree)))

# --- Report ------------------------------------------------------------------
res <- do.call(rbind, res)
ok <- all(res$identical)
md <- c(
  "# Controllo di determinismo",
  "",
  sprintf("Generato da `tests/determinism_check.R` il %s, in una sessione R nuova, dopo la run completa. Durata: %s.",
          Sys.Date(), format(round(difftime(Sys.time(), t0), 1))),
  "",
  "Le superfici di costo e tutti i percorsi a costo minimo della rete R-W sono stati ricalcolati con il codice della pipeline e confrontati con gli oggetti scritti dalla run (`identical()`, cioè bit per bit; tolleranza zero per le geometrie).",
  "",
  sprintf("**Esito: %s.**", if (ok) "identici in tutti i controlli" else "DIFFERENZE — resta una fonte di casualità non controllata"),
  "",
  "| controllo | identico | dettaglio |", "|---|---|---|",
  sprintf("| %s | %s | %s |", res$check, ifelse(res$identical, "sì", "**no**"), res$detail)
)
writeLines(md, table_path("determinism_check.md"), useBytes = TRUE)
if (!ok) stop("Determinism check FAILED: ", paste(res$check[!res$identical], collapse = "; "))
message("Determinism check passed (", nrow(res), " checks). Saved determinism_check.md")
