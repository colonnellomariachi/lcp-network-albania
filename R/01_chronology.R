# =============================================================================
# 01_chronology.R — Chronological phase assignment
#
# Loads the site database, applies a binary overlap test against the
# Hellenistic and Roman phase windows, and saves filtered site objects.
#
# Algorithm: a site is included in a phase if at least one of its attested
# periods overlaps the target window by > MIN_OVERLAP_YEARS (25 years).
# No weighting; binary inclusion only.
#
# Input:  data/sites.gpkg   (143 sites, already contains corrected DUR024
#                             coordinates — see REFACTOR_NOTES.md §2)
# Output: output/rds/siti_hell.rds
#         output/rds/siti_rom.rds
# =============================================================================

# --- Data loading ------------------------------------------------------------
# sites.gpkg is the authoritative source; siti.csv is a tabular export
# used only for site-type labels in later scripts.
# The gpkg already carries the corrected DUR024 (Ad Quintum) coordinates.
siti_raw <- st_read(data_path("sites.gpkg"))

# --- Chronological dictionary (astronomical years: negative = BC) ------------
chrono_dict <- list(
  neo_ant  = c(-6500, -5500), neo_med  = c(-5500, -4500),
  neo_fin  = c(-4500, -3600), eneol    = c(-3600, -2300),
  bron_gen = c(-2300, -1100), bron_rec = c(-1500, -1100),
  ott_ac   = c(-800,  -700),  sett_ac  = c(-700,  -600),
  ses_ac   = c(-600,  -500),  qui_ac   = c(-500,  -400),
  qua_ac   = c(-400,  -300),  ter_ac   = c(-300,  -200),
  sec_ac   = c(-200,  -100),  pri_ac   = c(-100,     0),
  republ   = c(-509,   -27),  imper    = c(-27,    284),
  roman    = c(-168,   395),  lateant  = c(284,    600),
  pri_dc   = c(0,    100),    sec_dc   = c(100,    200),
  ter_dc   = c(200,  300),    qua_dc   = c(300,    400),
  qui_dc   = c(400,  500),    ses_dc   = c(500,    600),
  sett_dc  = c(600,  700)
)

# --- Phase assignment --------------------------------------------------------
site_phase <- do.call(rbind, lapply(seq_len(nrow(siti_raw)), function(i) {
  row <- as.list(siti_raw[i, ])
  data.frame(
    id_sito        = row[["id_sito"]],
    in_hellenistic = site_in_window(row, chrono_dict, "id_sito",
                                    HELL_START, ROM_BOUND),
    in_roman       = site_in_window(row, chrono_dict, "id_sito",
                                    ROM_BOUND,  ROM_END),
    stringsAsFactors = FALSE
  )
}))
site_phase$dual_phase <- site_phase$in_hellenistic & site_phase$in_roman

# --- Diagnostic: cross-tabulate Hellenistic vs Roman assignment --------------
message("Phase assignment cross-table:")
print(table(site_phase$in_hellenistic, site_phase$in_roman, useNA = "ifany"))

# Per-period raw counts (useful to check dictionary coverage)
raw_period_counts <- sapply(names(chrono_dict), function(p) {
  if (p %in% names(siti_raw)) sum(is_active(siti_raw[[p]]), na.rm = TRUE) else 0
})
message("Active sites per period:")
print(sort(raw_period_counts, decreasing = TRUE))

# Dual-phase detail: which periods activate each site in both windows
dual_detail <- do.call(rbind, lapply(seq_len(nrow(siti_raw)), function(i) {
  explain_dual_phase(as.list(siti_raw[i, ]), chrono_dict, "id_sito",
                     c(HELL_START, ROM_BOUND), c(ROM_BOUND, ROM_END))
}))
message("Dual-phase sites and activating periods:")
print(dual_detail)

# --- Build spatial objects ---------------------------------------------------
siti_sf <- siti_raw %>%
  left_join(site_phase, by = "id_sito") %>%
  filter(!is.na(jx), !is.na(Sy), !is.na(in_hellenistic)) %>%
  st_as_sf(coords = c("jx", "Sy"), crs = CRS_UTM)

siti_hell <- siti_sf %>% filter(in_hellenistic)
siti_rom  <- siti_sf %>% filter(in_roman)

message("Hellenistic sites: ", nrow(siti_hell),
        " | Roman sites: ",    nrow(siti_rom))

# --- Save -------------------------------------------------------------------
saveRDS(siti_hell, rds_path("siti_hell.rds"))
saveRDS(siti_rom,  rds_path("siti_rom.rds"))
message("Saved siti_hell.rds and siti_rom.rds")
