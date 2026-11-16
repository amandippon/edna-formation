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

# Node.js 22 (copié depuis l'image officielle), nécessaire aux CLI d'agents IA
COPY --from=node:22-bookworm-slim /usr/local/bin/node /usr/local/bin/node
COPY --from=node:22-bookworm-slim /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln -s ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx \
    && node --version && npm --version

# Agents IA en ligne de commande : Claude Code (claude) et Codex (codex)
RUN npm install -g @anthropic-ai/claude-code @openai/codex \
    && claude --version && codex --version

# Dossiers de config des agents, montés en volumes nommés (login conservé au rebuild).
# Créés ici pour que les volumes neufs appartiennent à vscode et non à root.
RUN mkdir -p /home/vscode/.claude /home/vscode/.codex \
    && chown -R vscode:vscode /home/vscode/.claude /home/vscode/.codex
