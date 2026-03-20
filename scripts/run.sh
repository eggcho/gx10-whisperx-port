#!/usr/bin/env bash
set -euo pipefail

IMAGE_TAG="${IMAGE_TAG:-whisperx:gx10-cuda-portable}"
CONTAINER_NAME="${CONTAINER_NAME:-whisperx-gx10}"
PORT="${PORT:-5000}"

if [[ "${1:-}" == "--no-build" ]]; then
  :
else
  ./scripts/build.sh
fi

docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
docker run -d \
  --name "$CONTAINER_NAME" \
  --gpus all \
  --add-host=host.docker.internal:host-gateway \
  -p "$PORT":5000 \
  "$IMAGE_TAG" \
  "python -m cog.server.http" >/dev/null

echo "Started container: $CONTAINER_NAME on http://127.0.0.1:$PORT"
