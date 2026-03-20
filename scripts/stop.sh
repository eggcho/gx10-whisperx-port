#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="${CONTAINER_NAME:-whisperx-gx10}"
docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
echo "Stopped container: $CONTAINER_NAME"
