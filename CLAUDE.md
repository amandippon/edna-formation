# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) and other AI assistants when working with code in this repository.

## Project

Local, hands-on data pipeline used for workshops (originally a course for design students, now also a 3-hour meetup workshop for data/dev profiles). Participants work individually: SQL on Parquet, then three dbt missions (one per layer, on dedicated git branches, against pre-written tests), lineage, then a Superset dashboard on their own Gold table. Everything is driven by `task` commands.

**Theme**: NCAA Women's Basketball (Kaggle 2019): teams, seasons, regular season games 1998-2019, NCAA tournament 1998-2018. Box scores and game cities only from season 2010.

User-facing docs are in French: `README.md` (setup), `docs/prerequis.md` (to send before the workshop), `atelier/README.md` (exercise guide) and `atelier/donnees.md` (reporting tables, pitfalls, dashboard ideas). Keep them in sync with the code.

## Commands

```bash
task ingest            # PyArrow: resources/*.csv -> processed-resources/<table>/<table>.parquet
task build             # dbt build (models + tests) -> edna-sports-data.duckdb; prints a hint and exits 1 on failure
task docs              # dbt docs generate + colibri generate, then serves colibri-docs/ on port 8088
task sql               # copy the DB to /tmp and open it in the DuckDB CLI (never locks the real file)
task step N=2          # workshop: stash local work, switch to branch atelier/etape-N-..., rebuild the DB
task topic NAME=domicile  # workshop mission 3 option B: copy a free-topic skeleton (domicile|tirs-3pts|upsets)
task superset:up       # build + start Superset on host port 8089, copy the DB, create admin, register the DB connection
task superset:sync     # docker cp of the DB into the running Superset container + flush the Redis chart cache
task superset:down     # stop Superset (volumes kept)
task doctor            # check Docker, DuckDB file, Superset /health
```

The Taskfile is deliberately short. Anything else uses the underlying tools directly: `cd transformation && uv run dbt ...`, `docker logs -f superset`, `docker compose -f visualization/docker-compose.yml down -v` (wipe Superset), `git restore transformation/` (undo workshop edits).

There is no `dbt deps` step: the project has no dbt packages.

## Architecture

- **Ingestion** (`ingestion/pipeline.py`): pure PyArrow. Reads every `resources/*.csv`, writes one Parquet file per table to `processed-resources/<table_name>/<table_name>.parquet`.
- **Transformation** (`transformation/`): dbt-duckdb, output `edna-sports-data.duckdb` at the repo root (`profiles.yml` path `../edna-sports-data.duckdb`, so dbt must run from `transformation/`; the Taskfile handles it).
  - `macros/generate_schema_name.sql`: custom schemas are used as-is, so schemas are `staging`, `marts`, `reporting` (no `main_` prefix).
  - `models/staging/` (schema `staging`, **materialized as tables**): one `stg_*` per CSV, reads Parquet with `read_parquet('../processed-resources/...')`, renames to snake_case, no business logic. Tables, not views, because the relative Parquet path breaks when the DB is opened from elsewhere (Superset, DBeaver, repo root).
  - Layering rule: reporting models only `ref()` marts, never staging.
  - `models/marts/` (schema `marts`, tables): `dim_teams` (team_state inferred from home games, 2010+), `dim_seasons`, `dim_cities`, `dim_tourney_seeds` (one row per season and seeded team, with bracket region name), `fct_regular_season_games`, `fct_tourney_games` (winner/loser format, game_id, game_date, box score, seeds and upsets for tournament).
  - `models/reporting/` (schema `reporting`, tables): wide, denormalized tables meant as Superset datasets:
    - `rpt_team_games`: one row per team per game (regular + tournament), team point of view, signed `pt_diff`, `team_location`, seeds, upset flags, team box score + a few opponent stats. PK `team_game_id`. Most flexible table.
    - `rpt_games`: one row per game, winner/loser names, city/state, upset label.
    - `rpt_team_season_stats`: one row per team per regular season.
    - `rpt_tourney_runs`: one row per team per tournament, `tournament_result`, `is_champion`.
  - `models/reporting/examples/`: `rpt_uconn_tennessee_*` (5 models, schema `reporting`), example of "one business question = one model". Documented in `_examples_models.yml`.
- **Visualization** (`visualization/`): Superset 6.0.0 + PostgreSQL 16 + Redis 7 via Docker Compose, host port 8089 -> container 8088.
  - Python packages (`psycopg2-binary`, `duckdb==1.5.1`, `duckdb-engine`) are installed into the image venv with `/app/.venv/bin/python -m ensurepip && /app/.venv/bin/python -m pip install ...`. A plain `pip install` goes to system Python and is invisible to Superset.
  - The DuckDB file is copied with `docker cp` to `/app/superset_home/edna-sports-data.duckdb` (in `superset:up` and `superset:sync`). No bind mount: with Docker-outside-of-Docker, the devcontainer path (`/workspaces/...`) does not exist on the host.
  - `superset:up` registers the connection automatically: `superset set-database-uri -d "NCAA Basketball (DuckDB)" -u "duckdb:////app/superset_home/edna-sports-data.duckdb?access_mode=read_only"`. Read-only so several processes can open the file.
  - The Superset schema dropdown shows schemas as `"edna-sports-data".reporting` (catalog prefix from the file name); datasets created on `reporting` also work.

## Workshop (`atelier/` and `atelier/etape-*` branches)

- Step branches, each created from the final state by removing what comes later and replacing the mission model by a skeleton:
  - `atelier/etape-1-bronze`: staging only; `stg_tourney_seeds.sql` is a skeleton.
  - `atelier/etape-2-silver`: staging + `dim_teams`, `dim_seasons`, `dim_cities`, `fct_regular_season_games`; `dim_tourney_seeds.sql` is a skeleton (`fct_tourney_games` and reporting are absent because they depend on it).
  - `atelier/etape-3-gold`: everything; `rpt_tourney_runs.sql` is a skeleton.
  - `atelier/etape-4-solution`: the complete project.
  The solution of mission N is the file in step N+1. YAML entries of absent models are removed on each branch. When the final project changes, rebuild the step branches.
- Skeletons compile and return NULL placeholders, so generic tests (YAML) and the singular tests in `transformation/tests/missions/` fail until the mission is done. Every mission test passes on the final project.
- `atelier/sujets/<sujet>/`: free-topic skeleton + YAML + singular test for mission 3 option B, copied by `task topic` to `transformation/models/reporting/atelier/` and `transformation/tests/atelier/` (both git-ignored). Solutions in `atelier/solutions/`; `ex1.sql` is the SQL warm-up.
- DuckDB locks the file for any open connection, even read-only: an open DuckDB CLI or DBeaver session makes `dbt` fail with `Could not set lock on file`. `task sql` works on a copy for that reason.

## Adding a reporting model

1. Create `transformation/models/reporting/rpt_<topic>.sql` (snake_case, `rpt_` prefix). Build from `marts` (or other `reporting` models) with `{{ ref('...') }}`, never from Parquet directly. Use CTEs (`with ... as (...) select * from final`), like existing models.
2. Document it in a YAML file in the same folder (`_reporting_models.yml` or a new `_<topic>_models.yml`): model description in French, every column described, tests on keys. dbt 1.11 syntax for generic tests with arguments:

   ```yaml
   - name: game_type
     data_tests:
       - not_null
       - accepted_values:
           arguments:
             values: ['Regular', 'Tournament']
   ```

3. Run `task build`, then `task superset:sync` if Superset is running (it also flushes the Redis chart cache). In Superset: Datasets > + Dataset for a new table, or Edit dataset > Sync columns from source for a changed one.
4. Keep data coverage in mind: box score and cities only from 2010, tournament until 2018, seeds null for regular season.

## Dev environment

VS Code devcontainer (`.devcontainer/`: Python 3.12, uv, DuckDB CLI 1.5.1, Task) with Docker-outside-of-Docker. `post-create.sh` runs `uv sync --no-install-project`, `task ingest` and `task build`, so the DB exists when the container opens. Only port 8088 (Colibri) is forwarded; Superset runs on the host Docker and is reached at http://localhost:8089 from the host browser. Fully local, no cloud.

DuckDB 1.5.1 is locked in `uv.lock` and pinned in `visualization/docker/Dockerfile` to guarantee file format compatibility between dbt and Superset. Python is constrained to `>=3.12,<3.13` in `pyproject.toml`; dev dependencies are in `[dependency-groups]`.

## Key files

- `Taskfile.yml`: all user-facing commands
- `transformation/dbt_project.yml`: materializations and schemas per folder
- `transformation/profiles.yml`: dbt profile pointing to `../edna-sports-data.duckdb`
- `transformation/macros/generate_schema_name.sql`: schema naming without prefix
- `visualization/docker/Dockerfile`: Superset image, installs Python deps into `/app/.venv`
- `visualization/docker/superset_config.py`: metadata DB URI, Redis cache, CSRF disabled
- `visualization/docker-compose.yml`: superset, db, redis; no bind mount for DuckDB
- `colibri-docs/`: generated column-level lineage (`task docs`), committed
- `atelier/`: workshop guide, skeletons, tests and solutions (French)
- `docs/prerequis.md`: pre-workshop setup (French)
