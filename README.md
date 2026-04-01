# edna-formation — Pipeline de données Jeux Olympiques

Projet pédagogique pour découvrir les métiers de la data, de l'ingestion jusqu'à la visualisation — **aucune connaissance en code requise.**

---

## Installation des outils

Avant de commencer, tu dois installer quelques outils sur ton ordinateur. Suis le guide correspondant à ton système.

> Les outils listés ici sont gratuits et open source. Une fois installés, tu n'auras plus à t'en occuper — le projet se configure automatiquement.

---

### macOS

#### 1. Git

Git est l'outil qui permet de télécharger et versionner le projet.

Ouvre le **Terminal** (cherche "Terminal" dans Spotlight avec `Cmd+Espace`) et colle cette commande :

```bash
xcode-select --install
```

Une fenêtre s'ouvre, clique sur **Installer**. Git sera installé automatiquement.

#### 2. Visual Studio Code

VSCode est l'éditeur de code dans lequel tu vas travailler.

- Télécharge VSCode sur [code.visualstudio.com](https://code.visualstudio.com)
- Ouvre le fichier `.dmg` téléchargé
- Glisse l'icône VSCode dans ton dossier **Applications**

#### 3. Docker Desktop

Docker permet de faire tourner des outils isolés sur ta machine (Superset dans notre cas), sans rien installer manuellement.

- Télécharge Docker Desktop sur [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/)
- Choisis la version **Mac Apple Silicon** (puce M1/M2/M3/M4) ou **Mac Intel** selon ton modèle
- Ouvre le fichier `.dmg` et glisse Docker dans **Applications**
- Lance Docker Desktop et accepte les conditions d'utilisation
- Attends que l'icône Docker en haut de l'écran soit stable (plus animée)

> Pour savoir quelle puce tu as : menu Pomme → **À propos de ce Mac**. Si tu vois "Apple M..." c'est Apple Silicon, sinon c'est Intel.

#### 4. Extension Dev Containers dans VSCode

- Ouvre VSCode
- Clique sur l'icône Extensions dans la barre de gauche (ou `Cmd+Shift+X`)
- Cherche **Dev Containers**
- Installe l'extension publiée par **Microsoft**

#### 5. DBeaver

DBeaver permet d'explorer visuellement la base de données.

- Télécharge DBeaver Community sur [dbeaver.io](https://dbeaver.io/download/)
- Choisis la version **macOS** (`.dmg`)
- Installe-le comme n'importe quelle application macOS

---

### Windows

#### 1. Git

- Télécharge Git sur [git-scm.com](https://git-scm.com/download/win)
- Lance l'installateur et laisse toutes les options par défaut
- À la fin, tu auras accès à **Git Bash** (un terminal)

#### 2. Visual Studio Code

- Télécharge VSCode sur [code.visualstudio.com](https://code.visualstudio.com)
- Lance l'installateur `.exe`
- Coche l'option **"Ajouter au PATH"** pendant l'installation

#### 3. WSL2 (Windows Subsystem for Linux)

WSL2 est requis pour faire tourner Docker sur Windows. C'est un Linux léger intégré à Windows.

Ouvre le **PowerShell en tant qu'administrateur** (clic droit sur le menu Démarrer → Windows PowerShell (admin)) et tape :

```powershell
wsl --install
```

Redémarre ton ordinateur quand c'est demandé.

#### 4. Docker Desktop

- Télécharge Docker Desktop sur [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/)
- Lance l'installateur et coche **"Use WSL 2 instead of Hyper-V"**
- Redémarre si demandé
- Lance Docker Desktop et attends que l'icône dans la barre des tâches soit stable

#### 5. Extension Dev Containers dans VSCode

- Ouvre VSCode
- Clique sur l'icône Extensions dans la barre de gauche (ou `Ctrl+Shift+X`)
- Cherche **Dev Containers**
- Installe l'extension publiée par **Microsoft**

#### 6. DBeaver

- Télécharge DBeaver Community sur [dbeaver.io](https://dbeaver.io/download/)
- Choisis la version **Windows** (`.exe`)
- Lance l'installateur et laisse les options par défaut

---

### Télécharger le projet

Une fois les outils installés, récupère le projet sur ton ordinateur.

**Sur macOS**, ouvre le Terminal.
**Sur Windows**, ouvre **Git Bash**.

Puis tape :

```bash
git clone https://github.com/amandippon/edna-formation
cd edna-formation
```

Ouvre ensuite le dossier dans VSCode :

```bash
code .
```

---

## C'est quoi ce projet ?

Tu vas simuler le travail d'une équipe data sur des données réelles des Jeux Olympiques (2016–2024).

La donnée part de simples fichiers CSV et arrive jusqu'à des tableaux de bord interactifs, en passant par des étapes de nettoyage et d'organisation — exactement comme dans une vraie équipe data.

```
Fichiers CSV (données brutes)
    ↓  Ingestion : on lit et range les fichiers
Fichiers Parquet (données organisées)
    ↓  Transformation : on nettoie et enrichit les données
Base de données (données prêtes à explorer)
    ↓  Visualisation
Superset (tableaux de bord)  ·  DBeaver (exploration SQL)
```

---

## Workflow étudiant

Suis ces 4 étapes dans l'ordre. Tu n'as pas besoin de comprendre le code — juste de lancer les commandes et d'observer ce qui se passe.

---

### Étape 0 — Ouvrir l'environnement de travail

Ouvre ce dossier dans **VSCode**, puis :

`Ctrl+Shift+P` → **Dev Containers: Reopen in Container**

VSCode prépare automatiquement tout l'environnement (Python, outils data, base de données). La première fois, ça peut prendre quelques minutes.

---

### Étape 1 — Lancer le pipeline

Dans le terminal VSCode, tape :

```bash
task pipeline
```

Cette commande fait tout le travail data en une fois :
- Elle lit les fichiers CSV du dossier `resources/` (athlètes, sports, résultats…)
- Elle les transforme et les range dans une base de données prête à explorer : `edna-sports-data.duckdb`

Tu verras défiler des logs dans le terminal — c'est normal, c'est le pipeline qui tourne.

---

### Étape 2 — Explorer les données dans DBeaver

DBeaver te permet de naviguer dans la base de données et d'écrire des requêtes SQL, comme on formulerait des questions à la donnée.

1. Ouvre **DBeaver**
2. Crée une nouvelle connexion de type **DuckDB**
3. Indique ce fichier : `edna-sports-data.duckdb` (à la racine du projet)
4. Explore les deux schémas disponibles :
   - `staging` : les données telles qu'elles arrivent des CSV, sans transformation
   - `marts` : les tables enrichies et prêtes pour l'analyse (athlètes, compétitions, résultats)

---

### Étape 3 — Visualiser avec Superset

Superset est un outil de création de tableaux de bord, similaire à Tableau ou Power BI.

```bash
task superset:up
```

Une fois démarré, VSCode affiche une notification **"Open in Browser"** en bas à droite — clique dessus, ou ouvre http://localhost:8089 directement dans ton navigateur.
Connecte-toi avec : **admin** / **admin**

**Connecter la base de données à Superset (à faire une seule fois) :**
1. Va dans **Settings → Database Connections → + Database**
2. Fais défiler jusqu'en bas et choisis **Other**
3. Dans le champ **SQLAlchemy URI**, colle exactement ce texte :
   `duckdb:////app/superset_home/edna-sports-data.duckdb`
4. Clique sur **Test Connection** pour vérifier, puis **Connect**

Tu peux ensuite créer des graphiques et des dashboards à partir des tables `marts`.

---

### Étape 4 — Explorer la documentation du pipeline

Le projet inclut une documentation interactive générée automatiquement : **`colibri-docs/index.html`**

Elle te montre visuellement comment les données circulent d'une table à l'autre (le "lineage"), quelles colonnes existent, et quels tests de qualité ont été définis.

**Option A — Ouvrir directement le fichier** (le plus simple) :

Dans l'explorateur de fichiers de VSCode, double-clique sur `colibri-docs/index.html` → clique sur **Open with Live Preview** ou **Open in Default Browser**.

**Option B — Via le terminal** :

```bash
task documentation
```

VSCode affiche une notification **"Open in Browser"**, ou ouvre http://localhost:8088 dans ton navigateur.

---

## Toutes les commandes disponibles

Ces commandes se tapent dans le terminal VSCode.

### Commandes principales

| Commande | Ce que ça fait |
|---|---|
| `task pipeline` | Lance tout le pipeline d'un coup : ingestion + transformation |
| `task ingest` | Relit les fichiers CSV et les convertit en Parquet (1ère étape) |
| `task dbt:run` | Transforme les données Parquet en tables analytiques (2ème étape) |

### Documentation & exploration

| Commande | Ce que ça fait |
|---|---|
| `task documentation` | Génère et ouvre la documentation Colibri du pipeline dans le navigateur (port 8088) |
| `task dbt:test` | Vérifie la qualité des données (valeurs manquantes, doublons, etc.) |

### Superset (tableaux de bord)

| Commande | Ce que ça fait |
|---|---|
| `task superset:up` | Démarre Superset et ouvre le navigateur (port 8089) |
| `task superset:down` | Arrête Superset proprement |
| `task superset:logs` | Affiche les logs de Superset (utile en cas de problème) |
| `task superset:reset` | Remet Superset à zéro (efface tous les dashboards créés) |

### Maintenance

| Commande | Ce que ça fait |
|---|---|
| `task clean` | Supprime les fichiers temporaires générés par le pipeline |

---

## Les données

Le projet utilise des données sur les Jeux Olympiques (2016–2024) :

| Fichier | Contenu |
|---|---|
| `resources/sports.csv` | 15 sports et disciplines |
| `resources/athletes.csv` | 30 athlètes internationaux |
| `resources/competitions.csv` | 25 épreuves olympiques |
| `resources/results.csv` | 60 résultats avec médailles |

---

## Structure du projet

```
edna-formation/
├── resources/               # Données sources (CSV) — point de départ
├── processed-resources/     # Données intermédiaires (Parquet) — généré automatiquement
├── ingestion/               # Code de l'étape d'ingestion
├── transformation/          # Code de l'étape de transformation
│   └── models/
│       ├── staging/         # Tables brutes issues des CSV
│       └── marts/           # Tables analytiques enrichies (pour Superset et DBeaver)
├── visualization/           # Configuration de Superset
├── edna-sports-data.duckdb  # Base de données finale — générée automatiquement
└── Taskfile.yml             # Définition de toutes les commandes
```
