# Guide de l'atelier : du CSV au dashboard

Ce guide suit le déroulé de la soirée. Chaque exercice se fait sur ta machine, dans le terminal du devcontainer (VS Code, **Terminal > New Terminal**).

Avant de commencer : `task doctor` doit afficher ✅ pour Docker et pour la base. Sinon, voir le [README](../README.md#7-dépannage) ou lève la main.

## Les commandes de la soirée

| Commande | Quand |
|---|---|
| `task ingest` | Ex. 1 : convertir les CSV en Parquet |
| `task sql` | Ouvrir la base dans le terminal DuckDB (quitter avec `.quit`) |
| `task atelier:start EX=2` | Préparer l'ex. 2 |
| `task atelier:start EX=3 SUJET=domicile` | Préparer l'ex. 3 (`domicile`, `tirs-3pts` ou `upsets`) |
| `task atelier:check` | Construire tes modèles et lancer leurs tests : tout vert = exercice réussi |
| `task atelier:solution EX=2` | Bloqué ? Installe la solution et repars de là |
| `task documentation` | Ex. 3 : ouvrir le lineage Colibri (port 8088) |
| `task superset:up` | Démarrer Superset (à lancer avant la pause) |
| `task superset:refresh` | Recopier la base dans Superset après un changement de modèle |

> **Le piège du verrou DuckDB.** DuckDB verrouille le fichier `edna-sports-data.duckdb` dès qu'un programme l'ouvre, même en lecture seule. Si DBeaver ou un terminal `duckdb` lancé à la main est ouvert sur ce fichier, `dbt` échoue avec `Could not set lock on file`. Ferme-le, ou passe par `task sql`, qui ouvre une copie de la base.

## Ex. 1 : interroger des fichiers Parquet avec DuckDB (10 min)

But : voir qu'un moteur SQL analytique lit directement des fichiers, sans rien charger.

1. Lance l'ingestion : `task ingest`. Compare les tailles :
   ```bash
   du -sh resources processed-resources
   ```
2. Ouvre DuckDB **en mémoire** (sans fichier de base) : `duckdb`
3. Réponds aux trois questions en SQL, en lisant les Parquet avec `read_parquet('processed-resources/<Table>/*.parquet')` :
   1. Combien de matchs de saison régulière par saison ? (`WRegularSeasonCompactResults`, colonne `Season`)
   2. Quelles sont les 5 équipes avec le plus de victoires en 2019 ? (jointure avec `WTeams` sur `WTeamID = TeamID`)
   3. Le nombre de points par match (`WScore + LScore`) a-t-il évolué entre 1998 et 2019 ?

Pour commencer :

```sql
select * from read_parquet('processed-resources/WTeams/*.parquet') limit 5;
```

Solutions : [`solutions/ex1.sql`](solutions/ex1.sql).

## Ex. 2 : enrichir une table Silver (15 min)

But : modifier un modèle dbt existant, le reconstruire et le valider par un test.

La table `marts.fct_regular_season_games` (couche Silver) contient un match par ligne. Tu vas lui ajouter deux colonnes :

| Colonne | Règle |
|---|---|
| `is_blowout` | vrai si l'écart de score (`score_margin`) est d'au moins 20 points |
| `game_month` | premier jour du mois du match, pour les graphiques par mois (`date_trunc('month', ...)`) |

1. `task atelier:start EX=2` : installe le test qui vérifie ton travail.
2. `task atelier:check` : le test `assert_atelier_ex2_blowout` est rouge, c'est normal.
3. Ouvre `transformation/models/marts/fct_regular_season_games.sql` et ajoute les deux colonnes dans le `select` du CTE `enriched`. Astuce : `game_date` y est calculé à partir de `s.day_zero` et `c.day_num`.
4. Documente-les dans `transformation/models/marts/_marts_models.yml` (bloc `fct_regular_season_games`), avec un test `not_null`.
5. `task atelier:check` jusqu'à ce que tout soit vert.

**Bonus** : expose `is_blowout` dans `reporting.rpt_games`. Attention, ce modèle assemble saison régulière et tournoi avec un `union all` : les deux parties doivent avoir les mêmes colonnes (pour le tournoi, calcule-la directement depuis `score_margin`). Vérifie avec `cd transformation && uv run dbt build --select rpt_games`.

Bloqué : `task atelier:solution EX=2`.

## Ex. 3 : créer ta table Gold (25 min + 10 min de documentation)

But : écrire un modèle de reporting de A à Z. Les tests sont déjà écrits, c'est à toi d'écrire le SQL qui les fait passer.

Choisis un sujet :

| Sujet | Commande | Question | Source |
|---|---|---|---|
| `domicile` | `task atelier:start EX=3 SUJET=domicile` | L'équipe qui reçoit gagne-t-elle plus souvent, et l'écart change-t-il selon les saisons ? | `fct_regular_season_games` |
| `tirs-3pts` | `task atelier:start EX=3 SUJET=tirs-3pts` | Le tir à 3 points prend-il de plus en plus de place depuis 2010 ? | `fct_regular_season_games` |
| `upsets` | `task atelier:start EX=3 SUJET=upsets` | Au tournoi NCAA, quelles affiches produisent le plus de surprises ? | `fct_tourney_games` |

1. La commande copie trois fichiers :
   - le modèle à compléter dans `transformation/models/reporting/atelier/` (les `TODO` sont numérotés) ;
   - sa documentation et ses tests (`_rpt_....yml`) à côté ;
   - un test de résultat dans `transformation/tests/atelier/`.
2. `task atelier:check` : beaucoup de rouge au départ.
3. Complète les `TODO` un par un et relance `task atelier:check` après chacun.
4. Tout est vert ? Ouvre la documentation : `task documentation`, puis le port **8088** (onglet **PORTS** de VS Code). Cherche ton modèle et remonte son lineage jusqu'aux fichiers sources.

Bloqué : `task atelier:solution EX=3 SUJET=<ton sujet>`. Fini en avance : fais un deuxième sujet.

## Ex. 4 : le dashboard (35 min)

But : brancher Superset sur ta table Gold et en tirer un dashboard.

1. Superset a été lancé avant la pause (`task superset:up`). Sinon, lance-le maintenant (1 à 2 minutes).
2. `task superset:refresh` : recopie ta base (avec ta table de l'ex. 3) dans Superset.
3. Ouvre **http://localhost:8089** dans le navigateur de ta machine, connecte-toi avec `admin` / `admin`.
4. La connexion **NCAA Basketball (DuckDB)** existe déjà : **Settings > Database Connections** pour voir son URI.
5. **Datasets > + Dataset** : base `NCAA Basketball (DuckDB)`, schéma `"edna-sports-data".reporting`, ta table.
6. Crée 2 ou 3 charts (un **Line Chart** par saison, un **Big Number**, une **Table**), puis assemble-les dans un dashboard.
7. Encore du temps : ajoute un chart sur une autre table `reporting` ([idées et dictionnaire](donnees.md)).

## Si tu es perdu

- Un exercice ne passe pas : `task atelier:solution ...` installe la solution, tu repars du même point que tout le monde.
- Tout est cassé : `task atelier:reset` remet les modèles dans leur état d'origine, puis `task dbt:build`.
- Ta machine ne suit pas : rejoins un voisin, on travaille très bien à deux sur un écran.
