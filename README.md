# South Illyria Least-Cost Path Network Analysis

## Project purpose

This repository contains the full computational pipeline for a landscape
archaeology study modelling ancient connectivity in southern Illyria (modern
Albania) during the Hellenistic (300–31 BC) and Roman (31 BC – AD 450) periods.
The method constructs least-cost path (LCP) networks from a 25 m digital
elevation model, applies cost functions appropriate to each period (Tobler's
walking speed / wheeled transport), filters edges by travel-time thresholds,
and computes standard network-centrality metrics (degree, harmonic centrality,
normalised betweenness). The spatial structure of the Roman network is further
tested with Leiden community detection and two null models. A validation step
compares modelled routes against the digitised Via Egnatia itinerary, using a
locally corrected implementation of the path deviation index (see
"Known issue: PDI validation" below).

The results are published in:
> [CITATION PLACEHOLDER — to be updated with journal reference and DOI]

Archived dataset:
> Zenodo DOI: [PLACEHOLDER]

---

## Requirements

| Component      | Version tested | Notes |
|-----------------|---------------|-------|
| R               | 4.5.1 (2025-06-13) | |
| leastcostpath   | 2.0.13        | Pinned, not a minimum. See "Known issue" below — behaviour on self-intersecting polygons is version- and GEOS-dependent, and has not been verified against other releases. |
| GEOS            | 3.13.1        | System dependency of `sf`. Affects `st_area()` behaviour on invalid geometries; do not assume a different GEOS version reproduces the PDI bug identically. |
| GDAL            | 3.11.0        | System dependency of `sf`/`terra`. |
| PROJ            | 9.6.0         | System dependency of `sf`/`terra`. |
| igraph          | ≥ 2.0.0       | |
| sf              | 1.0.21        | |
| terra           | ≥ 1.7         | |
| dplyr           | ≥ 1.1         | |
| tidyr           | ≥ 1.3         | |
| ggplot2         | ≥ 3.5         | |
| ggrepel         | ≥ 0.9         | |
| here            | ≥ 1.0         | |

Install R package dependencies with:

```r
install.packages(c("leastcostpath", "igraph", "sf", "terra",
                   "dplyr", "tidyr", "ggplot2", "ggrepel", "here"))
```

System libraries (GEOS/GDAL/PROJ) must be installed separately and are not
managed by this script; see the `sf` package installation guide for your
platform. A full session snapshot is written to
`output/tables/session_info.txt` on every run — compare it against the
versions above if a result cannot be reproduced.

---

## How to run

1. Clone or download the repository.
2. Download the large data files from Zenodo (DOI above) and place them
   in `data/` as listed in the Input data section below.
3. Open `south ill lcp.Rproj` in RStudio (or `cd` to the project root in a
   terminal), then:

```r
source("run_all.R")
```

Individual scripts can be sourced independently after running `00_setup.R`,
provided their input RDS files already exist in `output/rds/`.

---

## Input data

| File | Description | Source |
|------|-------------|--------|
| `data/dem.tif` | 25 m DEM, EPSG:32634, RMSE 2.9 m | [PLACEHOLDER: data source/citation] |
| `data/sites.gpkg` | 144 archaeological sites with chronological attributes ; includes DUR024 corrected in two steps — a raw coordinate fix, then a snap to the digitised route (documented in the Zenodo supplementary material, not in this repository) |Moderato, M. (2021). Dinamiche insediative nel paesaggio storico di Durrës fra età classica e tarda antichità. Edipuglia.
 |
| `data/egnatia_itinere.gpkg` | Digitised Via Egnatia itinerary; feature `Dyrrhachium-Scampis` used for validation | Itiner-e (De Soto et al., 2025) |

---

## Known issue: PDI validation (fixed locally)

`leastcostpath::PDI_validation()` (v. 2.0.13) computes the path deviation
index from a polygon built between the modelled and comparison lines, calling
`sf::st_area()` without first checking or repairing geometric validity. Where
the two lines cross, the resulting polygon self-intersects, and `st_area()`
returns a signed algebraic area that can understate the true deviation by
more than two orders of magnitude; the same corrupted areas can also cause
`which.min()` to select the wrong candidate polygon.

A corrected implementation, `pdi_fixed()`, is provided in
`R/functions/pdi_validation_fixed.R`. It applies `sf::st_make_valid()` to both
candidate polygons before any area is computed and before selection, and sums
all resulting polygon parts. `08_egnatia_validation.R` calls this function
alongside the untouched package function, so both the original and corrected
values are retained (`egnatia_validation_segments.csv` / `_full.csv` for the
former, `egnatia_pdi_final.csv` for the latter).

Full diagnosis, the correction procedure, the effect on every reported value,
and independent geometric verification are documented in the supplementary
material accompanying the manuscript (Zenodo deposit). An issue describing
the bug has been filed against the upstream package (Lewis, 2023):
[ISSUE URL PLACEHOLDER].

---

## Output description

| Path | Contents |
|------|----------|
| `output/tables/centrality_comparison.csv` | Per-site degree, harmonic centrality, and normalised betweenness for both phases — the primary analytical output |
| `output/tables/threshold_sweep_roman.csv` | Roman network metrics across 30–300 min thresholds |
| `output/tables/betweenness_concentration_sweep.csv` | Betweenness concentration (top-1 share, Gini) at matched network density, Hellenistic vs Roman |
| `output/tables/community_by_sitetype.csv` | Leiden community × site-type cross-table |
| `output/tables/null_model_results.csv` | Null model p-values |
| `output/tables/egnatia_validation_segments.csv` | PDI and buffer overlap per route segment, **original package function, pre-correction** — retained for comparison only |
| `output/tables/egnatia_validation_full.csv` | PDI for the full Dyrrachium–Scampis route, **original package function, pre-correction** — retained for comparison only |
| `output/tables/egnatia_pdi_final.csv` | Corrected PDI values, all segments and full route — canonical source for the manuscript |
| `output/tables/egnatia_pdi_comparison_bug.csv` | Side-by-side comparison, original vs corrected PDI, all cases |
| `output/tables/egnatia_corridor_containment.csv` | Attested-route containment within modelled cost-corridor quantiles, per segment and cost function |
| `output/tables/full_route_truncated_comparison.csv` | Full-route PDI against a comparison line truncated to match the combined extent of the three segments |
| `output/tables/pdi_geom_diagnostics.csv` | Geometry class, part count, and area-sum check for corrected PDI polygons (segment-level cases) |
| `output/tables/pdi_independent_check.csv` | Resampling-based independent validation of corrected PDI values |
| `output/tables/session_info.txt` | R session info for reproducibility |
| `output/images/fig_boxplot_centrality.png` | Boxplots of centrality by phase |
| `output/images/fig_scatter_dualphase.png` | Dual-phase site scatter plot |
| `output/images/fig_map_degree.png` | Geographic map — degree centrality |
| `output/images/fig_map_harmonic.png` | Geographic map — harmonic centrality |
| `output/images/fig_map_betweenness.png` | Geographic map — betweenness |
| `output/images/qc/*.png` | PDI polygon quality-control panels (post-`st_make_valid()`), not used in the manuscript figures |
| `output/rds/*.rds` | Intermediate objects (networks, edge tables, cost surfaces, LCPs, digitised route) |

---

## Verification

After running the pipeline, compare the regenerated tables against the
baseline copies retained in the project root:

```r
baseline <- read.csv("centrality_comparison.csv")
new_file <- read.csv("output/tables/centrality_comparison.csv")
all.equal(baseline, new_file)   # must return TRUE

baseline_pdi <- read.csv("egnatia_pdi_final.csv")
new_pdi <- read.csv("output/tables/egnatia_pdi_final.csv")
all.equal(baseline_pdi, new_pdi)   # must return TRUE
```

Any discrepancy indicates a behaviour change and must be investigated before
updating the manuscript.

---

## Repository structure

```
├── R/
│   ├── 00_setup.R              # libraries, paths, all parameters 
│   ├── 01_chronology.R
│   ├── 02_cost_surfaces.R
│   ├── 03_least_cost_paths.R
│   ├── 04_networks.R
│   ├── 05_centrality.R
│   ├── 06_community_detection.R
│   ├── 07_null_models.R
│   ├── 08_egnatia_validation.R # calls both PDI_validation() and pdi_fixed()
│   ├── 09_figures.R
│   ├── 10_discussion_checks.R  # chronological and network-structural checks
│   │                           # supporting Discussion Sections 5.5–5.6
│   │                           # (site-count vs 146 BC boundary, road-station
│   │                           # module membership) 
│   └── functions/
│       ├── chronology_helpers.R
│       ├── network_helpers.R
│       ├── route_helpers.R
│       └── pdi_validation_fixed.R   # pdi_fixed(): corrected PDI implementation
├── data/                       # inputs only — never written to
├── output/
│   ├── tables/
│   ├── images/
│   │   └── qc/                 # PDI polygon QC panels
│   └── rds/
├── run_all.R
├── README.md
└── LICENSE
```

Superseded and exploratory scripts are not tracked in this repository; where
a documented result depended on such a script, that dependency is recorded in
the Zenodo supplementary material rather than as a file here.

```
```

---

## License

Code: [PLACEHOLDER — e.g., MIT]. The archaeological dataset carries a
separate licence, described in the Zenodo record rather than in this
repository; see the data-sharing note in the manuscript's data availability
statement before reusing `sites.gpkg`.