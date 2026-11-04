# Guide de l'atelier : du CSV au dashboard

Ce guide suit le déroulé de la soirée. Tout se fait sur ta machine, dans le terminal du devcontainer (VS Code, **Terminal > New Terminal**).

Avant de commencer : `task doctor` doit afficher ✅ pour Docker et pour la base. Sinon, voir le [README](../README.md#7-dépannage) ou lève la main.

## Les commandes de la soirée

| Commande | Quand |
|---|---|
| `task step N=1` | Passer à l'étape 1, 2, 3 ou 4 de l'atelier (voir plus bas) |
| `task build` | Construire tous les modèles dbt et lancer les tests : tout vert = mission réussie |
| `task show M=<nom>` | Afficher les 10 premières lignes d'un modèle, ou les problèmes remontés par un test |
| `task docs` | Ouvrir la documentation et le lineage dbt-colibri (port 8088) |
| `task sql` | Ouvrir une copie de la base dans le terminal DuckDB (quitter avec `.quit`) |
| `task superset:up` | Démarrer Superset (à lancer avant la pause) |
| `task superset:sync` | Recopier la base dans Superset après un `task build` |

> **Le piège du verrou DuckDB.** DuckDB verrouille le fichier `edna-sports-data.duckdb` dès qu'un programme l'ouvre, même en lecture seule. Si DBeaver ou un terminal `duckdb` lancé à la main est ouvert sur ce fichier, `dbt` échoue avec `Could not set lock on file`. Ferme-le, ou passe par `task sql`, qui ouvre une copie de la base.

> **dbt ne fait pas le ménage.** À chaque `task build`, dbt recrée les tables de tes modèles : modifier un modèle et relancer suffit. En revanche, il ne supprime jamais une table ou un schéma dont le modèle a disparu : si tu renommes ou supprimes un modèle, l'ancienne table reste dans la base, et dans Superset après `task superset:sync`. Pour repartir d'une base propre : `rm edna-sports-data.duckdb` puis `task build`. `task step` repart toujours d'une base vide.

## Échauffement facultatif : interroger les fichiers Parquet

À faire pendant que les dernières installations se terminent, ou plus tard. But : voir qu'un moteur SQL analytique lit directement des fichiers, sans rien charger.

1. Ouvre DuckDB **en mémoire** (sans fichier de base) : `duckdb`
2. Réponds aux trois questions en lisant les Parquet avec `read_parquet('processed-resources/<Table>/*.parquet')` :
   1. Combien de matchs de saison régulière par saison ? (`WRegularSeasonCompactResults`, colonne `Season`)
   2. Quelles sont les 5 équipes avec le plus de victoires en 2019 ? (jointure avec `WTeams` sur `WTeamID = TeamID`)
   3. Le nombre de points par match (`WScore + LScore`) a-t-il évolué entre 1998 et 2019 ?

```sql
select * from read_parquet('processed-resources/WTeams/*.parquet') limit 5;
```

Solutions : [`solutions/ex1.sql`](solutions/ex1.sql).

## Les missions dbt : une branche par étape

Le projet dbt est découpé en étapes, une par couche. Chaque étape est une **branche git** : elle contient tout ce qui a été construit avant, plus un modèle à terminer, ta mission. Chaque mission te fait écrire du SQL et pratiquer un mécanisme de dbt : les tests, `ref()`, la documentation.

| Étape | Branche | Ta mission | Ce que tu pratiques |
|---|---|---|---|
| 1 | `atelier/etape-1-staging` | `stg_tourney_seeds` : découper le seed brut en région et numéro | Les tests dans le YAML |
| 2 | `atelier/etape-2-marts` | `dim_tourney_seeds` : joindre seeds, équipes et régions | `ref()` et le DAG |
| 3 | `atelier/etape-3-reporting` | `rpt_tourney_runs` : le parcours de chaque équipe au tournoi | La documentation et le lineage |
| 4 | `atelier/etape-4-solution` | Le projet complet | |

**Au départ d'une mission, `task build` est rouge : c'est normal.** Les tests de la mission sont déjà écrits et échouent tant que le modèle n'est pas terminé. La mission est finie quand `task build` est entièrement vert.

**Lire la sortie de `task build`.** Chaque modèle et chaque test affiche `PASS` (vert), `ERROR` ou `FAIL` (rouge), ou `SKIP` (pas lancé parce qu'un modèle en amont a échoué). Le récapitulatif en fin de sortie liste les échecs. Pour le détail d'un test de mission, `task show M=mission_1_stg_tourney_seeds` affiche une ligne par problème.

**La solution d'une mission, c'est l'étape suivante.** `task step N=2` range ton travail en cours dans `git stash`, passe sur la branche de l'étape 2 (qui contient la solution de la mission 1) et reconstruit la base. Tu ne restes donc jamais bloqué.

```bash
git diff origin/atelier/etape-1-staging origin/atelier/etape-2-marts --stat    # ce qu'une étape a ajouté
git show origin/atelier/etape-2-marts:transformation/models/staging/stg_tourney_seeds.sql   # la solution de la mission 1
git stash list                                                                 # ton travail rangé
```

### Mission 1 : staging, `stg_tourney_seeds` (15 min)

```bash
task step N=1
```

La base ne contient que la couche `staging`. Un modèle dbt est un simple `select` : dbt-duckdb l'exécute dans DuckDB et enregistre le résultat comme une table. Les fonctions disponibles sont donc celles de DuckDB ([fonctions texte](https://duckdb.org/docs/current/sql/functions/text)).

**Entrée**, le fichier Parquet `WNCAATourneySeeds` :

| Season | TeamID | Seed |
|---|---|---|
| 2019 | 3163 | `W02` |
| 2019 | 3346 | `Z11` |

**Sortie attendue**, la table `staging.stg_tourney_seeds` (1 408 lignes) :

| season | team_id | seed_raw | seed_region | seed_number |
|---|---|---|---|---|
| 2019 | 3163 | `W02` | `W` | 2 |
| 2019 | 3346 | `Z11` | `Z` | 11 |

`seed_region` est la lettre de la région du bracket ; `seed_number` est un **entier**.

1. Dans `transformation/models/staging/stg_tourney_seeds.sql`, remplace les deux `null::...` (TODO 1 et 2) par une expression calculée à partir de la colonne `Seed`, en gardant les alias :

   | Fonction DuckDB | Exemple | Résultat |
   |---|---|---|
   | `left(texte, n)` : les n premiers caractères | `left('W02', 1)` | `'W'` |
   | `regexp_extract(texte, '[0-9]+')` : les chiffres, en texte | `regexp_extract('W02', '[0-9]+')` | `'02'` |
   | `cast(texte as integer)` : conversion en entier | `cast('02' as integer)` | `2` |

2. `task show M=stg_tourney_seeds` : tes deux colonnes doivent ressembler à la sortie attendue.
3. Dans `transformation/models/staging/_staging_models.yml`, TODO 3 : déclare les tests de `seed_region` (`not_null`, et `accepted_values` limité à W, X, Y, Z) et de `seed_number` (`not_null`). La syntaxe est donnée en commentaire ; le bloc `data_tests` se place sous `description`, au même niveau.
4. `task build` jusqu'au vert. Tant que les tests ne sont pas déclarés, le test de mission reste rouge : `task show M=mission_1_stg_tourney_seeds` dit ce qui manque.

### Mission 2 : marts, `dim_tourney_seeds` (20 min)

```bash
task step N=2
```

La base contient `staging` et une partie de `marts`. Un modèle dbt ne lit jamais une table par son nom : il écrit `{{ ref('nom_du_modele') }}`. dbt remplace `ref()` par le nom complet de la table et en déduit l'ordre de construction, le DAG.

**Entrées**, trois modèles staging (exemple de Connecticut en 2019) :

| Modèle | Colonnes utiles | Exemple |
|---|---|---|
| `stg_tourney_seeds` | season, team_id, seed_raw, seed_region, seed_number | 2019, 3163, `W02`, `W`, 2 |
| `stg_teams` | team_id, team_name | 3163, `Connecticut` |
| `stg_seasons` | season, region_w, region_x, region_y, region_z | 2019, `Albany`, `Chicago`, `Greensboro`, `Portland` |

**Sortie attendue**, la table `marts.dim_tourney_seeds` (1 408 lignes) :

| season | team_id | team_name | seed_raw | seed_region | seed_number | region_name |
|---|---|---|---|---|---|---|
| 2019 | 3163 | `Connecticut` | `W02` | `W` | 2 | `Albany` |

`region_name` est la colonne `region_w`, `region_x`, `region_y` ou `region_z` qui correspond à `seed_region`.

1. Ouvre `transformation/models/marts/dim_tourney_seeds.sql`. La CTE `seeds` montre comment lire un modèle avec `ref()`.
2. TODO 1 et 2 : écris de la même façon une CTE `teams` sur `stg_teams` et une CTE `seasons` sur `stg_seasons`.
3. TODO 3 : `left join` sur `teams` (clé `team_id`), puis remplace `null::varchar as team_name` par la colonne de `teams`.
4. TODO 4 : `left join` sur `seasons` (clé `season`), puis un `case s.seed_region when 'W' then se.region_w ... end` pour `region_name`.
5. `task build` jusqu'au vert. Pour voir ce que dbt a fait de tes `ref()` : `transformation/target/compiled/transformation/models/marts/dim_tourney_seeds.sql`.

Fini en avance : ajoute une colonne `is_blowout` (écart d'au moins 20 points) à `fct_regular_season_games.sql`, documente-la dans `_marts_models.yml` et ajoute-lui un test `not_null`.

**Avant la pause : `task superset:up`**, pour que Superset démarre pendant la pause (1 à 2 minutes).

### Mission 3 : reporting, `rpt_tourney_runs` (25 min)

```bash
task step N=3
```

La base contient toutes les couches, sauf ta mission. Le tournoi NCAA féminin compte 64 équipes : 6 victoires donnent le titre, une défaite élimine.

**Entrée principale**, `marts.fct_tourney_games` (un match par ligne, gagnant et perdant) :

| season | w_team_id | l_team_id | w_score | l_score |
|---|---|---|---|---|
| 2016 | 3163 | 3393 | 82 | 51 |

**Déjà fait** dans le squelette (CTE `all_tourney_team_games`) : chaque match devient deux lignes, une par équipe.

| season | team_id | is_win | pts_scored | pts_allowed |
|---|---|---|---|---|
| 2016 | 3163 | 1 | 82 | 51 |
| 2016 | 3393 | 0 | 51 | 82 |

**Sortie attendue**, la table `reporting.rpt_tourney_runs` (1 344 lignes, extrait de 2016) :

| team_name | season_label | seed_number | tourney_wins | tourney_losses | tournament_result |
|---|---|---|---|---|---|
| `Connecticut` | `Season 2016` | 1 | 6 | 0 | `Champion` |
| `Syracuse` | `Season 2016` | 4 | 5 | 1 | `Runner-Up` |
| `Albany NY` | `Season 2016` | 12 | 1 | 1 | `Second Round` |

1. TODO 1 et 2, dans la CTE `team_tourney_stats` : `tourney_wins` est la somme de `is_win`, `tourney_losses` le nombre de matchs moins les victoires. Convertis les deux en entier avec `::integer` : sans conversion, `sum()` renvoie un `HUGEINT`, que Superset ne traite pas comme un nombre (le test de mission le vérifie).
2. TODO 3 à 5, dans la CTE `final` : trois `left join` vers des marts lus avec `ref()`, puis remplace les `null::...` par leurs colonnes :

   | Mart | Clé de jointure | Colonnes à prendre |
   |---|---|---|
   | `dim_teams` (alias `t`) | `team_id` | `team_name`, `team_state`, `team_state_iso` |
   | `dim_seasons` (alias `se`) | `season` | `season_label` |
   | `dim_tourney_seeds` (alias `sd`) | `season` **et** `team_id` | `seed_number` |

   Le `case` qui calcule `tournament_result` est déjà écrit.
3. Dans `transformation/models/reporting/_reporting_models.yml`, TODO 6 : décris les colonnes `seed_number`, `is_champion` et `tournament_result` (une phrase : ce que contient la colonne et ses valeurs possibles).
4. `task build` jusqu'au vert.
5. `task docs`, puis le port **8088** (onglet **PORTS** de VS Code) : retrouve `rpt_tourney_runs`, tes descriptions, et remonte le lineage d'une colonne jusqu'au fichier source.

Solution : `task step N=4`.

Fini en avance : un sujet libre, avec son squelette et ses tests, copié dans `transformation/models/reporting/atelier/` :

| Sujet | Commande | Question |
|---|---|---|
| `domicile` | `task topic NAME=domicile` | L'équipe qui reçoit gagne-t-elle plus souvent, selon les saisons ? |
| `tirs-3pts` | `task topic NAME=tirs-3pts` | Le tir à 3 points prend-il plus de place depuis 2010 ? |
| `upsets` | `task topic NAME=upsets` | Au tournoi, quelles affiches produisent le plus de surprises ? |

Solutions dans `atelier/solutions/`.

## Le dashboard (40 min)

But : brancher Superset sur ta table de reporting et en tirer un dashboard qui répond à une question.

1. Superset a été lancé avant la pause (`task superset:up`). Sinon, lance-le maintenant (1 à 2 minutes).
2. `task superset:sync` : recopie ta base (avec ta table de la mission 3) dans Superset.
3. Ouvre **http://localhost:8089** dans le navigateur de ta machine, connecte-toi avec `admin` / `admin`.
4. La connexion **NCAA Basketball (DuckDB)** existe déjà : **Settings > Database Connections** pour voir son URI.
5. **Datasets > + Dataset** : base `NCAA Basketball (DuckDB)`, schéma `"edna-sports-data".reporting`, ta table.
6. Crée 2 à 4 charts (un **Line Chart** par saison, un **Big Number**, une **Table**), puis assemble-les dans un dashboard.
7. Encore du temps : ajoute un chart sur une autre table `reporting` ([idées et dictionnaire](donnees.md)).

## Si tu es perdu

- Une mission ne passe pas : `task show M=mission_<n>_<modèle>` pour le détail, ou `task step N=<étape suivante>` pour installer la solution et repartir du même point que tout le monde.
- Tout est cassé sur ta branche : `git restore transformation/`, puis `task build`.
- Une ancienne table traîne dans la base ou dans Superset : `rm edna-sports-data.duckdb`, puis `task build` (et `task superset:sync`).
- Ta machine ne suit pas : rejoins un voisin, on travaille très bien à deux sur un écran.
