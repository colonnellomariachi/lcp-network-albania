# Task 10 — Sensibilità a dimensione e orizzonte tardoantico

Generato da `R/13_size_horizon_sensitivity.R` il 2026-10-05. Solo numeri, nessuna interpretazione.

## Verifica preliminare

Nessun passaggio della costruzione degli archi dipende dall'insieme dei siti (media delle due direzioni per coppia, soglia assoluta). Controllo empirico sulle coppie fra i 46 siti dual-phase: tobler — 1035 coppie, scarto massimo di costo 0 min, sottografo indotto identico: sì; wheeled — 1035 coppie, scarto massimo di costo 0 min, sottografo indotto identico: sì. Tutte le reti ristrette sono quindi sottografi indotti; nessun LCP ricalcolato.

## Rete romana con ROM_END = 300

Siti che superano il criterio dei 25 anni con la finestra -31/300: **72** (= 94 − 22). Siti dual-phase presenti anche nella rete ellenistica: 43 (su 46).

Siti esclusi: DUR002, DUR006, DUR010, DUR016, DUR020, DUR021, DUR030, DUR031, DUR034, DUR038, DUR040, DUR042, DUR045, DUR052, DUR056, DUR109, DUR112, DUR113, DUR114, DUR122, DUR135, DUR138.

| rete | nodi | archi | densità | grado mediano | isolati | componenti | gigante |
|---|---|---|---|---|---|---|---|
| H-T | 71 | 1085 | 0.437 | 37.0 | 0 | 2 | 68 (95.8 %) |
| H-W | 71 | 434 | 0.175 | 9.0 | 7 | 13 | 41 (57.7 %) |
| R-T | 94 | 1553 | 0.355 | 35.5 | 0 | 1 | 94 (100.0 %) |
| R-W | 94 | 355 | 0.081 | 8.0 | 5 | 13 | 66 (70.2 %) |
| R300-T | 72 | 881 | 0.345 | 27.0 | 0 | 1 | 72 (100.0 %) |
| R300-W | 72 | 209 | 0.082 | 6.0 | 3 | 11 | 47 (65.3 %) |

## 1. La concentrazione della betweenness resta più bassa nella rete romana di quella ellenistica, a funzione costante, quando la rete romana è ristretta a ROM_END = 300?

**Sì**.

| misura | H-T | R300-T | più bassa (T) | R-T (rif.) | H-W | R300-W | più bassa (W) | R-W (rif.) |
|---|---|---|---|---|---|---|---|---|
| quota 1° nodo | 0.191 | 0.057 | sì | 0.043 | 0.293 | 0.110 | sì | 0.080 |
| Gini | 0.676 | 0.516 | sì | 0.511 | 0.917 | 0.754 | sì | 0.743 |
| Freeman | 0.121 | 0.052 | sì | 0.036 | 0.117 | 0.101 | sì | 0.088 |

Nodo di testa: H-T DUR003, R300-T DUR027, R-T DUR138; H-W DUR033, R300-W DUR046, R-W DUR050.

Test sulle centralità per sito (Mann-Whitney su tutti i siti; Wilcoxon appaiato e Spearman sui 43 dual-phase presenti in entrambe le reti):

| metrica | confronto | mediane (tutti) | p MW | mediane (dual) | p Wilcoxon | ρ Spearman (dual) |
|---|---|---|---|---|---|---|
| degree_norm | H-T vs R300-T | 0.5286 → 0.3803 | 7e-04 | 0.3286 → 0.3944 | 0.31 | 0.784 (p=5.1e-10) |
| degree_norm | H-W vs R300-W | 0.1286 → 0.0845 | 0.0016 | 0.1000 → 0.0986 | 0.48 | 0.723 (p=4.2e-08) |
| harmonic | H-T vs R300-T | 0.7143 → 0.6458 | 0.00033 | 0.6107 → 0.6549 | 0.41 | 0.800 (p=1.2e-10) |
| harmonic | H-W vs R300-W | 0.2536 → 0.2266 | 0.063 | 0.1357 → 0.2471 | 0.13 | 0.597 (p=2.3e-05) |
| betweenness_norm | H-T vs R300-T | 0.0037 → 0.0105 | 0.00014 | 0.0043 → 0.0082 | 0.017 | 0.720 (p=5.2e-08) |
| betweenness_norm | H-W vs R300-W | 0.0001 → 0.0012 | 0.0037 | 0.0000 → 0.0016 | 0.00015 | 0.564 (p=8.3e-05) |

Centri d'altura — rank di betweenness / n (betweenness normalizzata):

| sito | H-T | R300-T | R-T | H-W | R300-W | R-W |
|---|---|---|---|---|---|---|
| DUR032 | 2/71 (0.0302) | 15/72 (0.0309) | 4/94 (0.0348) | 40/71 (0.0000) | 45/72 (0.0000) | 65/94 (0.0000) |
| DUR053 | 38/71 (0.0031) | 12/72 (0.0341) | 41/94 (0.0129) | 40/71 (0.0000) | 45/72 (0.0000) | 65/94 (0.0000) |
| DUR015 | 44/71 (0.0017) | 69/72 (0.0002) | 73/94 (0.0021) | 40/71 (0.0000) | 45/72 (0.0000) | 62/94 (0.0002) |
| DUR025 | 60/71 (0.0000) | 62/72 (0.0016) | 74/94 (0.0018) | 40/71 (0.0000) | 45/72 (0.0000) | 65/94 (0.0000) |

## 2. Il valore ellenistico cade fuori dall'intervallo 2,5–97,5 % dei sottocampioni romani di 71 siti, per ciascuna misura e ciascuna funzione?

**Parzialmente** (R-T e R-W: 7 misure su 8 fuori dall'intervallo).

999 sottoinsiemi casuali di 71 siti per rete, seed 13 (stessi sottoinsiemi per le due funzioni). Percentile = quota di sottocampioni con valore ≤ quello ellenistico.

| rete | misura | n siti | valore rete intera | mediana sottocampioni | 2,5 % – 97,5 % | valore ellenistico | percentile | fuori dall'intervallo |
|---|---|---|---|---|---|---|---|---|
| R-T | quota 1° nodo | 94 | 0.0430 | 0.0660 | 0.0469 – 0.1130 | 0.1915 (H-T) | 100.0 | sì |
| R-T | Gini | 94 | 0.5107 | 0.5266 | 0.4739 – 0.5945 | 0.6764 (H-T) | 100.0 | sì |
| R-T | Freeman | 94 | 0.0359 | 0.0606 | 0.0345 – 0.1196 | 0.1206 (H-T) | 98.3 | sì |
| R-T | betweenness mediana | 94 | 0.0097 | 0.0112 | 0.0070 – 0.0148 | 0.0037 (H-T) | 0.0 | sì |
| R-W | quota 1° nodo | 94 | 0.0800 | 0.1223 | 0.0829 – 0.1888 | 0.2933 (H-W) | 100.0 | sì |
| R-W | Gini | 94 | 0.7428 | 0.7569 | 0.7027 – 0.8269 | 0.9174 (H-W) | 100.0 | sì |
| R-W | Freeman | 94 | 0.0884 | 0.1259 | 0.0640 – 0.2256 | 0.1170 (H-W) | 41.0 | no |
| R-W | betweenness mediana | 94 | 0.0035 | 0.0022 | 0.0002 – 0.0066 | 0.0001 (H-W) | 1.9 | sì |

Stesso sottocampionamento sulle reti ristrette a ROM_END = 300. Attenzione: con 72 siti i sottoinsiemi di 71 sono al più 72 distinti (leave-one-out), quindi la distribuzione misura solo l'effetto di togliere 1 sito/i e l'intervallo è per costruzione stretto.

| rete | misura | n siti | valore rete intera | mediana sottocampioni | 2,5 % – 97,5 % | valore ellenistico | percentile | fuori dall'intervallo |
|---|---|---|---|---|---|---|---|---|
| R300-T | quota 1° nodo | 72 | 0.0565 | 0.0571 | 0.0523 – 0.0753 | 0.1915 (H-T) | 100.0 | sì |
| R300-T | Gini | 72 | 0.5158 | 0.5155 | 0.5016 – 0.5379 | 0.6764 (H-T) | 100.0 | sì |
| R300-T | Freeman | 72 | 0.0517 | 0.0522 | 0.0455 – 0.0748 | 0.1206 (H-T) | 100.0 | sì |
| R300-T | betweenness mediana | 72 | 0.0105 | 0.0108 | 0.0095 – 0.0122 | 0.0037 (H-T) | 0.0 | sì |
| R300-W | quota 1° nodo | 72 | 0.1095 | 0.1097 | 0.1026 – 0.1641 | 0.2933 (H-W) | 100.0 | sì |
| R300-W | Gini | 72 | 0.7536 | 0.7514 | 0.7473 – 0.7951 | 0.9174 (H-W) | 100.0 | sì |
| R300-W | Freeman | 72 | 0.1015 | 0.1034 | 0.0928 – 0.1669 | 0.1170 (H-W) | 89.9 | no |
| R300-W | betweenness mediana | 72 | 0.0012 | 0.0012 | 0.0004 – 0.0027 | 0.0001 (H-W) | 0.0 | sì |
