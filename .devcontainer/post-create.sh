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

echo ""
echo "✅ Environnement prêt !"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Commandes disponibles (lance avec 'task') :"
echo ""
echo "  task pipeline      → Pipeline complet"
echo "  task ingest        → Ingestion CSV → Parquet"
echo "  task dbt:run       → Transformation des données"
echo "  task dbt:test      → Tests qualité"
echo "  task superset:up   → Démarrer Superset (port 8089)"
echo "  task superset:down → Arrêter Superset"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
