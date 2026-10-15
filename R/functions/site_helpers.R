# =============================================================================
# functions/site_helpers.R
# Site labels (tipo_sito, def_sito, toponyms) shared by 06, 09, 10 and 11.
# =============================================================================

# English labels (names = labels as stored in sites.gpkg, "città" repaired)
TIPO_EN <- c("urban settlement"       = "urban settlement",
             "minor settlement"       = "minor settlement",
             "rural settlement"       = "rural settlement",
             "sacred place"           = "sacred place",
             "area di frequentazione" = "frequentation area",
             "(missing)"              = "unclassified")
DEF_EN <- c("citt\u00e0"               = "city",
            "centro fortificato"       = "fortified centre",
            "insediamento generico"    = "generic settlement",
            "complesso funerario"      = "funerary complex",
            "complesso monastico"      = "monastic complex",
            "mansio/statio"            = "road station (mansio/statio)",
            "necropoli"                = "necropolis",
            "sepoltura"                = "burial",
            "vicus"                    = "vicus",
            "fattoria"                 = "farmstead",
            "villa"                    = "villa",
            "basilica paleocristiana"  = "Early Christian basilica",
            "chiesa"                   = "church",
            "santuario"                = "sanctuary",
            "(missing)"                = "unspecified")

# Toponyms used in the text for the upland centres and Hamallaj
FOCUS_TOPONYMS <- c(DUR032 = "Dorez", DUR053 = "Mliku", DUR015 = "Zgerdesh",
                    DUR025 = "Shenlliu", DUR003 = "Hamallaj")

#' Site labels from sites.gpkg
#'
#' "città" is stored with U+FFFD in place of "à" (the latin1 byte was lost on
#' export; iconv(latin1) would turn it into "cittï¿½"); it is repaired here.
#' Missing tipo_sito / def_sito stay NA (tipo_orig / def_orig carry
#' "(missing)"). `toponym` is FOCUS_TOPONYMS, else localita, else comune,
#' else id_sito.
#' @return data.frame: id_sito, tipo_sito, def_sito, tipo_orig, def_orig,
#'   tipo_en, def_en, localita, comune, toponym
read_site_labels <- function() {
  s <- sf::st_drop_geometry(sf::st_read(data_path("sites.gpkg"), quiet = TRUE))[
    , c("id_sito", "tipo_sito", "def_sito", "localita", "comune")]
  s$def_sito <- sub("^citt\uFFFD$", "citt\u00e0", s$def_sito)
  for (v in c("localita", "comune")) {   # empty strings are missing values
    s[[v]] <- trimws(s[[v]]); s[[v]][!is.na(s[[v]]) & s[[v]] == ""] <- NA
  }
  s$tipo_orig <- ifelse(is.na(s$tipo_sito), "(missing)", s$tipo_sito)
  s$def_orig  <- ifelse(is.na(s$def_sito),  "(missing)", s$def_sito)
  stopifnot("unmapped tipo_sito label" = all(s$tipo_orig %in% names(TIPO_EN)),
            "unmapped def_sito label"  = all(s$def_orig  %in% names(DEF_EN)),
            "U+FFFD left in the labels" =
              !any(grepl("\uFFFD", c(s$def_sito, s$tipo_sito, s$localita, s$comune))))
  s$tipo_en <- unname(TIPO_EN[s$tipo_orig])
  s$def_en  <- unname(DEF_EN[s$def_orig])
  s$toponym <- ifelse(s$id_sito %in% names(FOCUS_TOPONYMS), FOCUS_TOPONYMS[s$id_sito],
                      ifelse(!is.na(s$localita), s$localita,
                             ifelse(!is.na(s$comune), s$comune, s$id_sito)))
  s
}
