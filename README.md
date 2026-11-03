# edna-formation : du CSV au dashboard

Pipeline de données 100 % local sur le basketball universitaire féminin américain (NCAA Women's Basketball, saisons 1998 à 2019). Les fichiers CSV sont convertis en Parquet, transformés avec dbt dans une base DuckDB, puis explorés dans Superset.

```
resources/*.csv                    11 fichiers bruts (Kaggle)
      │  task ingest               PyArrow
      ▼
processed-resources/*/*.parquet    un fichier Parquet par table
      │  task dbt:build            dbt + DuckDB (modèles + tests)
      ▼
edna-sports-data.duckdb            schémas staging -> marts -> reporting
      │  task superset:up          copie de la base dans le conteneur
      ▼
Superset (http://localhost:8089)   datasets, charts, dashboards, SQL Lab
```

**Stack** (versions épinglées dans le repo) : Python 3.12 et uv, PyArrow, DuckDB 1.5.1, dbt-core 1.11 avec dbt-duckdb, dbt-colibri (lineage), Superset 6.0.0 (+ PostgreSQL 16 et Redis 7 pour ses métadonnées), Task pour les commandes, le tout dans un devcontainer VS Code. Aucun service cloud.

---

## 1. À faire avant l'atelier (20 à 30 min, une seule fois)

Le jour J, le Wi-Fi ne suffira pas à télécharger les images Docker de toute la salle. Fais ces étapes chez toi.

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

2. `Cmd+Shift+P` (macOS) ou `Ctrl+Shift+P` (Windows), puis **Dev Containers: Reopen in Container**. Le premier build prend 5 à 10 minutes. À la fin, le script de post-création installe les dépendances Python (`uv sync`) et construit la base avec `task pipeline` : attends le message « ✅ Environnement prêt ! » dans le terminal.

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
task pipeline
task superset:up
```

uv télécharge Python 3.12 si besoin. Le CLI `duckdb` et les extensions VS Code du devcontainer ne sont alors pas installés pour toi.
</details>

---

## 2. Le jour J : setup en 15 minutes

1. Démarre Docker Desktop.
2. Ouvre le projet dans VS Code, puis **Dev Containers: Reopen in Container** (quelques secondes, l'image est déjà construite).
3. Dans le terminal du devcontainer :

   ```bash
   task pipeline       # facultatif si la base existe déjà (~10 s)
   task superset:up    # ~1 à 2 min
   ```

4. Ouvre **http://localhost:8089 dans le navigateur de ta machine**, et pas via la notification de port de VS Code : Superset tourne sur le Docker de ta machine, pas dans le devcontainer. Identifiants : `admin` / `admin`.
5. La base est **déjà connectée** sous le nom **NCAA Basketball (DuckDB)**, en lecture seule. Rien à configurer.

En cas de doute : `task doctor`.

> Dans les menus déroulants de Superset, les schémas s'affichent sous la forme `"edna-sports-data".reporting`. C'est normal (le préfixe est le nom du fichier DuckDB) : choisis celui qui finit par `reporting`.

Une seule machine par équipe a besoin de faire tourner Superset.

---

## 3. Construire un dashboard

La fiche [docs/atelier.md](docs/atelier.md) détaille les tables, leurs pièges et six idées de dashboards.

**Chemin rapide : une table existante**

1. **Datasets > + Dataset** : base `NCAA Basketball (DuckDB)`, schéma `reporting`, une table (par exemple `rpt_team_games`).
2. **Create chart** depuis le dataset, choisis un type de graphique, glisse colonnes et métriques, **Save** en l'ajoutant à un dashboard.
3. Les booléens (`is_win`, `is_close_game`…) s'agrègent avec une métrique SQL personnalisée, par exemple `AVG(CASE WHEN is_win THEN 1 ELSE 0 END)`.

**Chemin SQL : dataset virtuel**

**SQL > SQL Lab**, écris ta requête sur n'importe quel schéma (`staging`, `marts`, `reporting`), exécute-la, puis **Save > Save dataset**. Le résultat devient un dataset utilisable dans les charts, sans toucher au projet dbt.

**Niveau 2 : un nouveau modèle dbt**

1. Crée `transformation/models/reporting/rpt_<ton_sujet>.sql`, construit à partir des tables `marts` avec `{{ ref('...') }}`. Les modèles de `transformation/models/reporting/examples/` (rivalité UConn vs Tennessee) montrent comment traduire une question en table.
2. Documente-le dans un fichier YAML du même dossier (description, colonnes, tests).
3. Lance :

   ```bash
   task superset:refresh
   ```

   La commande reconstruit les modèles dbt (avec les tests) et recopie la base dans Superset, sans redémarrage. Une nouvelle table apparaît dans **Datasets > + Dataset** ; pour une table modifiée, **Edit dataset > Sync columns from source**.

Un assistant IA (Claude Code ou équivalent) peut écrire le modèle : le fichier `CLAUDE.md` à la racine lui décrit l'architecture et les conventions.

---

## 4. Explorer la base hors Superset

**CLI DuckDB** (installé dans le devcontainer) :

```bash
duckdb -readonly edna-sports-data.duckdb
```

```sql
SHOW ALL TABLES;
SELECT team_name, count(*) AS titres
FROM reporting.rpt_tourney_runs
WHERE is_champion
GROUP BY team_name
ORDER BY titres DESC;
```

**DuckDB UI** (facultatif, non testé dans le devcontainer) : `duckdb -ui edna-sports-data.duckdb` ouvre une interface notebook sur http://localhost:4213. L'extension télécharge son interface depuis internet, et dans le devcontainer il faut transférer le port 4213 depuis l'onglet **Ports** de VS Code.

**DBeaver** (facultatif) : nouvelle connexion **DuckDB**, fichier `edna-sports-data.duckdb` à la racine du repo cloné sur ta machine. Coche une connexion en lecture seule, ou ferme DBeaver avant `task pipeline` : DuckDB n'accepte qu'un seul processus en écriture.

**Lineage** : `task documentation` génère la documentation Colibri (lineage au niveau des colonnes, descriptions, tests) et la sert sur le port 8088, transféré automatiquement par VS Code. Le fichier `colibri-docs/index.html` s'ouvre aussi directement dans un navigateur.

---

## 5. Commandes

À lancer dans le terminal du devcontainer. `task` seul affiche la liste.

| Commande | Effet |
|---|---|
| `task pipeline` | Ingestion puis `dbt build` (modèles + tests) |
| `task ingest` | CSV de `resources/` -> Parquet dans `processed-resources/` |
| `task dbt:build` | Construit tous les modèles dbt et lance les tests |
| `task dbt:run` | Construit les modèles, sans les tests |
| `task dbt:test` | Lance uniquement les tests de qualité |
| `task documentation` | Génère et sert le lineage Colibri (port 8088) |
| `task colibri:generate` | Génère seulement `colibri-docs/` |
| `task colibri:open` | Sert ou ouvre `colibri-docs/index.html` |
| `task superset:up` | Construit et démarre Superset, copie la base, crée l'admin et connecte la base |
| `task superset:refresh` | `dbt build` puis recopie la base dans Superset (Superset doit tourner) |
| `task superset:down` | Arrête Superset (dashboards conservés) |
| `task superset:logs` | Affiche les logs de Superset |
| `task superset:reset` | Supprime toutes les données Superset (dashboards compris) puis redémarre |
| `task doctor` | Vérifie Docker, la base et Superset |
| `task clean` | Supprime les fichiers générés par dbt et les caches Python |

---

## 6. Modèle de données

Toutes les tables vivent dans `edna-sports-data.duckdb`, en trois schémas.

| Schéma | Rôle | Tables |
|---|---|---|
| `staging` | Copie fidèle des CSV, colonnes renommées en snake_case, aucune règle métier | 11 tables `stg_*` |
| `marts` | Dimensions et faits nettoyés et enrichis | `dim_teams`, `dim_seasons`, `dim_cities`, `fct_regular_season_games`, `fct_tourney_games` |
| `reporting` | Tables larges prêtes pour Superset | `rpt_team_games`, `rpt_games`, `rpt_team_season_stats`, `rpt_tourney_runs` |
| `reporting` (exemples) | Une question métier = un modèle | `rpt_uconn_tennessee_*` (5 tables) |

Le code des modèles est dans `transformation/models/<couche>/`, leur documentation dans les fichiers `_*_models.yml`. Le dictionnaire des tables `reporting` est dans [docs/atelier.md](docs/atelier.md).

---

## 7. Dépannage

| Symptôme | Solution |
|---|---|
| « Docker is not running » ou `❌ Docker ne répond pas` | Démarre Docker Desktop et attends que l'icône soit immobile. |
| `❌ Base edna-sports-data.duckdb introuvable` | `task pipeline` |
| Superset ne voit pas mon nouveau modèle | `task superset:refresh`, puis **Datasets > + Dataset** (ou **Sync columns from source** pour une table modifiée). |
| La page http://localhost:8089 ne répond pas | `task doctor`. Si Superset démarre encore, patiente ; sinon `task superset:logs`. Ouvre l'URL dans le navigateur de ta machine, pas via la notification de port de VS Code. |
| Port 8089 déjà utilisé | Change `"8089:8088"` en `"8090:8088"` dans `visualization/docker-compose.yml`, relance `task superset:up` et ouvre http://localhost:8090. |
| Erreur `EOF` ou `failed to do request` au build | Erreur réseau temporaire : relance **Dev Containers: Reopen in Container** ou `task superset:up`. |
| « No space left on device » (Windows) | Le disque virtuel de Docker (WSL2) est plein : Docker Desktop > **Settings > Resources > Disk image > Clean / Purge data**, ou `docker system prune -a` (supprime aussi les images des autres projets). |
| `Could not set lock on file` dans DuckDB | Un autre processus (DBeaver, CLI `duckdb`) tient la base en écriture : ferme-le ou ouvre-le en lecture seule, puis relance. |
| Superset dans un état incohérent | `task superset:reset` (efface dashboards et charts). |

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
├── docs/atelier.md          # Fiche atelier : tables et idées de dashboards
├── edna-sports-data.duckdb  # Base générée (ignorée par git)
├── Taskfile.yml             # Toutes les commandes
└── CLAUDE.md                # Contexte pour les assistants IA
```
