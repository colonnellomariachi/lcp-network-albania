# METHODS_pdi_note.md — elementi fattuali per il paragrafo di Methods

Generato programmaticamente da `egnatia_pdi_final.csv` e
`egnatia_pdi_comparison_bug.csv`. Solo elementi fattuali — la prosa viene
scritta dopo. Non modificare a mano: rigenerare rileggendo i CSV.

---

## Versioni software

- R: 4.5.1 (2025-06-13)
- leastcostpath: 2.0.13
- sf: 1.0.21
- GEOS: 3.13.1
- GDAL: 3.11.0
- PROJ: 9.6.0

---

## Comportamento osservato del bug

`leastcostpath::PDI_validation()` (v 2.0.13) costruisce il poligono PDI come
`st_polygon(list(rbind(coords_lcp_reversed, coords_comparison)))` e chiama
`sf::st_area()` direttamente sul risultato, senza prima verificare o riparare
la validità geometrica.

Quando il percorso modellato e il percorso attestato si incrociano, l'anello
si auto-interseca (geometria "figure-eight"). GEOS 3.13 restituisce l'area
algebrica con segno, che per una figura-otto si annulla parzialmente,
producendo valori ordini di grandezza inferiori all'area reale della striscia.
Il bug affetta anche `which.min`: poiché entrambi i candidati sono invalidi,
la selezione del candidato minore può essere sbagliata.

`was_valid_before = FALSE` per tutte le 12 righe di `egnatia_pdi_final.csv`
(8 casi segmenti + 4 percorso completo, compreso baseline straight).

### Caso più grave — segmento 3 (Ad Quintum → Scampis, wheeled transport)

```
st_is_valid(polygon originale)          → FALSE
st_area(polygon originale)              → ~5 306 m²   [CORROTTO]
st_area(st_make_valid(polygon))         → 1 257 048 m² [CORRETTO]
normalised_pdi (corrotto, da pkg)       → 0.015
normalised_pdi (corretto, da pdi_fixed) → 3.643
fattore di errore                       → ~243×
```

---

## Correzione applicata

Funzione `pdi_fixed()` in `R/functions/pdi_validation_fixed.R`:

1. Costruisce i due candidati esattamente come la funzione originale.
2. Applica `sf::st_make_valid()` a **entrambi** prima di qualsiasi calcolo
   di area e prima di `which.min`.
3. Somma le aree di tutte le componenti POLYGON risultanti.
4. `max_distance` = distanza euclidea fra primo e ultimo vertice del
   *comparison* — identica alla funzione originale.
5. Restituisce un data.frame con colonne diagnostiche (geom class, n_lobes,
   area di entrambi i candidati, was_valid_before, n_crossings).

Geometria risultante: in tutti i 12 casi il poligono post-`st_make_valid()`
è un POLYGON semplice (`geom_class = "XY"`, `n_lobes = 1`). Nessuna
GEOMETRYCOLLECTION.

---

## Tabella di confronto — valori pkg (corrotti) vs corretti

(Fonte: `egnatia_pdi_comparison_bug.csv`. Solo wheeled e tobler; straight
baseline non presente nel CSV originale del pacchetto.)

| Segmento | Cost fn | PDI_norm corrotto | PDI_norm corretto | delta_abs | fattore |
|---|---|---|---|---|---|
| DUR001 → DUR022 | wheeled | 0.522 | 0.909 | +0.388 | 1.74× |
| DUR001 → DUR022 | tobler  | 6.031 | 18.329 | +12.299 | 3.04× |
| DUR022 → DUR024 | wheeled | 5.103 | 5.145 | +0.042 | 1.01× |
| DUR022 → DUR024 | tobler  | 3.991 | 5.940 | +1.948 | 1.49× |
| DUR024 → DUR017 | wheeled | 0.015 | 3.643 | +3.628 | 243× |
| DUR024 → DUR017 | tobler  | 0.568 | 2.991 | +2.423 | 5.27× |
| full route | wheeled | 13.378 | 30.595 | +17.217 | 2.29× |
| full route | tobler  | 19.130 | 25.135 | +6.005 | 1.31× |

*Nota*: i valori "corrotti" per il percorso completo derivano da
`egnatia_validation_full.csv` (prodotto da `validate_segment()` che usa la
funzione originale del pacchetto); il confronto diretto è pertanto indicativo.

---

## Valori canonici (fonte: `egnatia_pdi_final.csv`)

### Per-segmento

| Segmento | Cost fn | area_selected (m²) | max_distance (m) | PDI_norm | rank |
|---|---|---|---|---|---|
| DUR001 → DUR022 | wheeled transport | 23 523 225 | 50 863 | 0.909 | 1 |
| DUR001 → DUR022 | straight baseline | 329 602 235 | 50 863 | 12.740 | 2 |
| DUR001 → DUR022 | tobler | 474 196 922 | 50 863 | 18.329 | 3 |
| DUR022 → DUR024 | wheeled transport | 2 693 780 | 7 236 | 5.145 | 1 |
| DUR022 → DUR024 | tobler | 3 110 033 | 7 236 | 5.940 | 2 |
| DUR022 → DUR024 | straight baseline | 3 935 704 | 7 236 | 7.517 | 3 |
| DUR024 → DUR017 | straight baseline | 927 558 | 5 874 | 2.688 | 1 |
| DUR024 → DUR017 | tobler | 1 031 872 | 5 874 | 2.991 | 2 |
| DUR024 → DUR017 | wheeled transport | 1 257 048 | 5 874 | 3.643 | 3 |

### Percorso completo (comparison = egnatia_stitched, max_dist = 52 402 m)

| Cost fn | area_selected (m²) | PDI_norm |
|---|---|---|
| straight baseline | 615 412 865 | 22.411 |
| tobler | 690 216 160 | 25.135 |
| wheeled transport | 840 135 576 | 30.595 |

Ordine: baseline < tobler < wheeled. Nessuna funzione di costo batte la
linea retta end-to-end. Vedere PROVENANCE §3 per la spiegazione del
`max_distance` del percorso completo (52 402 m, non 57 501 m).

### Percorso completo troncato (comparison troncato a DUR001–DUR017, max_dist = 57 798 m)

Fonte: `output/tables/full_route_truncated_comparison.csv`.
Comparison della stessa estensione (77 748 m) della concatenazione dei
tre segmenti.

| Cost fn | area_selected (m²) | PDI_norm |
|---|---|---|
| straight baseline | 617 516 220 | 18.485 |
| tobler | 688 162 893 | 20.600 |
| wheeled transport | 837 421 405 | 25.068 |

---

## Riproducibilità

La funzione del pacchetto (`PDI_validation`) è lasciata intatta. I valori
corrotti sono conservati in `egnatia_validation_segments.csv` e
`egnatia_validation_full.csv`. I valori corretti sono in
`egnatia_pdi_final.csv` (fonte canonica). Tutto è riprodotto re-eseguendo
`run_all.R` seguìto da `source(here("R","pdi_qc_plots.R"))`.
