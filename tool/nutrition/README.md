# Database degli alimenti (F4, D-54)

Lo script `build_food_db.dart` produce `assets/nutrition/foods.sqlite`, il database in sola lettura con cui l'app
stima i valori nutrizionali, e accanto `assets/nutrition/foods.version` (la sola `meta.version`, senza a capo finale:
l'app la legge per sapere se ricopiare il database). Lo schema è il contratto `lib/features/nutrition/data/food_db_schema.dart`.

## Rigenerare

```sh
dart run tool/nutrition/build_food_db.dart              # usa curated_foods.csv e manual_foods.csv
dart run tool/nutrition/build_food_db.dart --cache /percorso/cache --curated altro.csv --manual manuali.csv \
    --out /tmp/foods.sqlite                             # scrive anche /tmp/foods.version
```

Al primo avvio scarica le fonti in `tool/nutrition/.cache/` (non versionata, ~80 MB), controlla la dimensione di ogni
file ed estrae gli zip con `unzip` di sistema. Poi stampa un riepilogo (alimenti per fonte, porzioni, alias, voci
della ricerca, dimensione). Se la tabella curata o i valori manuali hanno errori (alias doppi, alimento assente o
escluso, fonte sconosciuta, id o chiave manuale doppi, numeri non validi) lo script li elenca tutti e si ferma senza
scrivere il file.

`meta.version` è un hash dei contenuti (alimenti, porzioni, alias, voci della ricerca): stessi dati → stessa versione
e, nello stesso giorno, stesso file byte per byte (`built_at` è solo la data UTC; `--built-at` la imposta).

La logica sta in `tool/nutrition/src/` (fuori dall'app); i test sono in `test/tool/nutrition/` con mini-dataset
sintetici. L'unica parte condivisa con l'app è `normalizeFoodName` (`lib/features/nutrition/domain/food_name.dart`).

## Fonti e licenze

| Fonte | File | Licenza |
|---|---|---|
| USDA FoodData Central, SR Legacy 2018-04 | https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_sr_legacy_food_csv_2018-04.zip | CC0 1.0 (pubblico dominio) |
| USDA FoodData Central, Foundation Foods 2025-12-18 | https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_foundation_food_csv_2025-12-18.zip | CC0 1.0 |
| ANSES-CIQUAL 2025 (XML del 2025-11-03) | Recherche Data Gouv, DOI [10.57745/RDMHWY](https://doi.org/10.57745/RDMHWY): `alim_`, `alim_grp_`, `compo_2025_11_03.xml` (`https://entrepot.recherche.data.gouv.fr/api/access/datafile/{666252,666250,666249}`) | Licence Ouverte / Open Licence Etalab 2.0, con attribuzione |
| Open Food Facts (etichette dei produttori, consultate il 2026-10-06) | `manual_foods.csv`: mediane calcolate a mano, codici EAN nella colonna `sources` (`https://world.openfoodfacts.org/product/<EAN>`) | database ODbL 1.0, contenuti DbCL 1.0, con attribuzione |

Testi delle licenze nell'app: `assets/licenses/USDA-FoodData-Central.txt`, `assets/licenses/CIQUAL-Etalab.txt` e
`assets/licenses/OpenFoodFacts.txt`.

## Regole

- **SR Legacy:** tutti gli alimenti con kcal (1008), proteine (1003), carboidrati (1005) e grassi (1004); zuccheri
  (2000, ripiego 1063), saturi (1258), fibre (1079) e sodio (1093) se presenti.
- **Foundation:** solo le righe `foundation_food` con tutti gli 8 nutrienti (kcal 1008, ripiego 2047 Atwater generale).
- **CIQUAL:** solo gli alimenti citati dalla tabella curata. "traces" = 0, "< x" = x/2, "-" = NULL; sodio dal
  costituente 10110 o, se manca, dal sale (sale / 2,5 × 1000 mg). Id = 9.000.000 + `alim_code`.
- **Valori manuali:** tutte le righe di `manual_foods.csv`, fonte `manual`, id = 8.000.000 + `id`, `source_id` = `id`,
  nessuna categoria; `name_it` del CSV (la tabella curata lo sovrascrive). Obbligatori kcal, proteine, carboidrati e
  grassi; vuoto = NULL; numeri non negativi, densità > 0. Porzioni: solo `piece` da `piece_g` della tabella curata;
  densità dalla colonna `density_g_per_ml`.
- **Porzioni** (grammi per unità, `gram_weight / amount`): `cup`, `tbsp`, `tsp` dalla prima parola della porzione;
  `piece` in ordine "medium" → "large" → porzione unitaria ("clove", "egg", "fruit"…) → "small" (per le uova "large"
  prima di "medium"); mai once, confezioni, panetti. A parità, `seq_num` più basso. `piece_g` della tabella curata
  sostituisce il pezzo USDA. Regole complete in `src/portions.dart`.
- **Densità** g/ml: tazza / 236,6 o, senza tazza, cucchiaio / 14,79.
- **Alias:** `aliases_en` → `en`; `name_it` e `aliases_it` → `it`; normalizzati con `normalizeFoodName`. Lo stesso
  alias in due righe (stessa lingua) ferma lo script.
- **Ricerca di ripiego (`food_search`):** stessa regola per tutte le fonti (CIQUAL e valori manuali compresi: nomi
  inglesi descrittivi, senza categoria esclusa né marchi). Escluse le categorie Fast Foods, Restaurant Foods, Snacks, Meals/Entrees,
  Baby Foods, American Indian/Alaska Native Foods e le descrizioni con parole in maiuscolo di almeno tre lettere
  (marchi: "KRAFT", "DENNY'S"; ammesse USDA, BBQ, NFS).

## Valori manuali (`manual_foods.csv`)

Prodotti italiani assenti da USDA e CIQUAL (guanciale, 'nduja, stracchino, piadina, scamorza, caciocavallo, speck,
ricotta salata, porcini secchi, pandoro, colomba, halloumi, glassa balsamica). Valori per 100 g ricercati il
2026-10-06: **mediana delle etichette dei produttori** (codici EAN su Open Food Facts,
`https://world.openfoodfacts.org/product/<EAN>`) e, dove esistono, tabelle CREA; fonti e variabilità nelle colonne
`sources` e `note`. Sodio = sale / 2,5 × 1000 mg; la densità della glassa è una stima. Sono valori fattuali aggregati,
non un estratto del database: si cita comunque Open Food Facts come fonte.

Dalla F4 fase 2 lo script li legge come fonte `manual` (id da `id`, mai riusato; `key` solo come nome tecnico
univoco) e la tabella curata li usa (`source` = `manual`, `source_id` = `id`) al posto delle approssimazioni di prima
(annotate nella colonna `note`). Testo dell'attribuzione nell'app: `assets/licenses/OpenFoodFacts.txt`.
