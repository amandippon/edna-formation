# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Pedagogical data pipeline for design students (no coding background). Students run `task` commands and explore data in Superset and DBeaver.

**Theme**: Olympic Games data (athletes, sports, competitions, results — 2016–2024).

## Commands

```bash
task pipeline        # Full pipeline: ingest + dbt:deps + dbt:run
task ingest          # PyArrow: CSV (resources/) → Parquet (processed-resources/<table>/)
task dbt:run         # dbt: Parquet → edna-sports-data.duckdb
task dbt:test        # dbt data quality tests
task documentation   # Generate and open Colibri lineage dashboard on port 8088
task superset:up     # Build and start Superset stack on port 8089
task superset:down   # Stop Superset
task superset:reset  # Wipe Superset volumes and restart
task clean           # Remove transformation/target, logs, dbt_packages, __pycache__
```

## Architecture

- **Ingestion** (`ingestion/pipeline.py`): pure PyArrow — reads every `resources/*.csv`, writes one Parquet file per table to `processed-resources/<table_name>/<table_name>.parquet`. No dlt, no cloud.
- **Transformation** (`transformation/`): dbt-duckdb reads Parquet via `read_parquet(...)` in sources, outputs to `edna-sports-data.duckdb` at the repo root.
  - `models/staging/`: one view per CSV source, no business logic
  - `models/marts/`: `dim_athletes`, `dim_competitions` (enriched dimensions) + `fct_results` (fact table joining staging only)
  - `models/reporting/`: `rpt_results` — wide denormalized table joining all marts, intended as the primary Superset dataset
- **Visualization** (`visualization/`): Superset 6.0.0 + PostgreSQL 16 + Redis 7 via Docker Compose.
  - Packages (`psycopg2-binary`, `duckdb==1.5.1`, `duckdb-engine`) are installed into the image's venv via `/app/.venv/bin/python -m ensurepip && /app/.venv/bin/python -m pip install ...` — plain `pip install` installs into system Python and is invisible to Superset.
  - The DuckDB file is copied into the container via `docker cp` (in `superset:up`) to `/app/superset_home/edna-sports-data.duckdb`. No bind mount — bind mounts don't work in Docker-outside-of-Docker devcontainers because the host path (`/workspaces/...`) doesn't exist on the Mac.
  - Superset connection: type **Other**, URI `duckdb:////app/superset_home/edna-sports-data.duckdb`.

## Dev environment

VSCode DevContainer (Python 3.12, uv, DuckDB CLI 1.5.1, Task) with Docker-outside-of-Docker. No AWS, no cloud — fully local.

`duckdb==1.5.1` is pinned in both `pyproject.toml` (dev) and `visualization/docker/Dockerfile` (container) to guarantee file format compatibility.

## Key files

- `Taskfile.yml`: all student-facing commands
- `transformation/profiles.yml`: dbt profile pointing to `../edna-sports-data.duckdb`
- `visualization/docker/Dockerfile`: Superset image — installs Python deps into `/app/.venv`
- `visualization/docker/superset_config.py`: SQLAlchemy URI, Redis cache, CSRF disabled
- `visualization/docker-compose.yml`: three-service stack (superset, db, redis); no bind mount for DuckDB
