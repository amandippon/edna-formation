"""
Pipeline d'ingestion : CSV (resources/) → Parquet (processed-resources/)
Utilise PyArrow pour lire les CSV et écrire les fichiers Parquet.
"""

import glob
import os
import time

import pyarrow.csv as pa_csv
import pyarrow.parquet as pq


RESOURCES_DIR = os.path.join(os.path.dirname(__file__), "..", "resources")
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "processed-resources")


def get_csv_files() -> list[tuple[str, str]]:
    """Retourne la liste des fichiers CSV avec leur nom de table."""
    pattern = os.path.join(RESOURCES_DIR, "*.csv")
    files = glob.glob(pattern)
    return [(os.path.splitext(os.path.basename(f))[0], f) for f in sorted(files)]


def ingest_csv(table_name: str, file_path: str) -> None:
    """Lit un fichier CSV et l'écrit en Parquet."""
    print(f"  → Lecture de {os.path.basename(file_path)}")
    table = pa_csv.read_csv(file_path)

    output_dir = os.path.join(OUTPUT_DIR, table_name)
    os.makedirs(output_dir, exist_ok=True)

    output_path = os.path.join(output_dir, f"{table_name}.parquet")
    pq.write_table(table, output_path)
    print(f"  ✓ {table.num_rows} lignes → {output_path}")


def run_pipeline():
    csv_files = get_csv_files()
    if not csv_files:
        print(f"Aucun fichier CSV trouvé dans {RESOURCES_DIR}")
        return

    print(f"Fichiers trouvés : {[name for name, _ in csv_files]}\n")

    start = time.time()
    for table_name, file_path in csv_files:
        print(f"Ingestion : {table_name}")
        ingest_csv(table_name, file_path)

    elapsed = time.time() - start
    print(f"\n✅ Ingestion terminée en {elapsed:.1f}s")
    print(f"   Parquet écrits dans : {os.path.abspath(OUTPUT_DIR)}")


if __name__ == "__main__":
    run_pipeline()
