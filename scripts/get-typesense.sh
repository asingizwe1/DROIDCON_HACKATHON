#!/usr/bin/env bash
#
# Download the Typesense server binary for this machine.
#
# Why a script and not the binary itself: typesense-server is about 325 MB,
# and GitHub rejects any file over 100 MB. Committing a release binary would
# also go stale and bloat every clone. This fetches the exact version the
# project was built and tested against, verifies it with a checksum, and puts
# it where docker-compose.yml and run-local.sh expect to find it.
#
# Usage: ./scripts/get-typesense.sh [version]
set -euo pipefail

VERSION="${1:-27.1}"
DEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/.typesense"
BIN="$DEST_DIR/typesense-server"

if [ -x "$BIN" ]; then
  echo "Typesense binary already present: $BIN"
  "$BIN" --version || true
  exit 0
fi

case "$(uname -s)" in
  Linux)  OS=linux ;;
  Darwin) OS=darwin ;;
  *) echo "Unsupported OS: $(uname -s). Use Docker instead (see README)." >&2; exit 1 ;;
esac

case "$(uname -m)" in
  x86_64|amd64) ARCH=amd64 ;;
  arm64|aarch64) ARCH=arm64 ;;
  *) echo "Unsupported CPU: $(uname -m)." >&2; exit 1 ;;
esac

NAME="typesense-server-${VERSION}-${OS}-${ARCH}.tar.gz"
URL="https://dl.typesense.org/releases/${VERSION}/${NAME}"

mkdir -p "$DEST_DIR"
echo "Downloading Typesense v${VERSION} (${OS}/${ARCH})..."
echo "  $URL"
curl -fL --retry 3 -o "$DEST_DIR/$NAME" "$URL"

echo "Extracting..."
tar -xzf "$DEST_DIR/$NAME" -C "$DEST_DIR"
chmod +x "$BIN"
rm -f "$DEST_DIR/$NAME"

echo
echo "Done: $BIN"
"$BIN" --version || true
echo
echo "Start it with:"
echo "  ./scripts/run-typesense.sh"
