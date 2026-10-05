# UPDATE — Task 9 (revisione JAMT)

Disegno fattoriale 2×2, sensibilità idrografica, orizzonte tardoantico.
Lavoro svolto fra il 2 e il 3 ottobre 2026; documento aggiornato al 5 ottobre 2026.

**Stato in una riga.** Le tre parti sono complete e riproducibili da script. Nessun
numero pubblicato è cambiato. Sono emersi tre problemi della pipeline esistente
(§2) che vanno decisi prima di riscrivere qualunque sezione del manoscritto.
Non è stato fatto alcun commit.

---

## 1. Cosa è stato fatto

### 1.1 Ordine seguito

Parte 1 Step 1 (regressione) → Parte 3 → Parte 1 Step 2–5 → Parte 2, come da consegna.

| criterio di stop | esito |
|---|---|
| la regressione della diagonale fallisce | non scattato (12/12 verifiche; vedi §2.3 per il grado mediano) |
| Dorez o Mliku nella rete romana solo per la fase tardoantica | non scattato (ma Dorez è al limite, §3.1) |
| il layer idrografico non si trova | **scattato**: mi sono fermato, poi ho proceduto con la tua autorizzazione al download (§3.3) |

### 1.2 File nuovi

| file | contenuto |
|---|---|
| `R/11_cost_function_factorial.R` | Parte 1: regressione, celle nuove, metriche, confronti, riepilogo |
| `R/12_hydrographic_sensitivity.R` | Parte 2: fiumi OSM, penalità ×5/×20, confronto con le reti senza penalità |
| `R/functions/lcp_helpers.R` | funzioni LCP condivise fra `03`, `11` e `12` |
| `tests/discussion_checks_baseline/q7_late_antique_horizon.csv` | baseline di regressione per Q7 |
| `data/hydro/osm_rivers_raw.json`, `rivers_main.gpkg` | snapshot OSM dei fiumi e selezione usata |

### 1.3 File modificati

| file | modifica |
|---|---|
| `R/00_setup.R` | carica `lcp_helpers.R`; aggiunti `HYDRO_PENALTIES`, `HYDRO_RIVER_NAMES`, `HYDRO_BUFFER_M`. **`ROM_END = 450` verificato e non toccato.** |
| `R/03_least_cost_paths.R` | la logica è stata spostata negli helper; le chiamate sono le stesse. Corretto il difetto di §2.2. **Non rieseguito** (solo controllo di sintassi). |
| `R/10_discussion_checks.R` | aggiunto il blocco Q7 con asserzioni; pattern della baseline esteso a `q[1-7]_` |
| `R/functions/network_helpers.R` | aggiunte `gini`, `build_cell_network`, `composition_row`, `centrality_table`, `concentration_row` |
| `run_all.R` | aggiunta la chiamata a `11` (non a `12`, vedi §4) |
| `CLAUDE.md` | pipeline, tabelle e note 16–18 |

`04_networks.r` e `05_centrality.R` **non sono stati modificati**.

### 1.4 Scelte tecniche che devi conoscere

- **Motore LCP veloce.** `leastcostpath::create_lcp()` ricostruisce il grafo a ogni
  chiamata e lancia un Dijkstra per ogni destinazione: circa 3,8 min per origine,
  cioè ~10 h per le due celle nuove. Ho scritto `compute_lcps_graph()`, che fa lo
  stesso calcolo (stesso grafo, pesi 1/conduttanza, stesso algoritmo) costruendo
  il grafo una volta sola. Verifiche: costi, geometrie e celle identici a
  `create_lcp()` su un sottoinsieme; scarto 0 sulle 990 coppie dual-phase
  pubblicate, per entrambe le funzioni. Tempo: ~25 min per insieme.
  `03` continua a usare le funzioni originali del pacchetto.
- **Nessun riuso delle coppie dual-phase**: le due celle nuove sono ricalcolate
  per intero; le coppie già esistenti servono solo da controllo.
- **Spostamento di DUR103 su finestra locale.** L'helper cerca il pixel valido più
  vicino in una finestra del DEM attorno al sito, invece di convertire l'intero
  DEM in punti. Restituisce la stessa cella della run pubblicata (3143022);
  `11` e `12` lo verificano con un'asserzione.
- **Strategia per insieme di siti** come in `03`: schema FETE per i siti
  ellenistici, schema loop per i romani.

---

## 2. Problemi trovati nella pipeline esistente

### 2.1 DUR103 (Capo Rodon) è isolato in R-W per un errore di `04`

- In `03` il sito cade su una cella NoData (mare) e viene spostato di 73 m.
- `04` riconduce gli LCP romani ai siti usando le coordinate **non** spostate: le
  186 righe di DUR103 restano con ID mancante e finiscono in un gruppo spurio di
  `edges_rom.rds` (`n_directions = 186`), scartato dalla soglia.
- Costi reali: DUR104 61,8 min, DUR106 67,2 min → 2 archi sotto i 150 min.
- La rete ellenistica non ha il problema (lo schema FETE porta gli ID dei siti).

| | archi | isolati | componenti | gigante |
|---|---|---|---|---|
| R-W pubblicata | 348 | 6 | 14 | 66 (70,2 %) |
| R-W con DUR103 risolto | 350 | 5 | 13 | 66 (70,2 %) |
| R-T come R-W | 1550 | 1 (DUR103) | 2 | 93 (98,9 %) |
| R-T con DUR103 risolto | 1554 | 0 | 1 | 94 (100 %) |

In R-W le misure di concentrazione non cambiano (DUR103 si aggancia a una
componente minore). I numeri pubblicati non sono stati toccati: R-T replica lo
stesso trattamento per restare confrontabile con R-W. Dettagli in
`factorial_dur103_sensitivity.csv`.

### 2.2 Rieseguire `03` avrebbe spostato anche DUR001 (Dyrrachium)

In una sessione R nuova il primo controllo di attraversabilità fallisce per un
errore tecnico (namespace `Matrix` non caricato). La funzione trattava qualunque
errore come "sito non attraversabile" e spostava il primo sito testato, DUR001.
Gli LCP pubblicati vengono dagli script in `archive/` e spostano solo DUR103,
quindi non sono toccati. La funzione è corretta in `lcp_helpers.R`.

Conseguenza: **prima della correzione, `run_all.R` non avrebbe riprodotto le reti
pubblicate.** Dopo la correzione dovrebbe, ma `03` non è stato rieseguito per
intero (§4).

### 2.3 Grado mediano di R-W = 7,5, non 8

Su 94 nodi la mediana è 7,5; 8 è la mediana senza i 6 isolati. Il grafo è
identico a `net_rom.rds`, quindi è una questione di definizione o di
arrotondamento nel testo. Ho tenuto 7,5 nel controllo di regressione.

---

## 3. Risultati

### 3.1 Parte 3 — orizzonte tardoantico

Output: `output/tables/q7_late_antique_horizon.csv` (24 righe).

- **Inizio ≥ 300 d.C.: 9 siti su 94 (9,6 %)** — DUR020, DUR042, DUR109, DUR112,
  DUR113, DUR114, DUR122, DUR135, DUR138. Nessuno è isolato.
- **Presenti solo grazie a 300–450 d.C.: 22 su 94 (23,4 %).** Ai 9 sopra si
  aggiungono 10 siti che iniziano nel 284 (periodo `lateant`) e 3 con una fase
  ellenistica e poi un vuoto fino al IV secolo (DUR006, DUR038, DUR045).
- Fra i 22 ci sono quattro dei primi dieci nodi per betweenness di R-W:
  DUR002 (rank 2), DUR056 (rank 3), DUR040 (rank 8), DUR034 (rank 9).
  Tre dei sei isolati sono fra i 22: DUR016, DUR030, DUR052.

| sito | date | rank betweenness | grado | resta con ROM_END = 300? |
|---|---|---|---|---|
| DUR002 Arapaj | 284–700 | 2 | 13 | no |
| DUR016 Gjuricai | 284–600 | isolato | 0 | no |
| DUR030 Ndroq | 284–600 | isolato | 0 | no |
| DUR032 Dorez | −600–500 | 65 (betw. 0) | 1 | sì, **solo via I sec. a.C.** |
| DUR053 Mliku | −400–600 | isolato | 0 | sì (occupazione continua) |

**Dorez.** Passa il criterio dei 25 anni anche con ROM_END = 300, ma solo per il
periodo `pri_ac` (−100/0): 31 anni di sovrapposizione con la finestra romana e
nessuna attestazione fra 0 e 300 d.C. È lo stesso margine già noto per DUR025.
Il criterio di stop non scatta alla lettera; la sostanza va valutata da te.

### 3.2 Parte 1 — disegno fattoriale 2×2

**Regressione (Step 1).** H-T e R-W ricostruite dagli LCP salvati coincidono con
gli oggetti pubblicati: archi, grafo, composizione, centralità per sito
(`all.equal` = TRUE su `centrality_comparison.csv`) e concentrazione. 12/12.

**Composizione.**

| cella | nodi | archi | densità | grado mediano | isolati | componenti | gigante |
|---|---|---|---|---|---|---|---|
| H-T | 71 | 1084 | 0,436 | 37 | 0 | 2 | 68 (95,8 %) |
| R-W | 94 | 348 | 0,080 | 7,5 | 6 | 14 | 66 (70,2 %) |
| H-W | 71 | 434 | 0,175 | 9 | 7 | 13 | 41 (57,7 %) |
| R-T | 94 | 1550 | 0,355 | 35,5 | 1 | 2 | 93 (98,9 %) |

Isolati in H-W: DUR003, DUR015, DUR025, DUR032, DUR041, DUR051, DUR053 — cioè
tutti e quattro i centri d'altura più Hamallaj.

**Concentrazione della betweenness.**

| cella | quota 1° nodo | Gini | Freeman | nodo di testa |
|---|---|---|---|---|
| H-T | 0,191 | 0,677 | 0,121 | DUR003 |
| R-T | 0,042 | 0,514 | 0,033 | DUR138 |
| H-W | 0,293 | 0,917 | 0,117 | DUR033 |
| R-W | 0,092 | 0,751 | 0,105 | DUR050 |

**Le tre domande dello Step 5 (solo numeri).**

1. *La concentrazione cala dall'ellenistico al romano in entrambi i confronti a
   funzione costante?* **Sì**, su tutte e tre le misure (tabella sopra: H-T→R-T
   e H-W→R-W).

2. *I centri d'altura perdono posizione in entrambi i confronti a funzione
   costante?* **No.**

   | sito | H-T | R-T | H-W | R-W |
   |---|---|---|---|---|
   | DUR032 Dorez | 2/71 (0,0302) | 4/94 (0,0353) | 0 | 0 |
   | DUR053 Mliku | 37/71 (0,0031) | 41/94 (0,0129) | 0 | 0 |
   | DUR015 Zgerdesh | 44/71 (0,0017) | 73/94 (0,0019) | 0 | 62/94 (0,0002) |
   | DUR025 Shenlliu | 60/71 (0) | 74/94 (0,0018) | 0 | 0 |
   | DUR003 Hamallaj | 1/71 (0,1284) | assente | 0 | assente |

   Rank / n (betweenness normalizzata). Con Tobler perdono rank percentile 2 su 4
   (Dorez, Zgerdesh), ma i valori di betweenness restano dello stesso ordine.
   Con il trasporto su ruota nessuno perde: 3 su 4 sono a zero in entrambe le
   celle. Il crollo compare a fase costante quando cambia la funzione
   (H-T→H-W: Dorez da rank 2 a isolato).

3. *Quanta parte del contrasto della diagonale si ritrova a funzione costante?*

   | misura | Δ diagonale (R-W − H-T) | Δ Tobler (R-T − H-T) | Δ ruota (R-W − H-W) | effetto funzione, ellenistico (H-W − H-T) | effetto funzione, romano (R-W − R-T) |
   |---|---|---|---|---|---|
   | quota 1° nodo | −0,099 | −0,150 (150 %) | −0,201 (202 %) | +0,102 | +0,050 |
   | Gini | +0,074 | −0,163 | −0,167 | +0,240 | +0,237 |
   | Freeman | −0,016 | −0,088 (567 %) | −0,012 (77 %) | −0,004 | +0,072 |

   Il Gini ha segno opposto: sale nella diagonale, scende a funzione costante.

**Test sulle centralità per sito** (Mann-Whitney su tutti i siti; Wilcoxon
appaiato e Spearman sui 46 dual-phase).

| metrica | confronto | mediane | p MW | p Wilcoxon (dual) | ρ (dual) |
|---|---|---|---|---|---|
| grado norm. | diagonale | 0,529 → 0,081 | <2e-16 | 3,6e-09 | 0,650 |
| grado norm. | H-T vs R-T | 0,529 → 0,382 | 0,001 | 0,14 | 0,755 |
| grado norm. | H-W vs R-W | 0,129 → 0,081 | 0,0023 | 0,79 | 0,715 |
| harmonic | diagonale | 0,714 → 0,255 | <2e-16 | 3,6e-09 | 0,665 |
| harmonic | H-T vs R-T | 0,714 → 0,648 | 0,00079 | 0,38 | 0,769 |
| harmonic | H-W vs R-W | 0,254 → 0,255 | 0,15 | 0,064 | 0,613 |
| betweenness | diagonale | 0,0038 → 0,0033 | 0,60 | 0,23 | 0,360 |
| betweenness | H-T vs R-T | 0,0038 → 0,0076 | 0,031 | 0,97 | 0,777 |
| betweenness | H-W vs R-W | 0,0001 → 0,0033 | 5,2e-05 | 0,047 | 0,534 |

**Confronti sincronici** (stessi siti, funzione diversa).

| confronto | ρ grado | ρ harmonic | ρ betweenness | primi dieci in comune |
|---|---|---|---|---|
| H-T vs H-W (n = 71) | 0,550 | 0,667 | 0,021 (p = 0,86) | 3 |
| R-T vs R-W (n = 94) | 0,806 | 0,842 | 0,282 (p = 0,006) | 0 |

Tutti i test, con statistica, p e n, sono in `factorial_tests.csv`. Le
statistiche di categoria dei centri fortificati (betweenness massima, grado
mediano) sono nelle righe `category` di `factorial_upland_centres.csv`.

### 3.3 Parte 2 — sensibilità idrografica

**Dato.** Nel progetto non c'era alcun layer idrografico (cercato in `data/`,
`archive/`, progetto QGIS, storia git, cronologia R). `waterbodies.gpkg`, che hai
caricato, contiene 167 poligoni di laghi e invasi, molti artificiali del XX
secolo, e nessuna linea fluviale: non è stato usato. Con la tua autorizzazione ho
scaricato da OpenStreetMap i `waterway=river` (snapshot OSM del 31/05/2026,
licenza ODbL). Fonte, query ed elenchi completi in `hydro_source.md`.

- **Inclusi** (per nome, in `HYDRO_RIVER_NAMES`): Shkumbin 132,6 km, Erzen
  81,1 km, Ishëm 18,9 km, e i tre fiumi che formano l'Ishëm — Tirana 38,6 km,
  Tërkuzë 37,0 km, Zeza 28,0 km.
- **Esclusi**: Mat, Devoll, Seman, Drin, Lana, Rrapun, Peza, Gjole e altri
  minori; 305 km di tratti senza nome.
- **Trattamento**: linee con buffer di 25 m rasterizzate sul DEM → 42 825 celle
  (27 km²). Il costo di ingresso in una cella fluviale è moltiplicato per 5 o
  per 20. Nessuna barriera assoluta. Nessun sito cade in una cella fluviale.
- **DUR103**: spostato sullo stesso pixel di prima. Il suo NoData è il mare, a
  9,3 km dal fiume selezionato più vicino. Nessun altro sito viene spostato.

**Risultati** (penalità 1 = rete senza penalità).

| rete | penalità | archi | isolati | componenti | gigante | quota 1° | Gini | Freeman | primi dieci in comune | ρ betweenness |
|---|---|---|---|---|---|---|---|---|---|---|
| H-T | 1 | 1084 | 0 | 2 | 95,8 % | 0,191 | 0,677 | 0,121 | — | — |
| H-T | ×5 | 1083 | 0 | 2 | 95,8 % | 0,191 | 0,674 | 0,121 | 9 | 0,996 |
| H-T | ×20 | 1079 | 0 | 2 | 95,8 % | 0,184 | 0,692 | 0,120 | 8 | 0,970 |
| R-W | 1 | 348 | 6 | 14 | 70,2 % | 0,092 | 0,751 | 0,105 | — | — |
| R-W | ×5 | 347 | 6 | 14 | 70,2 % | 0,095 | 0,753 | 0,109 | 10 | 0,995 |
| R-W | ×20 | 343 | 6 | 14 | 70,2 % | 0,096 | 0,757 | 0,113 | 9 | 0,988 |
| H-W | ×5 | 434 | 7 | 13 | 57,7 % | 0,293 | 0,917 | 0,117 | 10 | 1,000 |
| H-W | ×20 | 432 | 7 | 13 | 57,7 % | 0,334 | 0,919 | 0,147 | 9 | 0,954 |
| R-T | ×5 | 1548 | 1 | 2 | 98,9 % | 0,041 | 0,515 | 0,032 | 8 | 0,997 |
| R-T | ×20 | 1531 | 1 | 2 | 98,9 % | 0,041 | 0,506 | 0,032 | 8 | 0,971 |

Isolati, componenti e percentuale della gigante non cambiano in nessun caso; gli
elenchi degli isolati sono identici. Il nodo di testa cambia solo in R-T
(DUR138 → DUR141).

**Centri d'altura.** L'unico spostamento rilevante è Dorez in H-T: rank 2 senza
penalità e con ×5, rank 15 con ×20 (betweenness 0,030 → 0,019). Zgerdesh in H-T
scende a betweenness 0 con ×20. Nelle reti su ruota non cambia nulla.
Dettagli in `hydro_upland_centres.csv`.

---

## 4. Cosa rimane da fare

### Decisioni tue

1. **DUR103 (§2.1).** Correggere `04` e aggiornare il manoscritto (isolati 6 → 5,
   archi 348 → 350, componenti 14 → 13), oppure lasciare la rete pubblicata e
   dichiarare l'artefatto. Se si corregge, vanno rigenerati `04`–`10` e le
   figure, e aggiornate le baseline.
2. **Grado mediano di R-W (§2.3).** Verificare quale definizione usa il testo:
   7,5 su tutti i nodi, 8 senza isolati.
3. **Dorez (§3.1).** Decidere se 31 anni di sovrapposizione via I sec. a.C.,
   senza attestazioni fra 0 e 300 d.C., bastano per trattarlo come sito romano
   nella discussione dei centri d'altura.
4. **Orizzonte tardoantico (§3.1).** Il 23,4 % della rete romana, fra cui il
   secondo e il terzo nodo per betweenness, dipende da 300–450 d.C. ROM_END
   resta 450 per decisione presa; resta da decidere come presentarlo al
   revisore 1.
5. **Selezione dei fiumi (§3.3).** Confermare l'elenco. Sono esclusi Lana,
   Rrapun, Zaranika, Peza e Gjole, sul cui rango non avevo certezza, e Mat e
   Devoll, ai margini dell'area. Va anche valutato se dichiarare in Methods che
   il tracciato OSM è moderno.
6. **Interpretazione della Parte 1.** Per consegna non ho interpretato: i numeri
   di §3.2 vanno discussi prima di riscrivere qualunque sezione.

### Lavoro tecnico

7. **`run_all.R` completo non è stato rieseguito.** `03` è stato rifattorizzato e
   corretto ma verificato solo come sintassi; `11` e `12` sono stati eseguiti
   singolarmente dopo `00_setup.R`. Serve una run completa (2–4 h più ~3,5 h per
   `12`) per confermare che la pipeline riproduce le reti pubblicate.
8. **`12` non è in `run_all.R`**, per via della durata alla prima esecuzione. Va
   aggiunto se lo vuoi in pipeline.
9. **Dati da archiviare.** `data/hydro/` e tutti gli output sono esclusi da git:
   vanno messi su Zenodo con gli altri dati. `waterbodies.gpkg` è nella radice
   del progetto, inutilizzato: da spostare o eliminare.
10. **Nessun commit.** Modifiche e file nuovi sono nel working tree del branch
    `lcp_1` (elenco in §1.2–1.3).
11. **Non fatto perché non richiesto**: nessuna figura per il manoscritto (solo
    QC), nessun modello nullo o Leiden sulle celle nuove, nessuna modifica al
    testo.

---

## 5. Dove sono i risultati

| file | contenuto |
|---|---|
| `output/tables/q7_late_antique_horizon.csv` | Parte 3 |
| `output/tables/factorial_summary.md` | Parte 1, riepilogo leggibile |
| `output/tables/factorial_composition.csv` | composizione delle quattro celle |
| `output/tables/factorial_centrality_long.csv` | centralità e rank per sito e cella (330 righe) |
| `output/tables/factorial_concentration.csv` | concentrazione e nodo di testa |
| `output/tables/factorial_upland_centres.csv` | centri d'altura e categoria dei centri fortificati |
| `output/tables/factorial_tests.csv` | tutti i test dello Step 4 |
| `output/tables/factorial_lcp_consistency.csv` | coppie dual-phase ricalcolate vs pubblicate |
| `output/tables/factorial_dur103_sensitivity.csv` | effetto della correzione di DUR103 |
| `output/tables/hydro_sensitivity.csv` | Parte 2, una riga per rete × penalità |
| `output/tables/hydro_upland_centres.csv` | centri d'altura per rete × penalità |
| `output/tables/hydro_source.md` | fonte, elementi inclusi ed esclusi, DUR103 |
| `output/images/qc/factorial_betweenness_distributions.png` | QC, quattro pannelli |
| `output/images/qc/hydro_rivers_selected.png` | QC, fiumi inclusi ed esclusi |
| `output/rds/lcp_hell_wheeled.gpkg`, `lcp_rom_tobler.gpkg` | LCP grezzi di H-W e R-T |
| `output/rds/lcp_{hw,rt}_processed.rds`, `edges_{hw,rt}*.rds`, `net_{hw,rt}.rds` | reti nuove |
| `output/rds/lcp_hydro_*_x{5,20}.gpkg`, `net_hydro_*_x{5,20}.rds` | LCP e reti con penalità |
