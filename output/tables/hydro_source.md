# Fonte del layer idrografico

Generato da `R/12_hydrographic_sensitivity.R` il 2026-10-05.

## Layer

- File: `data/river polygon.gpkg` (layer `waterbodies__water_bodies`), poligoni delle aree dei corsi dei fiumi principali, prodotto dall'autore. Sostituisce le linee OSM con buffer di 25 m del Task 9.
- Elementi: 24; geometria: MULTIPOLYGON; campi: NAME, TYPE, NATION, CNTRYNAME, RANK, SQKM, Shape_Leng, Shape_Area.
- CRS: EPSG:32634 (nessuna riproiezione).
- Area totale: 39.80 km².
- Validità (`sf::st_is_valid`): 0 elementi invalidi su 24.
- Sovrapposizioni: 1 coppie di poligoni sovrapposti; i poligoni sono uniti (`st_union`) prima della rasterizzazione; area dell'unione 39.80 km².

## Elementi per nome

| NAME | poligoni | km² |
|---|---|---|
| Liqeni i Shkumbinit | 3 | 14.38 |
| Liqeni i Erzenit | 2 | 8.51 |
| Liqeni i Tiranës | 1 | 2.36 |
| Perror i Zhullimës | 1 | 2.32 |
| Liqeni i Darçit | 1 | 2.08 |
| Liqeni i Ishmit | 3 | 1.83 |
| Liqeni i Pezës | 1 | 1.51 |
| Liqeni i Zezës | 1 | 1.19 |
| Durrës | 1 | 1.05 |
| Kavajë | 1 | 1.05 |
| Laç | 1 | 1.03 |
| Liqeni i Gjolës | 3 | 0.79 |
| Liqeni i Tërkuzës | 2 | 0.67 |
| Perror i Murdharit | 1 | 0.52 |
| Elbasan | 1 | 0.43 |
| Tiranë | 1 | 0.07 |

## Rasterizzazione e trattamento

- Griglia del DEM (stessa estensione, risoluzione e allineamento). Una cella è fluviale se il suo centro cade dentro un poligono (`terra::rasterize` predefinito, senza `touches = TRUE`).
- Celle fluviali: 62870 (39.7 km²); altre 128 celle dentro i poligoni sono NoData nel DEM e restano non attraversabili. Task 9 (linee OSM + buffer 25 m, `touches = TRUE`): 42825 celle (27.0 km²).
- Penalità di attraversamento: costo di ingresso in una cella fluviale × 5 e ×20 (colonne della matrice di conduttanza divise per il fattore). Nessuna barriera assoluta, nessuna cella NoData aggiunta.
- Nessun sito viene spostato: la pipeline si ferma se un sito cade su NoData.

## Siti dentro i poligoni fluviali (da dichiarare in Methods)

Posizioni dalla geometria di `data/sites.gpkg`. Per un sito su cella fluviale la penalità si applica ai passi che entrano nella sua cella, non a quelli che ne escono.

Nessun sito cade dentro un poligono fluviale o su una cella fluviale.

## File non più usati

- `data/hydro/osm_rivers_raw.json`, `data/hydro/rivers_main.gpkg` (Task 9, linee OSM): non letti da nessuno script.
- `waterbodies.gpkg` nella radice del progetto: non letto da nessuno script.
