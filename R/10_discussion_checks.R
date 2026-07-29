# =============================================================================
# 10_discussion_checks.R — Reproducible source for all discussion-section
#                          empirical claims
#
# Consolidates Q1–Q6 (chronological threshold analysis, §5.2) and the
# road-station network analysis (§5.5) previously run in interactive sessions.
# No analytical parameters are changed; this script only formalises the
# provenance of numbers already in the manuscript.
#
# Dependencies (must be sourced / run before this script):
#   00_setup.R        — global parameters (HELL_START, ROM_BOUND, ROM_END,
#                        MIN_OVERLAP_YEARS, CRS_UTM, SCATTER_SEED) and
#                        helper functions (is_active, overlaps_min)
#   01_chronology.R   — siti_hell.rds, siti_rom.rds
#   04_networks.R     — net_rom.rds, nodes_rom.rds
#   05_centrality.R   — centrality_comparison.csv
#   06_community_detection.R — giant.rds, cl_leiden.rds
#   08_egnatia_validation.R  — egnatia_stitched.rds (Q4 only; see below)
#
# ROM_END: 450 (as in 00_setup.R). All published counts (n_hell=71, n_rom=94,
# n_dual=46) were computed with this value.
#
# Q4 (distance from Via Egnatia) requires egnatia_stitched.rds produced by
# 08_egnatia_validation.R. That script is sourced after 07 in run_all.R, so
# Q4 is placed last in this script to avoid ordering problems when sourced
# in isolation; in the full pipeline it always has the file available.
#
# Regression baseline: tests/discussion_checks_baseline/<file>.csv
# To initialise the baseline directory (run once after generating the first
# canonical outputs):
#   dir.create(here("tests","discussion_checks_baseline"), recursive=TRUE)
#   for (f in list.files(table_path(), pattern="^(q[1-6]_|road_|station_)",
#                        full.names=TRUE))
#     file.copy(f, here("tests","discussion_checks_baseline",basename(f)))
# =============================================================================

# ---------------------------------------------------------------------------
# 0. Local constants
# ---------------------------------------------------------------------------

# Chronological dictionary — identical to 01_chronology.R.
# Defined locally so this script can run standalone after 00_setup.R.
chrono_dict <- list(
  neo_ant  = c(-6500, -5500), neo_med  = c(-5500, -4500),
  neo_fin  = c(-4500, -3600), eneol    = c(-3600, -2300),
  bron_gen = c(-2300, -1100), bron_rec = c(-1500, -1100),
  ott_ac   = c(-800,   -700), sett_ac  = c(-700,   -600),
  ses_ac   = c(-600,   -500), qui_ac   = c(-500,   -400),
  qua_ac   = c(-400,   -300), ter_ac   = c(-300,   -200),
  sec_ac   = c(-200,   -100), pri_ac   = c(-100,      0),
  republ   = c(-509,    -27), imper    = c( -27,    284),
  roman    = c(-168,    395), lateant  = c( 284,    600),
  pri_dc   = c(   0,    100), sec_dc   = c( 100,    200),
  ter_dc   = c( 200,    300), qua_dc   = c( 300,    400),
  qui_dc   = c( 400,    500), ses_dc   = c( 500,    600),
  sett_dc  = c( 600,    700)
)

STATION_IDS       <- c("DUR054", "DUR022", "DUR024", "DUR059", "DUR102")
UPLAND_IDS        <- c("DUR032", "DUR025", "DUR053", "DUR015")
POST146_THRESHOLD <- -146   # 146 BC — Roman conquest of Macedonia

dir.create(image_path("qc"), showWarnings = FALSE, recursive = TRUE)

# ---------------------------------------------------------------------------
# 1. Load network objects and site data
# ---------------------------------------------------------------------------

siti_hell <- readRDS(rds_path("siti_hell.rds"))
siti_rom  <- readRDS(rds_path("siti_rom.rds"))
net_rom   <- readRDS(rds_path("net_rom.rds"))
giant     <- readRDS(rds_path("giant.rds"))
cl_leiden <- readRDS(rds_path("cl_leiden.rds"))

cc      <- read.csv(table_path("centrality_comparison.csv"),
                    stringsAsFactors = FALSE)
cc_hell <- cc[cc$phase == "hellenistic", ]
cc_rom  <- cc[cc$phase == "roman",       ]

hell_ids <- siti_hell$id_sito
rom_ids  <- siti_rom$id_sito
dual_ids <- intersect(hell_ids, rom_ids)

message("Network sizes: n_hell=", length(hell_ids),
        "  n_rom=",  length(rom_ids),
        "  n_dual=", length(dual_ids))
stopifnot(
  "n_hell must be 71"  = length(hell_ids) == 71L,
  "n_rom must be 94"   = length(rom_ids)  == 94L,
  "n_dual must be 46"  = length(dual_ids) == 46L
)

# Site attribute table (geometry-free).
# iconv repairs any residual latin-1 bytes in string fields.
sites_sf <- sf::st_read(data_path("sites.gpkg"), quiet = TRUE) %>%
  dplyr::mutate(
    def_sito  = iconv(def_sito,  "latin1", "UTF-8", sub = "?"),
    tipo_sito = iconv(tipo_sito, "latin1", "UTF-8", sub = "?"),
    top_ant   = iconv(top_ant,   "latin1", "UTF-8", sub = "?")
  )
sites_d <- sf::st_drop_geometry(sites_sf)

# ---------------------------------------------------------------------------
# 2. Chronological summary
#    earliest_start, latest_end, in_hellenistic, in_roman
#    (replicates 01_chronology.R logic using helpers from 00_setup.R)
# ---------------------------------------------------------------------------

period_cols <- names(chrono_dict)[names(chrono_dict) %in% names(sites_d)]

chrono_rows <- lapply(seq_len(nrow(sites_d)), function(ii) {
  row    <- sites_d[ii, , drop = FALSE]
  active <- period_cols[
    sapply(period_cols, function(pp) is_active(row[[pp]]))
  ]
  if (length(active) == 0L) {
    return(data.frame(
      id_sito        = row$id_sito,
      earliest_start = NA_real_,
      latest_end     = NA_real_,
      in_hellenistic = FALSE,
      in_roman       = FALSE,
      stringsAsFactors = FALSE
    ))
  }
  starts <- sapply(active, function(pp) chrono_dict[[pp]][1])
  ends   <- sapply(active, function(pp) chrono_dict[[pp]][2])
  data.frame(
    id_sito        = row$id_sito,
    earliest_start = min(starts),
    latest_end     = max(ends),
    in_hellenistic = any(overlaps_min(starts, ends, HELL_START, ROM_BOUND)),
    in_roman       = any(overlaps_min(starts, ends, ROM_BOUND,  ROM_END)),
    stringsAsFactors = FALSE
  )
})
chrono_df <- do.call(rbind, chrono_rows)

# Base attribute table (site metadata + chrono summary)
base_cols   <- c("id_sito", "def_sito", "tipo_sito", "top_ant",
                 "comune", "localita", "Longit", "Latitud")
chrono_base <- merge(sites_d[, base_cols], chrono_df, by = "id_sito")

# ---------------------------------------------------------------------------
# 3. Module lookup (giant component, Leiden clustering)
# ---------------------------------------------------------------------------

mod_vec   <- igraph::membership(cl_leiden)
mod_ids   <- igraph::V(giant)$id_sito
module_df <- data.frame(
  id_sito  = mod_ids,
  module   = as.integer(mod_vec),
  stringsAsFactors = FALSE
)
mod_sizes        <- table(module_df$module)
module_df$n_members <- as.integer(mod_sizes[as.character(module_df$module)])

# ---------------------------------------------------------------------------
# Q1 — Post-146 BC sites in the hellenistic network
# ---------------------------------------------------------------------------

q1 <- chrono_base[
  chrono_base$id_sito %in% hell_ids &
  !is.na(chrono_base$earliest_start) &
  chrono_base$earliest_start > POST146_THRESHOLD, ]
q1$dual_phase <- q1$id_sito %in% dual_ids
q1 <- q1[order(q1$earliest_start, q1$id_sito), ]

stopifnot(
  "Q1 count must be 6"           = nrow(q1) == 6L,
  "Q1 percentage must be ~8.5 %" = abs(nrow(q1) / length(hell_ids) * 100 - 8.5) < 0.1
)
message("Q1: ", nrow(q1), " / ", length(hell_ids), " = ",
        round(nrow(q1) / length(hell_ids) * 100, 1), " %")

write.csv(q1, table_path("q1_post146_hellenistic.csv"), row.names = FALSE)
message("Saved q1_post146_hellenistic.csv")

# ---------------------------------------------------------------------------
# Q2 — Dual-phase overlap within Q1
# ---------------------------------------------------------------------------

stopifnot("Q2: all Q1 sites must be dual-phase" = all(q1$dual_phase))
message("Q2: ", sum(q1$dual_phase), " / ", nrow(q1),
        " = 100 % dual-phase")

# ---------------------------------------------------------------------------
# Q3 — Top-10 betweenness in hellenistic network
# ---------------------------------------------------------------------------

q3 <- cc_hell[order(-cc_hell$betweenness_norm), ][seq_len(10L), ]
q3 <- merge(q3,
            chrono_base[, c("id_sito", "earliest_start", "latest_end",
                            "def_sito", "tipo_sito")],
            by = "id_sito", all.x = TRUE)
# drop duplicate def_sito / tipo_sito cols that may arrive from cc_hell
if ("def_sito.x" %in% names(q3)) {
  q3$def_sito  <- q3$def_sito.x;  q3$def_sito.x  <- NULL; q3$def_sito.y  <- NULL
  q3$tipo_sito <- q3$tipo_sito.x; q3$tipo_sito.x <- NULL; q3$tipo_sito.y <- NULL
}
q3$post_146 <- !is.na(q3$earliest_start) & q3$earliest_start > POST146_THRESHOLD
q3 <- q3[order(-q3$betweenness_norm), ]

stopifnot(
  "Q3 rank-1 must be DUR003"       = q3$id_sito[1] == "DUR003",
  "Q3 rank-2 must be DUR032"       = q3$id_sito[2] == "DUR032",
  "DUR044 must be post_146 = TRUE" = isTRUE(q3$post_146[q3$id_sito == "DUR044"])
)
message("Q3: DUR003 betweenness = ", round(q3$betweenness_norm[1], 4),
        " | any post-146 in top-10: ", any(q3$post_146, na.rm = TRUE))

write.csv(q3, table_path("q3_top10_betweenness_hellenistic.csv"), row.names = FALSE)
message("Saved q3_top10_betweenness_hellenistic.csv")

# ---------------------------------------------------------------------------
# Q5 — Upland centres
# ---------------------------------------------------------------------------

q5 <- chrono_base[chrono_base$id_sito %in% UPLAND_IDS, ]
q5$in_hell_network <- q5$id_sito %in% hell_ids
q5$in_rom_network  <- q5$id_sito %in% rom_ids
q5$dual_phase      <- q5$id_sito %in% dual_ids
q5 <- q5[match(UPLAND_IDS, q5$id_sito), ]

stopifnot(
  "DUR025 must be in roman network"  = isTRUE(q5$in_rom_network[q5$id_sito == "DUR025"]),
  "DUR025 latest_end must be 0"      = q5$latest_end[q5$id_sito == "DUR025"] == 0
)
# Overlap margin: ROM_END (450) - ROM_BOUND (-31) = 481 years window;
# DUR025 latest_end = 0, overlap with [-31, 450] = [−31, 0] = 31 years > 25.
message("Q5: DUR025 latest_end = ", q5$latest_end[q5$id_sito == "DUR025"],
        " | roman-window overlap = ",
        0 - ROM_BOUND, " yr | in roman network: ",
        q5$in_rom_network[q5$id_sito == "DUR025"])

write.csv(q5, table_path("q5_upland_centres_dates.csv"), row.names = FALSE)
message("Saved q5_upland_centres_dates.csv")

# ---------------------------------------------------------------------------
# Q6 — Road-station dates and hellenistic overlap
# ---------------------------------------------------------------------------

q6 <- chrono_base[chrono_base$id_sito %in% STATION_IDS, ]
q6$in_hell_network <- q6$id_sito %in% hell_ids
q6$in_rom_network  <- q6$id_sito %in% rom_ids
q6$dual_phase      <- q6$id_sito %in% dual_ids
# overlaps_hell: site start early enough for > MIN_OVERLAP_YEARS overlap
# with the Hellenistic window [HELL_START, ROM_BOUND].
# Equivalent to: site would have been included in siti_hell had it existed.
q6$overlaps_hell <- !is.na(q6$earliest_start) &
                     q6$earliest_start <= (ROM_BOUND - MIN_OVERLAP_YEARS)
q6 <- q6[match(STATION_IDS, q6$id_sito), ]

stopifnot(
  "All 5 stations must have overlaps_hell = FALSE" = !any(q6$overlaps_hell, na.rm = TRUE)
)
message("Q6: overlaps_hell for all 5 stations = FALSE")

write.csv(q6, table_path("q6_stations_dates.csv"), row.names = FALSE)
message("Saved q6_stations_dates.csv")

# ---------------------------------------------------------------------------
# Road-stations check — betweenness medians
# ---------------------------------------------------------------------------

# Centrality columns for the 5 mansio/statio sites (from Roman phase)
station_cc <- cc_rom[cc_rom$id_sito %in% STATION_IDS,
                     c("id_sito", "betweenness_norm", "degree", "harmonic")]
station_cc <- merge(
  station_cc,
  sites_d[, c("id_sito", "comune", "localita", "top_ant", "def_sito", "tipo_sito")],
  by = "id_sito", all.x = TRUE
)

# Median betweenness_norm for mansio/statio (n = 5)
median_mansio <- median(station_cc$betweenness_norm)

# Median betweenness_norm for tipo_sito == "minor settlement" (Roman phase)
minor_set_ids <- sites_d$id_sito[
  !is.na(sites_d$tipo_sito) & sites_d$tipo_sito == "minor settlement"
]
minor_set_btw <- cc_rom[cc_rom$id_sito %in% minor_set_ids, ]
median_minor  <- median(minor_set_btw$betweenness_norm)

station_cc$median_mansio           <- median_mansio
station_cc$median_minor_settlement <- median_minor

road_check <- station_cc[order(station_cc$id_sito),
                          c("id_sito", "comune", "localita", "top_ant",
                            "def_sito", "tipo_sito", "betweenness_norm",
                            "degree", "harmonic",
                            "median_mansio", "median_minor_settlement")]

stopifnot(
  "median mansio must equal baseline" =
    abs(median_mansio - 0.000467508181393174) < 1e-12,
  "median minor settlement must equal baseline" =
    abs(median_minor  - 0.000455206448902711) < 1e-12,
  "n minor settlement sites must be 50" =
    nrow(minor_set_btw) == 50L
)
message("Road stations: median_mansio = ", round(median_mansio, 9),
        " | median_minor_settlement = ", round(median_minor, 9))

write.csv(road_check, table_path("road_stations_check.csv"), row.names = FALSE)
message("Saved road_stations_check.csv")

# ---------------------------------------------------------------------------
# Station modules — community membership
# ---------------------------------------------------------------------------

st_mod <- merge(
  data.frame(id_sito = STATION_IDS, stringsAsFactors = FALSE),
  module_df[, c("id_sito", "module", "n_members")],
  by = "id_sito", all.x = TRUE
)
st_mod <- merge(st_mod,
                sites_d[, c("id_sito", "def_sito", "comune", "localita")],
                by = "id_sito", all.x = TRUE)
st_mod <- merge(st_mod,
                cc_rom[, c("id_sito", "betweenness_norm", "degree")],
                by = "id_sito", all.x = TRUE)
st_mod <- st_mod[order(st_mod$id_sito),
                  c("id_sito", "module", "n_members", "def_sito",
                    "comune", "localita", "betweenness_norm", "degree")]

stopifnot(
  "DUR054 must be in module 6"        = st_mod$module[st_mod$id_sito == "DUR054"] == 6L,
  "DUR102 must be in module 3"        = st_mod$module[st_mod$id_sito == "DUR102"] == 3L,
  "DUR054 n_members must be 22"       = st_mod$n_members[st_mod$id_sito == "DUR054"] == 22L,
  "DUR022 module must be NA (outside giant)" =
    is.na(st_mod$module[st_mod$id_sito == "DUR022"])
)
message("Station modules: DUR054 mod=", st_mod$module[st_mod$id_sito == "DUR054"],
        " n=", st_mod$n_members[st_mod$id_sito == "DUR054"],
        " | DUR102 mod=", st_mod$module[st_mod$id_sito == "DUR102"],
        " n=", st_mod$n_members[st_mod$id_sito == "DUR102"])

write.csv(st_mod, table_path("station_modules.csv"), row.names = FALSE)
message("Saved station_modules.csv")

# ---------------------------------------------------------------------------
# Station neighbors — direct neighbors in the Roman network
# ---------------------------------------------------------------------------

# Helper: returns data.frame of one station's neighbors with module labels
build_neighbors <- function(site_id, net, mod_df, attr_d, own_mod) {
  v_idx <- which(igraph::V(net)$id_sito == site_id)
  if (length(v_idx) == 0L) return(NULL)
  nb_sito <- igraph::V(net)$id_sito[igraph::neighbors(net, v_idx)]
  if (length(nb_sito) == 0L) return(NULL)
  nb_df <- data.frame(
    source   = site_id,
    neighbor = nb_sito,
    stringsAsFactors = FALSE
  )
  nb_df <- merge(nb_df,
                 attr_d[, c("id_sito", "def_sito", "comune")],
                 by.x = "neighbor", by.y = "id_sito", all.x = TRUE)
  nb_df <- merge(nb_df,
                 mod_df[, c("id_sito", "module")],
                 by.x = "neighbor", by.y = "id_sito", all.x = TRUE)
  nb_df$own_module    <- own_mod
  nb_df$inter_modular <- !is.na(nb_df$module) &
                          !is.na(own_mod) &
                          nb_df$module != own_mod
  nb_df[, c("source", "neighbor", "def_sito", "comune",
            "module", "own_module", "inter_modular")]
}

own_mods <- setNames(st_mod$module, st_mod$id_sito)

nb_list <- lapply(STATION_IDS, function(sid) {
  build_neighbors(sid, net_rom, module_df, sites_d, own_mods[[sid]])
})
station_neighbors <- do.call(rbind, nb_list)
station_neighbors <- station_neighbors[
  order(station_neighbors$source, station_neighbors$neighbor), ]
rownames(station_neighbors) <- NULL

stopifnot(
  "station_neighbors must have 23 rows" = nrow(station_neighbors) == 23L
)
message("Station neighbors: ", nrow(station_neighbors), " rows")

write.csv(station_neighbors, table_path("station_neighbors.csv"), row.names = FALSE)
message("Saved station_neighbors.csv")

# ---------------------------------------------------------------------------
# Station network roles
# ---------------------------------------------------------------------------

# Helper: compute role classification for one station
compute_role <- function(sid, nb_df, own_mod, in_giant, n_members) {
  nb           <- nb_df[nb_df$source == sid, ]
  n_neighbours <- nrow(nb)
  n_intra      <- if (in_giant) sum(!nb$inter_modular & !is.na(nb$module))
                  else NA_integer_
  n_inter      <- if (in_giant) sum(nb$inter_modular, na.rm = TRUE)
                  else NA_integer_
  n_not_giant  <- sum(is.na(nb$module))
  prop_inter   <- if (in_giant && n_neighbours > 0L)
                    as.numeric(n_inter) / n_neighbours
                  else NA_real_
  inter_mods   <- if (in_giant && !is.na(n_inter) && n_inter > 0L)
                    paste(sort(unique(nb$module[nb$inter_modular])), collapse = ",")
                  else NA_character_
  # Classification: prop_inter >= 0.30 → ponte inter-modulare; else hub locale
  role <- if (!in_giant) "outside giant" else
          if (!is.na(prop_inter) && prop_inter >= 0.30) "ponte inter-modulare" else
          "hub locale"
  data.frame(
    id_sito          = sid,
    module           = if (in_giant) own_mod else NA_integer_,
    n_members_module = if (in_giant) n_members else NA_integer_,
    degree           = st_mod$degree[st_mod$id_sito == sid],
    betweenness_norm = st_mod$betweenness_norm[st_mod$id_sito == sid],
    n_neighbours     = n_neighbours,
    n_intra          = n_intra,
    n_inter          = n_inter,
    n_not_in_giant   = n_not_giant,
    prop_inter       = prop_inter,
    inter_modules    = inter_mods,
    role             = role,
    stringsAsFactors = FALSE
  )
}

in_giant_flag <- setNames(!is.na(st_mod$module), st_mod$id_sito)
n_members_map <- setNames(st_mod$n_members,       st_mod$id_sito)

roles_list <- lapply(STATION_IDS, function(sid) {
  compute_role(sid, station_neighbors,
               own_mods[[sid]], in_giant_flag[[sid]], n_members_map[[sid]])
})
station_roles <- do.call(rbind, roles_list)
station_roles <- station_roles[order(station_roles$id_sito), ]
rownames(station_roles) <- NULL

stopifnot(
  "DUR054 role must be 'hub locale'"  =
    station_roles$role[station_roles$id_sito == "DUR054"] == "hub locale",
  "DUR102 role must be 'hub locale'"  =
    station_roles$role[station_roles$id_sito == "DUR102"] == "hub locale",
  "DUR054 prop_inter must be 0.20"    =
    abs(station_roles$prop_inter[station_roles$id_sito == "DUR054"] - 0.20) < 1e-10,
  "DUR102 prop_inter must be 0.25"    =
    abs(station_roles$prop_inter[station_roles$id_sito == "DUR102"] - 0.25) < 1e-10
)
message("Station roles: DUR054 = '",
        station_roles$role[station_roles$id_sito == "DUR054"],
        "' (prop_inter=", station_roles$prop_inter[station_roles$id_sito == "DUR054"],
        ") | DUR102 = '",
        station_roles$role[station_roles$id_sito == "DUR102"],
        "' (prop_inter=", station_roles$prop_inter[station_roles$id_sito == "DUR102"],
        ")")

write.csv(station_roles, table_path("station_network_roles.csv"), row.names = FALSE)
message("Saved station_network_roles.csv")

# ---------------------------------------------------------------------------
# Q4 — Distance from Via Egnatia  [requires egnatia_stitched.rds from 08]
# ---------------------------------------------------------------------------

egnatia_path <- rds_path("egnatia_stitched.rds")
if (!file.exists(egnatia_path)) {
  warning("Q4 skipped: egnatia_stitched.rds not found. ",
          "Run 08_egnatia_validation.R first.")
} else {
  egnatia_sf <- sf::st_sf(geometry = readRDS(egnatia_path))

  q1_sf <- sites_sf[sites_sf$id_sito %in% q1$id_sito, ] %>%
    sf::st_transform(CRS_UTM)
  dists  <- as.numeric(sf::st_distance(q1_sf, egnatia_sf))
  coords <- sf::st_coordinates(q1_sf)

  dist_df <- data.frame(
    id_sito        = q1_sf$id_sito,
    X_UTM          = round(coords[, 1]),
    Y_UTM          = round(coords[, 2]),
    dist_egnatia_m = round(dists),
    stringsAsFactors = FALSE
  )
  q4 <- merge(q1, dist_df, by = "id_sito", all.x = TRUE)
  q4 <- q4[order(q4$dist_egnatia_m), ]
  rownames(q4) <- NULL

  stopifnot(
    "Q4 DUR126 must be closest to Egnatia" = q4$id_sito[1] == "DUR126",
    "Q4 DUR126 distance must be ~2407 m"   =
      abs(q4$dist_egnatia_m[q4$id_sito == "DUR126"] - 2407) <= 5
  )
  message("Q4: ", nrow(q4), " sites | DUR126 (closest) = ",
          q4$dist_egnatia_m[q4$id_sito == "DUR126"], " m from Egnatia",
          " | DUR118 (farthest) = ",
          max(q4$dist_egnatia_m), " m")

  write.csv(q4, table_path("q4_post146_distance_egnatia.csv"), row.names = FALSE)
  message("Saved q4_post146_distance_egnatia.csv")

  # QC scatter
  p_q4 <- ggplot2::ggplot(q4,
      ggplot2::aes(x     = X_UTM,
                   y     = dist_egnatia_m,
                   colour = dual_phase,
                   label  = id_sito)) +
    ggplot2::geom_point(size = 2.5) +
    ggrepel::geom_text_repel(size = 2.5, max.overlaps = 20,
                              seed = SCATTER_SEED) +
    ggplot2::labs(
      x      = "X UTM 34N (m)",
      y      = "Distance from Via Egnatia (m)",
      title  = "Q4: post-146 BC hellenistic sites — distance from Via Egnatia",
      colour = "dual-phase") +
    ggplot2::theme_minimal(base_size = 9)
  ggplot2::ggsave(
    image_path("qc", "q4_post146_egnatia_scatter.png"),
    p_q4, width = 8, height = 5, dpi = 150)
  message("Saved qc/q4_post146_egnatia_scatter.png")
}

# ---------------------------------------------------------------------------
# Regression check
# ---------------------------------------------------------------------------

baseline_dir <- here::here("tests", "discussion_checks_baseline")
if (!dir.exists(baseline_dir)) {
  message("\nRegression check skipped: baseline directory not found.")
  message("Initialise with:")
  message("  dir.create(here('tests','discussion_checks_baseline'),",
          " recursive=TRUE)")
  message("  for (f in list.files(table_path(),",
          " pattern='^(q[1-6]_|road_|station_)', full.names=TRUE))")
  message("    file.copy(f,",
          " here('tests','discussion_checks_baseline',basename(f)))")
} else {
  baseline_files <- list.files(baseline_dir, pattern = "\\.csv$",
                               full.names = TRUE)
  if (length(baseline_files) == 0L) {
    message("\nRegression check: baseline directory empty — skipped.")
  } else {
    message("\n--- Regression check (", length(baseline_files),
            " files) ---")
    for (f in sort(baseline_files)) {
      fname    <- basename(f)
      new_path <- table_path(fname)
      if (!file.exists(new_path)) {
        stop("Regression: regenerated file missing: ", fname)
      }
      baseline <- read.csv(f,        stringsAsFactors = FALSE)
      new_file <- read.csv(new_path, stringsAsFactors = FALSE)
      result   <- all.equal(baseline, new_file, tolerance = 1e-8)
      if (!isTRUE(result)) {
        stop(sprintf("Regression mismatch in %s:\n  %s",
                     fname, paste(result, collapse = "\n  ")))
      }
      message("  OK  ", fname)
    }
    message("All regression checks passed.")
  }
}

message("\n10_discussion_checks.R complete.")
