FROM mcr.microsoft.com/devcontainers/python:3.12-bookworm

ENV UV_LINK_MODE=copy \
    UV_COMPILE_BYTECODE=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install uv (system-wide so all users including vscode can use it)
RUN curl -LsSf https://astral.sh/uv/install.sh | UV_INSTALL_DIR=/usr/local/bin sh

# Install DuckDB CLI
# (le script installe dans ~/.duckdb/cli/<version>/ sans toucher au PATH : on copie le binaire dans /usr/local/bin)
RUN curl https://install.duckdb.org | DUCKDB_VERSION=1.5.1 sh \
    && install -m 755 "$(find /root/.duckdb/cli -name duckdb -type f | head -n 1)" /usr/local/bin/duckdb \
    && duckdb --version

# Install Task runner
RUN sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin
