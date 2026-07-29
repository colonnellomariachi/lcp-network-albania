# =============================================================================
# run_all.R — Execute the full analysis pipeline in order
#
# Expected total runtime: 2–4 hours on a modern desktop (16 GB RAM).
# Expensive steps are flagged with [SLOW] below.
#
# Intermediate objects are written to output/rds/ so you can re-run
# downstream scripts without repeating the LCP computation.
#
# Usage:
#   Rscript run_all.R          # from the terminal (project root)
#   source("run_all.R")        # from an R session
# =============================================================================

# Ensure here::here() anchors to this project root
library(here)

message(rep("=", 60))
message("Pipeline start: ", Sys.time())
message(rep("=", 60))

# 00 — Libraries, paths, global parameters
source(here("R", "00_setup.R"))

# 01 — Chronological phase assignment
message("\n[01] Chronological phase assignment...")
source(here("R", "01_chronology.R"))

# 02 — Cost surface creation [SLOW: ~10–20 min]
message("\n[02] Cost surface creation (SLOW)...")
source(here("R", "02_cost_surfaces.R"))

# 03 — Least-cost path computation [SLOW: ~30–90 min per network]
message("\n[03] Least-cost path computation (SLOW)...")
source(here("R", "03_least_cost_paths.R"))

# 04 — Network construction + centrality + threshold sweep
message("\n[04] Network construction and centrality...")
source(here("R", "04_networks.R"))

# 05 — Centrality export
message("\n[05] Centrality export...")
source(here("R", "05_centrality.R"))

# 06 — Community detection (Leiden)
message("\n[06] Community detection...")
source(here("R", "06_community_detection.R"))

# 07 — Null models [SLOW: 999 × 2 Leiden calls, ~20–60 min]
message("\n[07] Null models (SLOW)...")
source(here("R", "07_null_models.R"))

# 08 — Egnatia route validation
message("\n[08] Egnatia validation...")
source(here("R", "08_egnatia_validation.R"))

# 09 — Figures
message("\n[09] Figures...")
source(here("R", "09_figures.R"))

# 10 — Discussion checks (Q1–Q6, road-station network roles)
message("\n[10] Discussion checks...")
source(here("R", "10_discussion_checks.R"))

# Session info for reproducibility
message("\n[Session info] Writing session_info.txt...")
sink(here("output", "tables", "session_info.txt"))
print(sessionInfo())
sink()

message(rep("=", 60))
message("Pipeline complete: ", Sys.time())
message(rep("=", 60))
message("\nVerification: compare output/tables/centrality_comparison.csv")
message("against the baseline copy in the project root.")
message("They must be identical. See README.md §Verification for details.")
