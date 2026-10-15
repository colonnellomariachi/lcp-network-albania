# =============================================================================
# run_all.R — Execute the full analysis pipeline in order
#
# Expected total runtime: ~8 hours on a modern desktop (32 GB RAM); the
# conductance graphs need ~13 GB.
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

# 04b — Betweenness concentration across thresholds
message("\n[04b] Betweenness concentration sweep...")
source(here("R", "04b_betweenness_concentration_sweep.R"))

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

# 10 — Discussion checks (Q1–Q6, road-station network roles)
message("\n[10] Discussion checks...")
source(here("R", "10_discussion_checks.R"))

# 11 — 2×2 factorial: site set × cost function [SLOW first run: new LCPs]
message("\n[11] Cost-function factorial design...")
source(here("R", "11_cost_function_factorial.R"))

# 09 — Figures (after 11: fig02–fig05 and fig07 read its objects and tables)
message("\n[09] Figures...")
source(here("R", "09_figures.R"))

# 12 — Hydrographic sensitivity [SLOW first run: 8 penalised LCP sets, ~3.5 h]
message("\n[12] Hydrographic sensitivity (SLOW)...")
source(here("R", "12_hydrographic_sensitivity.R"))

# 13 — Size and late-antique horizon sensitivity (induced subgraphs, no LCPs)
message("\n[13] Size / horizon sensitivity...")
source(here("R", "13_size_horizon_sensitivity.R"))

# Tables produced after 10 (11-13)
regression_check(file.path(REGRESSION_BASELINE_DIR, "after_10"))

# Values that differ from the published ones / regression baselines
if (length(regression_log)) {
  message("\n", length(regression_log), " regression difference(s) logged:")
  for (x in regression_log) message("  - ", x)
}
writeLines(regression_log, here("output", "tables", "regression_log.txt"))

# Session info for reproducibility
message("\n[Session info] Writing session_info.txt...")
sink(here("output", "tables", "session_info.txt"))
print(sessionInfo())
sink()

message(rep("=", 60))
message("Pipeline complete: ", Sys.time())
message(rep("=", 60))
message("\nVerification: differences from the published values / regression")
message("baselines are listed in output/tables/regression_log.txt.")
