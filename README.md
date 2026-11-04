# edna-formation : du CSV au dashboard

Pipeline de données 100 % local sur le basketball universitaire féminin américain (NCAA Women's Basketball, saisons 1998 à 2019). Les fichiers CSV sont convertis en Parquet, transformés avec dbt dans une base DuckDB, puis explorés dans Superset.

```
resources/*.csv                    11 fichiers bruts (Kaggle)
      │  task ingest               PyArrow
      ▼
processed-resources/*/*.parquet    un fichier Parquet par table
      │  task build                dbt + DuckDB (modèles + tests)
      ▼
edna-sports-data.duckdb            schémas staging -> marts -> reporting
      │  task superset:up          copie de la base dans le conteneur
      ▼
Superset (http://localhost:8089)   datasets, charts, dashboards, SQL Lab
```

**Stack** (versions épinglées dans le repo) : Python 3.12 et uv, PyArrow, DuckDB 1.5.1, dbt-core 1.11 avec dbt-duckdb, dbt-colibri (lineage), Superset 6.0.0 (+ PostgreSQL 16 et Redis 7 pour ses métadonnées), Task pour les commandes, le tout dans un devcontainer VS Code. Aucun service cloud.

---

## 1. À faire avant l'atelier (20 à 30 min, une seule fois)

Le jour J, le Wi-Fi ne suffira pas à télécharger les images Docker de toute la salle. Fais ces étapes chez toi (version courte à envoyer aux participants : [docs/prerequis.md](docs/prerequis.md)).

### Installer les outils

| Outil | macOS | Windows |
|---|---|---|
| Docker Desktop | [docker.com](https://www.docker.com/products/docker-desktop/), version **Apple Silicon** (M1 à M4) ou **Intel** | D'abord `wsl --install` dans un PowerShell administrateur puis redémarrage, ensuite Docker Desktop avec l'option **Use WSL 2** |
| Git | `xcode-select --install` | [git-scm.com](https://git-scm.com/download/win), options par défaut (fournit Git Bash) |
| VS Code | [code.visualstudio.com](https://code.visualstudio.com) | idem |
| Extension VS Code | **Dev Containers** (éditeur : Microsoft) | idem |

Lance Docker Desktop et attends que l'icône de la baleine soit immobile.

### Préparer le projet

1. Clone le repo (Terminal sur macOS, Git Bash sur Windows) et ouvre-le dans VS Code :

   ```bash
   git clone https://github.com/amandippon/edna-formation
   cd edna-formation
   code .
   ```

   VS Code doit être ouvert **sur le dossier `edna-formation` lui-même**, sinon le devcontainer n'est pas détecté.

2. `Cmd+Shift+P` (macOS) ou `Ctrl+Shift+P` (Windows), puis **Dev Containers: Reopen in Container**. Le premier build prend 5 à 10 minutes. À la fin, le script de post-création installe les dépendances Python (`uv sync`) et construit la base (`task ingest` puis `task build`) : attends le message « ✅ Environnement prêt ! » dans le terminal.

3. Dans le terminal VS Code (donc dans le devcontainer), télécharge et construis la stack Superset une première fois :

   ```bash
   task superset:up
   task doctor
   ```

   `task doctor` doit afficher quatre lignes ✅ (Docker, base, conteneur, Superset). Ouvre http://localhost:8089 pour vérifier, connecte-toi avec `admin` / `admin`, puis arrête la stack :

   ```bash
   task superset:down
   ```

Tu es prêt : les images sont en cache et la base existe.

<details>
<summary>Sans devcontainer (pour les habitués)</summary>

Le Taskfile fonctionne aussi directement sur ta machine si tu as installé [uv](https://docs.astral.sh/uv/), [Task](https://taskfile.dev) et Docker. Depuis la racine du repo :

```bash
uv sync
task ingest
task build
task superset:up
```

uv télécharge Python 3.12 si besoin. Le CLI `duckdb` et les extensions VS Code du devcontainer ne sont alors pas installés pour toi.
</details>

---

## 2. Le jour de l'atelier

1. Démarre Docker Desktop **avant** d'ouvrir VS Code.
2. Ouvre le projet dans VS Code, puis **Dev Containers: Reopen in Container** (quelques secondes, l'image est déjà construite).
3. Dans le terminal du devcontainer : `task doctor`. Les lignes Docker et base doivent être ✅ (Superset sera démarré plus tard).
4. Mets à jour le projet si on te le demande : `git pull`.

La suite se passe dans le **[guide de l'atelier](atelier/README.md)** :

| Étape | Ce que tu fais | Ce que tu pratiques |
|---|---|---|
| Échauffement (facultatif) | Interroger les fichiers Parquet en SQL avec DuckDB | SQL sur fichiers |
| Mission 1 | Terminer `stg_tourney_seeds` (branche `atelier/etape-1-staging`) | Tests dans le YAML |
| Mission 2 | Terminer `dim_tourney_seeds` (branche `atelier/etape-2-marts`) | `ref()` et le DAG |
| Mission 3 | Terminer `rpt_tourney_runs` (branche `atelier/etape-3-reporting`) | Documentation et lineage |
| Dashboard | Construire un dashboard Superset sur ta table | Visualisation |

Chaque mission a ses tests déjà écrits, et sa solution est dans la branche de l'étape suivante : `task step N=2` y passe en rangeant ton travail.

---

## 3. Superset

```bash
task superset:up        # ~1 à 2 min (plus si les images ne sont pas en cache)
```

1. Ouvre **http://localhost:8089 dans le navigateur de ta machine**, et pas via la notification de port de VS Code : Superset tourne sur le Docker de ta machine, pas dans le devcontainer. Identifiants : `admin` / `admin`.
2. La base est **déjà connectée** sous le nom **NCAA Basketball (DuckDB)**, en lecture seule (URI : `duckdb:////app/superset_home/edna-sports-data.duckdb?access_mode=read_only`).
3. **Datasets > + Dataset** : base `NCAA Basketball (DuckDB)`, schéma `reporting`, une table.

> Dans les menus déroulants, les schémas s'affichent sous la forme `"edna-sports-data".reporting` (le préfixe est le nom du fichier DuckDB) : choisis celui qui finit par `reporting` et ignore les autres (`system.main`, `temp.main`, etc.).

Superset travaille sur **une copie** de la base. Après une modification d'un modèle dbt, `task build` puis `task superset:sync` recopie la base, sans redémarrage. Une nouvelle table apparaît dans **Datasets > + Dataset** ; pour une table modifiée, **Edit dataset > Sync columns from source**.

Autres chemins utiles :

- **SQL Lab** (**SQL > SQL Lab**) : une requête sur n'importe quel schéma, puis **Save > Save dataset**, devient un dataset virtuel.
- **Booléens** (`is_win`, `is_close_game`…) : métrique SQL personnalisée, par exemple `AVG(CASE WHEN is_win THEN 1 ELSE 0 END)`.
- **Idées de dashboards et dictionnaire des tables** : [atelier/donnees.md](atelier/donnees.md).

Un assistant IA (Claude Code ou équivalent) peut écrire un modèle dbt : le fichier `CLAUDE.md` à la racine lui décrit l'architecture et les conventions.

---

## 4. Explorer la base hors Superset

> **Verrou DuckDB.** DuckDB verrouille le fichier `edna-sports-data.duckdb` dès qu'un programme l'ouvre, **même en lecture seule**. Tant qu'un terminal `duckdb` ou DBeaver est ouvert dessus, `dbt` échoue avec `Could not set lock on file`. Utilise `task sql` (qui ouvre une copie) ou ferme ces outils avant de lancer dbt.

**Terminal DuckDB** (installé dans le devcontainer) :

```bash
task sql
```

```sql
SHOW ALL TABLES;
SELECT team_name, count(*) AS titres
FROM reporting.rpt_tourney_runs
WHERE is_champion
GROUP BY team_name
ORDER BY titres DESC;
```

`task sql` travaille sur une copie de la base prise au lancement : relance-le après un `dbt build` pour voir tes nouvelles tables.

**DBeaver** (facultatif) : nouvelle connexion **DuckDB**, fichier `edna-sports-data.duckdb` à la racine du repo cloné sur ta machine. **Déconnecte-toi** avant de lancer dbt.

**Lineage** : `task docs` génère la documentation Colibri (lineage au niveau des colonnes, descriptions, tests) et la sert sur le port 8088, transféré automatiquement par VS Code. Le fichier `colibri-docs/index.html` s'ouvre aussi directement dans un navigateur.

---

## 5. Commandes

À lancer dans le terminal du devcontainer. `task` seul affiche la liste.

| Commande | Effet |
|---|---|
| `task ingest` | CSV de `resources/` -> Parquet dans `processed-resources/` |
| `task build` | `dbt build` : construit les modèles et lance les tests |
| `task docs` | Génère la documentation dbt-colibri et la sert sur le port 8088 |
| `task show M=…` | Affiche les 10 premières lignes d'un modèle ou d'un test dbt, sans rien écrire dans la base |
| `task sql` | Ouvre une copie de la base dans le terminal DuckDB (ne bloque pas dbt) |
| `task step N=…` | Atelier : passe à l'étape 1 à 4 (met le travail en cours dans `git stash`, change de branche, reconstruit la base) |
| `task topic NAME=…` | Atelier, mission 3 : copie le squelette d'un sujet libre (`domicile`, `tirs-3pts`, `upsets`) |
| `task superset:up` | Démarre Superset et y enregistre la base |
| `task superset:sync` | Recopie la base dans Superset et vide le cache des charts |
| `task superset:down` | Arrête Superset (dashboards conservés) |
| `task doctor` | Vérifie Docker, la base et Superset |

Pour le reste, les commandes d'origine restent disponibles : `cd transformation && uv run dbt run --select ...`, `docker logs -f superset`, `git restore transformation/`.

---

## 6. Modèle de données

Toutes les tables vivent dans `edna-sports-data.duckdb`, en trois schémas.

En vocabulaire médaillon : les fichiers Parquet de `processed-resources/` tiennent lieu de Bronze, `staging` correspond au Silver, `marts` au Gold, et `reporting` est une couche d'exposition construite sur le Gold.

| Schéma | Rôle | Tables |
|---|---|---|
| `staging` | Copie fidèle des CSV, colonnes renommées en snake_case, aucune règle métier | 11 tables `stg_*` |
| `marts` | Dimensions et faits nettoyés et enrichis | `dim_teams`, `dim_seasons`, `dim_cities`, `dim_tourney_seeds`, `fct_regular_season_games`, `fct_tourney_games` |
| `reporting` | Tables larges prêtes pour Superset | `rpt_team_games`, `rpt_games`, `rpt_team_season_stats`, `rpt_tourney_runs` |
| `reporting` (exemples) | Une question métier = un modèle | `rpt_uconn_tennessee_*` (5 tables) |

Le code des modèles est dans `transformation/models/<couche>/`, leur documentation dans les fichiers `_*_models.yml`. Le dictionnaire des tables `reporting` est dans [atelier/donnees.md](atelier/donnees.md).

---

## 7. Dépannage

| Symptôme | Solution |
|---|---|
| « Docker is not running » ou `❌ Docker ne répond pas` | Démarre Docker Desktop et attends que l'icône soit immobile. |
| `❌ Base edna-sports-data.duckdb introuvable` | `task ingest` puis `task build` |
| Superset ne voit pas mon nouveau modèle | `task build` puis `task superset:sync` (qui vide aussi le cache des charts), puis **Datasets > + Dataset** (ou **Sync columns from source** pour une table modifiée). Si un chart affiche encore d'anciennes valeurs : **Force refresh** dans le menu du chart ou du dashboard. |
| La page http://localhost:8089 ne répond pas | `task doctor`. Si Superset démarre encore, patiente ; sinon `docker logs -f superset`. Ouvre l'URL dans le navigateur de ta machine, pas via la notification de port de VS Code. |
| Port 8089 déjà utilisé | Change `"8089:8088"` en `"8090:8088"` dans `visualization/docker-compose.yml`, relance `task superset:up` et ouvre http://localhost:8090. |
| Erreur `EOF` ou `failed to do request` au build | Erreur réseau temporaire : relance **Dev Containers: Reopen in Container** ou `task superset:up`. |
| « No space left on device » (Windows) | Le disque virtuel de Docker (WSL2) est plein : Docker Desktop > **Settings > Resources > Disk image > Clean / Purge data**, ou `docker system prune -a` (supprime aussi les images des autres projets). |
| `Could not set lock on file` dans DuckDB | Un autre programme a ouvert la base (DBeaver, terminal `duckdb`), même en lecture seule : ferme-le ou déconnecte-le, puis relance. Pour explorer sans bloquer dbt : `task sql`. |
| Une ancienne table reste dans la base (ou dans Superset) après avoir renommé ou supprimé un modèle | dbt recrée les tables de ses modèles à chaque build, mais ne supprime jamais une table ou un schéma dont le modèle a disparu. Pour repartir d'une base propre : `rm edna-sports-data.duckdb` puis `task build` (et `task superset:sync` si Superset tourne). `task step` le fait déjà à chaque changement d'étape. |
| Une mission de l'atelier ne passe pas | `task show M=mission_<n>_<modèle>` liste les problèmes ; `task step N=<étape suivante>` pour repartir de la solution ; tout est cassé : `git restore transformation/` puis `task build`. |
| Superset dans un état incohérent | `docker compose -f visualization/docker-compose.yml down -v` (efface dashboards et charts), puis `task superset:up`. |

---

## Données

Source : [Kaggle, Women's Machine Learning Competition 2019](https://www.kaggle.com/competitions/womens-machine-learning-competition-2019/data). Le tournoi s'arrête en 2018 car le but de la compétition était de prédire celui de 2019.

| Fichier | Contenu |
|---|---|
| `WTeams.csv` | 366 équipes de Division I |
| `WSeasons.csv` | 22 saisons (1998 à 2019), date de référence et régions du bracket |
| `WCities.csv` | 435 villes hôtes |
| `WRegularSeasonCompactResults.csv` | 107 133 matchs de saison régulière (scores) |
| `WRegularSeasonDetailedResults.csv` | 51 582 matchs de saison régulière avec box score (2010 à 2019) |
| `WNCAATourneyCompactResults.csv` | 1 323 matchs du tournoi NCAA (1998 à 2018) |
| `WNCAATourneyDetailedResults.csv` | 567 matchs du tournoi avec box score (2010 à 2018) |
| `WNCAATourneySeeds.csv` | 1 408 seeds (têtes de série) par saison |
| `WNCAATourneySlots.csv` | 63 slots décrivant le bracket |
| `WGameCities.csv` | 52 082 matchs associés à leur ville (2010 à 2019) |
| `WTeamSpellings.csv` | 1 141 variantes orthographiques des noms d'équipes |

## Structure du projet

```
edna-formation/
├── .devcontainer/           # Image et post-création du devcontainer
├── resources/               # CSV sources
├── ingestion/pipeline.py    # CSV -> Parquet (PyArrow)
├── processed-resources/     # Parquet générés (ignorés par git)
├── transformation/          # Projet dbt
│   ├── macros/              # generate_schema_name : schémas sans préfixe
│   └── models/
│       ├── staging/         # stg_* : CSV renommés
│       ├── marts/           # dim_* et fct_*
│       └── reporting/       # rpt_* pour Superset
│           └── examples/    # rpt_uconn_tennessee_* (modèles d'exemple)
├── visualization/           # docker-compose et image Superset
├── colibri-docs/            # Lineage généré par Colibri
├── atelier/                 # Guide de l'atelier, sujets libres et solutions
├── docs/prerequis.md        # Prérequis à faire avant l'atelier
├── edna-sports-data.duckdb  # Base générée (ignorée par git)
├── Taskfile.yml             # Toutes les commandes
└── CLAUDE.md                # Contexte pour les assistants IA
```
