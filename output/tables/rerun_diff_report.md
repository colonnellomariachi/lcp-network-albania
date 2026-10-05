# Rapporto di confronto — run completa (Task 10)

Generato da `tests/rerun_diff_report.R` il 2026-10-05.

- **precedente**: `archive/pre_task10_2026-10-05/` (prima sottomissione + Task 9: superfici di costo senza seed, DUR103 spostato dal codice e non risolto in `04`).
- **nuovo**: `output/`, da `run_all.R` eseguito per intero in una sessione R nuova (`00`–`13`), con superfici di costo rigenerate (`DEM_ERROR_SEED = 20261005`), coordinate dei siti dal dato sorgente e nessuno spostamento automatico.
- I valori sono calcolati con lo stesso codice sui due insiemi di output. "variato" = differenza oltre una tolleranza relativa di 1e-9.

## Due cause di variazione

1. **DUR103** recupera i propri archi (nessuno spostamento, celle risolte in `04`). L'effetto atteso di questa sola correzione è nella colonna "atteso" delle tabelle della rete romana (rete precedente con DUR103 risolto).
2. **Superfici di costo rigenerate con seed** (decisione dell'autore, Task 10): l'errore casuale del DEM è una nuova estrazione, quindi tutti i costi a coppie cambiano di poco e le coppie vicine alla soglia possono cambiare stato. Questo effetto non era fra i cambiamenti attesi della consegna; è quantificato nella sezione "Costi a coppie e archi".

## Cambiamenti attesi dalla consegna

| rete | quantità | atteso dalla consegna | precedente con DUR103 risolto | nuovo | conforme |
|---|---|---|---|---|---|
| R-W | archi | 350 | 350 | 355 | **no** |
| R-W | isolati | 5 | 5 | 5 | sì |
| R-W | componenti | 13 | 13 | 13 | sì |
| R-W | componente gigante (nodi) | 66 | 66 | 66 | sì |
| R-T | archi | 1554 | — | 1553 | **no** |
| R-T | isolati | 0 | — | 0 | sì |
| R-T | componenti | 1 | — | 1 | sì |
| R-T | componente gigante (nodi) | 94 | — | 94 | sì |

- Rete ellenistica H-T: insieme degli archi **cambiato** rispetto alla run precedente.
- Componente gigante di R-W: stessi nodi sì; stessi archi **no**.

## Riepilogo per sezione

| sezione | valori | variati |
|---|---|---|
| Dati di ingresso | 5 | 1 |
| Costi a coppie e archi — H-T (Tobler) | 8 | 6 |
| Costi a coppie e archi — R-W (ruota; coppie senza DUR103, non risolto nella run precedente) | 8 | 6 |
| Rete ellenistica H-T | 16 | 7 |
| Rete romana R-W | 16 | 12 |
| Centralità, test, dispersione spaziale, Kruskal-Wallis | 59 | 37 |
| Community detection e null model (gigante romana) | 10 | 6 |
| community_by_sitetype.csv | 48 | 48 |
| threshold_sweep_roman.csv | 80 | 55 |
| betweenness_concentration_sweep.csv | 96 | 66 |
| egnatia_pdi_final.csv | 120 | 48 |
| egnatia_validation_segments.csv | 30 | 15 |
| egnatia_validation_full.csv | 10 | 8 |
| egnatia_corridor_containment.csv | 18 | 5 |
| egnatia_pdi_comparison_bug.csv | 40 | 24 |
| q1_post146_hellenistic.csv | 72 | 0 |
| q3_top10_betweenness_hellenistic.csv | 40 | 9 |
| q4_post146_distance_egnatia.csv | 6 | 0 |
| q5_upland_centres_dates.csv | 56 | 0 |
| q6_stations_dates.csv | 75 | 0 |
| q7_late_antique_horizon.csv | 144 | 21 |
| road_stations_check.csv | 25 | 9 |
| station_modules.csv | 20 | 2 |
| station_network_roles.csv | 50 | 0 |
| station_neighbors.csv | 5 | 0 |
| factorial_composition.csv | 36 | 15 |
| factorial_concentration.csv | 24 | 15 |
| factorial_upland_centres.csv | 192 | 10 |
| factorial_tests.csv | 340 | 148 |
| Sensibilità idrografica: layer OSM vs layer poligonale — hydro_sensitivity.csv | 144 | 80 |
| Sensibilità idrografica: layer OSM vs layer poligonale — hydro_upland_centres.csv | 240 | 39 |

## Differenze registrate dalla pipeline (`regression_log.txt`)

- median minor settlement must equal baseline
- baseline: q3_top10_betweenness_hellenistic.csv
- baseline: q7_late_antique_horizon.csv
- baseline: road_stations_check.csv
- baseline: station_modules.csv
- baseline: station_network_roles.csv

## Dati di ingresso e costi

### Dati di ingresso

5 valori, 1 variati.

| quantità | precedente | nuovo | variato |
|---|---|---|---|
| siti ellenistici (n) | 71 | 71 | no |
| siti romani (n) | 94 | 94 | no |
| stessi siti ellenistici | TRUE | TRUE | no |
| stessi siti romani | TRUE | TRUE | no |
| siti con coordinate cambiate | — | DUR103 (68 m) | sì |

### Costi a coppie e archi — H-T (Tobler)

8 valori, 6 variati.

| quantità | precedente | nuovo | variato |
|---|---|---|---|
| coppie confrontabili (n) | 2485 | 2485 | no |
| costo: variazione relativa mediana (%) | 0 | -0.0061247 | sì |
| costo: \|variazione relativa\| mediana (%) | 0 | 0.14085 | sì |
| costo: \|variazione relativa\| massima (%) | 0 | 34.163 | sì |
| archi sotto soglia (240 min) fra le coppie confrontabili | 1084 | 1085 | sì |
| archi guadagnati (coppie) | — | DUR061 DUR098 | sì |
| archi persi (coppie) | — | nessuno | no |
| distanza relativa dalla soglia delle coppie che cambiano stato: massimo (%) | — | 0.030369 | sì |

### Costi a coppie e archi — R-W (ruota; coppie senza DUR103, non risolto nella run precedente)

8 valori, 6 variati.

| quantità | precedente | nuovo | variato |
|---|---|---|---|
| coppie confrontabili (n) | 4278 | 4278 | no |
| costo: variazione relativa mediana (%) | 0 | -0.0092427 | sì |
| costo: \|variazione relativa\| mediana (%) | 0 | 0.2552 | sì |
| costo: \|variazione relativa\| massima (%) | 0 | 69.376 | sì |
| archi sotto soglia (150 min) fra le coppie confrontabili | 348 | 353 | sì |
| archi guadagnati (coppie) | — | DUR043 DUR046; DUR061 DUR112; DUR076 DUR079; DUR076 DUR114; DUR079 DUR114 | sì |
| archi persi (coppie) | — | nessuno | no |
| distanza relativa dalla soglia delle coppie che cambiano stato: massimo (%) | — | 2.8957 | sì |

## Composizione e concentrazione delle reti

### Rete ellenistica H-T

16 valori, 7 variati.

| quantità | precedente | nuovo | variato |
|---|---|---|---|
| nodi | 71 | 71 | no |
| archi | 1084 | 1085 | sì |
| densità | 0.43622 | 0.43662 | sì |
| grado mediano (tutti i nodi) | 37 | 37 | no |
| isolati (n) | 0 | 0 | no |
| isolati (elenco) |  |  | no |
| componenti | 2 | 2 | no |
| componente gigante (nodi) | 68 | 68 | no |
| componente gigante (%) | 95.775 | 95.775 | no |
| betweenness: quota 1° nodo | 0.19136 | 0.19148 | sì |
| betweenness: rapporto 1°/2° | 4.2524 | 4.2525 | sì |
| betweenness: quota primi 5 | 0.35393 | 0.35334 | sì |
| betweenness: Gini | 0.67691 | 0.6764 | sì |
| betweenness: Freeman | 0.12062 | 0.12062 | sì |
| betweenness: nodo di testa | DUR003 | DUR003 | no |
| betweenness: secondo nodo | DUR032 | DUR032 | no |

### Rete romana R-W

16 valori, 12 variati.

| quantità | precedente | atteso (precedente + DUR103 risolto) | nuovo | variato | come atteso |
|---|---|---|---|---|---|
| nodi | 94 | 94 | 94 | no | sì |
| archi | 348 | 350 | 355 | sì | no |
| densità | 0.079616 | 0.080073 | 0.081217 | sì | no |
| grado mediano (tutti i nodi) |    7.5 |    7.5 | 8 | sì | no |
| isolati (n) | 6 | 5 | 5 | sì | sì |
| isolati (elenco) | DUR016;DUR029;DUR030;DUR052;DUR053;DUR103 | DUR016;DUR029;DUR030;DUR052;DUR053 | DUR016;DUR029;DUR030;DUR052;DUR053 | sì | sì |
| componenti | 14 | 13 | 13 | sì | sì |
| componente gigante (nodi) | 66 | 66 | 66 | no | sì |
| componente gigante (%) | 70.213 | 70.213 | 70.213 | no | sì |
| betweenness: quota 1° nodo | 0.091889 | 0.091889 | 0.079981 | sì | no |
| betweenness: rapporto 1°/2° | 1.3175 | 1.3175 | 1.1059 | sì | no |
| betweenness: quota primi 5 | 0.34625 | 0.34625 | 0.33388 | sì | no |
| betweenness: Gini | 0.75054 | 0.75054 | 0.74281 | sì | no |
| betweenness: Freeman | 0.1051 | 0.1051 | 0.088405 | sì | no |
| betweenness: nodo di testa | DUR050 | DUR050 | DUR050 | no | sì |
| betweenness: secondo nodo | DUR002 | DUR002 | DUR046 | sì | no |

## Centralità per fase, test, dispersione spaziale, Kruskal-Wallis

### Centralità, test, dispersione spaziale, Kruskal-Wallis

59 valori, 37 variati.

| quantità | precedente | nuovo | variato |
|---|---|---|---|
| siti dual-phase (n) | 46 | 46 | no |
| degree — mediana ellenistica | 37 | 37 | no |
| degree — mediana romana |    7.5 | 8 | sì |
| degree — Mann-Whitney W | 5899.5 | 5892 | sì |
| degree — Mann-Whitney p | 0 | 0 | no |
| degree — dual: mediana ellenistica | 35 | 35 | no |
| degree — dual: mediana romana | 9 |    9.5 | sì |
| degree — dual: Wilcoxon appaiato V | 1081 | 1081 | no |
| degree — dual: Wilcoxon appaiato p | 3.5399e-09 | 3.522e-09 | sì |
| degree — dual: Spearman rho | 0.6495 | 0.64283 | sì |
| degree — dual: Spearman p | 1.0421e-06 | 1.457e-06 | sì |
| degree_norm — mediana ellenistica | 0.52857 | 0.52857 | no |
| degree_norm — mediana romana | 0.080645 | 0.086022 | sì |
| degree_norm — Mann-Whitney W | 6029 | 6019 | sì |
| degree_norm — Mann-Whitney p | 0 | 0 | no |
| degree_norm — dual: mediana ellenistica |    0.5 |    0.5 | no |
| degree_norm — dual: mediana romana | 0.096774 | 0.10215 | sì |
| degree_norm — dual: Wilcoxon appaiato V | 1081 | 1081 | no |
| degree_norm — dual: Wilcoxon appaiato p | 3.629e-09 | 3.6106e-09 | sì |
| degree_norm — dual: Spearman rho | 0.6495 | 0.64283 | sì |
| degree_norm — dual: Spearman p | 1.0421e-06 | 1.457e-06 | sì |
| harmonic — mediana ellenistica | 0.71429 | 0.71429 | no |
| harmonic — mediana romana | 0.25472 | 0.25555 | sì |
| harmonic — Mann-Whitney W | 6455 | 6455 | no |
| harmonic — Mann-Whitney p | 0 | 0 | no |
| harmonic — dual: mediana ellenistica | 0.7131 | 0.7131 | no |
| harmonic — dual: mediana romana | 0.26526 | 0.26615 | sì |
| harmonic — dual: Wilcoxon appaiato V | 1081 | 1081 | no |
| harmonic — dual: Wilcoxon appaiato p | 3.6319e-09 | 3.629e-09 | sì |
| harmonic — dual: Spearman rho | 0.66464 | 0.65362 | sì |
| harmonic — dual: Spearman p | 4.724e-07 | 8.4399e-07 | sì |
| betweenness_norm — mediana ellenistica | 0.0037715 | 0.0037276 | sì |
| betweenness_norm — mediana romana | 0.0033361 | 0.0034703 | sì |
| betweenness_norm — Mann-Whitney W | 3495 | 3505 | sì |
| betweenness_norm — Mann-Whitney p | 0.60114 | 0.57825 | sì |
| betweenness_norm — dual: mediana ellenistica | 0.0048999 | 0.0048532 | sì |
| betweenness_norm — dual: mediana romana | 0.0033361 | 0.0034703 | sì |
| betweenness_norm — dual: Wilcoxon appaiato V | 477 | 460 | sì |
| betweenness_norm — dual: Wilcoxon appaiato p | 0.22734 | 0.33206 | sì |
| betweenness_norm — dual: Spearman rho | 0.36027 | 0.38462 | sì |
| betweenness_norm — dual: Spearman p | 0.013917 | 0.00831 | sì |
| primi 10 per betweenness, hellenistic — elenco | DUR003;DUR032;DUR131;DUR132;DUR133;DUR060;DUR043;DUR044;DUR129;DUR130 | DUR003;DUR032;DUR131;DUR132;DUR133;DUR060;DUR043;DUR044;DUR129;DUR130 | no |
| primi 10 per betweenness, hellenistic — dev. std. X (m) | 5601.3 | 5601.3 | no |
| primi 10 per betweenness, hellenistic — estensione Y (m) |  27035 |  27035 | no |
| primi 10 per betweenness, roman — elenco | DUR050;DUR002;DUR056;DUR033;DUR046;DUR062;DUR128;DUR040;DUR034;DUR066 | DUR050;DUR046;DUR002;DUR128;DUR033;DUR062;DUR056;DUR040;DUR066;DUR112 | sì |
| primi 10 per betweenness, roman — dev. std. X (m) | 3163.9 | 3233.1 | sì |
| primi 10 per betweenness, roman — estensione Y (m) |  33115 |  33115 | no |
| Kruskal-Wallis betweenness ~ tipo_sito, roman — categorie | 4 | 4 | no |
| Kruskal-Wallis betweenness ~ tipo_sito, roman — chi² | 9.7387 | 10.856 | sì |
| Kruskal-Wallis betweenness ~ tipo_sito, roman — p | 0.020923 | 0.012528 | sì |
| Kruskal-Wallis betweenness ~ def_sito, roman — categorie | 12 | 12 | no |
| Kruskal-Wallis betweenness ~ def_sito, roman — chi² | 25.983 | 25.814 | sì |
| Kruskal-Wallis betweenness ~ def_sito, roman — p | 0.0065287 | 0.0069175 | sì |
| Kruskal-Wallis betweenness ~ tipo_sito, hellenistic — categorie | 5 | 5 | no |
| Kruskal-Wallis betweenness ~ tipo_sito, hellenistic — chi² | 3.9442 | 3.9296 | sì |
| Kruskal-Wallis betweenness ~ tipo_sito, hellenistic — p | 0.26756 | 0.26917 | sì |
| Kruskal-Wallis betweenness ~ def_sito, hellenistic — categorie | 9 | 9 | no |
| Kruskal-Wallis betweenness ~ def_sito, hellenistic — chi² | 8.4931 | 8.5483 | sì |
| Kruskal-Wallis betweenness ~ def_sito, hellenistic — p | 0.38684 | 0.38182 | sì |

## Community detection e null model

### Community detection e null model (gigante romana)

10 valori, 6 variati.

| quantità | precedente | nuovo | variato |
|---|---|---|---|
| componente gigante (nodi) | 66 | 66 | no |
| componente gigante (archi) | 330 | 335 | sì |
| moduli (n) | 6 | 6 | no |
| modularità | 0.60534 | 0.59967 | sì |
| dimensioni dei moduli (ordinate) | 22,15,11,7,6,5 | 22,15,11,7,6,5 | no |
| null 1 (degree-preserving): media | 0.23981 | 0.23719 | sì |
| null 1: p | 0 | 0 | no |
| null 2 (spaziale): media | 0.53922 | 0.53579 | sì |
| null 2: n validi | 975 | 868 | sì |
| null 2: p | 0.087179 | 0.18548 | sì |

### community_by_sitetype.csv

48 valori, 48 variati.

| quantità | precedente | nuovo | variato |
|---|---|---|---|
| 1 — insediamento.minore | 3 | — | sì |
| 1 — insediamento.rurale.semplice | 6 | — | sì |
| 1 — insediamento.urbano | 1 | — | sì |
| 1 — luogo.di.culto.complesso | 1 | — | sì |
| 1 — minor.settlement | — | 3 | sì |
| 1 — rural.settlement | — | 6 | sì |
| 1 — sacred.place | — | 1 | sì |
| 1 — urban.settlement | — | 1 | sì |
| 2 — insediamento.minore | 6 | — | sì |
| 2 — insediamento.rurale.semplice | 0 | — | sì |
| 2 — insediamento.urbano | 0 | — | sì |
| 2 — luogo.di.culto.complesso | 0 | — | sì |
| 2 — minor.settlement | — | 6 | sì |
| 2 — rural.settlement | — | 0 | sì |
| 2 — sacred.place | — | 0 | sì |
| 2 — urban.settlement | — | 0 | sì |
| 3 — insediamento.minore | 4 | — | sì |
| 3 — insediamento.rurale.semplice | 3 | — | sì |
| 3 — insediamento.urbano | 0 | — | sì |
| 3 — luogo.di.culto.complesso | 0 | — | sì |
| 3 — minor.settlement | — | 4 | sì |
| 3 — rural.settlement | — | 3 | sì |
| 3 — sacred.place | — | 0 | sì |
| 3 — urban.settlement | — | 0 | sì |
| 4 — insediamento.minore | 7 | — | sì |
| 4 — insediamento.rurale.semplice | 6 | — | sì |
| 4 — insediamento.urbano | 0 | — | sì |
| 4 — luogo.di.culto.complesso | 2 | — | sì |
| 4 — minor.settlement | — | 7 | sì |
| 4 — rural.settlement | — | 6 | sì |
| 4 — sacred.place | — | 2 | sì |
| 4 — urban.settlement | — | 0 | sì |
| 5 — insediamento.minore | 2 | — | sì |
| 5 — insediamento.rurale.semplice | 2 | — | sì |
| 5 — insediamento.urbano | 0 | — | sì |
| 5 — luogo.di.culto.complesso | 1 | — | sì |
| 5 — minor.settlement | — | 2 | sì |
| 5 — rural.settlement | — | 2 | sì |
| 5 — sacred.place | — | 1 | sì |
| 5 — urban.settlement | — | 0 | sì |
| 6 — insediamento.minore | 10 | — | sì |
| 6 — insediamento.rurale.semplice | 12 | — | sì |
| 6 — insediamento.urbano | 0 | — | sì |
| 6 — luogo.di.culto.complesso | 0 | — | sì |
| 6 — minor.settlement | — | 10 | sì |
| 6 — rural.settlement | — | 12 | sì |
| 6 — sacred.place | — | 0 | sì |
| 6 — urban.settlement | — | 0 | sì |

## Sweep di soglia

### threshold_sweep_roman.csv

80 valori, 55 variati.

| quantità | precedente | atteso (precedente + DUR103 risolto) | nuovo | variato | come atteso |
|---|---|---|---|---|---|
| 30 min — n_edges | 36 | 36 | 37 | sì | no |
| 30 min — n_isolates | 57 | 57 | 56 | sì | no |
| 30 min — pct_isolates | 0.60638 | 0.60638 | 0.59574 | sì | no |
| 30 min — mean_degree | 0.76596 | 0.76596 | 0.78723 | sì | no |
| 30 min — n_components | 69 | 69 | 68 | sì | no |
| 30 min — giant_size | 6 | 6 | 6 | no | sì |
| 30 min — giant_fraction | 0.06383 | 0.06383 | 0.06383 | no | sì |
| 30 min — stato di DUR103 | isolato (archi non risolti in 04) | isolato | isolato | sì | sì |
| 60 min — n_edges | 107 | 107 | 108 | sì | no |
| 60 min — n_isolates | 31 | 31 | 30 | sì | no |
| 60 min — pct_isolates | 0.32979 | 0.32979 | 0.31915 | sì | no |
| 60 min — mean_degree | 2.2766 | 2.2766 | 2.2979 | sì | no |
| 60 min — n_components | 45 | 45 | 44 | sì | no |
| 60 min — giant_size | 12 | 12 | 12 | no | sì |
| 60 min — giant_fraction | 0.12766 | 0.12766 | 0.12766 | no | sì |
| 60 min — stato di DUR103 | isolato (archi non risolti in 04) | isolato | isolato | sì | sì |
| 90 min — n_edges | 172 | 174 | 172 | no | no |
| 90 min — n_isolates | 20 | 19 | 20 | no | no |
| 90 min — pct_isolates | 0.21277 | 0.20213 | 0.21277 | no | no |
| 90 min — mean_degree | 3.6596 | 3.7021 | 3.6596 | no | no |
| 90 min — n_components | 28 | 27 | 28 | no | no |
| 90 min — giant_size | 45 | 45 | 45 | no | sì |
| 90 min — giant_fraction | 0.47872 | 0.47872 | 0.47872 | no | sì |
| 90 min — stato di DUR103 | isolato (archi non risolti in 04) | grado 2 | grado 2 | sì | sì |
| 120 min — n_edges | 271 | 273 | 270 | sì | no |
| 120 min — n_isolates | 13 | 12 | 12 | sì | sì |
| 120 min — pct_isolates | 0.1383 | 0.12766 | 0.12766 | sì | sì |
| 120 min — mean_degree |  5.766 | 5.8085 | 5.7447 | sì | no |
| 120 min — n_components | 22 | 21 | 21 | sì | sì |
| 120 min — giant_size | 54 | 54 | 54 | no | sì |
| 120 min — giant_fraction | 0.57447 | 0.57447 | 0.57447 | no | sì |
| 120 min — stato di DUR103 | isolato (archi non risolti in 04) | grado 2 | grado 2 | sì | sì |
| 150 min — n_edges | 348 | 350 | 355 | sì | no |
| 150 min — n_isolates | 6 | 5 | 5 | sì | sì |
| 150 min — pct_isolates | 0.06383 | 0.053191 | 0.053191 | sì | sì |
| 150 min — mean_degree | 7.4043 | 7.4468 | 7.5532 | sì | no |
| 150 min — n_components | 14 | 13 | 13 | sì | sì |
| 150 min — giant_size | 66 | 66 | 66 | no | sì |
| 150 min — giant_fraction | 0.70213 | 0.70213 | 0.70213 | no | sì |
| 150 min — stato di DUR103 | isolato (archi non risolti in 04) | grado 2 | grado 2 | sì | sì |
| 180 min — n_edges | 487 | 489 | 492 | sì | no |
| 180 min — n_isolates | 2 | 1 | 1 | sì | sì |
| 180 min — pct_isolates | 0.021277 | 0.010638 | 0.010638 | sì | sì |
| 180 min — mean_degree | 10.362 | 10.404 | 10.468 | sì | no |
| 180 min — n_components | 7 | 6 | 6 | sì | sì |
| 180 min — giant_size | 80 | 80 | 80 | no | sì |
| 180 min — giant_fraction | 0.85106 | 0.85106 | 0.85106 | no | sì |
| 180 min — stato di DUR103 | isolato (archi non risolti in 04) | grado 2 | grado 2 | sì | sì |
| 210 min — n_edges | 633 | 635 | 633 | no | no |
| 210 min — n_isolates | 1 | 0 | 0 | sì | sì |
| 210 min — pct_isolates | 0.010638 | 0 | 0 | sì | sì |
| 210 min — mean_degree | 13.468 | 13.511 | 13.468 | no | no |
| 210 min — n_components | 4 | 3 | 3 | sì | sì |
| 210 min — giant_size | 87 | 87 | 87 | no | sì |
| 210 min — giant_fraction | 0.92553 | 0.92553 | 0.92553 | no | sì |
| 210 min — stato di DUR103 | isolato (archi non risolti in 04) | grado 2 | grado 2 | sì | sì |
| 240 min — n_edges | 793 | 795 | 797 | sì | no |
| 240 min — n_isolates | 1 | 0 | 0 | sì | sì |
| 240 min — pct_isolates | 0.010638 | 0 | 0 | sì | sì |
| 240 min — mean_degree | 16.872 | 16.915 | 16.957 | sì | no |
| 240 min — n_components | 3 | 2 | 2 | sì | sì |
| 240 min — giant_size | 91 | 91 | 91 | no | sì |
| 240 min — giant_fraction | 0.96809 | 0.96809 | 0.96809 | no | sì |
| 240 min — stato di DUR103 | isolato (archi non risolti in 04) | grado 2 | grado 2 | sì | sì |
| 270 min — n_edges | 974 | 976 | 971 | sì | no |
| 270 min — n_isolates | 1 | 0 | 0 | sì | sì |
| 270 min — pct_isolates | 0.010638 | 0 | 0 | sì | sì |
| 270 min — mean_degree | 20.723 | 20.766 |  20.66 | sì | no |
| 270 min — n_components | 3 | 2 | 2 | sì | sì |
| 270 min — giant_size | 91 | 91 | 91 | no | sì |
| 270 min — giant_fraction | 0.96809 | 0.96809 | 0.96809 | no | sì |
| 270 min — stato di DUR103 | isolato (archi non risolti in 04) | grado 2 | grado 2 | sì | sì |
| 300 min — n_edges | 1161 | 1163 | 1159 | sì | no |
| 300 min — n_isolates | 1 | 0 | 0 | sì | sì |
| 300 min — pct_isolates | 0.010638 | 0 | 0 | sì | sì |
| 300 min — mean_degree | 24.702 | 24.745 |  24.66 | sì | no |
| 300 min — n_components | 2 | 1 | 1 | sì | sì |
| 300 min — giant_size | 93 | 94 | 94 | sì | sì |
| 300 min — giant_fraction | 0.98936 | 1 | 1 | sì | sì |
| 300 min — stato di DUR103 | isolato (archi non risolti in 04) | grado 2 | grado 2 | sì | sì |

### betweenness_concentration_sweep.csv

96 valori, 66 variati.

| quantità | precedente | nuovo | variato |
|---|---|---|---|
| hellenistic \| 90 — n_edges | 422 | 422 | no |
| hellenistic \| 90 — density | 0.16982 | 0.16982 | no |
| hellenistic \| 90 — top1_share | 0.32189 | 0.32189 | no |
| hellenistic \| 90 — ratio_1st_2nd | 1.0063 | 1.0063 | no |
| hellenistic \| 90 — top5_share | 0.89814 | 0.89814 | no |
| hellenistic \| 90 — gini | 0.91645 | 0.91645 | no |
| hellenistic \| 120 — n_edges | 470 | 470 | no |
| hellenistic \| 120 — density | 0.18913 | 0.18913 | no |
| hellenistic \| 120 — top1_share | 0.25378 | 0.25378 | no |
| hellenistic \| 120 — ratio_1st_2nd | 1.5184 | 1.5184 | no |
| hellenistic \| 120 — top5_share | 0.67103 | 0.67103 | no |
| hellenistic \| 120 — gini | 0.82667 | 0.82667 | no |
| hellenistic \| 150 — n_edges | 564 | 564 | no |
| hellenistic \| 150 — density | 0.22696 | 0.22696 | no |
| hellenistic \| 150 — top1_share | 0.31041 | 0.31041 | no |
| hellenistic \| 150 — ratio_1st_2nd | 3.3964 | 3.3964 | no |
| hellenistic \| 150 — top5_share | 0.60168 | 0.60168 | no |
| hellenistic \| 150 — gini | 0.83413 | 0.83413 | no |
| hellenistic \| 180 — n_edges | 681 | 681 | no |
| hellenistic \| 180 — density | 0.27404 | 0.27404 | no |
| hellenistic \| 180 — top1_share | 0.09674 | 0.097118 | sì |
| hellenistic \| 180 — ratio_1st_2nd | 1.1096 | 1.0948 | sì |
| hellenistic \| 180 — top5_share | 0.36857 | 0.36598 | sì |
| hellenistic \| 180 — gini | 0.69836 | 0.69757 | sì |
| hellenistic \| 210 — n_edges | 918 | 915 | sì |
| hellenistic \| 210 — density | 0.36942 | 0.36821 | sì |
| hellenistic \| 210 — top1_share | 0.13935 | 0.13917 | sì |
| hellenistic \| 210 — ratio_1st_2nd | 2.4921 | 2.4765 | sì |
| hellenistic \| 210 — top5_share | 0.33973 |  0.342 | sì |
| hellenistic \| 210 — gini | 0.6403 | 0.6435 | sì |
| hellenistic \| 240 — n_edges | 1084 | 1085 | sì |
| hellenistic \| 240 — density | 0.43622 | 0.43662 | sì |
| hellenistic \| 240 — top1_share | 0.19136 | 0.19148 | sì |
| hellenistic \| 240 — ratio_1st_2nd | 4.2524 | 4.2525 | sì |
| hellenistic \| 240 — top5_share | 0.35393 | 0.35334 | sì |
| hellenistic \| 240 — gini | 0.67691 | 0.6764 | sì |
| hellenistic \| 270 — n_edges | 1201 | 1201 | no |
| hellenistic \| 270 — density | 0.4833 | 0.4833 | no |
| hellenistic \| 270 — top1_share | 0.10431 | 0.10431 | no |
| hellenistic \| 270 — ratio_1st_2nd | 1.0813 | 1.0813 | no |
| hellenistic \| 270 — top5_share | 0.39121 | 0.39121 | no |
| hellenistic \| 270 — gini | 0.70436 | 0.70436 | no |
| hellenistic \| 300 — n_edges | 1264 | 1265 | sì |
| hellenistic \| 300 — density | 0.50865 | 0.50905 | sì |
| hellenistic \| 300 — top1_share | 0.10706 | 0.092326 | sì |
| hellenistic \| 300 — ratio_1st_2nd | 1.2581 | 1.0922 | sì |
| hellenistic \| 300 — top5_share | 0.34665 | 0.34932 | sì |
| hellenistic \| 300 — gini | 0.67887 | 0.68591 | sì |
| roman \| 90 — n_edges | 172 | 172 | no |
| roman \| 90 — density | 0.03935 | 0.03935 | no |
| roman \| 90 — top1_share | 0.1298 | 0.12817 | sì |
| roman \| 90 — ratio_1st_2nd | 1.0095 | 1.0088 | sì |
| roman \| 90 — top5_share | 0.49294 | 0.4881 | sì |
| roman \| 90 — gini | 0.84029 |  0.832 | sì |
| roman \| 120 — n_edges | 271 | 270 | sì |
| roman \| 120 — density |  0.062 | 0.061771 | sì |
| roman \| 120 — top1_share | 0.12589 | 0.11475 | sì |
| roman \| 120 — ratio_1st_2nd | 1.0935 | 1.1916 | sì |
| roman \| 120 — top5_share | 0.41221 | 0.42534 | sì |
| roman \| 120 — gini | 0.76925 | 0.78871 | sì |
| roman \| 150 — n_edges | 348 | 355 | sì |
| roman \| 150 — density | 0.079616 | 0.081217 | sì |
| roman \| 150 — top1_share | 0.091889 | 0.079981 | sì |
| roman \| 150 — ratio_1st_2nd | 1.3175 | 1.1059 | sì |
| roman \| 150 — top5_share | 0.34625 | 0.33388 | sì |
| roman \| 150 — gini | 0.75054 | 0.74281 | sì |
| roman \| 180 — n_edges | 487 | 492 | sì |
| roman \| 180 — density | 0.11142 | 0.11256 | sì |
| roman \| 180 — top1_share | 0.05711 | 0.057169 | sì |
| roman \| 180 — ratio_1st_2nd | 1.1686 | 1.1576 | sì |
| roman \| 180 — top5_share | 0.24562 | 0.24543 | sì |
| roman \| 180 — gini | 0.66381 | 0.66346 | sì |
| roman \| 210 — n_edges | 633 | 633 | no |
| roman \| 210 — density | 0.14482 | 0.14482 | no |
| roman \| 210 — top1_share | 0.073726 | 0.077573 | sì |
| roman \| 210 — ratio_1st_2nd | 1.0297 |  1.097 | sì |
| roman \| 210 — top5_share | 0.33004 | 0.33148 | sì |
| roman \| 210 — gini | 0.70598 | 0.70787 | sì |
| roman \| 240 — n_edges | 793 | 797 | sì |
| roman \| 240 — density | 0.18142 | 0.18234 | sì |
| roman \| 240 — top1_share | 0.091135 | 0.08988 | sì |
| roman \| 240 — ratio_1st_2nd | 1.3323 | 1.0562 | sì |
| roman \| 240 — top5_share | 0.29584 | 0.32514 | sì |
| roman \| 240 — gini | 0.62634 | 0.64332 | sì |
| roman \| 270 — n_edges | 974 | 971 | sì |
| roman \| 270 — density | 0.22283 | 0.22215 | sì |
| roman \| 270 — top1_share | 0.084211 | 0.084135 | sì |
| roman \| 270 — ratio_1st_2nd | 1.7412 | 1.5673 | sì |
| roman \| 270 — top5_share | 0.2569 | 0.2578 | sì |
| roman \| 270 — gini | 0.58404 | 0.58874 | sì |
| roman \| 300 — n_edges | 1161 | 1159 | sì |
| roman \| 300 — density | 0.26561 | 0.26516 | sì |
| roman \| 300 — top1_share | 0.063416 | 0.061443 | sì |
| roman \| 300 — ratio_1st_2nd |  1.373 | 1.4391 | sì |
| roman \| 300 — top5_share | 0.23368 | 0.22381 | sì |
| roman \| 300 — gini | 0.57281 | 0.56421 | sì |

## Via Egnatia

### egnatia_pdi_final.csv

120 valori, 48 variati.

| quantità | precedente | nuovo | variato |
|---|---|---|---|
| DUR001 -> DUR022 \| wheeled transport — n_lobes | 1 | 1 | no |
| DUR001 -> DUR022 \| wheeled transport — area_candidate_1 | 2.3523e+07 | 2.2868e+07 | sì |
| DUR001 -> DUR022 \| wheeled transport — area_candidate_2 | 3.5343e+08 | 3.5228e+08 | sì |
| DUR001 -> DUR022 \| wheeled transport — area_selected | 2.3523e+07 | 2.2868e+07 | sì |
| DUR001 -> DUR022 \| wheeled transport — max_distance |  50863 |  50863 | no |
| DUR001 -> DUR022 \| wheeled transport — pdi | 462.48 | 449.59 | sì |
| DUR001 -> DUR022 \| wheeled transport — normalised_pdi | 0.90926 | 0.88392 | sì |
| DUR001 -> DUR022 \| wheeled transport — was_valid_before | FALSE | FALSE | no |
| DUR001 -> DUR022 \| wheeled transport — n_crossings | 21 | 13 | sì |
| DUR001 -> DUR022 \| wheeled transport — rank_within_segment | 1 | 1 | no |
| DUR001 -> DUR022 \| tobler — n_lobes | 1 | 1 | no |
| DUR001 -> DUR022 \| tobler — area_candidate_1 | 4.7773e+08 | 4.7679e+08 | sì |
| DUR001 -> DUR022 \| tobler — area_candidate_2 | 4.742e+08 | 4.7409e+08 | sì |
| DUR001 -> DUR022 \| tobler — area_selected | 4.742e+08 | 4.7409e+08 | sì |
| DUR001 -> DUR022 \| tobler — max_distance |  50863 |  50863 | no |
| DUR001 -> DUR022 \| tobler — pdi | 9322.9 | 9320.8 | sì |
| DUR001 -> DUR022 \| tobler — normalised_pdi | 18.329 | 18.325 | sì |
| DUR001 -> DUR022 \| tobler — was_valid_before | FALSE | FALSE | no |
| DUR001 -> DUR022 \| tobler — n_crossings | 3 | 3 | no |
| DUR001 -> DUR022 \| tobler — rank_within_segment | 3 | 3 | no |
| DUR001 -> DUR022 \| straight baseline — n_lobes | 1 | 1 | no |
| DUR001 -> DUR022 \| straight baseline — area_candidate_1 | 3.296e+08 | 3.296e+08 | no |
| DUR001 -> DUR022 \| straight baseline — area_candidate_2 | 3.296e+08 | 3.296e+08 | no |
| DUR001 -> DUR022 \| straight baseline — area_selected | 3.296e+08 | 3.296e+08 | no |
| DUR001 -> DUR022 \| straight baseline — max_distance |  50863 |  50863 | no |
| DUR001 -> DUR022 \| straight baseline — pdi | 6480.1 | 6480.1 | no |
| DUR001 -> DUR022 \| straight baseline — normalised_pdi |  12.74 |  12.74 | no |
| DUR001 -> DUR022 \| straight baseline — was_valid_before | FALSE | FALSE | no |
| DUR001 -> DUR022 \| straight baseline — n_crossings | 3 | 3 | no |
| DUR001 -> DUR022 \| straight baseline — rank_within_segment | 2 | 2 | no |
| DUR022 -> DUR024 \| wheeled transport — n_lobes | 1 | 1 | no |
| DUR022 -> DUR024 \| wheeled transport — area_candidate_1 | 2.6938e+06 | 3.2628e+06 | sì |
| DUR022 -> DUR024 \| wheeled transport — area_candidate_2 | 6.2869e+06 | 6.9559e+06 | sì |
| DUR022 -> DUR024 \| wheeled transport — area_selected | 2.6938e+06 | 3.2628e+06 | sì |
| DUR022 -> DUR024 \| wheeled transport — max_distance | 7236.1 | 7236.1 | no |
| DUR022 -> DUR024 \| wheeled transport — pdi | 372.27 | 450.91 | sì |
| DUR022 -> DUR024 \| wheeled transport — normalised_pdi | 5.1447 | 6.2314 | sì |
| DUR022 -> DUR024 \| wheeled transport — was_valid_before | FALSE | FALSE | no |
| DUR022 -> DUR024 \| wheeled transport — n_crossings | 11 | 5 | sì |
| DUR022 -> DUR024 \| wheeled transport — rank_within_segment | 1 | 2 | sì |
| DUR022 -> DUR024 \| tobler — n_lobes | 1 | 1 | no |
| DUR022 -> DUR024 \| tobler — area_candidate_1 | 3.11e+06 | 2.9816e+06 | sì |
| DUR022 -> DUR024 \| tobler — area_candidate_2 | 4.1919e+06 | 4.1716e+06 | sì |
| DUR022 -> DUR024 \| tobler — area_selected | 3.11e+06 | 2.9816e+06 | sì |
| DUR022 -> DUR024 \| tobler — max_distance | 7236.1 | 7236.1 | no |
| DUR022 -> DUR024 \| tobler — pdi |  429.8 | 412.04 | sì |
| DUR022 -> DUR024 \| tobler — normalised_pdi | 5.9396 | 5.6943 | sì |
| DUR022 -> DUR024 \| tobler — was_valid_before | FALSE | FALSE | no |
| DUR022 -> DUR024 \| tobler — n_crossings | 3 | 3 | no |
| DUR022 -> DUR024 \| tobler — rank_within_segment | 2 | 1 | sì |
| DUR022 -> DUR024 \| straight baseline — n_lobes | 1 | 1 | no |
| DUR022 -> DUR024 \| straight baseline — area_candidate_1 | 3.9357e+06 | 3.9357e+06 | no |
| DUR022 -> DUR024 \| straight baseline — area_candidate_2 | 3.9357e+06 | 3.9357e+06 | no |
| DUR022 -> DUR024 \| straight baseline — area_selected | 3.9357e+06 | 3.9357e+06 | no |
| DUR022 -> DUR024 \| straight baseline — max_distance | 7236.1 | 7236.1 | no |
| DUR022 -> DUR024 \| straight baseline — pdi |  543.9 |  543.9 | no |
| DUR022 -> DUR024 \| straight baseline — normalised_pdi | 7.5165 | 7.5165 | no |
| DUR022 -> DUR024 \| straight baseline — was_valid_before | FALSE | FALSE | no |
| DUR022 -> DUR024 \| straight baseline — n_crossings | 2 | 2 | no |
| DUR022 -> DUR024 \| straight baseline — rank_within_segment | 3 | 3 | no |
| DUR024 -> DUR017 \| wheeled transport — n_lobes | 1 | 1 | no |
| DUR024 -> DUR017 \| wheeled transport — area_candidate_1 | 1.2634e+06 | 1.2373e+06 | sì |
| DUR024 -> DUR017 \| wheeled transport — area_candidate_2 | 1.257e+06 | 1.2109e+06 | sì |
| DUR024 -> DUR017 \| wheeled transport — area_selected | 1.257e+06 | 1.2109e+06 | sì |
| DUR024 -> DUR017 \| wheeled transport — max_distance | 5873.8 | 5873.8 | no |
| DUR024 -> DUR017 \| wheeled transport — pdi | 214.01 | 206.15 | sì |
| DUR024 -> DUR017 \| wheeled transport — normalised_pdi | 3.6435 | 3.5097 | sì |
| DUR024 -> DUR017 \| wheeled transport — was_valid_before | FALSE | FALSE | no |
| DUR024 -> DUR017 \| wheeled transport — n_crossings | 2 | 3 | sì |
| DUR024 -> DUR017 \| wheeled transport — rank_within_segment | 3 | 3 | no |
| DUR024 -> DUR017 \| tobler — n_lobes | 1 | 1 | no |
| DUR024 -> DUR017 \| tobler — area_candidate_1 | 1.068e+06 | 9.1726e+05 | sì |
| DUR024 -> DUR017 \| tobler — area_candidate_2 | 1.0319e+06 | 1.0284e+06 | sì |
| DUR024 -> DUR017 \| tobler — area_selected | 1.0319e+06 | 9.1726e+05 | sì |
| DUR024 -> DUR017 \| tobler — max_distance | 5873.8 | 5873.8 | no |
| DUR024 -> DUR017 \| tobler — pdi | 175.67 | 156.16 | sì |
| DUR024 -> DUR017 \| tobler — normalised_pdi | 2.9908 | 2.6586 | sì |
| DUR024 -> DUR017 \| tobler — was_valid_before | FALSE | FALSE | no |
| DUR024 -> DUR017 \| tobler — n_crossings | 4 | 3 | sì |
| DUR024 -> DUR017 \| tobler — rank_within_segment | 2 | 1 | sì |
| DUR024 -> DUR017 \| straight baseline — n_lobes | 1 | 1 | no |
| DUR024 -> DUR017 \| straight baseline — area_candidate_1 | 9.2756e+05 | 9.2756e+05 | no |
| DUR024 -> DUR017 \| straight baseline — area_candidate_2 | 9.2756e+05 | 9.2756e+05 | no |
| DUR024 -> DUR017 \| straight baseline — area_selected | 9.2756e+05 | 9.2756e+05 | no |
| DUR024 -> DUR017 \| straight baseline — max_distance | 5873.8 | 5873.8 | no |
| DUR024 -> DUR017 \| straight baseline — pdi | 157.91 | 157.91 | no |
| DUR024 -> DUR017 \| straight baseline — normalised_pdi | 2.6885 | 2.6885 | no |
| DUR024 -> DUR017 \| straight baseline — was_valid_before | FALSE | FALSE | no |
| DUR024 -> DUR017 \| straight baseline — n_crossings | 2 | 2 | no |
| DUR024 -> DUR017 \| straight baseline — rank_within_segment | 1 | 2 | sì |
| full route \| wheeled transport — n_lobes | 1 | 1 | no |
| full route \| wheeled transport — area_candidate_1 | 8.4795e+08 | 8.5017e+08 | sì |
| full route \| wheeled transport — area_candidate_2 | 8.4014e+08 | 8.4292e+08 | sì |
| full route \| wheeled transport — area_selected | 8.4014e+08 | 8.4292e+08 | sì |
| full route \| wheeled transport — max_distance |  52402 |  52402 | no |
| full route \| wheeled transport — pdi |  16032 |  16086 | sì |
| full route \| wheeled transport — normalised_pdi | 30.595 | 30.696 | sì |
| full route \| wheeled transport — was_valid_before | FALSE | FALSE | no |
| full route \| wheeled transport — n_crossings | 3 | 3 | no |
| full route \| wheeled transport — rank_within_segment | 3 | 3 | no |
| full route \| tobler — n_lobes | 1 | 1 | no |
| full route \| tobler — area_candidate_1 | 6.9022e+08 | 6.895e+08 | sì |
| full route \| tobler — area_candidate_2 | 6.9222e+08 | 6.9218e+08 | sì |
| full route \| tobler — area_selected | 6.9022e+08 | 6.895e+08 | sì |
| full route \| tobler — max_distance |  52402 |  52402 | no |
| full route \| tobler — pdi |  13171 |  13158 | sì |
| full route \| tobler — normalised_pdi | 25.135 | 25.109 | sì |
| full route \| tobler — was_valid_before | FALSE | FALSE | no |
| full route \| tobler — n_crossings | 3 | 3 | no |
| full route \| tobler — rank_within_segment | 2 | 2 | no |
| full route \| straight baseline — n_lobes | 1 | 1 | no |
| full route \| straight baseline — area_candidate_1 | 6.1541e+08 | 6.1541e+08 | no |
| full route \| straight baseline — area_candidate_2 | 6.1541e+08 | 6.1541e+08 | no |
| full route \| straight baseline — area_selected | 6.1541e+08 | 6.1541e+08 | no |
| full route \| straight baseline — max_distance |  52402 |  52402 | no |
| full route \| straight baseline — pdi |  11744 |  11744 | no |
| full route \| straight baseline — normalised_pdi | 22.411 | 22.411 | no |
| full route \| straight baseline — was_valid_before | FALSE | FALSE | no |
| full route \| straight baseline — n_crossings | 2 | 2 | no |
| full route \| straight baseline — rank_within_segment | 1 | 1 | no |

### egnatia_validation_segments.csv

30 valori, 15 variati.

| quantità | precedente | nuovo | variato |
|---|---|---|---|
| tobler \| DUR001 -> DUR022 — pdi | 3067.5 | 3068.7 | sì |
| tobler \| DUR001 -> DUR022 — pdi_norm | 6.0309 | 6.0333 | sì |
| tobler \| DUR001 -> DUR022 — pdi_norm_straight | 12.498 | 12.498 | no |
| tobler \| DUR001 -> DUR022 — buffer_1km |  17.06 | 19.506 | sì |
| tobler \| DUR001 -> DUR022 — buffer_5km |  38.79 | 38.576 | sì |
| tobler \| DUR022 -> DUR024 — pdi | 288.82 | 320.51 | sì |
| tobler \| DUR022 -> DUR024 — pdi_norm | 3.9914 | 4.4293 | sì |
| tobler \| DUR022 -> DUR024 — pdi_norm_straight | 5.9017 | 5.9017 | no |
| tobler \| DUR022 -> DUR024 — buffer_1km | 100 | 100 | no |
| tobler \| DUR022 -> DUR024 — buffer_5km | 100 | 100 | no |
| tobler \| DUR024 -> DUR017 — pdi |  33.38 | 68.251 | sì |
| tobler \| DUR024 -> DUR017 — pdi_norm | 0.56829 |  1.162 | sì |
| tobler \| DUR024 -> DUR017 — pdi_norm_straight | 1.2369 | 1.2369 | no |
| tobler \| DUR024 -> DUR017 — buffer_1km | 100 | 100 | no |
| tobler \| DUR024 -> DUR017 — buffer_5km | 100 | 100 | no |
| wheeled transport \| DUR001 -> DUR022 — pdi | 265.29 |  249.1 | sì |
| wheeled transport \| DUR001 -> DUR022 — pdi_norm | 0.52156 | 0.48974 | sì |
| wheeled transport \| DUR001 -> DUR022 — pdi_norm_straight | 12.498 | 12.498 | no |
| wheeled transport \| DUR001 -> DUR022 — buffer_1km | 98.649 | 99.309 | sì |
| wheeled transport \| DUR001 -> DUR022 — buffer_5km | 100 | 100 | no |
| wheeled transport \| DUR022 -> DUR024 — pdi | 369.25 | 443.24 | sì |
| wheeled transport \| DUR022 -> DUR024 — pdi_norm | 5.1029 | 6.1254 | sì |
| wheeled transport \| DUR022 -> DUR024 — pdi_norm_straight | 5.9017 | 5.9017 | no |
| wheeled transport \| DUR022 -> DUR024 — buffer_1km | 100 | 100 | no |
| wheeled transport \| DUR022 -> DUR024 — buffer_5km | 100 | 100 | no |
| wheeled transport \| DUR024 -> DUR017 — pdi | 0.90326 | 43.106 | sì |
| wheeled transport \| DUR024 -> DUR017 — pdi_norm | 0.015378 | 0.73387 | sì |
| wheeled transport \| DUR024 -> DUR017 — pdi_norm_straight | 1.2369 | 1.2369 | no |
| wheeled transport \| DUR024 -> DUR017 — buffer_1km | 100 | 100 | no |
| wheeled transport \| DUR024 -> DUR017 — buffer_5km | 100 | 100 | no |

### egnatia_validation_full.csv

10 valori, 8 variati.

| quantità | precedente | nuovo | variato |
|---|---|---|---|
| tobler \| full route — pdi |  10025 |  10045 | sì |
| tobler \| full route — pdi_norm |  19.13 | 19.169 | sì |
| tobler \| full route — pdi_norm_straight | 22.411 | 22.411 | no |
| tobler \| full route — buffer_1km | 13.049 | 13.913 | sì |
| tobler \| full route — buffer_5km | 34.518 | 34.231 | sì |
| wheeled transport \| full route — pdi | 7010.5 |   6958 | sì |
| wheeled transport \| full route — pdi_norm | 13.378 | 13.278 | sì |
| wheeled transport \| full route — pdi_norm_straight | 22.411 | 22.411 | no |
| wheeled transport \| full route — buffer_1km | 10.136 | 10.419 | sì |
| wheeled transport \| full route — buffer_5km | 28.165 | 28.007 | sì |

### egnatia_corridor_containment.csv

18 valori, 5 variati.

| quantità | precedente | nuovo | variato |
|---|---|---|---|
| DUR001 -> DUR022 \| 0.05 — prop_wheeled | 0.98814 | 0.98305 | sì |
| DUR001 -> DUR022 \| 0.05 — prop_tobler | 0.084746 | 0.083051 | sì |
| DUR001 -> DUR022 \| 0.1 — prop_wheeled | 1 | 1 | no |
| DUR001 -> DUR022 \| 0.1 — prop_tobler | 0.12881 | 0.13051 | sì |
| DUR001 -> DUR022 \| 0.25 — prop_wheeled | 1 | 1 | no |
| DUR001 -> DUR022 \| 0.25 — prop_tobler | 1 | 1 | no |
| DUR022 -> DUR024 \| 0.05 — prop_wheeled | 0.48315 | 0.48315 | no |
| DUR022 -> DUR024 \| 0.05 — prop_tobler | 0.16854 | 0.1573 | sì |
| DUR022 -> DUR024 \| 0.1 — prop_wheeled | 1 | 1 | no |
| DUR022 -> DUR024 \| 0.1 — prop_tobler | 0.64045 | 0.64045 | no |
| DUR022 -> DUR024 \| 0.25 — prop_wheeled | 1 | 1 | no |
| DUR022 -> DUR024 \| 0.25 — prop_tobler | 1 | 1 | no |
| DUR024 -> DUR017 \| 0.05 — prop_wheeled | 0.83607 | 0.85246 | sì |
| DUR024 -> DUR017 \| 0.05 — prop_tobler | 1 | 1 | no |
| DUR024 -> DUR017 \| 0.1 — prop_wheeled | 1 | 1 | no |
| DUR024 -> DUR017 \| 0.1 — prop_tobler | 1 | 1 | no |
| DUR024 -> DUR017 \| 0.25 — prop_wheeled | 1 | 1 | no |
| DUR024 -> DUR017 \| 0.25 — prop_tobler | 1 | 1 | no |

### egnatia_pdi_comparison_bug.csv

40 valori, 24 variati.

| quantità | precedente | nuovo | variato |
|---|---|---|---|
| DUR001 -> DUR022 \| tobler — normalised_pdi_pkg | 6.0309 | 6.0333 | sì |
| DUR001 -> DUR022 \| tobler — normalised_pdi | 18.329 | 18.325 | sì |
| DUR001 -> DUR022 \| tobler — was_valid_before | FALSE | FALSE | no |
| DUR001 -> DUR022 \| tobler — n_lobes | 1 | 1 | no |
| DUR001 -> DUR022 \| tobler — delta_abs | 12.299 | 12.292 | sì |
| DUR001 -> DUR022 \| wheeled transport — normalised_pdi_pkg | 0.52156 | 0.48974 | sì |
| DUR001 -> DUR022 \| wheeled transport — normalised_pdi | 0.90926 | 0.88392 | sì |
| DUR001 -> DUR022 \| wheeled transport — was_valid_before | FALSE | FALSE | no |
| DUR001 -> DUR022 \| wheeled transport — n_lobes | 1 | 1 | no |
| DUR001 -> DUR022 \| wheeled transport — delta_abs | 0.38769 | 0.39418 | sì |
| DUR022 -> DUR024 \| tobler — normalised_pdi_pkg | 3.9914 | 4.4293 | sì |
| DUR022 -> DUR024 \| tobler — normalised_pdi | 5.9396 | 5.6943 | sì |
| DUR022 -> DUR024 \| tobler — was_valid_before | FALSE | FALSE | no |
| DUR022 -> DUR024 \| tobler — n_lobes | 1 | 1 | no |
| DUR022 -> DUR024 \| tobler — delta_abs | 1.9482 | 1.2649 | sì |
| DUR022 -> DUR024 \| wheeled transport — normalised_pdi_pkg | 5.1029 | 6.1254 | sì |
| DUR022 -> DUR024 \| wheeled transport — normalised_pdi | 5.1447 | 6.2314 | sì |
| DUR022 -> DUR024 \| wheeled transport — was_valid_before | FALSE | FALSE | no |
| DUR022 -> DUR024 \| wheeled transport — n_lobes | 1 | 1 | no |
| DUR022 -> DUR024 \| wheeled transport — delta_abs | 0.041761 | 0.10608 | sì |
| DUR024 -> DUR017 \| tobler — normalised_pdi_pkg | 0.56829 |  1.162 | sì |
| DUR024 -> DUR017 \| tobler — normalised_pdi | 2.9908 | 2.6586 | sì |
| DUR024 -> DUR017 \| tobler — was_valid_before | FALSE | FALSE | no |
| DUR024 -> DUR017 \| tobler — n_lobes | 1 | 1 | no |
| DUR024 -> DUR017 \| tobler — delta_abs | 2.4225 | 1.4967 | sì |
| DUR024 -> DUR017 \| wheeled transport — normalised_pdi_pkg | 0.015378 | 0.73387 | sì |
| DUR024 -> DUR017 \| wheeled transport — normalised_pdi | 3.6435 | 3.5097 | sì |
| DUR024 -> DUR017 \| wheeled transport — was_valid_before | FALSE | FALSE | no |
| DUR024 -> DUR017 \| wheeled transport — n_lobes | 1 | 1 | no |
| DUR024 -> DUR017 \| wheeled transport — delta_abs | 3.6281 | 2.7758 | sì |
| full route \| tobler — normalised_pdi_pkg |  19.13 | 19.169 | sì |
| full route \| tobler — normalised_pdi | 25.135 | 25.109 | sì |
| full route \| tobler — was_valid_before | FALSE | FALSE | no |
| full route \| tobler — n_lobes | 1 | 1 | no |
| full route \| tobler — delta_abs |  6.005 | 5.9401 | sì |
| full route \| wheeled transport — normalised_pdi_pkg | 13.378 | 13.278 | sì |
| full route \| wheeled transport — normalised_pdi | 30.595 | 30.696 | sì |
| full route \| wheeled transport — was_valid_before | FALSE | FALSE | no |
| full route \| wheeled transport — n_lobes | 1 | 1 | no |
| full route \| wheeled transport — delta_abs | 17.217 | 17.418 | sì |

## Tabelle di `10_discussion_checks.R`

### q1_post146_hellenistic.csv

72 valori, 0 variati.

| quantità | precedente | nuovo | variato |
|---|---|---|---|
| DUR044 — def_sito | insediamento generico | insediamento generico | no |
| DUR044 — tipo_sito | minor settlement | minor settlement | no |
| DUR044 — top_ant | NA | NA | no |
| DUR044 — comune | Hardishta | Hardishta | no |
| DUR044 — localita | Hardishta | Hardishta | no |
| DUR044 — Longit | 3.8079e+05 | 3.8079e+05 | no |
| DUR044 — Latitud | 4.5738e+06 | 4.5738e+06 | no |
| DUR044 — earliest_start | -100 | -100 | no |
| DUR044 — latest_end | 300 | 300 | no |
| DUR044 — in_hellenistic | TRUE | TRUE | no |
| DUR044 — in_roman | TRUE | TRUE | no |
| DUR044 — dual_phase | TRUE | TRUE | no |
| DUR110 — def_sito | complesso funerario | complesso funerario | no |
| DUR110 — tipo_sito | rural settlement | rural settlement | no |
| DUR110 — top_ant | NA | NA | no |
| DUR110 — comune | Kryevidh | Kryevidh | no |
| DUR110 — localita | Fushe Qerret | Fushe Qerret | no |
| DUR110 — Longit | NA | NA | no |
| DUR110 — Latitud | NA | NA | no |
| DUR110 — earliest_start | -100 | -100 | no |
| DUR110 — latest_end | 200 | 200 | no |
| DUR110 — in_hellenistic | TRUE | TRUE | no |
| DUR110 — in_roman | TRUE | TRUE | no |
| DUR110 — dual_phase | TRUE | TRUE | no |
| DUR116 — def_sito | complesso funerario | complesso funerario | no |
| DUR116 — tipo_sito | minor settlement | minor settlement | no |
| DUR116 — top_ant | NA | NA | no |
| DUR116 — comune | NA | NA | no |
| DUR116 — localita | Valias | Valias | no |
| DUR116 — Longit | NA | NA | no |
| DUR116 — Latitud | NA | NA | no |
| DUR116 — earliest_start | -100 | -100 | no |
| DUR116 — latest_end | 100 | 100 | no |
| DUR116 — in_hellenistic | TRUE | TRUE | no |
| DUR116 — in_roman | TRUE | TRUE | no |
| DUR116 — dual_phase | TRUE | TRUE | no |
| DUR117 — def_sito | complesso funerario | complesso funerario | no |
| DUR117 — tipo_sito | minor settlement | minor settlement | no |
| DUR117 — top_ant | NA | NA | no |
| DUR117 — comune | NA | NA | no |
| DUR117 — localita | Kashar | Kashar | no |
| DUR117 — Longit | NA | NA | no |
| DUR117 — Latitud | NA | NA | no |
| DUR117 — earliest_start | -100 | -100 | no |
| DUR117 — latest_end | 100 | 100 | no |
| DUR117 — in_hellenistic | TRUE | TRUE | no |
| DUR117 — in_roman | TRUE | TRUE | no |
| DUR117 — dual_phase | TRUE | TRUE | no |
| DUR118 — def_sito | complesso funerario | complesso funerario | no |
| DUR118 — tipo_sito | minor settlement | minor settlement | no |
| DUR118 — top_ant | NA | NA | no |
| DUR118 — comune | NA | NA | no |
| DUR118 — localita | Paskuqan | Paskuqan | no |
| DUR118 — Longit | NA | NA | no |
| DUR118 — Latitud | NA | NA | no |
| DUR118 — earliest_start | -100 | -100 | no |
| DUR118 — latest_end | 100 | 100 | no |
| DUR118 — in_hellenistic | TRUE | TRUE | no |
| DUR118 — in_roman | TRUE | TRUE | no |
| DUR118 — dual_phase | TRUE | TRUE | no |
| DUR126 — def_sito | fattoria | fattoria | no |
| DUR126 — tipo_sito | rural settlement | rural settlement | no |
| DUR126 — top_ant | NA | NA | no |
| DUR126 — comune | Durres | Durres | no |
| DUR126 — localita | Rrashbull | Rrashbull | no |
| DUR126 — Longit | NA | NA | no |
| DUR126 — Latitud | NA | NA | no |
| DUR126 — earliest_start | -100 | -100 | no |
| DUR126 — latest_end | 300 | 300 | no |
| DUR126 — in_hellenistic | TRUE | TRUE | no |
| DUR126 — in_roman | TRUE | TRUE | no |
| DUR126 — dual_phase | TRUE | TRUE | no |

### q3_top10_betweenness_hellenistic.csv

40 valori, 9 variati.

| quantità | precedente | nuovo | variato |
|---|---|---|---|
| riga 1 — id_sito | DUR003 | DUR003 | no |
| riga 1 — betweenness_norm | 0.12836 | 0.12836 | no |
| riga 1 — degree | 37 | 37 | no |
| riga 1 — post_146 | FALSE | FALSE | no |
| riga 2 — id_sito | DUR032 | DUR032 | no |
| riga 2 — betweenness_norm | 0.030186 | 0.030186 | sì |
| riga 2 — degree | 12 | 12 | no |
| riga 2 — post_146 | FALSE | FALSE | no |
| riga 3 — id_sito | DUR131 | DUR131 | no |
| riga 3 — betweenness_norm | 0.02629 | 0.026108 | sì |
| riga 3 — degree | 47 | 47 | no |
| riga 3 — post_146 | FALSE | FALSE | no |
| riga 4 — id_sito | DUR132 | DUR132 | no |
| riga 4 — betweenness_norm | 0.02629 | 0.026108 | sì |
| riga 4 — degree | 47 | 47 | no |
| riga 4 — post_146 | FALSE | FALSE | no |
| riga 5 — id_sito | DUR133 | DUR133 | no |
| riga 5 — betweenness_norm | 0.02629 | 0.026108 | sì |
| riga 5 — degree | 47 | 47 | no |
| riga 5 — post_146 | FALSE | FALSE | no |
| riga 6 — id_sito | DUR060 | DUR060 | no |
| riga 6 — betweenness_norm | 0.025232 | 0.025132 | sì |
| riga 6 — degree | 48 | 48 | no |
| riga 6 — post_146 | FALSE | FALSE | no |
| riga 7 — id_sito | DUR043 | DUR043 | no |
| riga 7 — betweenness_norm | 0.025183 | 0.02513 | sì |
| riga 7 — degree | 47 | 47 | no |
| riga 7 — post_146 | FALSE | FALSE | no |
| riga 8 — id_sito | DUR044 | DUR044 | no |
| riga 8 — betweenness_norm | 0.025183 | 0.02513 | sì |
| riga 8 — degree | 47 | 47 | no |
| riga 8 — post_146 | TRUE | TRUE | no |
| riga 9 — id_sito | DUR129 | DUR129 | no |
| riga 9 — betweenness_norm | 0.025183 | 0.02513 | sì |
| riga 9 — degree | 47 | 47 | no |
| riga 9 — post_146 | FALSE | FALSE | no |
| riga 10 — id_sito | DUR130 | DUR130 | no |
| riga 10 — betweenness_norm | 0.025183 | 0.02513 | sì |
| riga 10 — degree | 47 | 47 | no |
| riga 10 — post_146 | FALSE | FALSE | no |

### q4_post146_distance_egnatia.csv

6 valori, 0 variati.

| quantità | precedente | nuovo | variato |
|---|---|---|---|
| DUR126 — dist_egnatia_m | 2407 | 2407 | no |
| DUR110 — dist_egnatia_m | 6862 | 6862 | no |
| DUR044 — dist_egnatia_m | 7582 | 7582 | no |
| DUR117 — dist_egnatia_m | 18557 | 18557 | no |
| DUR116 — dist_egnatia_m | 22528 | 22528 | no |
| DUR118 — dist_egnatia_m | 26149 | 26149 | no |

### q5_upland_centres_dates.csv

56 valori, 0 variati.

| quantità | precedente | nuovo | variato |
|---|---|---|---|
| DUR032 — def_sito | centro fortificato | centro fortificato | no |
| DUR032 — tipo_sito | minor settlement | minor settlement | no |
| DUR032 — top_ant | NA | NA | no |
| DUR032 — comune | NA | NA | no |
| DUR032 — localita | Dorez | Dorez | no |
| DUR032 — Longit | 3.9471e+05 | 3.9471e+05 | no |
| DUR032 — Latitud | 4.5647e+06 | 4.5647e+06 | no |
| DUR032 — earliest_start | -600 | -600 | no |
| DUR032 — latest_end | 500 | 500 | no |
| DUR032 — in_hellenistic | TRUE | TRUE | no |
| DUR032 — in_roman | TRUE | TRUE | no |
| DUR032 — in_hell_network | TRUE | TRUE | no |
| DUR032 — in_rom_network | TRUE | TRUE | no |
| DUR032 — dual_phase | TRUE | TRUE | no |
| DUR025 — def_sito | centro fortificato | centro fortificato | no |
| DUR025 — tipo_sito | urban settlement | urban settlement | no |
| DUR025 — top_ant | NA | NA | no |
| DUR025 — comune | Petresh | Petresh | no |
| DUR025 — localita | Shenlliu | Shenlliu | no |
| DUR025 — Longit | 4.1655e+05 | 4.1655e+05 | no |
| DUR025 — Latitud | 4.5508e+06 | 4.5508e+06 | no |
| DUR025 — earliest_start | -700 | -700 | no |
| DUR025 — latest_end | 0 | 0 | no |
| DUR025 — in_hellenistic | TRUE | TRUE | no |
| DUR025 — in_roman | TRUE | TRUE | no |
| DUR025 — in_hell_network | TRUE | TRUE | no |
| DUR025 — in_rom_network | TRUE | TRUE | no |
| DUR025 — dual_phase | TRUE | TRUE | no |
| DUR053 — def_sito | centro fortificato | centro fortificato | no |
| DUR053 — tipo_sito | minor settlement | minor settlement | no |
| DUR053 — top_ant | NA | NA | no |
| DUR053 — comune | Kavaje | Kavaje | no |
| DUR053 — localita | Mlik | Mlik | no |
| DUR053 — Longit | 3.8965e+05 | 3.8965e+05 | no |
| DUR053 — Latitud | 4.5554e+06 | 4.5554e+06 | no |
| DUR053 — earliest_start | -400 | -400 | no |
| DUR053 — latest_end | 600 | 600 | no |
| DUR053 — in_hellenistic | TRUE | TRUE | no |
| DUR053 — in_roman | TRUE | TRUE | no |
| DUR053 — in_hell_network | TRUE | TRUE | no |
| DUR053 — in_rom_network | TRUE | TRUE | no |
| DUR053 — dual_phase | TRUE | TRUE | no |
| DUR015 — def_sito | cittï¿½ | cittï¿½ | no |
| DUR015 — tipo_sito | urban settlement | urban settlement | no |
| DUR015 — top_ant | NA | NA | no |
| DUR015 — comune | Kruja | Kruja | no |
| DUR015 — localita | Zgerdesh | Zgerdesh | no |
| DUR015 — Longit | 3.9792e+05 | 3.9792e+05 | no |
| DUR015 — Latitud | 4.5923e+06 | 4.5923e+06 | no |
| DUR015 — earliest_start | -700 | -700 | no |
| DUR015 — latest_end | 600 | 600 | no |
| DUR015 — in_hellenistic | TRUE | TRUE | no |
| DUR015 — in_roman | TRUE | TRUE | no |
| DUR015 — in_hell_network | TRUE | TRUE | no |
| DUR015 — in_rom_network | TRUE | TRUE | no |
| DUR015 — dual_phase | TRUE | TRUE | no |

### q6_stations_dates.csv

75 valori, 0 variati.

| quantità | precedente | nuovo | variato |
|---|---|---|---|
| DUR054 — def_sito | mansio/statio | mansio/statio | no |
| DUR054 — tipo_sito | minor settlement | minor settlement | no |
| DUR054 — top_ant | NA | NA | no |
| DUR054 — comune | Kavaja | Kavaja | no |
| DUR054 — localita | Kryeluz | Kryeluz | no |
| DUR054 — Longit | 3.8345e+05 | 3.8345e+05 | no |
| DUR054 — Latitud | 4.555e+06 | 4.555e+06 | no |
| DUR054 — earliest_start | -27 | -27 | no |
| DUR054 — latest_end | 600 | 600 | no |
| DUR054 — in_hellenistic | FALSE | FALSE | no |
| DUR054 — in_roman | TRUE | TRUE | no |
| DUR054 — in_hell_network | FALSE | FALSE | no |
| DUR054 — in_rom_network | TRUE | TRUE | no |
| DUR054 — dual_phase | FALSE | FALSE | no |
| DUR054 — overlaps_hell | FALSE | FALSE | no |
| DUR022 — def_sito | mansio/statio | mansio/statio | no |
| DUR022 — tipo_sito | minor settlement | minor settlement | no |
| DUR022 — top_ant | NA | NA | no |
| DUR022 — comune | Paper | Paper | no |
| DUR022 — localita | Paper | Paper | no |
| DUR022 — Longit | 4.1138e+05 | 4.1138e+05 | no |
| DUR022 — Latitud | 4.5455e+06 | 4.5455e+06 | no |
| DUR022 — earliest_start | -27 | -27 | no |
| DUR022 — latest_end | 284 | 284 | no |
| DUR022 — in_hellenistic | FALSE | FALSE | no |
| DUR022 — in_roman | TRUE | TRUE | no |
| DUR022 — in_hell_network | FALSE | FALSE | no |
| DUR022 — in_rom_network | TRUE | TRUE | no |
| DUR022 — dual_phase | FALSE | FALSE | no |
| DUR022 — overlaps_hell | FALSE | FALSE | no |
| DUR024 — def_sito | mansio/statio | mansio/statio | no |
| DUR024 — tipo_sito | minor settlement | minor settlement | no |
| DUR024 — top_ant | NA | NA | no |
| DUR024 — comune | Elbasan | Elbasan | no |
| DUR024 — localita | Bradashesh | Bradashesh | no |
| DUR024 — Longit | 4.1774e+05 | 4.1774e+05 | no |
| DUR024 — Latitud | 4.5508e+06 | 4.5508e+06 | no |
| DUR024 — earliest_start | -27 | -27 | no |
| DUR024 — latest_end | 600 | 600 | no |
| DUR024 — in_hellenistic | FALSE | FALSE | no |
| DUR024 — in_roman | TRUE | TRUE | no |
| DUR024 — in_hell_network | FALSE | FALSE | no |
| DUR024 — in_rom_network | TRUE | TRUE | no |
| DUR024 — dual_phase | FALSE | FALSE | no |
| DUR024 — overlaps_hell | FALSE | FALSE | no |
| DUR059 — def_sito | mansio/statio | mansio/statio | no |
| DUR059 — tipo_sito | minor settlement | minor settlement | no |
| DUR059 — top_ant | NA | NA | no |
| DUR059 — comune | Kruja | Kruja | no |
| DUR059 — localita | Burizane | Burizane | no |
| DUR059 — Longit | 3.9294e+05 | 3.9294e+05 | no |
| DUR059 — Latitud | 4.5957e+06 | 4.5957e+06 | no |
| DUR059 — earliest_start | 0 | 0 | no |
| DUR059 — latest_end | 300 | 300 | no |
| DUR059 — in_hellenistic | FALSE | FALSE | no |
| DUR059 — in_roman | TRUE | TRUE | no |
| DUR059 — in_hell_network | FALSE | FALSE | no |
| DUR059 — in_rom_network | TRUE | TRUE | no |
| DUR059 — dual_phase | FALSE | FALSE | no |
| DUR059 — overlaps_hell | FALSE | FALSE | no |
| DUR102 — def_sito | mansio/statio | mansio/statio | no |
| DUR102 — tipo_sito | minor settlement | minor settlement | no |
| DUR102 — top_ant | NA | NA | no |
| DUR102 — comune | Rromanat | Rromanat | no |
| DUR102 — localita | NA | NA | no |
| DUR102 — Longit | 3.823e+05 | 3.823e+05 | no |
| DUR102 — Latitud | 4.5713e+06 | 4.5713e+06 | no |
| DUR102 — earliest_start | 100 | 100 | no |
| DUR102 — latest_end | 600 | 600 | no |
| DUR102 — in_hellenistic | FALSE | FALSE | no |
| DUR102 — in_roman | TRUE | TRUE | no |
| DUR102 — in_hell_network | FALSE | FALSE | no |
| DUR102 — in_rom_network | TRUE | TRUE | no |
| DUR102 — dual_phase | FALSE | FALSE | no |
| DUR102 — overlaps_hell | FALSE | FALSE | no |

### q7_late_antique_horizon.csv

144 valori, 21 variati.

| quantità | precedente | nuovo | variato |
|---|---|---|---|
| DUR042 — in_roman_end300 | FALSE | FALSE | no |
| DUR042 — degree | 2 | 2 | no |
| DUR042 — betweenness_norm | 0.00035063 | 0.00035063 | no |
| DUR042 — rank_betweenness | 60 | 60 | no |
| DUR042 — isolate | FALSE | FALSE | no |
| DUR042 — late_antique_only | TRUE | TRUE | no |
| DUR109 — in_roman_end300 | FALSE | FALSE | no |
| DUR109 — degree | 14 | 14 | no |
| DUR109 — betweenness_norm | 0.023885 | 0.018751 | sì |
| DUR109 — rank_betweenness | 17 | 19 | sì |
| DUR109 — isolate | FALSE | FALSE | no |
| DUR109 — late_antique_only | TRUE | TRUE | no |
| DUR112 — in_roman_end300 | FALSE | FALSE | no |
| DUR112 — degree | 14 | 15 | sì |
| DUR112 — betweenness_norm | 0.023796 | 0.049301 | sì |
| DUR112 — rank_betweenness | 19 | 10 | sì |
| DUR112 — isolate | FALSE | FALSE | no |
| DUR112 — late_antique_only | TRUE | TRUE | no |
| DUR113 — in_roman_end300 | FALSE | FALSE | no |
| DUR113 — degree | 12 | 12 | no |
| DUR113 — betweenness_norm | 0.0054706 | 0.0051555 | sì |
| DUR113 — rank_betweenness | 41 | 41 | no |
| DUR113 — isolate | FALSE | FALSE | no |
| DUR113 — late_antique_only | TRUE | TRUE | no |
| DUR114 — in_roman_end300 | FALSE | FALSE | no |
| DUR114 — degree | 13 | 15 | sì |
| DUR114 — betweenness_norm | 0.0066326 | 0.014168 | sì |
| DUR114 — rank_betweenness | 37 | 27 | sì |
| DUR114 — isolate | FALSE | FALSE | no |
| DUR114 — late_antique_only | TRUE | TRUE | no |
| DUR122 — in_roman_end300 | FALSE | FALSE | no |
| DUR122 — degree | 7 | 7 | no |
| DUR122 — betweenness_norm | 0.0004429 | 0.00038247 | sì |
| DUR122 — rank_betweenness | 58 | 58 | no |
| DUR122 — isolate | FALSE | FALSE | no |
| DUR122 — late_antique_only | TRUE | TRUE | no |
| DUR138 — in_roman_end300 | FALSE | FALSE | no |
| DUR138 — degree | 4 | 4 | no |
| DUR138 — betweenness_norm | 0 | 0 | no |
| DUR138 — rank_betweenness | 65 | 65 | no |
| DUR138 — isolate | FALSE | FALSE | no |
| DUR138 — late_antique_only | TRUE | TRUE | no |
| DUR020 — in_roman_end300 | FALSE | FALSE | no |
| DUR020 — degree | 1 | 1 | no |
| DUR020 — betweenness_norm | 0 | 0 | no |
| DUR020 — rank_betweenness | 65 | 65 | no |
| DUR020 — isolate | FALSE | FALSE | no |
| DUR020 — late_antique_only | TRUE | TRUE | no |
| DUR135 — in_roman_end300 | FALSE | FALSE | no |
| DUR135 — degree | 3 | 3 | no |
| DUR135 — betweenness_norm | 0 | 0 | no |
| DUR135 — rank_betweenness | 65 | 65 | no |
| DUR135 — isolate | FALSE | FALSE | no |
| DUR135 — late_antique_only | TRUE | TRUE | no |
| DUR045 — in_roman_end300 | FALSE | FALSE | no |
| DUR045 — degree | 15 | 15 | no |
| DUR045 — betweenness_norm | 0.03652 | 0.032947 | sì |
| DUR045 — rank_betweenness | 12 | 14 | sì |
| DUR045 — isolate | FALSE | FALSE | no |
| DUR045 — late_antique_only | TRUE | TRUE | no |
| DUR006 — in_roman_end300 | FALSE | FALSE | no |
| DUR006 — degree | 8 | 8 | no |
| DUR006 — betweenness_norm | 0 | 0 | no |
| DUR006 — rank_betweenness | 65 | 65 | no |
| DUR006 — isolate | FALSE | FALSE | no |
| DUR006 — late_antique_only | TRUE | TRUE | no |
| DUR038 — in_roman_end300 | FALSE | FALSE | no |
| DUR038 — degree | 3 | 3 | no |
| DUR038 — betweenness_norm | 0 | 0 | no |
| DUR038 — rank_betweenness | 65 | 65 | no |
| DUR038 — isolate | FALSE | FALSE | no |
| DUR038 — late_antique_only | TRUE | TRUE | no |
| DUR002 — in_roman_end300 | FALSE | FALSE | no |
| DUR002 — degree | 13 | 13 | no |
| DUR002 — betweenness_norm | 0.089257 | 0.088775 | sì |
| DUR002 — rank_betweenness | 2 | 3 | sì |
| DUR002 — isolate | FALSE | FALSE | no |
| DUR002 — late_antique_only | TRUE | TRUE | no |
| DUR010 — in_roman_end300 | FALSE | FALSE | no |
| DUR010 — degree | 10 | 10 | no |
| DUR010 — betweenness_norm | 0.0033361 | 0.0034703 | sì |
| DUR010 — rank_betweenness | 45 | 47 | sì |
| DUR010 — isolate | FALSE | FALSE | no |
| DUR010 — late_antique_only | TRUE | TRUE | no |
| DUR016 — in_roman_end300 | FALSE | FALSE | no |
| DUR016 — degree | 0 | 0 | no |
| DUR016 — betweenness_norm | 0 | 0 | no |
| DUR016 — rank_betweenness | 65 | 65 | no |
| DUR016 — isolate | TRUE | TRUE | no |
| DUR016 — late_antique_only | TRUE | TRUE | no |
| DUR021 — in_roman_end300 | FALSE | FALSE | no |
| DUR021 — degree | 1 | 1 | no |
| DUR021 — betweenness_norm | 0 | 0 | no |
| DUR021 — rank_betweenness | 65 | 65 | no |
| DUR021 — isolate | FALSE | FALSE | no |
| DUR021 — late_antique_only | TRUE | TRUE | no |
| DUR030 — in_roman_end300 | FALSE | FALSE | no |
| DUR030 — degree | 0 | 0 | no |
| DUR030 — betweenness_norm | 0 | 0 | no |
| DUR030 — rank_betweenness | 65 | 65 | no |
| DUR030 — isolate | TRUE | TRUE | no |
| DUR030 — late_antique_only | TRUE | TRUE | no |
| DUR031 — in_roman_end300 | FALSE | FALSE | no |
| DUR031 — degree | 6 | 6 | no |
| DUR031 — betweenness_norm | 0.0035063 | 0.0035063 | no |
| DUR031 — rank_betweenness | 42 | 44 | sì |
| DUR031 — isolate | FALSE | FALSE | no |
| DUR031 — late_antique_only | TRUE | TRUE | no |
| DUR034 — in_roman_end300 | FALSE | FALSE | no |
| DUR034 — degree | 14 | 14 | no |
| DUR034 — betweenness_norm | 0.049654 | 0.049108 | sì |
| DUR034 — rank_betweenness | 9 | 11 | sì |
| DUR034 — isolate | FALSE | FALSE | no |
| DUR034 — late_antique_only | TRUE | TRUE | no |
| DUR040 — in_roman_end300 | FALSE | FALSE | no |
| DUR040 — degree | 4 | 4 | no |
| DUR040 — betweenness_norm | 0.057036 | 0.057036 | no |
| DUR040 — rank_betweenness | 8 | 8 | no |
| DUR040 — isolate | FALSE | FALSE | no |
| DUR040 — late_antique_only | TRUE | TRUE | no |
| DUR052 — in_roman_end300 | FALSE | FALSE | no |
| DUR052 — degree | 0 | 0 | no |
| DUR052 — betweenness_norm | 0 | 0 | no |
| DUR052 — rank_betweenness | 65 | 65 | no |
| DUR052 — isolate | TRUE | TRUE | no |
| DUR052 — late_antique_only | TRUE | TRUE | no |
| DUR056 — in_roman_end300 | FALSE | FALSE | no |
| DUR056 — degree | 13 | 13 | no |
| DUR056 — betweenness_norm | 0.080396 | 0.065109 | sì |
| DUR056 — rank_betweenness | 3 | 7 | sì |
| DUR056 — isolate | FALSE | FALSE | no |
| DUR056 — late_antique_only | TRUE | TRUE | no |
| DUR032 — in_roman_end300 | TRUE | TRUE | no |
| DUR032 — degree | 1 | 1 | no |
| DUR032 — betweenness_norm | 0 | 0 | no |
| DUR032 — rank_betweenness | 65 | 65 | no |
| DUR032 — isolate | FALSE | FALSE | no |
| DUR032 — late_antique_only | FALSE | FALSE | no |
| DUR053 — in_roman_end300 | TRUE | TRUE | no |
| DUR053 — degree | 0 | 0 | no |
| DUR053 — betweenness_norm | 0 | 0 | no |
| DUR053 — rank_betweenness | 65 | 65 | no |
| DUR053 — isolate | TRUE | TRUE | no |
| DUR053 — late_antique_only | FALSE | FALSE | no |

### road_stations_check.csv

25 valori, 9 variati.

| quantità | precedente | nuovo | variato |
|---|---|---|---|
| DUR022 — betweenness_norm | 0 | 0 | no |
| DUR022 — degree | 1 | 1 | no |
| DUR022 — harmonic | 0.016129 | 0.016129 | no |
| DUR022 — median_mansio | 0.00046751 | 0.00046751 | no |
| DUR022 — median_minor_settlement | 0.00045521 | 0.00042499 | sì |
| DUR024 — betweenness_norm | 0.00046751 | 0.00046751 | no |
| DUR024 — degree | 3 | 3 | no |
| DUR024 — harmonic | 0.032258 | 0.032258 | no |
| DUR024 — median_mansio | 0.00046751 | 0.00046751 | no |
| DUR024 — median_minor_settlement | 0.00045521 | 0.00042499 | sì |
| DUR054 — betweenness_norm | 0.025165 | 0.024344 | sì |
| DUR054 — degree | 10 | 10 | no |
| DUR054 — harmonic | 0.32824 | 0.32913 | sì |
| DUR054 — median_mansio | 0.00046751 | 0.00046751 | no |
| DUR054 — median_minor_settlement | 0.00045521 | 0.00042499 | sì |
| DUR059 — betweenness_norm | 0 | 0 | no |
| DUR059 — degree | 1 | 1 | no |
| DUR059 — harmonic | 0.016129 | 0.016129 | no |
| DUR059 — median_mansio | 0.00046751 | 0.00046751 | no |
| DUR059 — median_minor_settlement | 0.00045521 | 0.00042499 | sì |
| DUR102 — betweenness_norm | 0.019892 | 0.016509 | sì |
| DUR102 — degree | 8 | 8 | no |
| DUR102 — harmonic | 0.2853 | 0.28674 | sì |
| DUR102 — median_mansio | 0.00046751 | 0.00046751 | no |
| DUR102 — median_minor_settlement | 0.00045521 | 0.00042499 | sì |

### station_modules.csv

20 valori, 2 variati.

| quantità | precedente | nuovo | variato |
|---|---|---|---|
| DUR022 — module | NA | NA | no |
| DUR022 — n_members | NA | NA | no |
| DUR022 — betweenness_norm | 0 | 0 | no |
| DUR022 — degree | 1 | 1 | no |
| DUR024 — module | NA | NA | no |
| DUR024 — n_members | NA | NA | no |
| DUR024 — betweenness_norm | 0.00046751 | 0.00046751 | no |
| DUR024 — degree | 3 | 3 | no |
| DUR054 — module | 6 | 6 | no |
| DUR054 — n_members | 22 | 22 | no |
| DUR054 — betweenness_norm | 0.025165 | 0.024344 | sì |
| DUR054 — degree | 10 | 10 | no |
| DUR059 — module | NA | NA | no |
| DUR059 — n_members | NA | NA | no |
| DUR059 — betweenness_norm | 0 | 0 | no |
| DUR059 — degree | 1 | 1 | no |
| DUR102 — module | 3 | 3 | no |
| DUR102 — n_members | 7 | 7 | no |
| DUR102 — betweenness_norm | 0.019892 | 0.016509 | sì |
| DUR102 — degree | 8 | 8 | no |

### station_network_roles.csv

50 valori, 0 variati.

| quantità | precedente | nuovo | variato |
|---|---|---|---|
| DUR022 — module | NA | NA | no |
| DUR022 — n_members_module | NA | NA | no |
| DUR022 — degree | 1 | 1 | no |
| DUR022 — n_neighbours | 1 | 1 | no |
| DUR022 — n_intra | NA | NA | no |
| DUR022 — n_inter | NA | NA | no |
| DUR022 — n_not_in_giant | 1 | 1 | no |
| DUR022 — prop_inter | NA | NA | no |
| DUR022 — inter_modules | NA | NA | no |
| DUR022 — role | outside giant | outside giant | no |
| DUR024 — module | NA | NA | no |
| DUR024 — n_members_module | NA | NA | no |
| DUR024 — degree | 3 | 3 | no |
| DUR024 — n_neighbours | 3 | 3 | no |
| DUR024 — n_intra | NA | NA | no |
| DUR024 — n_inter | NA | NA | no |
| DUR024 — n_not_in_giant | 3 | 3 | no |
| DUR024 — prop_inter | NA | NA | no |
| DUR024 — inter_modules | NA | NA | no |
| DUR024 — role | outside giant | outside giant | no |
| DUR054 — module | 6 | 6 | no |
| DUR054 — n_members_module | 22 | 22 | no |
| DUR054 — degree | 10 | 10 | no |
| DUR054 — n_neighbours | 10 | 10 | no |
| DUR054 — n_intra | 8 | 8 | no |
| DUR054 — n_inter | 2 | 2 | no |
| DUR054 — n_not_in_giant | 0 | 0 | no |
| DUR054 — prop_inter |    0.2 |    0.2 | no |
| DUR054 — inter_modules | 4 | 4 | no |
| DUR054 — role | hub locale | hub locale | no |
| DUR059 — module | NA | NA | no |
| DUR059 — n_members_module | NA | NA | no |
| DUR059 — degree | 1 | 1 | no |
| DUR059 — n_neighbours | 1 | 1 | no |
| DUR059 — n_intra | NA | NA | no |
| DUR059 — n_inter | NA | NA | no |
| DUR059 — n_not_in_giant | 1 | 1 | no |
| DUR059 — prop_inter | NA | NA | no |
| DUR059 — inter_modules | NA | NA | no |
| DUR059 — role | outside giant | outside giant | no |
| DUR102 — module | 3 | 3 | no |
| DUR102 — n_members_module | 7 | 7 | no |
| DUR102 — degree | 8 | 8 | no |
| DUR102 — n_neighbours | 8 | 8 | no |
| DUR102 — n_intra | 6 | 6 | no |
| DUR102 — n_inter | 2 | 2 | no |
| DUR102 — n_not_in_giant | 0 | 0 | no |
| DUR102 — prop_inter |   0.25 |   0.25 | no |
| DUR102 — inter_modules | 4 | 4 | no |
| DUR102 — role | hub locale | hub locale | no |

### station_neighbors.csv

5 valori, 0 variati.

| quantità | precedente | nuovo | variato |
|---|---|---|---|
| DUR022 — vicini | DUR141 | DUR141 | no |
| DUR024 — vicini | DUR017;DUR025;DUR028 | DUR017;DUR025;DUR028 | no |
| DUR054 — vicini | DUR050;DUR056;DUR062;DUR063;DUR064;DUR065;DUR066;DUR112;DUR113;DUR114 | DUR050;DUR056;DUR062;DUR063;DUR064;DUR065;DUR066;DUR112;DUR113;DUR114 | no |
| DUR059 — vicini | DUR015 | DUR015 | no |
| DUR102 — vicini | DUR033;DUR043;DUR044;DUR045;DUR046;DUR128;DUR129;DUR130 | DUR033;DUR043;DUR044;DUR045;DUR046;DUR128;DUR129;DUR130 | no |

## Tabelle di `11` (disegno fattoriale)

### factorial_composition.csv

36 valori, 15 variati.

| quantità | precedente | nuovo | variato |
|---|---|---|---|
| H-T — n_nodes | 71 | 71 | no |
| H-T — n_edges | 1084 | 1085 | sì |
| H-T — density | 0.43622 | 0.43662 | sì |
| H-T — median_degree | 37 | 37 | no |
| H-T — n_isolates | 0 | 0 | no |
| H-T — isolates |  |  | no |
| H-T — n_components | 2 | 2 | no |
| H-T — giant_size | 68 | 68 | no |
| H-T — giant_pct | 95.775 | 95.775 | no |
| R-W — n_nodes | 94 | 94 | no |
| R-W — n_edges | 348 | 355 | sì |
| R-W — density | 0.079616 | 0.081217 | sì |
| R-W — median_degree |    7.5 | 8 | sì |
| R-W — n_isolates | 6 | 5 | sì |
| R-W — isolates | DUR016;DUR029;DUR030;DUR052;DUR053;DUR103 | DUR016;DUR029;DUR030;DUR052;DUR053 | sì |
| R-W — n_components | 14 | 13 | sì |
| R-W — giant_size | 66 | 66 | no |
| R-W — giant_pct | 70.213 | 70.213 | no |
| H-W — n_nodes | 71 | 71 | no |
| H-W — n_edges | 434 | 434 | no |
| H-W — density | 0.17465 | 0.17465 | no |
| H-W — median_degree | 9 | 9 | no |
| H-W — n_isolates | 7 | 7 | no |
| H-W — isolates | DUR003;DUR015;DUR025;DUR032;DUR041;DUR051;DUR053 | DUR003;DUR015;DUR025;DUR032;DUR041;DUR051;DUR053 | no |
| H-W — n_components | 13 | 13 | no |
| H-W — giant_size | 41 | 41 | no |
| H-W — giant_pct | 57.746 | 57.746 | no |
| R-T — n_nodes | 94 | 94 | no |
| R-T — n_edges | 1550 | 1553 | sì |
| R-T — density | 0.35461 | 0.3553 | sì |
| R-T — median_degree |   35.5 |   35.5 | no |
| R-T — n_isolates | 1 | 0 | sì |
| R-T — isolates | DUR103 |  | sì |
| R-T — n_components | 2 | 1 | sì |
| R-T — giant_size | 93 | 94 | sì |
| R-T — giant_pct | 98.936 | 100 | sì |

### factorial_concentration.csv

24 valori, 15 variati.

| quantità | precedente | nuovo | variato |
|---|---|---|---|
| H-T — top1_share | 0.19136 | 0.19148 | sì |
| H-T — ratio_1st_2nd | 4.2524 | 4.2525 | sì |
| H-T — top5_share | 0.35393 | 0.35334 | sì |
| H-T — gini | 0.67691 | 0.6764 | sì |
| H-T — freeman_centralization | 0.12062 | 0.12062 | sì |
| H-T — top_node | DUR003 | DUR003 | no |
| R-W — top1_share | 0.091889 | 0.079981 | sì |
| R-W — ratio_1st_2nd | 1.3175 | 1.1059 | sì |
| R-W — top5_share | 0.34625 | 0.33388 | sì |
| R-W — gini | 0.75054 | 0.74281 | sì |
| R-W — freeman_centralization | 0.1051 | 0.088405 | sì |
| R-W — top_node | DUR050 | DUR050 | no |
| H-W — top1_share | 0.29328 | 0.29328 | no |
| H-W — ratio_1st_2nd | 1.7997 | 1.7997 | no |
| H-W — top5_share | 0.7986 | 0.7986 | no |
| H-W — gini | 0.91736 | 0.91736 | no |
| H-W — freeman_centralization | 0.11703 | 0.11703 | no |
| H-W — top_node | DUR033 | DUR033 | no |
| R-T — top1_share | 0.041685 | 0.043041 | sì |
| R-T — ratio_1st_2nd | 1.0062 | 1.0815 | sì |
| R-T — top5_share | 0.19014 | 0.18474 | sì |
| R-T — gini | 0.5138 | 0.51071 | sì |
| R-T — freeman_centralization | 0.03273 | 0.035852 | sì |
| R-T — top_node | DUR138 | DUR138 | no |

### factorial_upland_centres.csv

192 valori, 10 variati.

| quantità | precedente | nuovo | variato |
|---|---|---|---|
| H-T \| site \| DUR032 — present | TRUE | TRUE | no |
| H-T \| site \| DUR032 — degree | 12 | 12 | no |
| H-T \| site \| DUR032 — betweenness_norm | 0.030186 | 0.030186 | sì |
| H-T \| site \| DUR032 — rank_betweenness | 2 | 2 | no |
| H-T \| site \| DUR032 — in_giant | TRUE | TRUE | no |
| H-T \| site \| DUR032 — btw_max | NA | NA | no |
| H-T \| site \| DUR032 — btw_max_site | NA | NA | no |
| H-T \| site \| DUR032 — degree_median | NA | NA | no |
| H-T \| site \| DUR053 — present | TRUE | TRUE | no |
| H-T \| site \| DUR053 — degree | 19 | 19 | no |
| H-T \| site \| DUR053 — betweenness_norm | 0.0031344 | 0.0031341 | sì |
| H-T \| site \| DUR053 — rank_betweenness | 37 | 38 | sì |
| H-T \| site \| DUR053 — in_giant | TRUE | TRUE | no |
| H-T \| site \| DUR053 — btw_max | NA | NA | no |
| H-T \| site \| DUR053 — btw_max_site | NA | NA | no |
| H-T \| site \| DUR053 — degree_median | NA | NA | no |
| H-T \| site \| DUR015 — present | TRUE | TRUE | no |
| H-T \| site \| DUR015 — degree | 5 | 5 | no |
| H-T \| site \| DUR015 — betweenness_norm | 0.0016809 | 0.0016809 | no |
| H-T \| site \| DUR015 — rank_betweenness | 44 | 44 | no |
| H-T \| site \| DUR015 — in_giant | TRUE | TRUE | no |
| H-T \| site \| DUR015 — btw_max | NA | NA | no |
| H-T \| site \| DUR015 — btw_max_site | NA | NA | no |
| H-T \| site \| DUR015 — degree_median | NA | NA | no |
| H-T \| site \| DUR025 — present | TRUE | TRUE | no |
| H-T \| site \| DUR025 — degree | 2 | 2 | no |
| H-T \| site \| DUR025 — betweenness_norm | 0 | 0 | no |
| H-T \| site \| DUR025 — rank_betweenness | 60 | 60 | no |
| H-T \| site \| DUR025 — in_giant | FALSE | FALSE | no |
| H-T \| site \| DUR025 — btw_max | NA | NA | no |
| H-T \| site \| DUR025 — btw_max_site | NA | NA | no |
| H-T \| site \| DUR025 — degree_median | NA | NA | no |
| H-T \| site \| DUR003 — present | TRUE | TRUE | no |
| H-T \| site \| DUR003 — degree | 37 | 37 | no |
| H-T \| site \| DUR003 — betweenness_norm | 0.12836 | 0.12836 | no |
| H-T \| site \| DUR003 — rank_betweenness | 1 | 1 | no |
| H-T \| site \| DUR003 — in_giant | TRUE | TRUE | no |
| H-T \| site \| DUR003 — btw_max | NA | NA | no |
| H-T \| site \| DUR003 — btw_max_site | NA | NA | no |
| H-T \| site \| DUR003 — degree_median | NA | NA | no |
| R-W \| site \| DUR032 — present | TRUE | TRUE | no |
| R-W \| site \| DUR032 — degree | 1 | 1 | no |
| R-W \| site \| DUR032 — betweenness_norm | 0 | 0 | no |
| R-W \| site \| DUR032 — rank_betweenness | 65 | 65 | no |
| R-W \| site \| DUR032 — in_giant | FALSE | FALSE | no |
| R-W \| site \| DUR032 — btw_max | NA | NA | no |
| R-W \| site \| DUR032 — btw_max_site | NA | NA | no |
| R-W \| site \| DUR032 — degree_median | NA | NA | no |
| R-W \| site \| DUR053 — present | TRUE | TRUE | no |
| R-W \| site \| DUR053 — degree | 0 | 0 | no |
| R-W \| site \| DUR053 — betweenness_norm | 0 | 0 | no |
| R-W \| site \| DUR053 — rank_betweenness | 65 | 65 | no |
| R-W \| site \| DUR053 — in_giant | FALSE | FALSE | no |
| R-W \| site \| DUR053 — btw_max | NA | NA | no |
| R-W \| site \| DUR053 — btw_max_site | NA | NA | no |
| R-W \| site \| DUR053 — degree_median | NA | NA | no |
| R-W \| site \| DUR015 — present | TRUE | TRUE | no |
| R-W \| site \| DUR015 — degree | 2 | 2 | no |
| R-W \| site \| DUR015 — betweenness_norm | 0.00023375 | 0.00023375 | no |
| R-W \| site \| DUR015 — rank_betweenness | 62 | 62 | no |
| R-W \| site \| DUR015 — in_giant | FALSE | FALSE | no |
| R-W \| site \| DUR015 — btw_max | NA | NA | no |
| R-W \| site \| DUR015 — btw_max_site | NA | NA | no |
| R-W \| site \| DUR015 — degree_median | NA | NA | no |
| R-W \| site \| DUR025 — present | TRUE | TRUE | no |
| R-W \| site \| DUR025 — degree | 1 | 1 | no |
| R-W \| site \| DUR025 — betweenness_norm | 0 | 0 | no |
| R-W \| site \| DUR025 — rank_betweenness | 65 | 65 | no |
| R-W \| site \| DUR025 — in_giant | FALSE | FALSE | no |
| R-W \| site \| DUR025 — btw_max | NA | NA | no |
| R-W \| site \| DUR025 — btw_max_site | NA | NA | no |
| R-W \| site \| DUR025 — degree_median | NA | NA | no |
| R-W \| site \| DUR003 — present | FALSE | FALSE | no |
| R-W \| site \| DUR003 — degree | NA | NA | no |
| R-W \| site \| DUR003 — betweenness_norm | NA | NA | no |
| R-W \| site \| DUR003 — rank_betweenness | NA | NA | no |
| R-W \| site \| DUR003 — in_giant | NA | NA | no |
| R-W \| site \| DUR003 — btw_max | NA | NA | no |
| R-W \| site \| DUR003 — btw_max_site | NA | NA | no |
| R-W \| site \| DUR003 — degree_median | NA | NA | no |
| H-W \| site \| DUR032 — present | TRUE | TRUE | no |
| H-W \| site \| DUR032 — degree | 0 | 0 | no |
| H-W \| site \| DUR032 — betweenness_norm | 0 | 0 | no |
| H-W \| site \| DUR032 — rank_betweenness | 40 | 40 | no |
| H-W \| site \| DUR032 — in_giant | FALSE | FALSE | no |
| H-W \| site \| DUR032 — btw_max | NA | NA | no |
| H-W \| site \| DUR032 — btw_max_site | NA | NA | no |
| H-W \| site \| DUR032 — degree_median | NA | NA | no |
| H-W \| site \| DUR053 — present | TRUE | TRUE | no |
| H-W \| site \| DUR053 — degree | 0 | 0 | no |
| H-W \| site \| DUR053 — betweenness_norm | 0 | 0 | no |
| H-W \| site \| DUR053 — rank_betweenness | 40 | 40 | no |
| H-W \| site \| DUR053 — in_giant | FALSE | FALSE | no |
| H-W \| site \| DUR053 — btw_max | NA | NA | no |
| H-W \| site \| DUR053 — btw_max_site | NA | NA | no |
| H-W \| site \| DUR053 — degree_median | NA | NA | no |
| H-W \| site \| DUR015 — present | TRUE | TRUE | no |
| H-W \| site \| DUR015 — degree | 0 | 0 | no |
| H-W \| site \| DUR015 — betweenness_norm | 0 | 0 | no |
| H-W \| site \| DUR015 — rank_betweenness | 40 | 40 | no |
| H-W \| site \| DUR015 — in_giant | FALSE | FALSE | no |
| H-W \| site \| DUR015 — btw_max | NA | NA | no |
| H-W \| site \| DUR015 — btw_max_site | NA | NA | no |
| H-W \| site \| DUR015 — degree_median | NA | NA | no |
| H-W \| site \| DUR025 — present | TRUE | TRUE | no |
| H-W \| site \| DUR025 — degree | 0 | 0 | no |
| H-W \| site \| DUR025 — betweenness_norm | 0 | 0 | no |
| H-W \| site \| DUR025 — rank_betweenness | 40 | 40 | no |
| H-W \| site \| DUR025 — in_giant | FALSE | FALSE | no |
| H-W \| site \| DUR025 — btw_max | NA | NA | no |
| H-W \| site \| DUR025 — btw_max_site | NA | NA | no |
| H-W \| site \| DUR025 — degree_median | NA | NA | no |
| H-W \| site \| DUR003 — present | TRUE | TRUE | no |
| H-W \| site \| DUR003 — degree | 0 | 0 | no |
| H-W \| site \| DUR003 — betweenness_norm | 0 | 0 | no |
| H-W \| site \| DUR003 — rank_betweenness | 40 | 40 | no |
| H-W \| site \| DUR003 — in_giant | FALSE | FALSE | no |
| H-W \| site \| DUR003 — btw_max | NA | NA | no |
| H-W \| site \| DUR003 — btw_max_site | NA | NA | no |
| H-W \| site \| DUR003 — degree_median | NA | NA | no |
| R-T \| site \| DUR032 — present | TRUE | TRUE | no |
| R-T \| site \| DUR032 — degree | 24 | 24 | no |
| R-T \| site \| DUR032 — betweenness_norm | 0.035292 | 0.034832 | sì |
| R-T \| site \| DUR032 — rank_betweenness | 4 | 4 | no |
| R-T \| site \| DUR032 — in_giant | TRUE | TRUE | no |
| R-T \| site \| DUR032 — btw_max | NA | NA | no |
| R-T \| site \| DUR032 — btw_max_site | NA | NA | no |
| R-T \| site \| DUR032 — degree_median | NA | NA | no |
| R-T \| site \| DUR053 — present | TRUE | TRUE | no |
| R-T \| site \| DUR053 — degree | 38 | 38 | no |
| R-T \| site \| DUR053 — betweenness_norm | 0.012886 | 0.012928 | sì |
| R-T \| site \| DUR053 — rank_betweenness | 41 | 41 | no |
| R-T \| site \| DUR053 — in_giant | TRUE | TRUE | no |
| R-T \| site \| DUR053 — btw_max | NA | NA | no |
| R-T \| site \| DUR053 — btw_max_site | NA | NA | no |
| R-T \| site \| DUR053 — degree_median | NA | NA | no |
| R-T \| site \| DUR015 — present | TRUE | TRUE | no |
| R-T \| site \| DUR015 — degree | 9 | 9 | no |
| R-T \| site \| DUR015 — betweenness_norm | 0.001946 | 0.0021179 | sì |
| R-T \| site \| DUR015 — rank_betweenness | 73 | 73 | no |
| R-T \| site \| DUR015 — in_giant | TRUE | TRUE | no |
| R-T \| site \| DUR015 — btw_max | NA | NA | no |
| R-T \| site \| DUR015 — btw_max_site | NA | NA | no |
| R-T \| site \| DUR015 — degree_median | NA | NA | no |
| R-T \| site \| DUR025 — present | TRUE | TRUE | no |
| R-T \| site \| DUR025 — degree | 6 | 6 | no |
| R-T \| site \| DUR025 — betweenness_norm | 0.0018191 | 0.0017975 | sì |
| R-T \| site \| DUR025 — rank_betweenness | 74 | 74 | no |
| R-T \| site \| DUR025 — in_giant | TRUE | TRUE | no |
| R-T \| site \| DUR025 — btw_max | NA | NA | no |
| R-T \| site \| DUR025 — btw_max_site | NA | NA | no |
| R-T \| site \| DUR025 — degree_median | NA | NA | no |
| R-T \| site \| DUR003 — present | FALSE | FALSE | no |
| R-T \| site \| DUR003 — degree | NA | NA | no |
| R-T \| site \| DUR003 — betweenness_norm | NA | NA | no |
| R-T \| site \| DUR003 — rank_betweenness | NA | NA | no |
| R-T \| site \| DUR003 — in_giant | NA | NA | no |
| R-T \| site \| DUR003 — btw_max | NA | NA | no |
| R-T \| site \| DUR003 — btw_max_site | NA | NA | no |
| R-T \| site \| DUR003 — degree_median | NA | NA | no |
| H-T \| category \| NA — present | NA | NA | no |
| H-T \| category \| NA — degree | NA | NA | no |
| H-T \| category \| NA — betweenness_norm | NA | NA | no |
| H-T \| category \| NA — rank_betweenness | NA | NA | no |
| H-T \| category \| NA — in_giant | NA | NA | no |
| H-T \| category \| NA — btw_max | 0.030186 | 0.030186 | sì |
| H-T \| category \| NA — btw_max_site | DUR032 | DUR032 | no |
| H-T \| category \| NA — degree_median | 12 | 12 | no |
| R-W \| category \| NA — present | NA | NA | no |
| R-W \| category \| NA — degree | NA | NA | no |
| R-W \| category \| NA — betweenness_norm | NA | NA | no |
| R-W \| category \| NA — rank_betweenness | NA | NA | no |
| R-W \| category \| NA — in_giant | NA | NA | no |
| R-W \| category \| NA — btw_max | 0.0010438 | 0.00060432 | sì |
| R-W \| category \| NA — btw_max_site | DUR080 | DUR080 | no |
| R-W \| category \| NA — degree_median | 1 | 1 | no |
| H-W \| category \| NA — present | NA | NA | no |
| H-W \| category \| NA — degree | NA | NA | no |
| H-W \| category \| NA — betweenness_norm | NA | NA | no |
| H-W \| category \| NA — rank_betweenness | NA | NA | no |
| H-W \| category \| NA — in_giant | NA | NA | no |
| H-W \| category \| NA — btw_max | 0.00013803 | 0.00013803 | no |
| H-W \| category \| NA — btw_max_site | DUR080 | DUR080 | no |
| H-W \| category \| NA — degree_median | 1 | 1 | no |
| R-T \| category \| NA — present | NA | NA | no |
| R-T \| category \| NA — degree | NA | NA | no |
| R-T \| category \| NA — betweenness_norm | NA | NA | no |
| R-T \| category \| NA — rank_betweenness | NA | NA | no |
| R-T \| category \| NA — in_giant | NA | NA | no |
| R-T \| category \| NA — btw_max | 0.035292 | 0.034832 | sì |
| R-T \| category \| NA — btw_max_site | DUR032 | DUR032 | no |
| R-T \| category \| NA — degree_median | 25 | 25 | no |

### factorial_tests.csv

340 valori, 148 variati.

| quantità | precedente | nuovo | variato |
|---|---|---|---|
| H-T vs R-T \| mann_whitney \| degree_norm — statistic | 4334 | 4344 | sì |
| H-T vs R-T \| mann_whitney \| degree_norm — p_value | 0.0010361 | 0.00092148 | sì |
| H-T vs R-T \| mann_whitney \| degree_norm — value_a | 0.52857 | 0.52857 | no |
| H-T vs R-T \| mann_whitney \| degree_norm — value_b | 0.38172 | 0.38172 | no |
| H-T vs R-T \| wilcoxon_paired_dual \| degree_norm — statistic | 675 | 669 | sì |
| H-T vs R-T \| wilcoxon_paired_dual \| degree_norm — p_value | 0.14317 | 0.16195 | sì |
| H-T vs R-T \| wilcoxon_paired_dual \| degree_norm — value_a |    0.5 |    0.5 | no |
| H-T vs R-T \| wilcoxon_paired_dual \| degree_norm — value_b | 0.40323 | 0.40323 | no |
| H-T vs R-T \| spearman_dual \| degree_norm — statistic | 0.75494 | 0.75593 | sì |
| H-T vs R-T \| spearman_dual \| degree_norm — p_value | 1.3512e-09 | 1.2498e-09 | sì |
| H-T vs R-T \| spearman_dual \| degree_norm — value_a | NA | NA | no |
| H-T vs R-T \| spearman_dual \| degree_norm — value_b | NA | NA | no |
| H-T vs R-T \| mann_whitney \| harmonic — statistic | 4357 | 4278 | sì |
| H-T vs R-T \| mann_whitney \| harmonic — p_value | 0.00079138 | 0.0019633 | sì |
| H-T vs R-T \| mann_whitney \| harmonic — value_a | 0.71429 | 0.71429 | no |
| H-T vs R-T \| mann_whitney \| harmonic — value_b | 0.64821 | 0.65233 | sì |
| H-T vs R-T \| wilcoxon_paired_dual \| harmonic — statistic | 622 | 601 | sì |
| H-T vs R-T \| wilcoxon_paired_dual \| harmonic — p_value | 0.37616 | 0.5121 | sì |
| H-T vs R-T \| wilcoxon_paired_dual \| harmonic — value_a | 0.7131 | 0.7131 | no |
| H-T vs R-T \| wilcoxon_paired_dual \| harmonic — value_b | 0.65367 | 0.65654 | sì |
| H-T vs R-T \| spearman_dual \| harmonic — statistic | 0.76857 | 0.78102 | sì |
| H-T vs R-T \| spearman_dual \| harmonic — p_value | 0 | 0 | no |
| H-T vs R-T \| spearman_dual \| harmonic — value_a | NA | NA | no |
| H-T vs R-T \| spearman_dual \| harmonic — value_b | NA | NA | no |
| H-T vs R-T \| mann_whitney \| betweenness_norm — statistic | 2680 | 2590 | sì |
| H-T vs R-T \| mann_whitney \| betweenness_norm — p_value | 0.030577 | 0.013954 | sì |
| H-T vs R-T \| mann_whitney \| betweenness_norm — value_a | 0.0037715 | 0.0037276 | sì |
| H-T vs R-T \| mann_whitney \| betweenness_norm — value_b | 0.0076449 | 0.0097022 | sì |
| H-T vs R-T \| wilcoxon_paired_dual \| betweenness_norm — statistic | 448 | 428 | sì |
| H-T vs R-T \| wilcoxon_paired_dual \| betweenness_norm — p_value | 0.97008 | 0.43768 | sì |
| H-T vs R-T \| wilcoxon_paired_dual \| betweenness_norm — value_a | 0.0048999 | 0.0048532 | sì |
| H-T vs R-T \| wilcoxon_paired_dual \| betweenness_norm — value_b | 0.0049803 | 0.005854 | sì |
| H-T vs R-T \| spearman_dual \| betweenness_norm — statistic | 0.77676 | 0.79011 | sì |
| H-T vs R-T \| spearman_dual \| betweenness_norm — p_value | 0 | 0 | no |
| H-T vs R-T \| spearman_dual \| betweenness_norm — value_a | NA | NA | no |
| H-T vs R-T \| spearman_dual \| betweenness_norm — value_b | NA | NA | no |
| H-T vs R-T \| concentration_difference \| top1_share — statistic | -0.14967 | -0.14844 | sì |
| H-T vs R-T \| concentration_difference \| top1_share — p_value | NA | NA | no |
| H-T vs R-T \| concentration_difference \| top1_share — value_a | 0.19136 | 0.19148 | sì |
| H-T vs R-T \| concentration_difference \| top1_share — value_b | 0.041685 | 0.043041 | sì |
| H-T vs R-T \| concentration_difference \| gini — statistic | -0.16312 | -0.16568 | sì |
| H-T vs R-T \| concentration_difference \| gini — p_value | NA | NA | no |
| H-T vs R-T \| concentration_difference \| gini — value_a | 0.67691 | 0.6764 | sì |
| H-T vs R-T \| concentration_difference \| gini — value_b | 0.5138 | 0.51071 | sì |
| H-T vs R-T \| concentration_difference \| freeman_centralization — statistic | -0.087885 | -0.084769 | sì |
| H-T vs R-T \| concentration_difference \| freeman_centralization — p_value | NA | NA | no |
| H-T vs R-T \| concentration_difference \| freeman_centralization — value_a | 0.12062 | 0.12062 | sì |
| H-T vs R-T \| concentration_difference \| freeman_centralization — value_b | 0.03273 | 0.035852 | sì |
| H-T vs R-T \| concentration_difference \| top5_share — statistic | -0.16379 | -0.1686 | sì |
| H-T vs R-T \| concentration_difference \| top5_share — p_value | NA | NA | no |
| H-T vs R-T \| concentration_difference \| top5_share — value_a | 0.35393 | 0.35334 | sì |
| H-T vs R-T \| concentration_difference \| top5_share — value_b | 0.19014 | 0.18474 | sì |
| H-T vs R-T \| concentration_difference \| ratio_1st_2nd — statistic | -3.2462 | -3.171 | sì |
| H-T vs R-T \| concentration_difference \| ratio_1st_2nd — p_value | NA | NA | no |
| H-T vs R-T \| concentration_difference \| ratio_1st_2nd — value_a | 4.2524 | 4.2525 | sì |
| H-T vs R-T \| concentration_difference \| ratio_1st_2nd — value_b | 1.0062 | 1.0815 | sì |
| H-T vs R-T \| upland_rank_change \| DUR032 — statistic | 2 | 2 | no |
| H-T vs R-T \| upland_rank_change \| DUR032 — p_value | NA | NA | no |
| H-T vs R-T \| upland_rank_change \| DUR032 — value_a | 2 | 2 | no |
| H-T vs R-T \| upland_rank_change \| DUR032 — value_b | 4 | 4 | no |
| H-T vs R-T \| upland_rank_change \| DUR053 — statistic | 4 | 3 | sì |
| H-T vs R-T \| upland_rank_change \| DUR053 — p_value | NA | NA | no |
| H-T vs R-T \| upland_rank_change \| DUR053 — value_a | 37 | 38 | sì |
| H-T vs R-T \| upland_rank_change \| DUR053 — value_b | 41 | 41 | no |
| H-T vs R-T \| upland_rank_change \| DUR015 — statistic | 29 | 29 | no |
| H-T vs R-T \| upland_rank_change \| DUR015 — p_value | NA | NA | no |
| H-T vs R-T \| upland_rank_change \| DUR015 — value_a | 44 | 44 | no |
| H-T vs R-T \| upland_rank_change \| DUR015 — value_b | 73 | 73 | no |
| H-T vs R-T \| upland_rank_change \| DUR025 — statistic | 14 | 14 | no |
| H-T vs R-T \| upland_rank_change \| DUR025 — p_value | NA | NA | no |
| H-T vs R-T \| upland_rank_change \| DUR025 — value_a | 60 | 60 | no |
| H-T vs R-T \| upland_rank_change \| DUR025 — value_b | 74 | 74 | no |
| H-T vs R-T \| upland_rank_change \| DUR003 — statistic | NA | NA | no |
| H-T vs R-T \| upland_rank_change \| DUR003 — p_value | NA | NA | no |
| H-T vs R-T \| upland_rank_change \| DUR003 — value_a | 1 | 1 | no |
| H-T vs R-T \| upland_rank_change \| DUR003 — value_b | NA | NA | no |
| H-W vs R-W \| mann_whitney \| degree_norm — statistic | 4261 | 4224.5 | sì |
| H-W vs R-W \| mann_whitney \| degree_norm — p_value | 0.0023152 | 0.0034369 | sì |
| H-W vs R-W \| mann_whitney \| degree_norm — value_a | 0.12857 | 0.12857 | no |
| H-W vs R-W \| mann_whitney \| degree_norm — value_b | 0.080645 | 0.086022 | sì |
| H-W vs R-W \| wilcoxon_paired_dual \| degree_norm — statistic | 493 | 470 | sì |
| H-W vs R-W \| wilcoxon_paired_dual \| degree_norm — p_value | 0.78634 | 0.59558 | sì |
| H-W vs R-W \| wilcoxon_paired_dual \| degree_norm — value_a |    0.1 |    0.1 | no |
| H-W vs R-W \| wilcoxon_paired_dual \| degree_norm — value_b | 0.096774 | 0.10215 | sì |
| H-W vs R-W \| spearman_dual \| degree_norm — statistic | 0.71503 | 0.72101 | sì |
| H-W vs R-W \| spearman_dual \| degree_norm — p_value | 2.3675e-08 | 1.5914e-08 | sì |
| H-W vs R-W \| spearman_dual \| degree_norm — value_a | NA | NA | no |
| H-W vs R-W \| spearman_dual \| degree_norm — value_b | NA | NA | no |
| H-W vs R-W \| mann_whitney \| harmonic — statistic | 3778 | 3750.5 | sì |
| H-W vs R-W \| mann_whitney \| harmonic — p_value | 0.14649 | 0.17341 | sì |
| H-W vs R-W \| mann_whitney \| harmonic — value_a | 0.25357 | 0.25357 | no |
| H-W vs R-W \| mann_whitney \| harmonic — value_b | 0.25472 | 0.25555 | sì |
| H-W vs R-W \| wilcoxon_paired_dual \| harmonic — statistic | 353 | 336 | sì |
| H-W vs R-W \| wilcoxon_paired_dual \| harmonic — p_value | 0.064041 | 0.040987 | sì |
| H-W vs R-W \| wilcoxon_paired_dual \| harmonic — value_a | 0.18036 | 0.18036 | no |
| H-W vs R-W \| wilcoxon_paired_dual \| harmonic — value_b | 0.26526 | 0.26615 | sì |
| H-W vs R-W \| spearman_dual \| harmonic — statistic |  0.613 | 0.60439 | sì |
| H-W vs R-W \| spearman_dual \| harmonic — p_value | 5.9342e-06 | 8.6703e-06 | sì |
| H-W vs R-W \| spearman_dual \| harmonic — value_a | NA | NA | no |
| H-W vs R-W \| spearman_dual \| harmonic — value_b | NA | NA | no |
| H-W vs R-W \| mann_whitney \| betweenness_norm — statistic | 2142 | 2135 | sì |
| H-W vs R-W \| mann_whitney \| betweenness_norm — p_value | 5.2294e-05 | 4.7259e-05 | sì |
| H-W vs R-W \| mann_whitney \| betweenness_norm — value_a | 6.2756e-05 | 6.2756e-05 | no |
| H-W vs R-W \| mann_whitney \| betweenness_norm — value_b | 0.0033361 | 0.0034703 | sì |
| H-W vs R-W \| wilcoxon_paired_dual \| betweenness_norm — statistic | 169 | 167 | sì |
| H-W vs R-W \| wilcoxon_paired_dual \| betweenness_norm — p_value | 0.047123 | 0.043347 | sì |
| H-W vs R-W \| wilcoxon_paired_dual \| betweenness_norm — value_a | 0 | 0 | no |
| H-W vs R-W \| wilcoxon_paired_dual \| betweenness_norm — value_b | 0.0033361 | 0.0034703 | sì |
| H-W vs R-W \| spearman_dual \| betweenness_norm — statistic | 0.53429 | 0.54156 | sì |
| H-W vs R-W \| spearman_dual \| betweenness_norm — p_value | 0.00013101 | 0.00010161 | sì |
| H-W vs R-W \| spearman_dual \| betweenness_norm — value_a | NA | NA | no |
| H-W vs R-W \| spearman_dual \| betweenness_norm — value_b | NA | NA | no |
| H-W vs R-W \| concentration_difference \| top1_share — statistic | -0.20139 | -0.2133 | sì |
| H-W vs R-W \| concentration_difference \| top1_share — p_value | NA | NA | no |
| H-W vs R-W \| concentration_difference \| top1_share — value_a | 0.29328 | 0.29328 | no |
| H-W vs R-W \| concentration_difference \| top1_share — value_b | 0.091889 | 0.079981 | sì |
| H-W vs R-W \| concentration_difference \| gini — statistic | -0.16682 | -0.17455 | sì |
| H-W vs R-W \| concentration_difference \| gini — p_value | NA | NA | no |
| H-W vs R-W \| concentration_difference \| gini — value_a | 0.91736 | 0.91736 | no |
| H-W vs R-W \| concentration_difference \| gini — value_b | 0.75054 | 0.74281 | sì |
| H-W vs R-W \| concentration_difference \| freeman_centralization — statistic | -0.011924 | -0.028622 | sì |
| H-W vs R-W \| concentration_difference \| freeman_centralization — p_value | NA | NA | no |
| H-W vs R-W \| concentration_difference \| freeman_centralization — value_a | 0.11703 | 0.11703 | no |
| H-W vs R-W \| concentration_difference \| freeman_centralization — value_b | 0.1051 | 0.088405 | sì |
| H-W vs R-W \| concentration_difference \| top5_share — statistic | -0.45234 | -0.46472 | sì |
| H-W vs R-W \| concentration_difference \| top5_share — p_value | NA | NA | no |
| H-W vs R-W \| concentration_difference \| top5_share — value_a | 0.7986 | 0.7986 | no |
| H-W vs R-W \| concentration_difference \| top5_share — value_b | 0.34625 | 0.33388 | sì |
| H-W vs R-W \| concentration_difference \| ratio_1st_2nd — statistic | -0.48214 | -0.69376 | sì |
| H-W vs R-W \| concentration_difference \| ratio_1st_2nd — p_value | NA | NA | no |
| H-W vs R-W \| concentration_difference \| ratio_1st_2nd — value_a | 1.7997 | 1.7997 | no |
| H-W vs R-W \| concentration_difference \| ratio_1st_2nd — value_b | 1.3175 | 1.1059 | sì |
| H-W vs R-W \| upland_rank_change \| DUR032 — statistic | 25 | 25 | no |
| H-W vs R-W \| upland_rank_change \| DUR032 — p_value | NA | NA | no |
| H-W vs R-W \| upland_rank_change \| DUR032 — value_a | 40 | 40 | no |
| H-W vs R-W \| upland_rank_change \| DUR032 — value_b | 65 | 65 | no |
| H-W vs R-W \| upland_rank_change \| DUR053 — statistic | 25 | 25 | no |
| H-W vs R-W \| upland_rank_change \| DUR053 — p_value | NA | NA | no |
| H-W vs R-W \| upland_rank_change \| DUR053 — value_a | 40 | 40 | no |
| H-W vs R-W \| upland_rank_change \| DUR053 — value_b | 65 | 65 | no |
| H-W vs R-W \| upland_rank_change \| DUR015 — statistic | 22 | 22 | no |
| H-W vs R-W \| upland_rank_change \| DUR015 — p_value | NA | NA | no |
| H-W vs R-W \| upland_rank_change \| DUR015 — value_a | 40 | 40 | no |
| H-W vs R-W \| upland_rank_change \| DUR015 — value_b | 62 | 62 | no |
| H-W vs R-W \| upland_rank_change \| DUR025 — statistic | 25 | 25 | no |
| H-W vs R-W \| upland_rank_change \| DUR025 — p_value | NA | NA | no |
| H-W vs R-W \| upland_rank_change \| DUR025 — value_a | 40 | 40 | no |
| H-W vs R-W \| upland_rank_change \| DUR025 — value_b | 65 | 65 | no |
| H-W vs R-W \| upland_rank_change \| DUR003 — statistic | NA | NA | no |
| H-W vs R-W \| upland_rank_change \| DUR003 — p_value | NA | NA | no |
| H-W vs R-W \| upland_rank_change \| DUR003 — value_a | 40 | 40 | no |
| H-W vs R-W \| upland_rank_change \| DUR003 — value_b | NA | NA | no |
| H-T vs R-W \| mann_whitney \| degree_norm — statistic | 6029 | 6019 | sì |
| H-T vs R-W \| mann_whitney \| degree_norm — p_value | 0 | 0 | no |
| H-T vs R-W \| mann_whitney \| degree_norm — value_a | 0.52857 | 0.52857 | no |
| H-T vs R-W \| mann_whitney \| degree_norm — value_b | 0.080645 | 0.086022 | sì |
| H-T vs R-W \| wilcoxon_paired_dual \| degree_norm — statistic | 1081 | 1081 | no |
| H-T vs R-W \| wilcoxon_paired_dual \| degree_norm — p_value | 3.629e-09 | 3.6106e-09 | sì |
| H-T vs R-W \| wilcoxon_paired_dual \| degree_norm — value_a |    0.5 |    0.5 | no |
| H-T vs R-W \| wilcoxon_paired_dual \| degree_norm — value_b | 0.096774 | 0.10215 | sì |
| H-T vs R-W \| spearman_dual \| degree_norm — statistic | 0.6495 | 0.64283 | sì |
| H-T vs R-W \| spearman_dual \| degree_norm — p_value | 1.0421e-06 | 1.457e-06 | sì |
| H-T vs R-W \| spearman_dual \| degree_norm — value_a | NA | NA | no |
| H-T vs R-W \| spearman_dual \| degree_norm — value_b | NA | NA | no |
| H-T vs R-W \| mann_whitney \| harmonic — statistic | 6455 | 6455 | no |
| H-T vs R-W \| mann_whitney \| harmonic — p_value | 0 | 0 | no |
| H-T vs R-W \| mann_whitney \| harmonic — value_a | 0.71429 | 0.71429 | no |
| H-T vs R-W \| mann_whitney \| harmonic — value_b | 0.25472 | 0.25555 | sì |
| H-T vs R-W \| wilcoxon_paired_dual \| harmonic — statistic | 1081 | 1081 | no |
| H-T vs R-W \| wilcoxon_paired_dual \| harmonic — p_value | 3.6319e-09 | 3.629e-09 | sì |
| H-T vs R-W \| wilcoxon_paired_dual \| harmonic — value_a | 0.7131 | 0.7131 | no |
| H-T vs R-W \| wilcoxon_paired_dual \| harmonic — value_b | 0.26526 | 0.26615 | sì |
| H-T vs R-W \| spearman_dual \| harmonic — statistic | 0.66464 | 0.65533 | sì |
| H-T vs R-W \| spearman_dual \| harmonic — p_value | 4.724e-07 | 7.7244e-07 | sì |
| H-T vs R-W \| spearman_dual \| harmonic — value_a | NA | NA | no |
| H-T vs R-W \| spearman_dual \| harmonic — value_b | NA | NA | no |
| H-T vs R-W \| mann_whitney \| betweenness_norm — statistic | 3495 | 3505 | sì |
| H-T vs R-W \| mann_whitney \| betweenness_norm — p_value | 0.60114 | 0.57825 | sì |
| H-T vs R-W \| mann_whitney \| betweenness_norm — value_a | 0.0037715 | 0.0037276 | sì |
| H-T vs R-W \| mann_whitney \| betweenness_norm — value_b | 0.0033361 | 0.0034703 | sì |
| H-T vs R-W \| wilcoxon_paired_dual \| betweenness_norm — statistic | 477 | 460 | sì |
| H-T vs R-W \| wilcoxon_paired_dual \| betweenness_norm — p_value | 0.22734 | 0.33206 | sì |
| H-T vs R-W \| wilcoxon_paired_dual \| betweenness_norm — value_a | 0.0048999 | 0.0048532 | sì |
| H-T vs R-W \| wilcoxon_paired_dual \| betweenness_norm — value_b | 0.0033361 | 0.0034703 | sì |
| H-T vs R-W \| spearman_dual \| betweenness_norm — statistic | 0.36027 | 0.38462 | sì |
| H-T vs R-W \| spearman_dual \| betweenness_norm — p_value | 0.013917 | 0.00831 | sì |
| H-T vs R-W \| spearman_dual \| betweenness_norm — value_a | NA | NA | no |
| H-T vs R-W \| spearman_dual \| betweenness_norm — value_b | NA | NA | no |
| H-T vs R-W \| concentration_difference \| top1_share — statistic | -0.099469 | -0.1115 | sì |
| H-T vs R-W \| concentration_difference \| top1_share — p_value | NA | NA | no |
| H-T vs R-W \| concentration_difference \| top1_share — value_a | 0.19136 | 0.19148 | sì |
| H-T vs R-W \| concentration_difference \| top1_share — value_b | 0.091889 | 0.079981 | sì |
| H-T vs R-W \| concentration_difference \| gini — statistic | 0.073629 | 0.066411 | sì |
| H-T vs R-W \| concentration_difference \| gini — p_value | NA | NA | no |
| H-T vs R-W \| concentration_difference \| gini — value_a | 0.67691 | 0.6764 | sì |
| H-T vs R-W \| concentration_difference \| gini — value_b | 0.75054 | 0.74281 | sì |
| H-T vs R-W \| concentration_difference \| freeman_centralization — statistic | -0.015512 | -0.032216 | sì |
| H-T vs R-W \| concentration_difference \| freeman_centralization — p_value | NA | NA | no |
| H-T vs R-W \| concentration_difference \| freeman_centralization — value_a | 0.12062 | 0.12062 | sì |
| H-T vs R-W \| concentration_difference \| freeman_centralization — value_b | 0.1051 | 0.088405 | sì |
| H-T vs R-W \| concentration_difference \| top5_share — statistic | -0.0076816 | -0.019454 | sì |
| H-T vs R-W \| concentration_difference \| top5_share — p_value | NA | NA | no |
| H-T vs R-W \| concentration_difference \| top5_share — value_a | 0.35393 | 0.35334 | sì |
| H-T vs R-W \| concentration_difference \| top5_share — value_b | 0.34625 | 0.33388 | sì |
| H-T vs R-W \| concentration_difference \| ratio_1st_2nd — statistic | -2.9349 | -3.1465 | sì |
| H-T vs R-W \| concentration_difference \| ratio_1st_2nd — p_value | NA | NA | no |
| H-T vs R-W \| concentration_difference \| ratio_1st_2nd — value_a | 4.2524 | 4.2525 | sì |
| H-T vs R-W \| concentration_difference \| ratio_1st_2nd — value_b | 1.3175 | 1.1059 | sì |
| H-T vs R-W \| upland_rank_change \| DUR032 — statistic | 63 | 63 | no |
| H-T vs R-W \| upland_rank_change \| DUR032 — p_value | NA | NA | no |
| H-T vs R-W \| upland_rank_change \| DUR032 — value_a | 2 | 2 | no |
| H-T vs R-W \| upland_rank_change \| DUR032 — value_b | 65 | 65 | no |
| H-T vs R-W \| upland_rank_change \| DUR053 — statistic | 28 | 27 | sì |
| H-T vs R-W \| upland_rank_change \| DUR053 — p_value | NA | NA | no |
| H-T vs R-W \| upland_rank_change \| DUR053 — value_a | 37 | 38 | sì |
| H-T vs R-W \| upland_rank_change \| DUR053 — value_b | 65 | 65 | no |
| H-T vs R-W \| upland_rank_change \| DUR015 — statistic | 18 | 18 | no |
| H-T vs R-W \| upland_rank_change \| DUR015 — p_value | NA | NA | no |
| H-T vs R-W \| upland_rank_change \| DUR015 — value_a | 44 | 44 | no |
| H-T vs R-W \| upland_rank_change \| DUR015 — value_b | 62 | 62 | no |
| H-T vs R-W \| upland_rank_change \| DUR025 — statistic | 5 | 5 | no |
| H-T vs R-W \| upland_rank_change \| DUR025 — p_value | NA | NA | no |
| H-T vs R-W \| upland_rank_change \| DUR025 — value_a | 60 | 60 | no |
| H-T vs R-W \| upland_rank_change \| DUR025 — value_b | 65 | 65 | no |
| H-T vs R-W \| upland_rank_change \| DUR003 — statistic | NA | NA | no |
| H-T vs R-W \| upland_rank_change \| DUR003 — p_value | NA | NA | no |
| H-T vs R-W \| upland_rank_change \| DUR003 — value_a | 1 | 1 | no |
| H-T vs R-W \| upland_rank_change \| DUR003 — value_b | NA | NA | no |
| H-T vs H-W \| spearman_same_sites \| degree_norm — statistic | 0.55031 | 0.54803 | sì |
| H-T vs H-W \| spearman_same_sites \| degree_norm — p_value | 6.6394e-07 | 7.5451e-07 | sì |
| H-T vs H-W \| spearman_same_sites \| degree_norm — value_a | NA | NA | no |
| H-T vs H-W \| spearman_same_sites \| degree_norm — value_b | NA | NA | no |
| H-T vs H-W \| spearman_same_sites \| harmonic — statistic | 0.66739 | 0.66447 | sì |
| H-T vs H-W \| spearman_same_sites \| harmonic — p_value | 0 | 0 | no |
| H-T vs H-W \| spearman_same_sites \| harmonic — value_a | NA | NA | no |
| H-T vs H-W \| spearman_same_sites \| harmonic — value_b | NA | NA | no |
| H-T vs H-W \| spearman_same_sites \| betweenness_norm — statistic | 0.021124 | 0.022092 | sì |
| H-T vs H-W \| spearman_same_sites \| betweenness_norm — p_value | 0.86119 | 0.8549 | sì |
| H-T vs H-W \| spearman_same_sites \| betweenness_norm — value_a | NA | NA | no |
| H-T vs H-W \| spearman_same_sites \| betweenness_norm — value_b | NA | NA | no |
| H-T vs H-W \| top10_betweenness_overlap \| betweenness_norm — statistic | 3 | 3 | no |
| H-T vs H-W \| top10_betweenness_overlap \| betweenness_norm — p_value | NA | NA | no |
| H-T vs H-W \| top10_betweenness_overlap \| betweenness_norm — value_a | NA | NA | no |
| H-T vs H-W \| top10_betweenness_overlap \| betweenness_norm — value_b | NA | NA | no |
| H-T vs H-W \| concentration_difference \| top1_share — statistic | 0.10192 | 0.10181 | sì |
| H-T vs H-W \| concentration_difference \| top1_share — p_value | NA | NA | no |
| H-T vs H-W \| concentration_difference \| top1_share — value_a | 0.19136 | 0.19148 | sì |
| H-T vs H-W \| concentration_difference \| top1_share — value_b | 0.29328 | 0.29328 | no |
| H-T vs H-W \| concentration_difference \| gini — statistic | 0.24045 | 0.24097 | sì |
| H-T vs H-W \| concentration_difference \| gini — p_value | NA | NA | no |
| H-T vs H-W \| concentration_difference \| gini — value_a | 0.67691 | 0.6764 | sì |
| H-T vs H-W \| concentration_difference \| gini — value_b | 0.91736 | 0.91736 | no |
| H-T vs H-W \| concentration_difference \| freeman_centralization — statistic | -0.0035882 | -0.0035941 | sì |
| H-T vs H-W \| concentration_difference \| freeman_centralization — p_value | NA | NA | no |
| H-T vs H-W \| concentration_difference \| freeman_centralization — value_a | 0.12062 | 0.12062 | sì |
| H-T vs H-W \| concentration_difference \| freeman_centralization — value_b | 0.11703 | 0.11703 | no |
| H-T vs H-W \| concentration_difference \| top5_share — statistic | 0.44466 | 0.44526 | sì |
| H-T vs H-W \| concentration_difference \| top5_share — p_value | NA | NA | no |
| H-T vs H-W \| concentration_difference \| top5_share — value_a | 0.35393 | 0.35334 | sì |
| H-T vs H-W \| concentration_difference \| top5_share — value_b | 0.7986 | 0.7986 | no |
| H-T vs H-W \| concentration_difference \| ratio_1st_2nd — statistic | -2.4527 | -2.4528 | sì |
| H-T vs H-W \| concentration_difference \| ratio_1st_2nd — p_value | NA | NA | no |
| H-T vs H-W \| concentration_difference \| ratio_1st_2nd — value_a | 4.2524 | 4.2525 | sì |
| H-T vs H-W \| concentration_difference \| ratio_1st_2nd — value_b | 1.7997 | 1.7997 | no |
| H-T vs H-W \| upland_rank_change \| DUR032 — statistic | 38 | 38 | no |
| H-T vs H-W \| upland_rank_change \| DUR032 — p_value | NA | NA | no |
| H-T vs H-W \| upland_rank_change \| DUR032 — value_a | 2 | 2 | no |
| H-T vs H-W \| upland_rank_change \| DUR032 — value_b | 40 | 40 | no |
| H-T vs H-W \| upland_rank_change \| DUR053 — statistic | 3 | 2 | sì |
| H-T vs H-W \| upland_rank_change \| DUR053 — p_value | NA | NA | no |
| H-T vs H-W \| upland_rank_change \| DUR053 — value_a | 37 | 38 | sì |
| H-T vs H-W \| upland_rank_change \| DUR053 — value_b | 40 | 40 | no |
| H-T vs H-W \| upland_rank_change \| DUR015 — statistic | -4 | -4 | no |
| H-T vs H-W \| upland_rank_change \| DUR015 — p_value | NA | NA | no |
| H-T vs H-W \| upland_rank_change \| DUR015 — value_a | 44 | 44 | no |
| H-T vs H-W \| upland_rank_change \| DUR015 — value_b | 40 | 40 | no |
| H-T vs H-W \| upland_rank_change \| DUR025 — statistic | -20 | -20 | no |
| H-T vs H-W \| upland_rank_change \| DUR025 — p_value | NA | NA | no |
| H-T vs H-W \| upland_rank_change \| DUR025 — value_a | 60 | 60 | no |
| H-T vs H-W \| upland_rank_change \| DUR025 — value_b | 40 | 40 | no |
| H-T vs H-W \| upland_rank_change \| DUR003 — statistic | 39 | 39 | no |
| H-T vs H-W \| upland_rank_change \| DUR003 — p_value | NA | NA | no |
| H-T vs H-W \| upland_rank_change \| DUR003 — value_a | 1 | 1 | no |
| H-T vs H-W \| upland_rank_change \| DUR003 — value_b | 40 | 40 | no |
| R-T vs R-W \| spearman_same_sites \| degree_norm — statistic | 0.80596 | 0.79931 | sì |
| R-T vs R-W \| spearman_same_sites \| degree_norm — p_value | 0 | 0 | no |
| R-T vs R-W \| spearman_same_sites \| degree_norm — value_a | NA | NA | no |
| R-T vs R-W \| spearman_same_sites \| degree_norm — value_b | NA | NA | no |
| R-T vs R-W \| spearman_same_sites \| harmonic — statistic | 0.84229 | 0.83756 | sì |
| R-T vs R-W \| spearman_same_sites \| harmonic — p_value | 0 | 0 | no |
| R-T vs R-W \| spearman_same_sites \| harmonic — value_a | NA | NA | no |
| R-T vs R-W \| spearman_same_sites \| harmonic — value_b | NA | NA | no |
| R-T vs R-W \| spearman_same_sites \| betweenness_norm — statistic | 0.28195 | 0.26108 | sì |
| R-T vs R-W \| spearman_same_sites \| betweenness_norm — p_value | 0.0059021 | 0.011033 | sì |
| R-T vs R-W \| spearman_same_sites \| betweenness_norm — value_a | NA | NA | no |
| R-T vs R-W \| spearman_same_sites \| betweenness_norm — value_b | NA | NA | no |
| R-T vs R-W \| top10_betweenness_overlap \| betweenness_norm — statistic | 0 | 1 | sì |
| R-T vs R-W \| top10_betweenness_overlap \| betweenness_norm — p_value | NA | NA | no |
| R-T vs R-W \| top10_betweenness_overlap \| betweenness_norm — value_a | NA | NA | no |
| R-T vs R-W \| top10_betweenness_overlap \| betweenness_norm — value_b | NA | NA | no |
| R-T vs R-W \| concentration_difference \| top1_share — statistic | 0.050204 | 0.03694 | sì |
| R-T vs R-W \| concentration_difference \| top1_share — p_value | NA | NA | no |
| R-T vs R-W \| concentration_difference \| top1_share — value_a | 0.041685 | 0.043041 | sì |
| R-T vs R-W \| concentration_difference \| top1_share — value_b | 0.091889 | 0.079981 | sì |
| R-T vs R-W \| concentration_difference \| gini — statistic | 0.23675 | 0.2321 | sì |
| R-T vs R-W \| concentration_difference \| gini — p_value | NA | NA | no |
| R-T vs R-W \| concentration_difference \| gini — value_a | 0.5138 | 0.51071 | sì |
| R-T vs R-W \| concentration_difference \| gini — value_b | 0.75054 | 0.74281 | sì |
| R-T vs R-W \| concentration_difference \| freeman_centralization — statistic | 0.072373 | 0.052553 | sì |
| R-T vs R-W \| concentration_difference \| freeman_centralization — p_value | NA | NA | no |
| R-T vs R-W \| concentration_difference \| freeman_centralization — value_a | 0.03273 | 0.035852 | sì |
| R-T vs R-W \| concentration_difference \| freeman_centralization — value_b | 0.1051 | 0.088405 | sì |
| R-T vs R-W \| concentration_difference \| top5_share — statistic | 0.15611 | 0.14914 | sì |
| R-T vs R-W \| concentration_difference \| top5_share — p_value | NA | NA | no |
| R-T vs R-W \| concentration_difference \| top5_share — value_a | 0.19014 | 0.18474 | sì |
| R-T vs R-W \| concentration_difference \| top5_share — value_b | 0.34625 | 0.33388 | sì |
| R-T vs R-W \| concentration_difference \| ratio_1st_2nd — statistic | 0.31139 | 0.024452 | sì |
| R-T vs R-W \| concentration_difference \| ratio_1st_2nd — p_value | NA | NA | no |
| R-T vs R-W \| concentration_difference \| ratio_1st_2nd — value_a | 1.0062 | 1.0815 | sì |
| R-T vs R-W \| concentration_difference \| ratio_1st_2nd — value_b | 1.3175 | 1.1059 | sì |
| R-T vs R-W \| upland_rank_change \| DUR032 — statistic | 61 | 61 | no |
| R-T vs R-W \| upland_rank_change \| DUR032 — p_value | NA | NA | no |
| R-T vs R-W \| upland_rank_change \| DUR032 — value_a | 4 | 4 | no |
| R-T vs R-W \| upland_rank_change \| DUR032 — value_b | 65 | 65 | no |
| R-T vs R-W \| upland_rank_change \| DUR053 — statistic | 24 | 24 | no |
| R-T vs R-W \| upland_rank_change \| DUR053 — p_value | NA | NA | no |
| R-T vs R-W \| upland_rank_change \| DUR053 — value_a | 41 | 41 | no |
| R-T vs R-W \| upland_rank_change \| DUR053 — value_b | 65 | 65 | no |
| R-T vs R-W \| upland_rank_change \| DUR015 — statistic | -11 | -11 | no |
| R-T vs R-W \| upland_rank_change \| DUR015 — p_value | NA | NA | no |
| R-T vs R-W \| upland_rank_change \| DUR015 — value_a | 73 | 73 | no |
| R-T vs R-W \| upland_rank_change \| DUR015 — value_b | 62 | 62 | no |
| R-T vs R-W \| upland_rank_change \| DUR025 — statistic | -9 | -9 | no |
| R-T vs R-W \| upland_rank_change \| DUR025 — p_value | NA | NA | no |
| R-T vs R-W \| upland_rank_change \| DUR025 — value_a | 74 | 74 | no |
| R-T vs R-W \| upland_rank_change \| DUR025 — value_b | 65 | 65 | no |
| R-T vs R-W \| upland_rank_change \| DUR003 — statistic | NA | NA | no |
| R-T vs R-W \| upland_rank_change \| DUR003 — p_value | NA | NA | no |
| R-T vs R-W \| upland_rank_change \| DUR003 — value_a | NA | NA | no |
| R-T vs R-W \| upland_rank_change \| DUR003 — value_b | NA | NA | no |

## Sensibilità idrografica: layer OSM vs layer poligonale

Gli output di `12` cambiano per costruzione (layer idrografico nuovo, oltre alle superfici rigenerate): non sono valori inattesi. "precedente" = Task 9, linee OSM con buffer di 25 m (42.825 celle); "nuovo" = poligoni di `data/river polygon.gpkg` (vedi `hydro_source.md`).

### Sensibilità idrografica: layer OSM vs layer poligonale — hydro_sensitivity.csv

144 valori, 80 variati.

| quantità | precedente | nuovo | variato |
|---|---|---|---|
| H-T \| 1 — n_edges | 1084 | 1085 | sì |
| H-T \| 1 — edges_lost_vs_base | 0 | 0 | no |
| H-T \| 1 — n_isolates | 0 | 0 | no |
| H-T \| 1 — isolates |  |  | no |
| H-T \| 1 — n_components | 2 | 2 | no |
| H-T \| 1 — giant_pct | 95.775 | 95.775 | no |
| H-T \| 1 — top1_share | 0.19136 | 0.19148 | sì |
| H-T \| 1 — gini | 0.67691 | 0.6764 | sì |
| H-T \| 1 — freeman_centralization | 0.12062 | 0.12062 | sì |
| H-T \| 1 — top_node | DUR003 | DUR003 | no |
| H-T \| 1 — top10_overlap_vs_base | 10 | 10 | no |
| H-T \| 1 — spearman_betweenness_vs_base | 1 | 1 | no |
| H-T \| 5 — n_edges | 1083 | 1083 | no |
| H-T \| 5 — edges_lost_vs_base | 1 | 2 | sì |
| H-T \| 5 — n_isolates | 0 | 0 | no |
| H-T \| 5 — isolates |  |  | no |
| H-T \| 5 — n_components | 2 | 2 | no |
| H-T \| 5 — giant_pct | 95.775 | 95.775 | no |
| H-T \| 5 — top1_share | 0.19065 | 0.19042 | sì |
| H-T \| 5 — gini | 0.67352 | 0.67308 | sì |
| H-T \| 5 — freeman_centralization | 0.12058 | 0.12057 | sì |
| H-T \| 5 — top_node | DUR003 | DUR003 | no |
| H-T \| 5 — top10_overlap_vs_base | 9 | 9 | no |
| H-T \| 5 — spearman_betweenness_vs_base | 0.99583 | 0.99541 | sì |
| H-T \| 20 — n_edges | 1079 | 1078 | sì |
| H-T \| 20 — edges_lost_vs_base | 5 | 7 | sì |
| H-T \| 20 — n_isolates | 0 | 0 | no |
| H-T \| 20 — isolates |  |  | no |
| H-T \| 20 — n_components | 2 | 2 | no |
| H-T \| 20 — giant_pct | 95.775 | 95.775 | no |
| H-T \| 20 — top1_share | 0.18409 | 0.18949 | sì |
| H-T \| 20 — gini | 0.69247 | 0.67868 | sì |
| H-T \| 20 — freeman_centralization | 0.12024 | 0.12052 | sì |
| H-T \| 20 — top_node | DUR003 | DUR003 | no |
| H-T \| 20 — top10_overlap_vs_base | 8 | 8 | no |
| H-T \| 20 — spearman_betweenness_vs_base | 0.96999 | 0.99285 | sì |
| R-W \| 1 — n_edges | 348 | 355 | sì |
| R-W \| 1 — edges_lost_vs_base | 0 | 0 | no |
| R-W \| 1 — n_isolates | 6 | 5 | sì |
| R-W \| 1 — isolates | DUR016;DUR029;DUR030;DUR052;DUR053;DUR103 | DUR016;DUR029;DUR030;DUR052;DUR053 | sì |
| R-W \| 1 — n_components | 14 | 13 | sì |
| R-W \| 1 — giant_pct | 70.213 | 70.213 | no |
| R-W \| 1 — top1_share | 0.091889 | 0.079981 | sì |
| R-W \| 1 — gini | 0.75054 | 0.74281 | sì |
| R-W \| 1 — freeman_centralization | 0.1051 | 0.088405 | sì |
| R-W \| 1 — top_node | DUR050 | DUR050 | no |
| R-W \| 1 — top10_overlap_vs_base | 10 | 10 | no |
| R-W \| 1 — spearman_betweenness_vs_base | 1 | 1 | no |
| R-W \| 5 — n_edges | 347 | 351 | sì |
| R-W \| 5 — edges_lost_vs_base | 1 | 4 | sì |
| R-W \| 5 — n_isolates | 6 | 5 | sì |
| R-W \| 5 — isolates | DUR016;DUR029;DUR030;DUR052;DUR053;DUR103 | DUR016;DUR029;DUR030;DUR052;DUR053 | sì |
| R-W \| 5 — n_components | 14 | 13 | sì |
| R-W \| 5 — giant_pct | 70.213 | 70.213 | no |
| R-W \| 5 — top1_share | 0.094542 | 0.094478 | sì |
| R-W \| 5 — gini | 0.75307 | 0.75382 | sì |
| R-W \| 5 — freeman_centralization | 0.10873 | 0.10847 | sì |
| R-W \| 5 — top_node | DUR050 | DUR050 | no |
| R-W \| 5 — top10_overlap_vs_base | 10 | 9 | sì |
| R-W \| 5 — spearman_betweenness_vs_base | 0.99485 | 0.98554 | sì |
| R-W \| 20 — n_edges | 343 | 345 | sì |
| R-W \| 20 — edges_lost_vs_base | 5 | 10 | sì |
| R-W \| 20 — n_isolates | 6 | 5 | sì |
| R-W \| 20 — isolates | DUR016;DUR029;DUR030;DUR052;DUR053;DUR103 | DUR016;DUR029;DUR030;DUR052;DUR053 | sì |
| R-W \| 20 — n_components | 14 | 13 | sì |
| R-W \| 20 — giant_pct | 70.213 | 70.213 | no |
| R-W \| 20 — top1_share | 0.096325 | 0.094776 | sì |
| R-W \| 20 — gini | 0.75743 | 0.7574 | sì |
| R-W \| 20 — freeman_centralization | 0.11256 | 0.11214 | sì |
| R-W \| 20 — top_node | DUR050 | DUR050 | no |
| R-W \| 20 — top10_overlap_vs_base | 9 | 8 | sì |
| R-W \| 20 — spearman_betweenness_vs_base | 0.98753 | 0.96198 | sì |
| H-W \| 1 — n_edges | 434 | 434 | no |
| H-W \| 1 — edges_lost_vs_base | 0 | 0 | no |
| H-W \| 1 — n_isolates | 7 | 7 | no |
| H-W \| 1 — isolates | DUR003;DUR015;DUR025;DUR032;DUR041;DUR051;DUR053 | DUR003;DUR015;DUR025;DUR032;DUR041;DUR051;DUR053 | no |
| H-W \| 1 — n_components | 13 | 13 | no |
| H-W \| 1 — giant_pct | 57.746 | 57.746 | no |
| H-W \| 1 — top1_share | 0.29328 | 0.29328 | no |
| H-W \| 1 — gini | 0.91736 | 0.91736 | no |
| H-W \| 1 — freeman_centralization | 0.11703 | 0.11703 | no |
| H-W \| 1 — top_node | DUR033 | DUR033 | no |
| H-W \| 1 — top10_overlap_vs_base | 10 | 10 | no |
| H-W \| 1 — spearman_betweenness_vs_base | 1 | 1 | no |
| H-W \| 5 — n_edges | 434 | 433 | sì |
| H-W \| 5 — edges_lost_vs_base | 0 | 1 | sì |
| H-W \| 5 — n_isolates | 7 | 7 | no |
| H-W \| 5 — isolates | DUR003;DUR015;DUR025;DUR032;DUR041;DUR051;DUR053 | DUR003;DUR015;DUR025;DUR032;DUR041;DUR051;DUR053 | no |
| H-W \| 5 — n_components | 13 | 13 | no |
| H-W \| 5 — giant_pct | 57.746 | 57.746 | no |
| H-W \| 5 — top1_share | 0.29328 | 0.34927 | sì |
| H-W \| 5 — gini | 0.91736 | 0.9214 | sì |
| H-W \| 5 — freeman_centralization | 0.11703 | 0.15021 | sì |
| H-W \| 5 — top_node | DUR033 | DUR033 | no |
| H-W \| 5 — top10_overlap_vs_base | 10 | 10 | no |
| H-W \| 5 — spearman_betweenness_vs_base | 1 | 0.99947 | sì |
| H-W \| 20 — n_edges | 432 | 432 | no |
| H-W \| 20 — edges_lost_vs_base | 2 | 2 | no |
| H-W \| 20 — n_isolates | 7 | 7 | no |
| H-W \| 20 — isolates | DUR003;DUR015;DUR025;DUR032;DUR041;DUR051;DUR053 | DUR003;DUR015;DUR025;DUR032;DUR041;DUR051;DUR053 | no |
| H-W \| 20 — n_components | 13 | 13 | no |
| H-W \| 20 — giant_pct | 57.746 | 57.746 | no |
| H-W \| 20 — top1_share | 0.33425 | 0.33425 | no |
| H-W \| 20 — gini | 0.91947 | 0.91947 | no |
| H-W \| 20 — freeman_centralization | 0.14724 | 0.14724 | no |
| H-W \| 20 — top_node | DUR033 | DUR033 | no |
| H-W \| 20 — top10_overlap_vs_base | 9 | 9 | no |
| H-W \| 20 — spearman_betweenness_vs_base | 0.95425 | 0.95425 | no |
| R-T \| 1 — n_edges | 1550 | 1553 | sì |
| R-T \| 1 — edges_lost_vs_base | 0 | 0 | no |
| R-T \| 1 — n_isolates | 1 | 0 | sì |
| R-T \| 1 — isolates | DUR103 |  | sì |
| R-T \| 1 — n_components | 2 | 1 | sì |
| R-T \| 1 — giant_pct | 98.936 | 100 | sì |
| R-T \| 1 — top1_share | 0.041685 | 0.043041 | sì |
| R-T \| 1 — gini | 0.5138 | 0.51071 | sì |
| R-T \| 1 — freeman_centralization | 0.03273 | 0.035852 | sì |
| R-T \| 1 — top_node | DUR138 | DUR138 | no |
| R-T \| 1 — top10_overlap_vs_base | 10 | 10 | no |
| R-T \| 1 — spearman_betweenness_vs_base | 1 | 1 | no |
| R-T \| 5 — n_edges | 1548 | 1539 | sì |
| R-T \| 5 — edges_lost_vs_base | 2 | 14 | sì |
| R-T \| 5 — n_isolates | 1 | 0 | sì |
| R-T \| 5 — isolates | DUR103 |  | sì |
| R-T \| 5 — n_components | 2 | 1 | sì |
| R-T \| 5 — giant_pct | 98.936 | 100 | sì |
| R-T \| 5 — top1_share | 0.0413 | 0.040487 | sì |
| R-T \| 5 — gini | 0.51487 | 0.50651 | sì |
| R-T \| 5 — freeman_centralization | 0.032419 | 0.033407 | sì |
| R-T \| 5 — top_node | DUR141 | DUR027 | sì |
| R-T \| 5 — top10_overlap_vs_base | 8 | 9 | sì |
| R-T \| 5 — spearman_betweenness_vs_base | 0.9973 | 0.98671 | sì |
| R-T \| 20 — n_edges | 1531 | 1526 | sì |
| R-T \| 20 — edges_lost_vs_base | 19 | 27 | sì |
| R-T \| 20 — n_isolates | 1 | 0 | sì |
| R-T \| 20 — isolates | DUR103 |  | sì |
| R-T \| 20 — n_components | 2 | 1 | sì |
| R-T \| 20 — giant_pct | 98.936 | 100 | sì |
| R-T \| 20 — top1_share | 0.040477 | 0.040129 | sì |
| R-T \| 20 — gini | 0.50556 | 0.50474 | sì |
| R-T \| 20 — freeman_centralization | 0.032183 | 0.033284 | sì |
| R-T \| 20 — top_node | DUR141 | DUR027 | sì |
| R-T \| 20 — top10_overlap_vs_base | 8 | 9 | sì |
| R-T \| 20 — spearman_betweenness_vs_base | 0.97054 | 0.9782 | sì |

### Sensibilità idrografica: layer OSM vs layer poligonale — hydro_upland_centres.csv

240 valori, 39 variati.

| quantità | precedente | nuovo | variato |
|---|---|---|---|
| H-T \| 1 \| DUR032 — degree | 12 | 12 | no |
| H-T \| 1 \| DUR032 — betweenness_norm | 0.030186 | 0.030186 | sì |
| H-T \| 1 \| DUR032 — rank_betweenness | 2 | 2 | no |
| H-T \| 1 \| DUR032 — in_giant | TRUE | TRUE | no |
| H-T \| 1 \| DUR053 — degree | 19 | 19 | no |
| H-T \| 1 \| DUR053 — betweenness_norm | 0.0031344 | 0.0031341 | sì |
| H-T \| 1 \| DUR053 — rank_betweenness | 37 | 38 | sì |
| H-T \| 1 \| DUR053 — in_giant | TRUE | TRUE | no |
| H-T \| 1 \| DUR015 — degree | 5 | 5 | no |
| H-T \| 1 \| DUR015 — betweenness_norm | 0.0016809 | 0.0016809 | no |
| H-T \| 1 \| DUR015 — rank_betweenness | 44 | 44 | no |
| H-T \| 1 \| DUR015 — in_giant | TRUE | TRUE | no |
| H-T \| 1 \| DUR025 — degree | 2 | 2 | no |
| H-T \| 1 \| DUR025 — betweenness_norm | 0 | 0 | no |
| H-T \| 1 \| DUR025 — rank_betweenness | 60 | 60 | no |
| H-T \| 1 \| DUR025 — in_giant | FALSE | FALSE | no |
| H-T \| 1 \| DUR003 — degree | 37 | 37 | no |
| H-T \| 1 \| DUR003 — betweenness_norm | 0.12836 | 0.12836 | no |
| H-T \| 1 \| DUR003 — rank_betweenness | 1 | 1 | no |
| H-T \| 1 \| DUR003 — in_giant | TRUE | TRUE | no |
| H-T \| 5 \| DUR032 — degree | 12 | 12 | no |
| H-T \| 5 \| DUR032 — betweenness_norm | 0.03006 | 0.030062 | sì |
| H-T \| 5 \| DUR032 — rank_betweenness | 2 | 2 | no |
| H-T \| 5 \| DUR032 — in_giant | TRUE | TRUE | no |
| H-T \| 5 \| DUR053 — degree | 19 | 19 | no |
| H-T \| 5 \| DUR053 — betweenness_norm | 0.0031344 | 0.0032403 | sì |
| H-T \| 5 \| DUR053 — rank_betweenness | 42 | 42 | no |
| H-T \| 5 \| DUR053 — in_giant | TRUE | TRUE | no |
| H-T \| 5 \| DUR015 — degree | 5 | 5 | no |
| H-T \| 5 \| DUR015 — betweenness_norm | 0.0017361 | 0.0017361 | no |
| H-T \| 5 \| DUR015 — rank_betweenness | 44 | 44 | no |
| H-T \| 5 \| DUR015 — in_giant | TRUE | TRUE | no |
| H-T \| 5 \| DUR025 — degree | 2 | 2 | no |
| H-T \| 5 \| DUR025 — betweenness_norm | 0 | 0 | no |
| H-T \| 5 \| DUR025 — rank_betweenness | 60 | 60 | no |
| H-T \| 5 \| DUR025 — in_giant | FALSE | FALSE | no |
| H-T \| 5 \| DUR003 — degree | 36 | 36 | no |
| H-T \| 5 \| DUR003 — betweenness_norm | 0.12836 | 0.12836 | no |
| H-T \| 5 \| DUR003 — rank_betweenness | 1 | 1 | no |
| H-T \| 5 \| DUR003 — in_giant | TRUE | TRUE | no |
| H-T \| 20 \| DUR032 — degree | 11 | 12 | sì |
| H-T \| 20 \| DUR032 — betweenness_norm | 0.019147 | 0.040129 | sì |
| H-T \| 20 \| DUR032 — rank_betweenness | 15 | 2 | sì |
| H-T \| 20 \| DUR032 — in_giant | TRUE | TRUE | no |
| H-T \| 20 \| DUR053 — degree | 19 | 19 | no |
| H-T \| 20 \| DUR053 — betweenness_norm | 0.0023682 | 0.0033503 | sì |
| H-T \| 20 \| DUR053 — rank_betweenness | 42 | 38 | sì |
| H-T \| 20 \| DUR053 — in_giant | TRUE | TRUE | no |
| H-T \| 20 \| DUR015 — degree | 3 | 5 | sì |
| H-T \| 20 \| DUR015 — betweenness_norm | 0 | 0.001894 | sì |
| H-T \| 20 \| DUR015 — rank_betweenness | 60 | 44 | sì |
| H-T \| 20 \| DUR015 — in_giant | TRUE | TRUE | no |
| H-T \| 20 \| DUR025 — degree | 2 | 2 | no |
| H-T \| 20 \| DUR025 — betweenness_norm | 0 | 0 | no |
| H-T \| 20 \| DUR025 — rank_betweenness | 60 | 62 | sì |
| H-T \| 20 \| DUR025 — in_giant | FALSE | FALSE | no |
| H-T \| 20 \| DUR003 — degree | 36 | 36 | no |
| H-T \| 20 \| DUR003 — betweenness_norm | 0.12836 | 0.12836 | no |
| H-T \| 20 \| DUR003 — rank_betweenness | 1 | 1 | no |
| H-T \| 20 \| DUR003 — in_giant | TRUE | TRUE | no |
| R-W \| 1 \| DUR032 — degree | 1 | 1 | no |
| R-W \| 1 \| DUR032 — betweenness_norm | 0 | 0 | no |
| R-W \| 1 \| DUR032 — rank_betweenness | 65 | 65 | no |
| R-W \| 1 \| DUR032 — in_giant | FALSE | FALSE | no |
| R-W \| 1 \| DUR053 — degree | 0 | 0 | no |
| R-W \| 1 \| DUR053 — betweenness_norm | 0 | 0 | no |
| R-W \| 1 \| DUR053 — rank_betweenness | 65 | 65 | no |
| R-W \| 1 \| DUR053 — in_giant | FALSE | FALSE | no |
| R-W \| 1 \| DUR015 — degree | 2 | 2 | no |
| R-W \| 1 \| DUR015 — betweenness_norm | 0.00023375 | 0.00023375 | no |
| R-W \| 1 \| DUR015 — rank_betweenness | 62 | 62 | no |
| R-W \| 1 \| DUR015 — in_giant | FALSE | FALSE | no |
| R-W \| 1 \| DUR025 — degree | 1 | 1 | no |
| R-W \| 1 \| DUR025 — betweenness_norm | 0 | 0 | no |
| R-W \| 1 \| DUR025 — rank_betweenness | 65 | 65 | no |
| R-W \| 1 \| DUR025 — in_giant | FALSE | FALSE | no |
| R-W \| 1 \| DUR003 — degree | NA | NA | no |
| R-W \| 1 \| DUR003 — betweenness_norm | NA | NA | no |
| R-W \| 1 \| DUR003 — rank_betweenness | NA | NA | no |
| R-W \| 1 \| DUR003 — in_giant | NA | NA | no |
| R-W \| 5 \| DUR032 — degree | 1 | 1 | no |
| R-W \| 5 \| DUR032 — betweenness_norm | 0 | 0 | no |
| R-W \| 5 \| DUR032 — rank_betweenness | 64 | 64 | no |
| R-W \| 5 \| DUR032 — in_giant | FALSE | FALSE | no |
| R-W \| 5 \| DUR053 — degree | 0 | 0 | no |
| R-W \| 5 \| DUR053 — betweenness_norm | 0 | 0 | no |
| R-W \| 5 \| DUR053 — rank_betweenness | 64 | 64 | no |
| R-W \| 5 \| DUR053 — in_giant | FALSE | FALSE | no |
| R-W \| 5 \| DUR015 — degree | 2 | 2 | no |
| R-W \| 5 \| DUR015 — betweenness_norm | 0.00023375 | 0.00023375 | no |
| R-W \| 5 \| DUR015 — rank_betweenness | 61 | 61 | no |
| R-W \| 5 \| DUR015 — in_giant | FALSE | FALSE | no |
| R-W \| 5 \| DUR025 — degree | 1 | 1 | no |
| R-W \| 5 \| DUR025 — betweenness_norm | 0 | 0 | no |
| R-W \| 5 \| DUR025 — rank_betweenness | 64 | 64 | no |
| R-W \| 5 \| DUR025 — in_giant | FALSE | FALSE | no |
| R-W \| 5 \| DUR003 — degree | NA | NA | no |
| R-W \| 5 \| DUR003 — betweenness_norm | NA | NA | no |
| R-W \| 5 \| DUR003 — rank_betweenness | NA | NA | no |
| R-W \| 5 \| DUR003 — in_giant | NA | NA | no |
| R-W \| 20 \| DUR032 — degree | 1 | 1 | no |
| R-W \| 20 \| DUR032 — betweenness_norm | 0 | 0 | no |
| R-W \| 20 \| DUR032 — rank_betweenness | 63 | 64 | sì |
| R-W \| 20 \| DUR032 — in_giant | FALSE | FALSE | no |
| R-W \| 20 \| DUR053 — degree | 0 | 0 | no |
| R-W \| 20 \| DUR053 — betweenness_norm | 0 | 0 | no |
| R-W \| 20 \| DUR053 — rank_betweenness | 63 | 64 | sì |
| R-W \| 20 \| DUR053 — in_giant | FALSE | FALSE | no |
| R-W \| 20 \| DUR015 — degree | 2 | 2 | no |
| R-W \| 20 \| DUR015 — betweenness_norm | 0.00023375 | 0.00023375 | no |
| R-W \| 20 \| DUR015 — rank_betweenness | 60 | 60 | no |
| R-W \| 20 \| DUR015 — in_giant | FALSE | FALSE | no |
| R-W \| 20 \| DUR025 — degree | 1 | 1 | no |
| R-W \| 20 \| DUR025 — betweenness_norm | 0 | 0 | no |
| R-W \| 20 \| DUR025 — rank_betweenness | 63 | 64 | sì |
| R-W \| 20 \| DUR025 — in_giant | FALSE | FALSE | no |
| R-W \| 20 \| DUR003 — degree | NA | NA | no |
| R-W \| 20 \| DUR003 — betweenness_norm | NA | NA | no |
| R-W \| 20 \| DUR003 — rank_betweenness | NA | NA | no |
| R-W \| 20 \| DUR003 — in_giant | NA | NA | no |
| H-W \| 1 \| DUR032 — degree | 0 | 0 | no |
| H-W \| 1 \| DUR032 — betweenness_norm | 0 | 0 | no |
| H-W \| 1 \| DUR032 — rank_betweenness | 40 | 40 | no |
| H-W \| 1 \| DUR032 — in_giant | FALSE | FALSE | no |
| H-W \| 1 \| DUR053 — degree | 0 | 0 | no |
| H-W \| 1 \| DUR053 — betweenness_norm | 0 | 0 | no |
| H-W \| 1 \| DUR053 — rank_betweenness | 40 | 40 | no |
| H-W \| 1 \| DUR053 — in_giant | FALSE | FALSE | no |
| H-W \| 1 \| DUR015 — degree | 0 | 0 | no |
| H-W \| 1 \| DUR015 — betweenness_norm | 0 | 0 | no |
| H-W \| 1 \| DUR015 — rank_betweenness | 40 | 40 | no |
| H-W \| 1 \| DUR015 — in_giant | FALSE | FALSE | no |
| H-W \| 1 \| DUR025 — degree | 0 | 0 | no |
| H-W \| 1 \| DUR025 — betweenness_norm | 0 | 0 | no |
| H-W \| 1 \| DUR025 — rank_betweenness | 40 | 40 | no |
| H-W \| 1 \| DUR025 — in_giant | FALSE | FALSE | no |
| H-W \| 1 \| DUR003 — degree | 0 | 0 | no |
| H-W \| 1 \| DUR003 — betweenness_norm | 0 | 0 | no |
| H-W \| 1 \| DUR003 — rank_betweenness | 40 | 40 | no |
| H-W \| 1 \| DUR003 — in_giant | FALSE | FALSE | no |
| H-W \| 5 \| DUR032 — degree | 0 | 0 | no |
| H-W \| 5 \| DUR032 — betweenness_norm | 0 | 0 | no |
| H-W \| 5 \| DUR032 — rank_betweenness | 40 | 40 | no |
| H-W \| 5 \| DUR032 — in_giant | FALSE | FALSE | no |
| H-W \| 5 \| DUR053 — degree | 0 | 0 | no |
| H-W \| 5 \| DUR053 — betweenness_norm | 0 | 0 | no |
| H-W \| 5 \| DUR053 — rank_betweenness | 40 | 40 | no |
| H-W \| 5 \| DUR053 — in_giant | FALSE | FALSE | no |
| H-W \| 5 \| DUR015 — degree | 0 | 0 | no |
| H-W \| 5 \| DUR015 — betweenness_norm | 0 | 0 | no |
| H-W \| 5 \| DUR015 — rank_betweenness | 40 | 40 | no |
| H-W \| 5 \| DUR015 — in_giant | FALSE | FALSE | no |
| H-W \| 5 \| DUR025 — degree | 0 | 0 | no |
| H-W \| 5 \| DUR025 — betweenness_norm | 0 | 0 | no |
| H-W \| 5 \| DUR025 — rank_betweenness | 40 | 40 | no |
| H-W \| 5 \| DUR025 — in_giant | FALSE | FALSE | no |
| H-W \| 5 \| DUR003 — degree | 0 | 0 | no |
| H-W \| 5 \| DUR003 — betweenness_norm | 0 | 0 | no |
| H-W \| 5 \| DUR003 — rank_betweenness | 40 | 40 | no |
| H-W \| 5 \| DUR003 — in_giant | FALSE | FALSE | no |
| H-W \| 20 \| DUR032 — degree | 0 | 0 | no |
| H-W \| 20 \| DUR032 — betweenness_norm | 0 | 0 | no |
| H-W \| 20 \| DUR032 — rank_betweenness | 39 | 39 | no |
| H-W \| 20 \| DUR032 — in_giant | FALSE | FALSE | no |
| H-W \| 20 \| DUR053 — degree | 0 | 0 | no |
| H-W \| 20 \| DUR053 — betweenness_norm | 0 | 0 | no |
| H-W \| 20 \| DUR053 — rank_betweenness | 39 | 39 | no |
| H-W \| 20 \| DUR053 — in_giant | FALSE | FALSE | no |
| H-W \| 20 \| DUR015 — degree | 0 | 0 | no |
| H-W \| 20 \| DUR015 — betweenness_norm | 0 | 0 | no |
| H-W \| 20 \| DUR015 — rank_betweenness | 39 | 39 | no |
| H-W \| 20 \| DUR015 — in_giant | FALSE | FALSE | no |
| H-W \| 20 \| DUR025 — degree | 0 | 0 | no |
| H-W \| 20 \| DUR025 — betweenness_norm | 0 | 0 | no |
| H-W \| 20 \| DUR025 — rank_betweenness | 39 | 39 | no |
| H-W \| 20 \| DUR025 — in_giant | FALSE | FALSE | no |
| H-W \| 20 \| DUR003 — degree | 0 | 0 | no |
| H-W \| 20 \| DUR003 — betweenness_norm | 0 | 0 | no |
| H-W \| 20 \| DUR003 — rank_betweenness | 39 | 39 | no |
| H-W \| 20 \| DUR003 — in_giant | FALSE | FALSE | no |
| R-T \| 1 \| DUR032 — degree | 24 | 24 | no |
| R-T \| 1 \| DUR032 — betweenness_norm | 0.035292 | 0.034832 | sì |
| R-T \| 1 \| DUR032 — rank_betweenness | 4 | 4 | no |
| R-T \| 1 \| DUR032 — in_giant | TRUE | TRUE | no |
| R-T \| 1 \| DUR053 — degree | 38 | 38 | no |
| R-T \| 1 \| DUR053 — betweenness_norm | 0.012886 | 0.012928 | sì |
| R-T \| 1 \| DUR053 — rank_betweenness | 41 | 41 | no |
| R-T \| 1 \| DUR053 — in_giant | TRUE | TRUE | no |
| R-T \| 1 \| DUR015 — degree | 9 | 9 | no |
| R-T \| 1 \| DUR015 — betweenness_norm | 0.001946 | 0.0021179 | sì |
| R-T \| 1 \| DUR015 — rank_betweenness | 73 | 73 | no |
| R-T \| 1 \| DUR015 — in_giant | TRUE | TRUE | no |
| R-T \| 1 \| DUR025 — degree | 6 | 6 | no |
| R-T \| 1 \| DUR025 — betweenness_norm | 0.0018191 | 0.0017975 | sì |
| R-T \| 1 \| DUR025 — rank_betweenness | 74 | 74 | no |
| R-T \| 1 \| DUR025 — in_giant | TRUE | TRUE | no |
| R-T \| 1 \| DUR003 — degree | NA | NA | no |
| R-T \| 1 \| DUR003 — betweenness_norm | NA | NA | no |
| R-T \| 1 \| DUR003 — rank_betweenness | NA | NA | no |
| R-T \| 1 \| DUR003 — in_giant | NA | NA | no |
| R-T \| 5 \| DUR032 — degree | 24 | 23 | sì |
| R-T \| 5 \| DUR032 — betweenness_norm | 0.035279 | 0.034323 | sì |
| R-T \| 5 \| DUR032 — rank_betweenness | 4 | 5 | sì |
| R-T \| 5 \| DUR032 — in_giant | TRUE | TRUE | no |
| R-T \| 5 \| DUR053 — degree | 38 | 38 | no |
| R-T \| 5 \| DUR053 — betweenness_norm | 0.012882 | 0.01434 | sì |
| R-T \| 5 \| DUR053 — rank_betweenness | 40 | 32 | sì |
| R-T \| 5 \| DUR053 — in_giant | TRUE | TRUE | no |
| R-T \| 5 \| DUR015 — degree | 9 | 9 | no |
| R-T \| 5 \| DUR015 — betweenness_norm | 0.0019474 | 0.0021346 | sì |
| R-T \| 5 \| DUR015 — rank_betweenness | 73 | 72 | sì |
| R-T \| 5 \| DUR015 — in_giant | TRUE | TRUE | no |
| R-T \| 5 \| DUR025 — degree | 6 | 6 | no |
| R-T \| 5 \| DUR025 — betweenness_norm | 0.0018167 | 0.0015406 | sì |
| R-T \| 5 \| DUR025 — rank_betweenness | 74 | 77 | sì |
| R-T \| 5 \| DUR025 — in_giant | TRUE | TRUE | no |
| R-T \| 5 \| DUR003 — degree | NA | NA | no |
| R-T \| 5 \| DUR003 — betweenness_norm | NA | NA | no |
| R-T \| 5 \| DUR003 — rank_betweenness | NA | NA | no |
| R-T \| 5 \| DUR003 — in_giant | NA | NA | no |
| R-T \| 20 \| DUR032 — degree | 23 | 23 | no |
| R-T \| 20 \| DUR032 — betweenness_norm | 0.030942 | 0.037048 | sì |
| R-T \| 20 \| DUR032 — rank_betweenness | 6 | 4 | sì |
| R-T \| 20 \| DUR032 — in_giant | TRUE | TRUE | no |
| R-T \| 20 \| DUR053 — degree | 38 | 38 | no |
| R-T \| 20 \| DUR053 — betweenness_norm | 0.014444 | 0.015131 | sì |
| R-T \| 20 \| DUR053 — rank_betweenness | 37 | 31 | sì |
| R-T \| 20 \| DUR053 — in_giant | TRUE | TRUE | no |
| R-T \| 20 \| DUR015 — degree | 7 | 9 | sì |
| R-T \| 20 \| DUR015 — betweenness_norm | 0.0015916 | 0.0024225 | sì |
| R-T \| 20 \| DUR015 — rank_betweenness | 73 | 72 | sì |
| R-T \| 20 \| DUR015 — in_giant | TRUE | TRUE | no |
| R-T \| 20 \| DUR025 — degree | 6 | 6 | no |
| R-T \| 20 \| DUR025 — betweenness_norm | 0.0018297 | 0.0015425 | sì |
| R-T \| 20 \| DUR025 — rank_betweenness | 71 | 78 | sì |
| R-T \| 20 \| DUR025 — in_giant | TRUE | TRUE | no |
| R-T \| 20 \| DUR003 — degree | NA | NA | no |
| R-T \| 20 \| DUR003 — betweenness_norm | NA | NA | no |
| R-T \| 20 \| DUR003 — rank_betweenness | NA | NA | no |
| R-T \| 20 \| DUR003 — in_giant | NA | NA | no |

