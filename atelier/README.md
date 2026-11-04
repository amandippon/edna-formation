# Guide de l'atelier : du CSV au dashboard

Ce guide suit le déroulé de la soirée. Tout se fait sur ta machine, dans le terminal du devcontainer (VS Code, **Terminal > New Terminal**).

Avant de commencer : `task doctor` doit afficher ✅ pour Docker et pour la base. Sinon, voir le [README](../README.md#7-dépannage) ou lève la main.

## Les commandes de la soirée

| Commande | Quand |
|---|---|
| `task ingest` | Ex. 1 : convertir les CSV en Parquet |
| `task sql` | Ouvrir la base dans le terminal DuckDB (quitter avec `.quit`) |
| `task etape N=1` | Passer à l'étape 1, 2, 3 ou 4 de l'atelier (voir plus bas) |
| `task atelier:check` | Construire tous les modèles dbt et lancer les tests : tout vert = mission réussie |
| `task documentation` | Ouvrir le lineage dbt-colibri (port 8088) |
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

## Les missions dbt : une branche par étape

Le projet dbt est découpé en étapes, une par couche. Chaque étape est une **branche git** : elle contient tout ce qui a été construit avant, plus un modèle à écrire, ta mission. Les tests de la mission sont déjà écrits : ils sont rouges au départ, à toi de les faire passer au vert.

| Étape | Branche | Ta mission | Couche |
|---|---|---|---|
| 1 | `atelier/etape-1-bronze` | `stg_seasons` : nettoyer le fichier des saisons | Bronze (`staging`) |
| 2 | `atelier/etape-2-silver` | `dim_tourney_seeds` : joindre seeds, équipes et régions | Silver (`marts`) |
| 3 | `atelier/etape-3-gold` | `rpt_tourney_runs` : le parcours de chaque équipe au tournoi, ou un sujet libre | Gold (`reporting`) |
| 4 | `atelier/etape-4-solution` | Le projet complet | |

**La solution d'une mission, c'est l'étape suivante.** `task etape N=2` range ton travail en cours dans `git stash`, passe sur la branche de l'étape 2 (qui contient la solution de la mission 1) et reconstruit la base. Tu ne restes donc jamais bloqué.

Pour voir ce qu'une étape a ajouté :

```bash
git diff origin/atelier/etape-1-bronze origin/atelier/etape-2-silver --stat
git show origin/atelier/etape-2-silver:transformation/models/staging/stg_seasons.sql   # la solution de la mission 1
```

Pour retrouver ton propre travail rangé : `git stash list`, puis `git stash show -p stash@{0}`.

### Mission 1 : Bronze, `stg_seasons` (15 min)

```bash
task etape N=1
```

1. La base est reconstruite avec la seule couche `staging`. Les tests de `stg_seasons` sont rouges.
2. Ouvre `transformation/models/staging/stg_seasons.sql` : les `TODO` sont numérotés.
3. Convertis `DayZero` (texte au format `10/29/2018`) en date, renomme les colonnes de régions.
4. `task atelier:check` jusqu'à ce que tout soit vert. Le test `mission_1_stg_seasons` (dans `transformation/tests/missions/`) vérifie le résultat.

Compare avec `stg_teams.sql`, déjà écrit : c'est la même structure.

### Mission 2 : Silver, `dim_tourney_seeds` (15 min)

```bash
task etape N=2
```

1. La base contient maintenant `staging` et une partie de `marts` : `dim_teams`, `dim_seasons`, `dim_cities`, `fct_regular_season_games`.
2. Ouvre `transformation/models/marts/dim_tourney_seeds.sql` et complète les `TODO` : une jointure pour le nom de l'équipe, une jointure et un `case` pour le nom de la région.
3. `task atelier:check` jusqu'au vert. La documentation et les tests du modèle sont dans `_marts_models.yml`.

Bonus : ajoute une colonne `is_blowout` (écart d'au moins 20 points) à `fct_regular_season_games.sql`, documente-la et ajoute-lui un test `not_null`.

### Mission 3 : Gold, ta table de reporting (25 min)

```bash
task etape N=3
```

La base contient toutes les couches, sauf ta mission. Deux options :

**Option A, guidée : `rpt_tourney_runs`.** Ouvre `transformation/models/reporting/rpt_tourney_runs.sql` : une agrégation, trois jointures et un `case`. Tests dans `_reporting_models.yml` et `tests/missions/mission_3_rpt_tourney_runs.sql`.

**Option B, sujet libre.** Un squelette et ses tests sont copiés dans `transformation/models/reporting/atelier/` :

| Sujet | Commande | Question |
|---|---|---|
| `domicile` | `task atelier:start SUJET=domicile` | L'équipe qui reçoit gagne-t-elle plus souvent, selon les saisons ? |
| `tirs-3pts` | `task atelier:start SUJET=tirs-3pts` | Le tir à 3 points prend-il plus de place depuis 2010 ? |
| `upsets` | `task atelier:start SUJET=upsets` | Au tournoi, quelles affiches produisent le plus de surprises ? |

Dans les deux cas : `task atelier:check` jusqu'au vert. Solution de l'option A : `task etape N=4` ; de l'option B : `task atelier:solution SUJET=<ton sujet>`.

Fini en avance : fais l'autre option.

## Documentation : retrouver ta table dans le lineage (7 min)

`task documentation`, puis le port **8088** (onglet **PORTS** de VS Code). Cherche ta table de la mission 3, lis sa description et ses tests, et remonte son lineage colonne par colonne jusqu'aux fichiers sources.

## Ex. 4 : le dashboard (30 min)

But : brancher Superset sur ta table Gold et en tirer un dashboard.

1. Superset a été lancé avant la pause (`task superset:up`). Sinon, lance-le maintenant (1 à 2 minutes).
2. `task superset:refresh` : recopie ta base (avec ta table de la mission 3) dans Superset.
3. Ouvre **http://localhost:8089** dans le navigateur de ta machine, connecte-toi avec `admin` / `admin`.
4. La connexion **NCAA Basketball (DuckDB)** existe déjà : **Settings > Database Connections** pour voir son URI.
5. **Datasets > + Dataset** : base `NCAA Basketball (DuckDB)`, schéma `"edna-sports-data".reporting`, ta table.
6. Crée 2 ou 3 charts (un **Line Chart** par saison, un **Big Number**, une **Table**), puis assemble-les dans un dashboard.
7. Encore du temps : ajoute un chart sur une autre table `reporting` ([idées et dictionnaire](donnees.md)).

## Si tu es perdu

- Une mission ne passe pas : `task etape N=<étape suivante>` installe la solution, tu repars du même point que tout le monde.
- Tout est cassé sur ta branche : `task atelier:reset`, puis `task atelier:check`.
- Ta machine ne suit pas : rejoins un voisin, on travaille très bien à deux sur un écran.
