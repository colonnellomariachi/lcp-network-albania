# =============================================================================
# functions/chronology_helpers.R
# Shared helpers for binary chronological phase assignment.
# =============================================================================

#' Test whether a period column value counts as active
#'
#' Handles both representations found in the project's source files:
#'   - "TRUE" / "FALSE" strings (from siti.csv)
#'   - 1 / 0 integers       (from sites.gpkg)
#'   - logical TRUE / FALSE
#'
#' @param x  A scalar value from a boolean period column (may be NA).
#' @return   Logical scalar: TRUE if the column records occupation.
is_active <- function(x) {
  if (all(is.na(x))) return(FALSE)
  s <- trimws(tolower(as.character(x)))
  s == "true" | s == "1"
}

#' Test whether two time intervals overlap by more than a minimum duration
#'
#' @param p_start    Start of the period (astronomical year).
#' @param p_end      End of the period.
#' @param w_start    Start of the target window.
#' @param w_end      End of the target window.
#' @param min_overlap  Minimum overlap length required (years); default from
#'                     global MIN_OVERLAP_YEARS.
#' @return Logical scalar.
overlaps_min <- function(p_start, p_end, w_start, w_end,
                         min_overlap = MIN_OVERLAP_YEARS) {
  ov_start <- pmax(p_start, w_start)
  ov_end   <- pmin(p_end,   w_end)
  (ov_end - ov_start) > min_overlap
}

#' Assign a site row to a chronological window (binary yes/no)
#'
#' @param row     Named list (one row of the sites data frame).
#' @param dict    Chronological dictionary: named list of c(start, end) vectors.
#' @param id_col  Name of the site-ID column (character).
#' @param w_start Start of the target window.
#' @param w_end   End of the target window.
#' @return Logical scalar, or NA if no period columns are active.
site_in_window <- function(row, dict, id_col, w_start, w_end) {
  active <- names(dict)[vapply(names(dict), function(p) {
    p %in% names(row) && is_active(row[[p]])
  }, logical(1))]
  if (length(active) == 0) return(NA)
  any(vapply(active, function(p) {
    overlaps_min(dict[[p]][1], dict[[p]][2], w_start, w_end)
  }, logical(1)))
}

#' Diagnostic: return which periods activate a site for both phases
#'
#' @param row        Named list (one row of the sites data frame).
#' @param dict       Chronological dictionary.
#' @param id_col     Name of the site-ID column.
#' @param hell_w     Numeric vector c(start, end) for the Hellenistic window.
#' @param rom_w      Numeric vector c(start, end) for the Roman window.
#' @param min_overlap Minimum overlap (years).
#' @return  data.frame with columns id_sito, hell_periods, rom_periods,
#'          or NULL if the site is not dual-phase.
explain_dual_phase <- function(row, dict, id_col, hell_w, rom_w,
                               min_overlap = MIN_OVERLAP_YEARS) {
  active <- names(dict)[vapply(names(dict), function(p) {
    p %in% names(row) && is_active(row[[p]])
  }, logical(1))]
  if (length(active) == 0) return(NULL)
  hell_hits <- active[vapply(active, function(p)
    overlaps_min(dict[[p]][1], dict[[p]][2], hell_w[1], hell_w[2], min_overlap),
    logical(1))]
  rom_hits  <- active[vapply(active, function(p)
    overlaps_min(dict[[p]][1], dict[[p]][2], rom_w[1],  rom_w[2],  min_overlap),
    logical(1))]
  if (length(hell_hits) > 0 && length(rom_hits) > 0) {
    data.frame(id_sito     = row[[id_col]],
               hell_periods = paste(hell_hits, collapse = ","),
               rom_periods  = paste(rom_hits,  collapse = ","),
               stringsAsFactors = FALSE)
  } else NULL
}

#' Chronological dictionary (astronomical years: negative = BC)
#'
#' Same values as the dictionaries defined in 01_chronology.R and
#' 10_discussion_checks.R; used by 13_size_horizon_sensitivity.R.
CHRONO_DICT <- list(
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
