#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <path-to-local-media-file> [port]" >&2
  exit 1
fi

FILE_PATH="$1"
PORT="${2:-5000}"
OUT_DIR="${OUT_DIR:-smoke-output}"
FILE_SERVER_NAME="${FILE_SERVER_NAME:-whisperx-local-file-server}"
FILE_SERVER_PORT="${FILE_SERVER_PORT:-8008}"
BASENAME="$(basename "$FILE_PATH")"
REQUEST_FILE="$OUT_DIR/local-request.json"
OUT_FILE="$OUT_DIR/local-response-$(date +%s).json"

if [[ ! -f "$FILE_PATH" ]]; then
  echo "File not found: $FILE_PATH" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

docker rm -f "$FILE_SERVER_NAME" >/dev/null 2>&1 || true
docker run -d \
  --name "$FILE_SERVER_NAME" \
  -v "$(realpath "$FILE_PATH"):/srv/$BASENAME:ro" \
  -w /srv \
  -p "$FILE_SERVER_PORT":8008 \
  python:3.12-slim python -m http.server 8008 >/dev/null

cat > "$REQUEST_FILE" <<JSON
{
  "input": {
    "audio_file": "http://host.docker.internal:${FILE_SERVER_PORT}/${BASENAME}",
    "language": null,
    "language_detection_min_prob": 0,
    "language_detection_max_tries": 5,
    "initial_prompt": null,
    "batch_size": 64,
    "temperature": 0,
    "vad_onset": 0.5,
    "vad_offset": 0.363,
    "align_output": false,
    "diarization": false,
    "huggingface_access_token": null,
    "min_speakers": null,
    "max_speakers": null,
    "debug": true
  }
}
JSON

curl -sS \
  -H "Content-Type: application/json" \
  -H "Prefer: wait=600" \
  --data @"$REQUEST_FILE" \
  "http://127.0.0.1:${PORT}/predictions" | tee "$OUT_FILE"

echo
echo "Saved request: $REQUEST_FILE"
echo "Saved response: $OUT_FILE"
