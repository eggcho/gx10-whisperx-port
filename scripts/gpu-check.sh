#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="${CONTAINER_NAME:-whisperx-gx10}"

echo "[host nvidia-smi]"
nvidia-smi

echo
echo "[container runtime check]"
docker exec -i "$CONTAINER_NAME" python - <<'PY'
import ctranslate2
import torch
print("ctranslate2 cuda compute types:", ctranslate2.get_supported_compute_types("cuda"))
print("torch.cuda.is_available:", torch.cuda.is_available())
print("torch.cuda.device_count:", torch.cuda.device_count())
PY
