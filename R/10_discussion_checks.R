# =============================================================================
# 10_discussion_checks.R — Reproducible source for all discussion-section
#                          empirical claims
#
# Consolidates Q1–Q6 (chronological threshold analysis, §5.2) and the
# road-station network analysis (§5.5) previously run in interactive sessions.
# Q7 (late-antique horizon of the Roman network, reviewer 1) mirrors
# Q1 at the other end of the Roman window.
# Two descriptive tables for the Results: site_typology.csv
# (def_sito within tipo_sito, by site set) and egnatia_certain_vs_conjectured.csv
# (segment 1 of the Egnatia split into the Itiner-e certain / conjectured
# stretches; requires the objects of 08).
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
# The values asserted with check_published() and the regression baselines
# (REGRESSION_BASELINE_DIR, tests/baseline_v2/) are those of the deterministic
# run (no DEM error).
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

check_published(
  "Q3 rank-1 must be DUR003"       = q3$id_sito[1] == "DUR003",
  "Q3 rank-2 must be DUR038"       = q3$id_sito[2] == "DUR038",
  "Q3: no post-146 site in the top ten" = !any(q3$post_146)
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

check_published(
  "median mansio must equal baseline" =
    abs(median_mansio - 0.00257129499766246) < 1e-12,
  "median minor settlement must equal baseline" =
    abs(median_minor  - 0.000273070468179853) < 1e-12,
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

check_published(
  "DUR054 must be in module 5"        = st_mod$module[st_mod$id_sito == "DUR054"] == 5L,
  "DUR102 must be in module 1"        = st_mod$module[st_mod$id_sito == "DUR102"] == 1L,
  "DUR054 n_members must be 22"       = st_mod$n_members[st_mod$id_sito == "DUR054"] == 22L,
  "DUR102 n_members must be 18"       = st_mod$n_members[st_mod$id_sito == "DUR102"] == 18L,
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

check_published(
  "station_neighbors must have 27 rows" = nrow(station_neighbors) == 27L
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

check_published(
  "DUR054 role must be 'hub locale'"  =
    station_roles$role[station_roles$id_sito == "DUR054"] == "hub locale",
  "DUR102 role must be 'hub locale'"  =
    station_roles$role[station_roles$id_sito == "DUR102"] == "hub locale",
  "DUR054 prop_inter must be 2/12"    =
    abs(station_roles$prop_inter[station_roles$id_sito == "DUR054"] - 2 / 12) < 1e-10,
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
# Q7 — Late-antique horizon of the Roman network (mirror of Q1)
#
# With ROM_END = 450 and century-coded chronology, sites founded in late
# antiquity can enter the Roman network. Flags, for every site in siti_rom:
#   start_ge_300        earliest attested start >= AD 300
#   in_roman_end300     would pass the Roman-window test with ROM_END = 300
#   late_antique_only   in the network only through overlap with AD 300-450
# Focus sites (DUR002, DUR016, DUR030, DUR032, DUR053) are always reported.
# ROM_END itself is not changed; 300 is used only as a counterfactual.
# ---------------------------------------------------------------------------

Q7_FOCUS_IDS   <- c("DUR002", "DUR016", "DUR030", "DUR032", "DUR053")

q7_rows <- lapply(seq_len(nrow(sites_d)), function(ii) {
  row    <- sites_d[ii, , drop = FALSE]
  active <- period_cols[sapply(period_cols, function(pp) is_active(row[[pp]]))]
  if (length(active) == 0L) return(NULL)
  starts <- sapply(active, function(pp) chrono_dict[[pp]][1])
  ends   <- sapply(active, function(pp) chrono_dict[[pp]][2])
  hit_450 <- overlaps_min(starts, ends, ROM_BOUND, ROM_END)
  hit_300 <- overlaps_min(starts, ends, ROM_BOUND, ROM_END_ALT)
  data.frame(
    id_sito          = row$id_sito,
    active_periods   = paste(active, collapse = ","),
    rom_periods_450  = paste(active[hit_450], collapse = ","),
    rom_periods_300  = paste(active[hit_300], collapse = ","),
    in_roman_end300  = any(hit_300),
    stringsAsFactors = FALSE
  )
})
q7_chrono <- do.call(rbind, q7_rows)

q7 <- merge(chrono_base[chrono_base$id_sito %in% rom_ids,
                        c("id_sito", "def_sito", "tipo_sito", "localita",
                          "earliest_start", "latest_end")],
            q7_chrono, by = "id_sito", all.x = TRUE)
q7_cc <- cc_rom[, c("id_sito", "degree", "betweenness_norm")]
q7_cc$rank_betweenness <- rank(-q7_cc$betweenness_norm, ties.method = "min")
q7 <- merge(q7, q7_cc, by = "id_sito", all.x = TRUE)

q7$isolate           <- q7$degree == 0L
q7$start_ge_300      <- !is.na(q7$earliest_start) & q7$earliest_start >= 300
q7$late_antique_only <- !q7$in_roman_end300
q7$focus_site        <- q7$id_sito %in% Q7_FOCUS_IDS

stopifnot("Q7 must cover the 94 Roman sites" = nrow(q7) == 94L)

q7_out <- q7[q7$start_ge_300 | q7$late_antique_only | q7$focus_site, ]
q7_out <- q7_out[order(-q7_out$start_ge_300, -q7_out$late_antique_only,
                       q7_out$earliest_start, q7_out$id_sito), ]
rownames(q7_out) <- NULL

n_ge300 <- sum(q7$start_ge_300)
n_lao   <- sum(q7$late_antique_only)
message("Q7: start >= AD 300: ", n_ge300, " / 94 = ",
        round(n_ge300 / 94 * 100, 1), " % (",
        paste(q7$id_sito[q7$start_ge_300], collapse = ", "), ")")
message("Q7: late-antique-only (fail with ROM_END = 300): ", n_lao, " / 94 = ",
        round(n_lao / 94 * 100, 1), " % (",
        paste(q7$id_sito[q7$late_antique_only], collapse = ", "), ")")
for (sid in Q7_FOCUS_IDS) {
  r <- q7[q7$id_sito == sid, ]
  message(sprintf("Q7: %s start=%d end=%d btw_rank=%d degree=%d in_roman_end300=%s",
                  sid, r$earliest_start, r$latest_end, r$rank_betweenness,
                  r$degree, r$in_roman_end300))
}

# Stop criterion: the upland-centre reading in 11 relies on Dorez and
# Mliku being in the Roman network independently of the late-antique phase.
stopifnot(
  "Q7 start >= AD 300 count must be 9"       = n_ge300 == 9L,
  "Q7 late-antique-only count must be 22"    = n_lao == 22L,
  "DUR002 must be late-antique-only"         =
    isTRUE(q7$late_antique_only[q7$id_sito == "DUR002"]),
  "DUR032 (Dorez) must be Roman also with ROM_END = 300" =
    isTRUE(q7$in_roman_end300[q7$id_sito == "DUR032"]),
  "DUR053 (Mliku) must be Roman also with ROM_END = 300" =
    isTRUE(q7$in_roman_end300[q7$id_sito == "DUR053"])
)

write.csv(q7_out, table_path("q7_late_antique_horizon.csv"), row.names = FALSE)
message("Saved q7_late_antique_horizon.csv")

# ---------------------------------------------------------------------------
# Site typology — def_sito within tipo_sito, by site set
# ---------------------------------------------------------------------------

# Labels (TIPO_EN, DEF_EN, "città" repaired) from read_site_labels(),
# R/functions/site_helpers.R; missing labels counted as "(missing)".
typ <- read_site_labels()[, c("id_sito", "tipo_orig", "def_orig")]
names(typ) <- c("id_sito", "tipo_sito", "def_sito")
typ$hell <- typ$id_sito %in% hell_ids
typ$rom  <- typ$id_sito %in% rom_ids
typ$dual <- typ$id_sito %in% dual_ids

count_sets <- function(d) data.frame(n_dataset = nrow(d), n_hellenistic = sum(d$hell),
                                     n_roman = sum(d$rom), n_dual = sum(d$dual))
tipo_order <- names(TIPO_EN)[names(TIPO_EN) %in% typ$tipo_sito]
site_typology <- do.call(rbind, c(lapply(tipo_order, function(tp) {
  d    <- typ[typ$tipo_sito == tp, ]
  defs <- names(sort(table(d$def_sito), decreasing = TRUE))
  rbind(
    do.call(rbind, lapply(defs, function(df) cbind(
      data.frame(row_type = "type", tipo_sito_en = TIPO_EN[[tp]], def_sito_en = DEF_EN[[df]],
                 tipo_sito_orig = tp, def_sito_orig = df),
      count_sets(d[d$def_sito == df, ])))),
    cbind(data.frame(row_type = "category total", tipo_sito_en = TIPO_EN[[tp]],
                     def_sito_en = "(all)", tipo_sito_orig = tp, def_sito_orig = "(all)"),
          count_sets(d)))
}), list(cbind(data.frame(row_type = "grand total", tipo_sito_en = "(all)", def_sito_en = "(all)",
                          tipo_sito_orig = "(all)", def_sito_orig = "(all)"),
               count_sets(typ)))))
rownames(site_typology) <- NULL

stopifnot("site typology totals must be 143 / 71 / 94 / 46" =
            identical(unlist(site_typology[site_typology$row_type == "grand total",
                                           c("n_dataset", "n_hellenistic", "n_roman", "n_dual")],
                             use.names = FALSE), c(143L, 71L, 94L, 46L)))
hell_cats <- unique(typ$tipo_sito[typ$hell])
message("Site typology: tipo_sito categories in the Hellenistic network: ", length(hell_cats),
        " (", paste(hell_cats, collapse = ", "), "); unclassified Hellenistic sites: ",
        paste(typ$id_sito[typ$hell & typ$tipo_sito == "(missing)"], collapse = ", "))
print(site_typology)
write.csv(site_typology, table_path("site_typology.csv"), row.names = FALSE)
message("Saved site_typology.csv")

# ---------------------------------------------------------------------------
# Egnatia segment 1: certain vs conjectured stretches
#   [requires the objects of 08]
#
# The attested line of segment 1 (DUR001 -> DUR022) is the one used in 08
# (egnatia_known_segments.rds). Each of its edges is assigned to the Itiner-e
# stretch (gpkg fid) it lies on. The segment is the continuous sequence
# 3084, 3083, 3085, 3087, 3088, 3089, 3086 and the western part of 3090: an
# edge lying on no stretch (for example a straight stitching chord) stops the
# script.
# Containment and distance use the sample points of 08 (corridor quantiles:
# max(50, length / 100) points, quantiles over every corridor cell) and of
# pdi_independent_check.csv (one point every PDI_SAMPLE_SPACING m), each
# point assigned to the part it lies on; the "whole segment" rows must
# reproduce those two tables.
# ---------------------------------------------------------------------------
EGN_CERTAIN_FIDS <- c(3085, 3086)   # stretches classified "Certain" in Itiner-e

itin <- sf::st_read(data_path("egnatia_itinere.gpkg"), quiet = TRUE, fid_column_name = "fid") %>%
  dplyr::filter(Name == "Dyrrhachium-Scampis") %>%
  sf::st_transform(CRS_UTM)
stopifnot("Itiner-e certain stretches changed" =
            setequal(itin$fid[itin$Segment_s == "Certain"], EGN_CERTAIN_FIDS))

seg1 <- readRDS(rds_path("egnatia_known_segments.rds"))[[1]]
seg1_label <- paste(WAYPOINT_IDS[1], WAYPOINT_IDS[2], sep = " -> ")
seg1_xy  <- sf::st_coordinates(seg1)[, 1:2]
edge_len <- sqrt(rowSums(diff(seg1_xy)^2))
edge_mid <- sf::st_as_sf(data.frame(x = (seg1_xy[-1, 1] + seg1_xy[-nrow(seg1_xy), 1]) / 2,
                                    y = (seg1_xy[-1, 2] + seg1_xy[-nrow(seg1_xy), 2]) / 2),
                         coords = c("x", "y"), crs = CRS_UTM)
edge_d   <- sf::st_distance(edge_mid, itin)
edge_fid <- itin$fid[apply(edge_d, 1, which.min)]
stopifnot("segment 1 has edges off the Itiner-e stretches" =
            all(apply(edge_d, 1, min) <= ROUTE_ON_SOURCE_TOL))
edge_part <- ifelse(edge_fid %in% EGN_CERTAIN_FIDS, "certain", "conjectured")

# One MULTILINESTRING per part, from the runs of consecutive edges
part_geom <- lapply(c("certain", "conjectured"), function(p) {
  r    <- rle(edge_part == p)
  ends <- cumsum(r$lengths); starts <- ends - r$lengths + 1
  runs <- which(r$values)
  sf::st_sfc(sf::st_multilinestring(lapply(runs, function(k)
    seg1_xy[starts[k]:(ends[k] + 1), ])), crs = CRS_UTM)
})
names(part_geom) <- c("certain", "conjectured")
part_of <- function(pts) {
  d <- sapply(part_geom, function(g) as.numeric(sf::st_distance(pts, g)))
  names(part_geom)[apply(d, 1, which.min)]
}

seg_len  <- as.numeric(sf::st_length(seg1))
part_len <- tapply(edge_len, edge_part, sum)[names(part_geom)]
stopifnot("parts must sum to the segment length" = abs(sum(part_len) - seg_len) < 1e-6)
fid_len <- tapply(edge_len, edge_fid, sum)
message(sprintf("Segment 1 (%.0f m): certain %.0f m, conjectured %.0f m",
                seg_len, part_len["certain"], part_len["conjectured"]))
message("  length per Itiner-e fid (m): ",
        paste(sprintf("%s %.0f", names(fid_len), fid_len), collapse = ", "))

# Sample points of 08: corridor containment and PDI sampling check
n_cont   <- max(50L, ceiling(seg_len / 100))
pts_cont <- sf::st_cast(sf::st_line_sample(sf::st_geometry(seg1), n = n_cont), "POINT")
pts_pdi  <- sf::st_cast(sf::st_line_sample(sf::st_geometry(seg1),
                                           density = 1 / PDI_SAMPLE_SPACING), "POINT")
part_cont <- part_of(pts_cont)
part_pdi  <- part_of(pts_pdi)

PART_SETS <- list("certain"       = "certain",
                  "conjectured"   = "conjectured",
                  "whole segment" = names(part_geom))
part_fids <- function(set)
  paste(sort(unique(edge_fid[edge_part %in% set])), collapse = ";")

cert_conj <- do.call(rbind, lapply(c("wheeled", "tobler"), function(fn) {
  corr  <- readRDS(rds_path(sprintf("corr_%s.rds", fn)))
  vals  <- as.numeric(terra::values(corr, na.rm = TRUE))
  q_val <- quantile(vals, c(0.05, 0.10, 0.25))
  ext   <- terra::extract(corr, terra::vect(sf::st_as_sf(pts_cont)))[, 2]
  lcp   <- readRDS(rds_path(sprintf("lcp_egnatia_%s_seg1.rds", fn)))
  dist  <- as.numeric(sf::st_distance(pts_pdi, sf::st_geometry(lcp)))
  do.call(rbind, lapply(names(PART_SETS), function(p) {
    ic <- part_cont %in% PART_SETS[[p]]; ip <- part_pdi %in% PART_SETS[[p]]
    data.frame(
      segment = seg1_label,
      part = p, itinere_fids = part_fids(PART_SETS[[p]]),
      length_m = sum(part_len[PART_SETS[[p]]]),
      share_of_segment = sum(part_len[PART_SETS[[p]]]) / seg_len,
      cost_function = if (fn == "wheeled") "wheeled transport" else "tobler",
      n_pts_corridor = sum(ic),
      n_pts_corridor_na = sum(is.na(ext[ic])),
      prop_q05 = mean(ext[ic] <= q_val[1], na.rm = TRUE),
      prop_q10 = mean(ext[ic] <= q_val[2], na.rm = TRUE),
      prop_q25 = mean(ext[ic] <= q_val[3], na.rm = TRUE),
      n_pts_200m = sum(ip),
      mean_dist_to_lcp_m = round(mean(dist[ip]), 1),
      max_dist_to_lcp_m  = round(max(dist[ip]), 1),
      stringsAsFactors = FALSE)
  }))
}))

# BLOCKING: the "whole segment" rows reproduce the tables of 08
whole <- cert_conj[cert_conj$part == "whole segment", ]
cont08 <- read.csv(table_path("egnatia_corridor_containment.csv"), stringsAsFactors = FALSE)
cont08 <- cont08[cont08$segment == whole$segment[1], ]
indep08 <- read.csv(table_path("pdi_independent_check.csv"), stringsAsFactors = FALSE)
indep08 <- indep08[indep08$segment == whole$segment[1], ]
for (k in seq_len(nrow(whole))) {
  ref_col <- if (whole$cost_function[k] == "tobler") "prop_tobler" else "prop_wheeled"
  ind <- indep08[indep08$cost_function == whole$cost_function[k], ]
  stopifnot(
    "whole-segment containment must reproduce egnatia_corridor_containment.csv" =
      isTRUE(all.equal(unname(unlist(whole[k, c("prop_q05", "prop_q10", "prop_q25")])),
                       cont08[[ref_col]][match(c(0.05, 0.10, 0.25), cont08$cost_quantile)])),
    "whole-segment distances must reproduce pdi_independent_check.csv" =
      whole$n_pts_200m[k] == ind$n_sample_pts &&
      whole$mean_dist_to_lcp_m[k] == ind$mean_dist_to_lcp_m &&
      whole$max_dist_to_lcp_m[k]  == ind$max_dist_to_lcp_m)
}
print(cert_conj)
write.csv(cert_conj, table_path("egnatia_certain_vs_conjectured.csv"), row.names = FALSE)
message("Saved egnatia_certain_vs_conjectured.csv")

# ---------------------------------------------------------------------------
# Regression check
# ---------------------------------------------------------------------------

# Tables produced up to this script (04-10) are compared with the CSV files
# in REGRESSION_BASELINE_DIR; tables of 11-13 are checked at the end of
# run_all.R against REGRESSION_BASELINE_DIR/after_10.
regression_check(REGRESSION_BASELINE_DIR)

message("\n10_discussion_checks.R complete.")
