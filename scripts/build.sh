#!/usr/bin/env bash
set -euo pipefail

IMAGE_TAG="${IMAGE_TAG:-whisperx:gx10-cuda-portable}"

docker build -f Dockerfile -t "$IMAGE_TAG" .
echo "Built image: $IMAGE_TAG"
