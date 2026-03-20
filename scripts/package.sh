#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="${OUT_DIR:-$ROOT_DIR/../artifacts}"
ARCHIVE_NAME="${ARCHIVE_NAME:-gx10-whisperx-container-$(date +%Y%m%d-%H%M%S).tar.gz}"

mkdir -p "$OUT_DIR"
tar -C "$ROOT_DIR" -czf "$OUT_DIR/$ARCHIVE_NAME" .

echo "Created archive: $OUT_DIR/$ARCHIVE_NAME"
