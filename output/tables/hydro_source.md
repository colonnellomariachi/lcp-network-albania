# Fonte del layer idrografico (Parte 2, Task 9)

Generato da `R/12_hydrographic_sensitivity.R` il 2026-10-03.

## Fonte

- **OpenStreetMap**, elementi `waterway=river` (way), © OpenStreetMap contributors, licenza ODbL 1.0.
- Snapshot del database OSM: 2026-05-31T22:37:44Z; scaricato il 2026-10-03 tramite Overpass API (mirror `overpass.private.coffee`; `overpass-api.de` non disponibile per sovraccarico).
- Query: `[out:json][timeout:180];way["waterway"="river"](40.80,19.10,41.80,20.50);out geom tags;`
- File salvato: `data/hydro/osm_rivers_raw.json`; selezione: `data/hydro/rivers_main.gpkg` (EPSG:32634).
- Il layer usato in passato per la maschera non è presente nel progetto e non è stato recuperato. `waterbodies.gpkg` (fornito dall'autore) contiene solo poligoni di laghi e invasi (molti artificiali, XX secolo), senza linee fluviali, e non è stato usato.
- Il tracciato è moderno (alvei canalizzati/rettificati, specie nella piana costiera): va dichiarato come approssimazione dei corsi antichi.

## Elementi inclusi

Aste principali di Ishëm, Erzen e Shkumbin e i tre fiumi dalla cui confluenza nasce l'Ishëm (Tërkuzë, Tirana, Zeza). OSM non distingue un rango gerarchico fra i `waterway=river`, quindi la selezione è per nome (`HYDRO_RIVER_NAMES` in `00_setup.R`).

| nome | way OSM | km nell'area | wikidata |
|---|---|---|---|
| Shkumbini | 41 | 132.6 | Q736668 |
| Erzeni | 1 | 52.3 | Q60492 |
| Lumi Erzenit | 3 | 28.8 |  |
| Tiranë | 51 | 28.5 |  |
| Zeza | 8 | 28.0 |  |
| Lumi i Tërkuzës | 7 | 26.6 | Q116808 |
| Ishëm | 3 | 18.9 |  |
| Tërkuzë | 2 | 10.4 |  |
| Lumi i Tiranës | 14 | 10.1 |  |

## Elementi esclusi (presenti nell'estensione del DEM)

| nome | way OSM | km nell'area | wikidata |
|---|---|---|---|
| (senza nome) | 67 | 304.6 |  |
| Mat | 14 | 108.1 | Q519866 |
| Devoll | 20 | 49.9 | Q83839 |
| Rrapun | 1 | 19.9 |  |
| Drini i Zi | 3 | 18.4 |  |
| Lana | 28 | 17.3 |  |
| Peza | 1 | 16.7 |  |
| Lumi i Drojës | 3 | 14.1 | Q22012361 |
| Lumi i Semanit | 1 | 12.7 | Q81632 |
| Seta | 1 | 9.9 |  |
| Lumi i Fandit | 1 | 8.6 |  |
| Fan | 1 | 6.6 |  |
| Gjole | 7 | 6.6 | Q5566034 |
| Zaranika | 1 | 5.2 |  |
| Lumi Drin | 2 | 4.0 |  |
| Batra | 1 | 3.6 |  |
| Kanali Tanës | 1 | 1.0 |  |

## Trattamento

- Linee bufferizzate di 25 m e rasterizzate sulla griglia del DEM (25 m, `touches = TRUE`): 42825 celle fluviali (27.0 km²). Fascia ≥ 2 celle, quindi non scavalcabile con un passo a 16 vicini.
- Penalità di attraversamento: costo di ingresso in una cella fluviale × 5 e ×20 (colonne della matrice di conduttanza divise per il fattore). Nessuna barriera assoluta, nessuna cella NoData aggiunta.
- Siti che cadono in una cella fluviale: nessuno.

## DUR103 (Capo Rodon)

- La penalità non crea celle NoData, quindi la regola di spostamento è la stessa della pipeline pubblicata: DUR103 cade in una cella NoData (mare, non fiume; distanza dal fiume selezionato più vicino 9287 m) e viene spostato di un pixel (73 m, cella 3143022), come nelle reti senza penalità. Nessun altro sito viene spostato.
- Celle di origine degli LCP penalizzati identiche a quelle della corrispondente rete senza penalità in tutti i casi: sì.
- Nelle reti romane (output del loop) DUR103 resta isolato per lo stesso artefatto di `04` documentato in `factorial_dur103_sensitivity.csv`; il confronto con la rete senza penalità è quindi omogeneo.
