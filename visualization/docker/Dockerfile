FROM apache/superset:6.0.0

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN /app/.venv/bin/python -m ensurepip && \
    /app/.venv/bin/python -m pip install --no-cache-dir \
    "psycopg2-binary==2.9.13" \
    "duckdb==1.5.1" \
    "duckdb-engine==0.17.0"

COPY superset_config.py /app/pythonpath/superset_config.py

USER superset

HEALTHCHECK --interval=30s --timeout=10s --retries=5 \
    CMD curl -f http://localhost:8088/health || exit 1