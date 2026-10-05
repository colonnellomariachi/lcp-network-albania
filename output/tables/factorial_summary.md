# Task 9 — Disegno fattoriale 2×2: lettura dei risultati

Generato da `R/11_cost_function_factorial.R` il 2026-10-05. Solo numeri, nessuna interpretazione.

## Controllo di regressione (Step 1)

H-T e R-W ricostruite dagli LCP salvati coincidono con gli oggetti di `04`/`05`: 10/10 verifiche superate (archi, grafo, centralità per sito vs `centrality_comparison.csv`, concentrazione vs `betweenness_concentration_sweep.csv`).

Coerenza degli LCP nuovi (coppie fra i 46 siti dual-phase, costo medio in minuti): H-W vs R-W (wheeled) — 1035 coppie, scarto massimo 0 min; R-T vs H-T (Tobler) — 1035 coppie, scarto massimo 0 min.

## Composizione

| cella | nodi | archi | densità | grado mediano | isolati | componenti | gigante | isolati (elenco) |
|---|---|---|---|---|---|---|---|---|
| H-T | 71 | 1085 | 0.437 | 37.0 | 0 |  2 | 68 (95.8 %) |  |
| R-W | 94 |  355 | 0.081 |  8.0 | 5 | 13 | 66 (70.2 %) | DUR016, DUR029, DUR030, DUR052, DUR053 |
| H-W | 71 |  434 | 0.175 |  9.0 | 7 | 13 | 41 (57.7 %) | DUR003, DUR015, DUR025, DUR032, DUR041, DUR051, DUR053 |
| R-T | 94 | 1553 | 0.355 | 35.5 | 0 |  1 | 94 (100.0 %) |  |

## 1. La concentrazione della betweenness diminuisce dall'ellenistico al romano in entrambi i confronti a funzione costante?

**Sì**.

| metrica | H-T | R-T | cala (T) | H-W | R-W | cala (W) |
|---|---|---|---|---|---|---|
| top-1 share | 0.191 | 0.043 | sì | 0.293 | 0.080 | sì |
| Gini | 0.676 | 0.511 | sì | 0.917 | 0.743 | sì |
| Freeman centralisation | 0.121 | 0.036 | sì | 0.117 | 0.088 | sì |

Nodo di testa: H-T DUR003, R-T DUR138, H-W DUR033, R-W DUR050.

## 2. I centri d'altura perdono posizione dall'ellenistico al romano in entrambi i confronti a funzione costante, o solo quando cambia la funzione?

Rank percentile di betweenness, ellenistico → romano a funzione costante. Tobler: 2/4 perdono (DUR032, DUR015); 0 pari a betweenness 0 (); 2 migliorano (DUR053, DUR025). Trasporto su ruota: 0/4 perdono (); 3 pari a betweenness 0 (DUR032, DUR053, DUR025); 1 migliorano (DUR015).

Rank di betweenness / n (betweenness normalizzata). Rank a pari merito = minimo del gruppo, quindi tutti i nodi a betweenness 0 condividono il primo rank del gruppo a zero; per questo i casi a 0 in entrambe le celle sono marcati "pari (0)" e, se solo una delle due è 0, decide il valore (0 → positivo = non perde). Negli altri casi decide il rank percentile.

| sito | H-T | R-T | perde (T) | H-W | R-W | perde (W) | perde H-T→H-W | perde R-T→R-W |
|---|---|---|---|---|---|---|---|---|
| DUR032 | 2/71 (0.0302) | 4/94 (0.0348) | sì | 40/71 (0.0000) | 65/94 (0.0000) | pari (0) | sì | sì |
| DUR053 | 38/71 (0.0031) | 41/94 (0.0129) | no | 40/71 (0.0000) | 65/94 (0.0000) | pari (0) | sì | sì |
| DUR015 | 44/71 (0.0017) | 73/94 (0.0021) | sì | 40/71 (0.0000) | 62/94 (0.0002) | no | sì | no |
| DUR025 | 60/71 (0.0000) | 74/94 (0.0018) | no | 40/71 (0.0000) | 65/94 (0.0000) | pari (0) | pari (0) | sì |
| DUR003 | 1/71 (0.1284) | assente | assente | 40/71 (0.0000) | assente | assente | sì | assente |

## 3. Quanta parte del contrasto della diagonale originale (H-T vs R-W) si ritrova nei confronti a funzione costante?

Differenze di concentrazione (romano − ellenistico) e quota rispetto alla diagonale; ultime due colonne = effetto della funzione a fase costante (W − T).

| metrica | Δ diagonale (R-W − H-T) | Δ Tobler (R-T − H-T) | Δ ruota (R-W − H-W) | H-W − H-T | R-W − R-T |
|---|---|---|---|---|---|
| top-1 share | -0.111 | -0.148 (133 %) | -0.213 (191 %) | 0.102 | 0.037 |
| Gini | 0.066 | -0.166 (-249 %) | -0.175 (-263 %) | 0.241 | 0.232 |
| Freeman centralisation | -0.032 | -0.085 (263 %) | -0.029 (89 %) | -0.004 | 0.053 |

Test sulle centralità per sito (mediane; Mann-Whitney su tutti i siti, Wilcoxon appaiato e Spearman sui 46 dual-phase):

| metrica | confronto | mediane (tutti) | p MW | mediane (dual) | p Wilcoxon | ρ Spearman (dual) |
|---|---|---|---|---|---|---|
| degree_norm | H-T vs R-W | 0.5286 → 0.0860 | <2e-16 | 0.5000 → 0.1022 | 3.6e-09 | 0.643 (p=1.5e-06) |
| degree_norm | H-T vs R-T | 0.5286 → 0.3817 | 0.00092 | 0.5000 → 0.4032 | 0.16 | 0.756 (p=1.2e-09) |
| degree_norm | H-W vs R-W | 0.1286 → 0.0860 | 0.0034 | 0.1000 → 0.1022 | 0.6 | 0.721 (p=1.6e-08) |
| harmonic | H-T vs R-W | 0.7143 → 0.2555 | <2e-16 | 0.7131 → 0.2662 | 3.6e-09 | 0.655 (p=7.7e-07) |
| harmonic | H-T vs R-T | 0.7143 → 0.6523 | 0.002 | 0.7131 → 0.6565 | 0.51 | 0.781 (p=1.5e-10) |
| harmonic | H-W vs R-W | 0.2536 → 0.2555 | 0.17 | 0.1804 → 0.2662 | 0.041 | 0.604 (p=8.7e-06) |
| betweenness_norm | H-T vs R-W | 0.0037 → 0.0035 | 0.58 | 0.0049 → 0.0035 | 0.33 | 0.385 (p=0.0083) |
| betweenness_norm | H-T vs R-T | 0.0037 → 0.0097 | 0.014 | 0.0049 → 0.0059 | 0.44 | 0.790 (p=6.6e-11) |
| betweenness_norm | H-W vs R-W | 0.0001 → 0.0035 | 4.7e-05 | 0.0000 → 0.0035 | 0.043 | 0.542 (p=1e-04) |
