# =============================================================================
# pdi_qc_plots.R — Visual QC for PDI polygon validity (Task 3)
#
# For all 9 cases (3 segments × 3 cost functions: wheeled, tobler, straight)
# produces a PNG in output/images/qc/ overlaying:
#   - the attested route segment (black, lwd 2)
#   - the modelled path / straight line (red, lwd 2)
#   - the PDI polygon after st_make_valid() (blue, alpha 0.3, no border)
#   - crossing points between the two lines (orange solid circles)
#
# Acceptance criterion: the blue area must cover the complete strip between
# the two lines. Any uncovered strip indicates the polygon is still broken.
#
# Also produces output/images/qc/pdi_qc_panel.png — 9-panel grid.
#
# Run standalone after 08_egnatia_validation.R has completed:
#   source(here("R", "00_setup.R"))
#   source(here("R", "pdi_qc_plots.R"))
# =============================================================================

library(ggplot2)
library(patchwork)

dir.create(image_path("qc"), showWarnings = FALSE, recursive = TRUE)

wp_snapped     <- readRDS(rds_path("wp_snapped.rds"))
known_segments <- readRDS(rds_path("egnatia_known_segments.rds"))
egnatia_full   <- st_sf(geometry = readRDS(rds_path("egnatia_stitched.rds")))

seg_labels_qc <- c(
  "DUR001 -> DUR022",
  "DUR022 -> DUR024",
  "DUR024 -> DUR017"
)

# Helper: straight-line sf between two waypoints
make_straight_qc <- function(from_pt, to_pt) {
  st_sf(geometry = st_sfc(
    st_linestring(rbind(st_coordinates(from_pt)[1, 1:2],
                        st_coordinates(to_pt)[1, 1:2])),
    crs = CRS_UTM))
}

# Helper: build PDI polygon (fixed) and return as sf
build_pdi_poly <- function(lcp, comparison) {
  lcps <- list(lcp, sf::st_reverse(lcp))
  polys <- lapply(lcps, function(x) {
    x$geometry[[1]][1L, ] <- comparison$geometry[[1]][1L, ]
    x$geometry[[1]][nrow(x$geometry[[1]]), ] <-
      comparison$geometry[[1]][nrow(comparison$geometry[[1]]), ]
    ring <- rbind(sf::st_coordinates(sf::st_reverse(x)),
                  sf::st_coordinates(comparison))
    p <- sf::st_sfc(sf::st_polygon(list(ring)), crs = sf::st_crs(comparison))
    sf::st_make_valid(p)
  })
  areas <- sapply(polys, function(p) sum(as.numeric(sf::st_area(p))))
  chosen <- polys[[which.min(areas)]]
  sf::st_as_sf(data.frame(geometry = chosen))
}

# Helper: find crossing points between two lines
find_crossings <- function(line1, line2) {
  xings <- tryCatch(
    sf::st_intersection(sf::st_geometry(line1), sf::st_geometry(line2)),
    error = function(e) NULL
  )
  if (is.null(xings) || length(xings) == 0) return(NULL)
  pts <- suppressWarnings(sf::st_cast(xings, "POINT"))
  if (length(pts) == 0) return(NULL)
  sf::st_as_sf(data.frame(geometry = pts))
}

make_qc_panel <- function(lcp_sf, comparison_sf, title) {
  pdi_poly  <- build_pdi_poly(lcp_sf, comparison_sf)
  crossings <- find_crossings(lcp_sf, comparison_sf)

  # Unified bounding box
  bb <- sf::st_bbox(sf::st_union(
    sf::st_geometry(lcp_sf),
    sf::st_geometry(comparison_sf)
  ))
  pad <- 0.08 * max(bb["xmax"] - bb["xmin"], bb["ymax"] - bb["ymin"])

  p <- ggplot() +
    geom_sf(data = pdi_poly, fill = scales::alpha("steelblue", 0.3),
            colour = NA) +
    geom_sf(data = comparison_sf, colour = "black", linewidth = 1.2) +
    geom_sf(data = lcp_sf,        colour = "red",   linewidth = 1.0)

  if (!is.null(crossings) && nrow(crossings) > 0) {
    p <- p + geom_sf(data = crossings, colour = "darkorange",
                     shape = 16, size = 2.5)
  }

  p +
    coord_sf(crs   = CRS_UTM,
             xlim  = c(bb["xmin"] - pad, bb["xmax"] + pad),
             ylim  = c(bb["ymin"] - pad, bb["ymax"] + pad),
             expand = FALSE) +
    labs(title = title, x = NULL, y = NULL) +
    theme_minimal(base_size = 8) +
    theme(plot.title = element_text(size = 7, face = "bold"))
}

# --- Generate individual PNGs and collect panels ----------------------------
all_panels <- list()

seg_cases <- list(
  list(seg = 1, o = 1, d = 2),
  list(seg = 2, o = 2, d = 3),
  list(seg = 3, o = 3, d = 4)
)
cf_cases <- list(
  list(tag = "wheeled", label = "wheeled transport"),
  list(tag = "tobler",  label = "tobler"),
  list(tag = "straight", label = "straight baseline")
)

for (sc in seg_cases) {
  kseg <- known_segments[[sc$seg]]
  for (cf in cf_cases) {
    lcp_i <- if (cf$tag == "straight") {
      make_straight_qc(wp_snapped[sc$o, ], wp_snapped[sc$d, ])
    } else {
      readRDS(rds_path(sprintf("lcp_egnatia_%s_seg%d.rds", cf$tag, sc$seg)))
    }

    seg_lbl <- seg_labels_qc[sc$seg]
    title_i <- sprintf("seg%d | %s", sc$seg, cf$label)
    p_i <- make_qc_panel(lcp_i, kseg, title_i)
    all_panels[[length(all_panels) + 1]] <- p_i

    fn <- sprintf("pdi_qc_seg%d_%s.png", sc$seg, cf$tag)
    ggsave(image_path("qc", fn), p_i, width = 5, height = 4, dpi = 200)
    message("Saved ", fn)
  }
}

# Full-route cases
full_cases <- list(
  list(tag = "wheeled", label = "wheeled transport",
       lcp = readRDS(rds_path("lcp_egnatia_wheeled_full.rds"))),
  list(tag = "tobler", label = "tobler",
       lcp = readRDS(rds_path("lcp_egnatia_tobler_full.rds"))),
  list(tag = "straight", label = "straight baseline",
       lcp = make_straight_qc(wp_snapped[1, ], wp_snapped[4, ]))
)

for (fc in full_cases) {
  title_i <- sprintf("full | %s", fc$label)
  p_i <- make_qc_panel(fc$lcp, egnatia_full, title_i)
  fn <- sprintf("pdi_qc_full_%s.png", fc$tag)
  ggsave(image_path("qc", fn), p_i, width = 5, height = 4, dpi = 200)
  message("Saved ", fn)
}

# --- 9-panel grid (3 segments × 3 cost functions) ---------------------------
# all_panels has 9 entries (3 segs × 3 cf, in row-major order)
p_grid <- wrap_plots(all_panels, ncol = 3) +
  plot_annotation(
    title = "PDI polygon QC — all segments after st_make_valid()\nBlue = PDI area | Red = modelled path | Black = attested | Orange = crossings",
    theme = theme(plot.title = element_text(size = 9))
  )

ggsave(image_path("qc", "pdi_qc_panel.png"),
       p_grid, width = 15, height = 9, dpi = 200)
message("Saved pdi_qc_panel.png")
message("QC plots complete. Inspect output/images/qc/ — blue area must cover full strip.")
