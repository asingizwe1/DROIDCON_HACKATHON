#!/usr/bin/env bash
#
# One-command dev setup for AquaFarm.
#
# Starts Typesense, creates the search-only parent key if it does not exist,
# writes server/.env, installs the API deps, seeds the collection, and starts
# the API. Then it tells you the one command left: flutter run.
#
# Safe to re-run: it reuses an existing .env and an existing search key.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

ADMIN_KEY="${TYPESENSE_ADMIN_KEY:-local-dev-key-change-me}"
TS_PORT="${TYPESENSE_PORT:-8108}"
TS_URL="http://localhost:${TS_PORT}"

# ---- 1. Typesense -----------------------------------------------------------
if curl -sf "$TS_URL/health" >/dev/null 2>&1; then
  echo "Typesense already running on $TS_PORT."
else
  echo "Starting Typesense..."
  ./scripts/run-typesense.sh >/tmp/aquafarm-typesense.log 2>&1 &
  for _ in $(seq 1 30); do
    if curl -sf "$TS_URL/health" >/dev/null 2>&1; then break; fi
    sleep 1
  done
  if ! curl -sf "$TS_URL/health" >/dev/null 2>&1; then
    echo "Typesense did not come up. See /tmp/aquafarm-typesense.log" >&2
    exit 1
  fi
  echo "Typesense is up."
fi

# ---- 2. Search-only parent key ---------------------------------------------
SEARCH_KEY="$(curl -sf "$TS_URL/keys" -H "X-TYPESENSE-API-KEY: $ADMIN_KEY" \
  | python3 -c '
import json,sys
keys = json.load(sys.stdin).get("keys", [])
for k in keys:
    if k.get("description") == "AquaFarm search-only key":
        print(k["value"]); break
' 2>/dev/null || true)"

if [ -z "$SEARCH_KEY" ]; then
  echo "Creating the search-only parent key..."
  SEARCH_KEY="$(curl -sf -X POST "$TS_URL/keys" \
    -H "X-TYPESENSE-API-KEY: $ADMIN_KEY" \
    -H "Content-Type: application/json" \
    -d '{"description":"AquaFarm search-only key","actions":["documents:search"],"collections":["inspections"]}' \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["value"])')"
fi
echo "Search-only key ready."

# ---- 3. server/.env --------------------------------------------------------
ENV_FILE="server/.env"
if [ ! -f "$ENV_FILE" ]; then
  echo "Writing $ENV_FILE..."
  cat > "$ENV_FILE" <<EOF
TYPESENSE_HOST=localhost
TYPESENSE_PORT=${TS_PORT}
TYPESENSE_PROTOCOL=http
TYPESENSE_ADMIN_KEY=${ADMIN_KEY}
TYPESENSE_SEARCH_KEY=${SEARCH_KEY}
TYPESENSE_COLLECTION=inspections
SEARCH_KEY_TTL_SECONDS=86400
PORT=8080
EOF
else
  echo "$ENV_FILE already exists; leaving it alone."
fi

# ---- 4. API deps + seed ----------------------------------------------------
if [ ! -d server/node_modules ]; then
  echo "Installing API dependencies..."
  (cd server && npm install --silent)
fi

echo "Seeding the inspections collection..."
(cd server && node seed.js)

# ---- 5. Run the API --------------------------------------------------------
echo
echo "Starting the API on http://localhost:8080 ..."
echo "In another terminal, run the app with:"
echo
echo "  flutter pub get"
echo "  flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080"
echo
cd server && exec node index.js
