# South Illyria least-cost path networks

R pipeline for a landscape-archaeology study of connectivity in southern
Illyria (central Albania) in the Hellenistic (300–31 BC) and Roman (31 BC – AD
450) periods. Least-cost paths between archaeological sites are computed on a
DEM with two cost functions (Tobler's hiking function and wheeled transport),
filtered by travel-time thresholds into networks, and compared through
centrality, community detection and null models. The modelled routes are
validated against the Via Egnatia as digitised in Itiner-e.

Article: [ARTICLE CITATION]

---

## Repository structure

```
├── R/                    analysis scripts 00–13 and shared functions (R/functions/)
├── tests/                regression baselines and stand-alone checks
├── output/
│   ├── tables/           result tables (CSV) and session info
│   ├── images/           Figures 1–10 of the article
│   └── rds/              intermediate objects (not in the repository; see "How to run")
├── supplementary/        README for the supplementary documents S1 and S2 (on Zenodo)
├── data/                 input data (not in the repository; see "Data")
├── run_all.R             runs the whole pipeline
└── LICENSE
```

Scripts, in the order run by `run_all.R`:

| Script | Function |
|---|---|
| `00_setup.R` | Libraries, path helpers and all global parameters (phase limits, thresholds, seeds) |
| `01_chronology.R` | Assigns sites to the Hellenistic and Roman phases (minimum overlap 25 years): 71 and 94 sites, 46 in both |
| `02_cost_surfaces.R` | Tobler and wheeled-transport cost surfaces from the DEM (16 neighbours) |
| `03_least_cost_paths.R` | Least-cost paths between all pairs of sites (Hellenistic sites with Tobler, Roman sites with wheeled transport) |
| `04_networks.R` | Networks below the travel-time threshold (240 min Tobler, 150 min wheeled), centrality, threshold sweep |
| `04b_betweenness_concentration_sweep.R` | Betweenness concentration across thresholds |
| `05_centrality.R` | Exports per-site centrality (`centrality_comparison.csv`) |
| `06_community_detection.R` | Weighted Leiden communities of the largest component of the Roman wheeled-transport network |
| `07_null_models.R` | Modularity against 999 degree-preserving and 999 spatial null networks |
| `08_egnatia_validation.R` | Via Egnatia: route stitching, per-segment and full-route LCPs, corrected PDI, cost corridors and containment |
| `10_discussion_checks.R` | Chronological and network checks cited in the Discussion (post-146 BC sites, road stations, site typology, late-antique horizon) |
| `11_cost_function_factorial.R` | 2 × 2 design, site set × cost function (H-T, H-W, R-T, R-W) |
| `09_figures.R` | Figures 1–10 (runs after `11`, whose tables it reads) |
| `12_hydrographic_sensitivity.R` | Sensitivity to a river-crossing penalty (× 5, × 20) |
| `13_size_horizon_sensitivity.R` | Sensitivity to the end of the Roman phase (AD 300) and to network size (71-site subsamples) |

`R/functions/` holds the shared helpers (chronology, LCP computation, network
construction, route stitching, site labels and the corrected PDI).
`R/pdi_qc_plots.R` draws quality-control plots of the PDI polygons and is not
run by `run_all.R`.

---

## Data

The four input files go in `data/`. Download them from the Zenodo deposit
[ZENODO CONCEPT DOI], version [ZENODO VERSION].

| File | Contents | Source |
|---|---|---|
| `sites.gpkg` | 143 archaeological sites with chronological attributes, EPSG:32634 | Moderato, M. (2021). *Dinamiche insediative nel paesaggio storico di Durrës fra età classica e tarda antichità*. Edipuglia |
| `dem.tif` | DEM, 25 m, EPSG:32634, used as it is | EU-DEM v1.1, Copernicus Land Monitoring Service |
| `egnatia_itinere.gpkg` | Digitised Roman roads; the `Dyrrhachium-Scampis` feature is used for validation | Itiner-e (de Soto et al. 2025) |
| `river polygon.gpkg` | Polygons of the main rivers and lakes, used only by `12` | Produced by the author |

---

## Requirements

Versions of the last complete run (`output/tables/session_info.txt`):

| Component | Version |
|---|---|
| R | 4.5.1 (2025-06-13), Windows 11 x64 |
| leastcostpath | 2.0.13 |
| sf | 1.0-21 |
| terra | 1.8-93 |
| igraph | 2.1.4 |
| dplyr | 1.1.4 |
| tidyr | 1.3.1 |
| ggplot2 | 4.0.0 |
| ggrepel | 0.9.6 |
| ggspatial | 1.1.10 |
| patchwork | 1.3.2 |
| here | 1.0.2 |
| GEOS / GDAL / PROJ | 3.13.1 / 3.11.0 / 9.6.0 |

Figure 1 also needs `rnaturalearth` and `rnaturalearthhires` (for the
country boundaries of the locator map).

```r
install.packages(c("leastcostpath", "sf", "terra", "igraph", "dplyr", "tidyr",
                   "ggplot2", "ggrepel", "ggspatial", "patchwork", "here",
                   "rnaturalearth"))
install.packages("rnaturalearthhires", repos = "https://ropensci.r-universe.dev")
```

---

## How to run

From the project root:

```r
source("run_all.R")      # or, from a terminal: Rscript run_all.R
```

- **Duration.** The last complete run took about 6 h 20 min. The slow steps
  are `02`, `03`, the new least-cost paths of `11` (only on the first run)
  and `12`.
- **Memory.** `08` needs about 35 GB: it ran on a machine with 32 GB of RAM
  plus paging.
- **Skipping the slow steps.** All intermediate objects are written to
  `output/rds/`. To skip the slow steps, download them from the Zenodo
  deposit and place them in `output/rds/`. `11` and `12` reuse existing
  least-cost paths, and every script can be run on its own after
  `R/00_setup.R` once its inputs exist.

---

## Reproducibility

- **Determinism.** The pipeline is deterministic. The cost surfaces are
  computed from the DEM as it is. Every random step runs under a seed
  declared in `R/00_setup.R`: Leiden (`COMMUNITY_SEED`), null models
  (`NULL1_SEED`, `NULL2_SEED`, `NULL2_STABILITY_SEEDS`), subsampling
  (`SUBSAMPLE_SEED`) and label placement in the figures.
- **Regression.** Every regenerated table is compared with its baseline in
  `tests/baseline_v2/` (27 tables) and `tests/baseline_v2/after_10/` (21
  tables), with `all.equal` and tolerance 1e-8. With
  `STRICT_REGRESSION <- TRUE` (default) any difference stops the run.
- **Determinism check (run by hand).** `tests/determinism_check.R`
  recomputes the cost surfaces and the Roman wheeled-transport network in a
  fresh session and compares them bit for bit with the saved objects (about
  45 min). It writes a local report, `output/tables/determinism_check.md`.

---

## Outputs

**Tables.** `output/tables/`: one CSV per result, written by the script named
in its header comment. The main ones:

| Table | Contents |
|---|---|
| `centrality_comparison.csv` | Per-site centrality in the two published networks |
| `factorial_*.csv` | The 2 × 2 design |
| `egnatia_pdi_final.csv` | Corrected PDI, the canonical values |
| `null_model_results.csv` | Null-model tests |

`session_info.txt` lists the package versions of the last run.

**Figures.** `output/images/`:

| Figure | File |
|---|---|
| 1 | `fig01_sites_dem.png` |
| 2 | `fig02_networks_tobler.png` |
| 3 | `fig03_networks_wheeled.png` |
| 4 | `fig04_boxplot_centrality.png` |
| 5 | `fig05_centrality_maps.png` |
| 6 | `fig06_communities.png` |
| 7 | `fig07_scatter_dualphase.png` |
| 8 | `fig08_threshold_sensitivity.png` |
| 9 | `fig09_egnatia_full_corridors.png` |
| 10 | `fig10_egnatia_segments.png` |

Quality-control plots go to `output/images/qc/` (not in the repository).

**Supplementary material.** S1 and S2 (docx) are deposited on Zenodo; see
`supplementary/README.md`.

---

## Corrected PDI

`leastcostpath::PDI_validation()` (version 2.0.13) computes the area between
the modelled and the attested route without first repairing the polygon. When
the two routes cross, the polygon self-intersects and the area, and hence the
PDI, is wrong. `R/functions/pdi_validation_fixed.R` provides `pdi_fixed()`,
which repairs both candidate polygons with `sf::st_make_valid()` before
computing and comparing their areas. `08` reports both values
(`egnatia_pdi_comparison_bug.csv`); the corrected ones are in
`egnatia_pdi_final.csv`.

See Supplementary Material S1 and [LEASTCOSTPATH ISSUE URL].

---

## Licences and attribution

- **Code:** MIT licence (see `LICENSE`).
- **Tables, figures and documentation** in this repository: CC BY 4.0.
- **DEM:** Produced using Copernicus data and information funded by the
  European Union — EU-DEM v1.1, Copernicus Land Monitoring Service, European
  Environment Agency. The file is a clipped and reprojected subset of the
  original.
- **Via Egnatia route:** Itiner-e (de Soto et al. 2025), CC BY 4.0.
- **Country boundaries of Figure 1:** Natural Earth (public domain).

---

## Citation

If you use this code or its results, please cite:

- [ARTICLE CITATION]
- Code and data: [ZENODO CONCEPT DOI]
