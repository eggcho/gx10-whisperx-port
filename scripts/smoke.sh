#!/usr/bin/env bash
set -euo pipefail

PORT="${PORT:-5000}"
REQUEST_FILE="${REQUEST_FILE:-request-example.json}"
OUT_DIR="${OUT_DIR:-smoke-output}"
OUT_FILE="$OUT_DIR/run-$(date +%s).json"

mkdir -p "$OUT_DIR"
jq . "$REQUEST_FILE" >/dev/null

for _ in $(seq 1 120); do
  if curl -fsS "http://127.0.0.1:${PORT}/health-check" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

curl -sS \
  -H "Content-Type: application/json" \
  -H "Prefer: wait=600" \
  --data @"$REQUEST_FILE" \
  "http://127.0.0.1:${PORT}/predictions" | tee "$OUT_FILE"

echo
echo "Saved: $OUT_FILE"
