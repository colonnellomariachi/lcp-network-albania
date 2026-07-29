# PROVENANCE_egnatia.md

Tracciabilità completa dei file di validazione Via Egnatia.
Ultimo aggiornamento: 2026-07-28.

---

## §1 — Provenienza di `egnatia_validation_segments_fixed.csv` e `egnatia_validation_full_fixed.csv`

**Timestamp**: entrambi i file portano data di modifica 2026-07-28 14:50.

**Script generatore**: NON sono stati prodotti da `08_egnatia_validation.R`.
Sono stati prodotti da una sessione R interattiva con il codice ad-hoc
`fix_pdi()` riportato nell'handover del task (2026-07-28). Il codice sorgente
generatore non esiste come file separato nel repository.

**Relazione con DUR024**: i file `wp_snapped.rds` e `egnatia_known_segments.rds`
da cui dipendono sono stati scritti da `08_egnatia_validation.R` alle 12:27
dello stesso giorno. Quella run ha applicato la correzione delle coordinate
DUR024 (X_FIXED=417306.64, Y_FIXED=4549673.05) e poi snappato DUR024 alla
route, ottenendo la posizione effettiva X=417339, Y=4549626. I `_fixed.csv`
derivano **dopo** il riposizionamento di DUR024.

**Significato del suffisso `_fixed`**: correzione del **bug PDI** (`st_make_valid`
applicato prima di `st_area`). NON si riferisce alla correzione di DUR024
(già incorporata nella run delle 12:27).

**File canonici da ora in poi**: `egnatia_pdi_final.csv` (valori PDI corretti),
`egnatia_pdi_comparison_bug.csv` (confronto side-by-side), entrambi prodotti
da `08_egnatia_validation.R` tramite `pdi_fixed()` in `R/functions/pdi_validation_fixed.R`.

---

## §2 — Verifica geometrica dei waypoint (Task 4)

### Coordinate dei quattro waypoint (da `wp_snapped.rds`, post-snap)

| # | id_sito | X (UTM34N, m) | Y (UTM34N, m) | Identificazione |
|---|---------|--------------|--------------|-----------------|
| 1 | DUR001  | 370 032      | 4 574 267    | Dyrrachium (Durrës) |
| 2 | DUR022  | 411 384      | 4 545 538    | Clodiana |
| 3 | DUR024  | 417 339      | 4 549 626    | Ad Quintum (snapped) |
| 4 | DUR017  | 422 882      | 4 551 613    | Scampis (Elbasan) |

### Distanze euclidee fra coppie consecutive

| Segmento | Da → A | Corda (m) | Corda (km) |
|----------|--------|-----------|-----------|
| seg1 | DUR001 → DUR022 | 50 864 | 50.86 |
| seg2 | DUR022 → DUR024 |  7 236 |  7.24 |
| seg3 | DUR024 → DUR017 |  5 874 |  5.87 |
| full | DUR001 → DUR017 | 57 501 | 57.50 |
| somma seg | — | 63 974 | 63.97 |

*Nota*: i valori nelle righe `max_distance` di `egnatia_pdi_final.csv`
differiscono leggermente dai valori qui sopra perché `pdi_fixed()` prende
il primo e l'ultimo **vertice del comparison** (non le coordinate dei
waypoint). Per i segmenti, il comparison è `known_segments[[i]]`, estratto
per indice di vertice dalla route digitizzata; l'endpoint corrisponde al
waypoint più vicino ma non è identico al millimetro. Le differenze sono
dell'ordine di 0–30 m e non influenzano i risultati.

### Posizione di DUR022 (Clodiana)

Distanza perpendicolare di DUR022 dalla retta DUR001–DUR017:

```
d_perp = |dx_line * dy_point - dy_line * dx_point| / |DUR001→DUR017|
       = 10 113 m  ≈  10.1 km
```

(Il valore "ΔY = 28.729 m" riportato in una versione precedente di questo
file era lo scarto grezzo in Y, non la distanza perpendicolare. Corretto qui.)

La corda DUR001→DUR022 di 50.86 km è coerente con l'identificazione topografica
di Clodiana in letteratura (~34–35 miglia romane da Dyrrachium; 1 mp ≈ 1 481 m
→ 50–52 km), conforme a Itiner-e (De Soto et al. 2025) e a Moderato 2021.

La discrepanza fra somma delle corde (63.97 km) e corda totale (57.50 km) è
geometricamente normale: DUR022 si trova 10.1 km a sud della retta diretta
DUR001–DUR017, rendendo il tracciato arcuato.

### Ordine dei segmenti e direzione

Verificato con `stopifnot(!is.unsorted(wp_vertex, strictly = TRUE))` in
`08_egnatia_validation.R`. Nessuna sovrapposizione o inversione.

### Conclusione Task 4

Nessuna anomalia. Gli endpoint reggono. Il segmento 1 (wheeled 0.909, baseline
12.740) è il risultato più robusto perché DUR022 è verificato con letteratura
indipendente.

---

## §3 — Riconciliazione del `max_distance` del percorso completo (Task A)

**max_distance = 52 402.42 m** nella riga `full route` di `egnatia_pdi_final.csv`.

**Spiegazione**: `pdi_fixed()` calcola `max_distance` come distanza euclidea
fra il **primo e l'ultimo vertice del comparison** passato alla funzione. Per
la riga `full route` il comparison è `egnatia_full_sf = st_sf(geometry = egnatia)`,
ossia la route digitizzata dopo stitching.

Coordinate dei vertici estremi di `egnatia_stitched.rds`:

| Vertice | X (m) | Y (m) | Distanza da waypoint |
|---------|--------|--------|----------------------|
| Primo (v[1]) | 374 902 | 4 572 680 | 5 121 m da DUR001 |
| Ultimo (v[1053]) | 422 882 | 4 551 613 | 0 m da DUR017 (coincide) |

Il primo vertice è **5 121 m a est-nordest di DUR001**, NON a ovest. La route
digitizzata non si estende fino a DUR001: inizia 5 121 m più a est. La route
termina esattamente a DUR017.

Pertanto:
- max_distance (full route PDI) = corda v[1]→DUR017 = **52 402 m**
- Corda DUR001→DUR017 = **57 501 m**
- 52 402 < 57 501 perché v[1] è più vicino a DUR017 di quanto lo sia DUR001

**Conseguenza**: la riga `full route` di `egnatia_pdi_final.csv` compara
l'LCP end-to-end con un comparison che **esclude i 5 121 m occidentali**
(dal primo vertice digitizzato a DUR001). I valori `normalised_pdi` del
percorso completo vanno citati con questa precisazione oppure sostituiti
con i valori `full route (truncated)` che usano un comparison troncato al
vertice più vicino a DUR001 (771 m di distanza, indice 78):

| | wheeled | tobler | baseline |
|--|---------|--------|---------|
| full route (stitched, max_dist=52402) | 30.595 | 25.135 | 22.411 |
| full route (truncated, max_dist=57798) | 25.068 | 20.600 | 18.485 |

**Raccomandazione**: usare i valori `truncated` nel manoscritto, perché il
comparison troncato ha la stessa estensione della concatenazione dei tre
segmenti (entrambi 77 748 m), rendendo i numeri direttamente confrontabili.

---

## §4 — Diagnostica poligoni PDI (Task C)

Vedere `output/tables/pdi_geom_diagnostics.csv`.

Risultati per tutti i 9 casi (3 segmenti × 3 funzioni di costo):

- `geom_class` dopo `st_make_valid()`: **"XY"** (POLYGON semplice) in tutti
  i 9 casi — nessuna GEOMETRYCOLLECTION.
- `n_lobes`: **1** in tutti i casi — nessun poligono multi-lobo.
- `area_sum_check == area_selected` in tutti i casi — la somma delle parti
  coincide con l'area totale (coerente con n_lobes=1).

La **riga bianca** visibile nei pannelli `seg1 | tobler` e `seg3 | wheeled`
del QC panel è un **artefatto di rendering** (bordo trasparente del
`geom_raster` / `geom_sf` con `alpha < 1`), non un lobo perso. Confermato
da n_lobes=1 e area_sum_check consistente.

Nota su `seg1 | tobler`: i due candidati hanno aree quasi identiche
(477 729 415 vs 474 196 922, differenza 0.74%). `which.min` seleziona il
candidato 2 (474 196 922). La selezione è stabile: anche invertendo la
scelta l'area differisce di soli 3.5 km².

---

## §5 — Validazione indipendente per campionamento (Task D)

Vedere `output/tables/pdi_independent_check.csv`.

Metodologia: campionamento del comparison a 200 m, calcolo della distanza
minima di ciascun punto all'LCP modellato, confronto della media con PDI.

I valori `mean_dist_to_lcp_m` risultano sistematicamente inferiori al PDI
di 0–570 m (il campionamento media la distanza lungo tutto il comparison,
mentre PDI = area/corda-retta con corda < lunghezza comparison). La
direzione e l'ordine di grandezza sono coerenti. Caso di controllo
(seg3, wheeled): mean_dist = 208.2 m, PDI = 214.0 m — differenza 2.7%.

**Conclusione**: il PDI corretto è geometricamente plausibile in tutti i
9 casi.

---

## §6 — PDI percorso completo troncato vs somma segmenti (Task F)

Vedere `output/tables/full_route_truncated_comparison.csv`.

Il comparison troncato (vertice 78 → DUR017, lunghezza 77 748 m) copre
**esattamente la stessa estensione** della concatenazione dei tre segmenti
(77 748 m): l'equivalenza è confermata numericamente.

| Metrica | wheeled | tobler |
|---------|---------|--------|
| Somma aree per-segmento | 27.5 km² | 478.3 km² |
| Area LCP libero vs comparison troncato | 837.4 km² | 688.2 km² |
| Rapporto LCP libero / somma segmenti | **30.5×** | 1.44× |

La singola route wheeled libera (non vincolata ai waypoint intermedi)
produce un'area di deviazione 30× superiore alla somma delle tre deviazioni
dei percorsi vincolati. A parità di estensione del confronto il divario
resta ampio: l'argomento §5.5 è **solido**.

(Per il tobler il rapporto è 1.44× perché la deviazione del segmento 1
dominata dalla rotta per le highlands occupa già 474 km² da sola.)

---

## §7 — Issue sul bug PDI

L'issue sul repository `leastcostpath` (Lewis 2023) verrà aperta separatamente.
Il numero e l'URL dell'issue saranno annotati qui una volta disponibili.

**[PLACEHOLDER]** Issue leastcostpath GitHub: URL e numero da inserire.

Vedere `output/METHODS_pdi_note.md` per tutti gli elementi tecnici.
