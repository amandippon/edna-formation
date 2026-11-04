#!/bin/bash
set -e

echo "🚀 Configuration de l'environnement edna-formation..."

# Le postCreateCommand s'exécute depuis le workspaceFolder
echo "📁 Répertoire de travail : $(pwd)"

# Vérification des outils
echo "🔧 Vérification des outils installés..."
echo "  Python : $(python --version)"
echo "  uv     : $(uv --version)"
echo "  DuckDB : $(duckdb --version)"
echo "  Task   : $(task --version)"

# Création du .env depuis .env_sample si absent
if [ ! -f .env ]; then
    cp .env_sample .env
    echo "📄 Fichier .env créé depuis .env_sample"
fi

# Installation des dépendances Python
echo ""
echo "📦 Installation des dépendances Python..."
uv sync --no-install-project

# Construction de la base DuckDB (ingestion + dbt), pour qu'elle soit prête dès l'ouverture
echo ""
echo "🏗️  Construction de la base edna-sports-data.duckdb..."
task ingest
task build

echo ""
echo "✅ Environnement prêt !"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Commandes utiles (liste complète : task) :"
echo ""
echo "  task doctor        → Vérifie Docker, la base et Superset"
echo "  task build         → dbt build (modèles + tests)"
echo "  task duckdb        → Ouvre une copie de la base dans DuckDB"
echo "  task superset:up   → Démarre Superset : http://localhost:8089 (admin / admin)"
echo "  task docs          → Documentation et lineage (port 8088)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
