#!/usr/bin/env bash
set -euo pipefail

PORT="${PORT:-5000}"
REQUEST_FILE="${REQUEST_FILE:-request-example.json}"
OUT_DIR="${OUT_DIR:-benchmark-output}"

mkdir -p "$OUT_DIR"
jq . "$REQUEST_FILE" >/dev/null

run_parallel() {
  local n="$1"
  local run_dir="$OUT_DIR/run_${n}"
  rm -rf "$run_dir"
  mkdir -p "$run_dir"

  local start_ms
  start_ms="$(date +%s%3N)"
  pids=()

  for i in $(seq 1 "$n"); do
    (
      curl -sS \
        -H "Content-Type: application/json" \
        -H "Prefer: wait=600" \
        --data @"$REQUEST_FILE" \
        "http://127.0.0.1:${PORT}/predictions" > "$run_dir/response_${i}.json"
    ) &
    pids+=("$!")
  done

  for pid in "${pids[@]}"; do
    wait "$pid"
  done

  local end_ms total_ms succeeded
  end_ms="$(date +%s%3N)"
  total_ms=$((end_ms - start_ms))
  succeeded="$(rg -l '"status":"succeeded"' "$run_dir"/*.json 2>/dev/null | wc -l | tr -d ' ')"
  echo "parallel=${n} total_ms=${total_ms} succeeded=${succeeded}/${n}"
}

run_parallel 1
run_parallel 4
run_parallel 8
