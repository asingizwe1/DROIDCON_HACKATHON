#!/usr/bin/env bash
#
# Run a local Typesense server for development.
#
# Prefers Docker if it is available, because that is the route in the README.
# Falls back to the downloaded binary under .typesense/ (see
# scripts/get-typesense.sh) so the project runs on a machine without Docker.
#
# --enable-cors is required: the Flutter web build queries Typesense directly
# from the browser, and without it every search request is blocked by CORS.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ADMIN_KEY="${TYPESENSE_ADMIN_KEY:-local-dev-key-change-me}"
DATA_DIR="$ROOT/.typesense/data"
PORT="${TYPESENSE_PORT:-8108}"

if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  echo "Starting Typesense v27.1 with Docker on port $PORT..."
  exec docker run --rm --name aquafarm-typesense \
    -p "${PORT}:8108" \
    -v "$DATA_DIR:/data" \
    typesense/typesense:27.1 \
    --data-dir /data \
    --api-key="$ADMIN_KEY" \
    --enable-cors
fi

BIN="$ROOT/.typesense/typesense-server"
if [ ! -x "$BIN" ]; then
  echo "Docker is not available and no binary was found." >&2
  echo "Run ./scripts/get-typesense.sh first, or install Docker." >&2
  exit 1
fi

mkdir -p "$DATA_DIR"
echo "Starting Typesense (local binary) on port $PORT..."
exec "$BIN" \
  --data-dir "$DATA_DIR" \
  --api-key="$ADMIN_KEY" \
  --api-port="$PORT" \
  --enable-cors \
  --listen-address 0.0.0.0
