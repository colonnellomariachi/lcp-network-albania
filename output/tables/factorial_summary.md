# Task 9 — Disegno fattoriale 2×2: lettura dei risultati

Generato da `R/11_cost_function_factorial.R` il 2026-10-03. Solo numeri, nessuna interpretazione.

## Controllo di regressione (Step 1)

H-T e R-W ricostruite dagli LCP salvati riproducono gli oggetti pubblicati: 12/12 verifiche superate (archi, grafo, composizione, centralità per sito vs `centrality_comparison.csv`, concentrazione vs `betweenness_concentration_sweep.csv`).

Nota: il grado mediano di R-W è 7.5 (94 nodi; senza isolati: 8), non 8 come indicato nella consegna; il grafo è identico a `net_rom.rds`.

Coerenza degli LCP nuovi (coppie fra i 46 siti dual-phase, costo medio in minuti): H-W vs R-W (wheeled) — 990 coppie, scarto massimo 0 min; R-T vs H-T (Tobler) — 990 coppie, scarto massimo 0 min.

## Composizione

| cella | nodi | archi | densità | grado mediano | isolati | componenti | gigante | isolati (elenco) |
|---|---|---|---|---|---|---|---|---|
| H-T | 71 | 1084 | 0.436 | 37.0 | 0 |  2 | 68 (95.8 %) |  |
| R-W | 94 |  348 | 0.080 |  7.5 | 6 | 14 | 66 (70.2 %) | DUR016, DUR029, DUR030, DUR052, DUR053, DUR103 |
| H-W | 71 |  434 | 0.175 |  9.0 | 7 | 13 | 41 (57.7 %) | DUR003, DUR015, DUR025, DUR032, DUR041, DUR051, DUR053 |
| R-T | 94 | 1550 | 0.355 | 35.5 | 1 |  2 | 93 (98.9 %) | DUR103 |

## 1. La concentrazione della betweenness diminuisce dall'ellenistico al romano in entrambi i confronti a funzione costante?

**Sì**.

| metrica | H-T | R-T | cala (T) | H-W | R-W | cala (W) |
|---|---|---|---|---|---|---|
| top-1 share | 0.191 | 0.042 | sì | 0.293 | 0.092 | sì |
| Gini | 0.677 | 0.514 | sì | 0.917 | 0.751 | sì |
| Freeman centralisation | 0.121 | 0.033 | sì | 0.117 | 0.105 | sì |

Nodo di testa: H-T DUR003, R-T DUR138, H-W DUR033, R-W DUR050.

## 2. I centri d'altura perdono posizione dall'ellenistico al romano in entrambi i confronti a funzione costante, o solo quando cambia la funzione?

Rank percentile di betweenness, ellenistico → romano a funzione costante. Tobler: 2/4 perdono (DUR032, DUR015); 0 pari a betweenness 0 (); 2 migliorano (DUR053, DUR025). Trasporto su ruota: 0/4 perdono (); 3 pari a betweenness 0 (DUR032, DUR053, DUR025); 1 migliorano (DUR015).

Rank di betweenness / n (betweenness normalizzata). Rank a pari merito = minimo del gruppo, quindi tutti i nodi a betweenness 0 condividono il primo rank del gruppo a zero; per questo i casi a 0 in entrambe le celle sono marcati "pari (0)" e, se solo una delle due è 0, decide il valore (0 → positivo = non perde). Negli altri casi decide il rank percentile.

| sito | H-T | R-T | perde (T) | H-W | R-W | perde (W) | perde H-T→H-W | perde R-T→R-W |
|---|---|---|---|---|---|---|---|---|
| DUR032 | 2/71 (0.0302) | 4/94 (0.0353) | sì | 40/71 (0.0000) | 65/94 (0.0000) | pari (0) | sì | sì |
| DUR053 | 37/71 (0.0031) | 41/94 (0.0129) | no | 40/71 (0.0000) | 65/94 (0.0000) | pari (0) | sì | sì |
| DUR015 | 44/71 (0.0017) | 73/94 (0.0019) | sì | 40/71 (0.0000) | 62/94 (0.0002) | no | sì | no |
| DUR025 | 60/71 (0.0000) | 74/94 (0.0018) | no | 40/71 (0.0000) | 65/94 (0.0000) | pari (0) | pari (0) | sì |
| DUR003 | 1/71 (0.1284) | assente | assente | 40/71 (0.0000) | assente | assente | sì | assente |

## 3. Quanta parte del contrasto della diagonale originale (H-T vs R-W) si ritrova nei confronti a funzione costante?

Differenze di concentrazione (romano − ellenistico) e quota rispetto alla diagonale; ultime due colonne = effetto della funzione a fase costante (W − T).

| metrica | Δ diagonale (R-W − H-T) | Δ Tobler (R-T − H-T) | Δ ruota (R-W − H-W) | H-W − H-T | R-W − R-T |
|---|---|---|---|---|---|
| top-1 share | -0.099 | -0.150 (150 %) | -0.201 (202 %) | 0.102 | 0.050 |
| Gini | 0.074 | -0.163 (-222 %) | -0.167 (-227 %) | 0.240 | 0.237 |
| Freeman centralisation | -0.016 | -0.088 (567 %) | -0.012 (77 %) | -0.004 | 0.072 |

Test sulle centralità per sito (mediane; Mann-Whitney su tutti i siti, Wilcoxon appaiato e Spearman sui 46 dual-phase):

| metrica | confronto | mediane (tutti) | p MW | mediane (dual) | p Wilcoxon | ρ Spearman (dual) |
|---|---|---|---|---|---|---|
| degree_norm | H-T vs R-W | 0.5286 → 0.0806 | <2e-16 | 0.5000 → 0.0968 | 3.6e-09 | 0.650 (p=1e-06) |
| degree_norm | H-T vs R-T | 0.5286 → 0.3817 | 0.001 | 0.5000 → 0.4032 | 0.14 | 0.755 (p=1.4e-09) |
| degree_norm | H-W vs R-W | 0.1286 → 0.0806 | 0.0023 | 0.1000 → 0.0968 | 0.79 | 0.715 (p=2.4e-08) |
| harmonic | H-T vs R-W | 0.7143 → 0.2547 | <2e-16 | 0.7131 → 0.2653 | 3.6e-09 | 0.665 (p=4.7e-07) |
| harmonic | H-T vs R-T | 0.7143 → 0.6482 | 0.00079 | 0.7131 → 0.6537 | 0.38 | 0.769 (p=4.5e-10) |
| harmonic | H-W vs R-W | 0.2536 → 0.2547 | 0.15 | 0.1804 → 0.2653 | 0.064 | 0.613 (p=5.9e-06) |
| betweenness_norm | H-T vs R-W | 0.0038 → 0.0033 | 0.6 | 0.0049 → 0.0033 | 0.23 | 0.360 (p=0.014) |
| betweenness_norm | H-T vs R-T | 0.0038 → 0.0076 | 0.031 | 0.0049 → 0.0050 | 0.97 | 0.777 (p=2.2e-10) |
| betweenness_norm | H-W vs R-W | 0.0001 → 0.0033 | 5.2e-05 | 0.0000 → 0.0033 | 0.047 | 0.534 (p=0.00013) |

## Nota DUR103

Nelle celle romane (output del loop) DUR103 resta isolato perché `04` risolve le celle con le coordinate non spostate (il sito è spostato di un pixel in `03`). Risolvendolo: R-W grado 2 (DUR104;DUR106), R-T grado 4 (DUR016;DUR039;DUR104;DUR106). Dettagli in `factorial_dur103_sensitivity.csv`.
