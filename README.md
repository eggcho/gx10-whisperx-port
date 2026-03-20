# WhisperX GX10 Portable Container Bundle

Self-contained folder for rebuilding and running the WhisperX service on NVIDIA GX ARM64 machines.

## Included

- `Dockerfile`: CUDA-enabled ARM64 build (CTranslate2 built from source with CUDA)
- `requirements.txt`: pinned Python dependencies
- `predict.py`: runtime patch preserving original API while handling ARM64 CUDA limitations
- `src/`: original service source and baked model files (`faster-whisper-large-v3` + VAD model)
- `request-example.json`: ready request body for `/predictions`
- `scripts/`: build/run/stop/smoke/local-file/benchmark/GPU-check scripts
- `.gitattributes`: preconfigured Git LFS tracking for the large model binaries

## Prerequisites on target GX machine

- Ubuntu + Docker Engine (with NVIDIA runtime support)
- NVIDIA driver installed and GPU visible (`nvidia-smi` works)
- Internet access for package install and source build during `docker build`

## Recreate image on another GX machine

1. Copy this folder to target machine.
2. Open terminal in this folder.
3. Build image:

```bash
./scripts/build.sh
```

Default tag is `whisperx:gx10-cuda-portable`.

## Run service

```bash
./scripts/run.sh --no-build
```

Service endpoint:
- `http://127.0.0.1:5000/predictions`
- `http://127.0.0.1:5000/health-check`

Stop service:

```bash
./scripts/stop.sh
```

## Smoke test (example URL payload)

```bash
./scripts/smoke.sh
```

Output JSON is written to `smoke-output/run-<timestamp>.json`.

## Test with local `.mp3` / `.mp4`

```bash
./scripts/test-local-file.sh /absolute/path/to/file.mp4
```

What it does:
- starts temporary file server container on port `8008`
- sends `/predictions` request with `audio_file` set to `http://host.docker.internal:8008/<filename>`
- stores request and response in `smoke-output/`

## Benchmark 1 / 4 / 8 parallel requests

```bash
./scripts/benchmark.sh
```

Outputs:
- `benchmark-output/run_1/*.json`
- `benchmark-output/run_4/*.json`
- `benchmark-output/run_8/*.json`

## Check GPU usage and runtime backends

```bash
./scripts/gpu-check.sh
```

Expected behavior on GX10:
- CTranslate2 reports CUDA compute types (GPU path active for transcription)
- `torch.cuda.is_available` is `False` (PyTorch parts on CPU due missing ARM64 CUDA wheels)

## Notes on feature behavior

- `/predictions` API contract is preserved.
- Current real workload (`diarization=false`, `align_output=false`) follows the original flow.
- Optional PyTorch-heavy features remain available but run on CPU on ARM64.

## Publish to Docker Hub (optional)

```bash
docker login -u YOUR_DOCKERHUB_USER
docker tag whisperx:gx10-cuda-portable YOUR_DOCKERHUB_USER/whisperx-gx10:gx10-cuda-v1
docker push YOUR_DOCKERHUB_USER/whisperx-gx10:gx10-cuda-v1
docker tag whisperx:gx10-cuda-portable YOUR_DOCKERHUB_USER/whisperx-gx10:latest
docker push YOUR_DOCKERHUB_USER/whisperx-gx10:latest
```

## Preparing for GitHub

- Install Git LFS locally (`git lfs install`) before `git add` so that `src/models/**` are pushed via LFS (each file is >100 MB).
- Initialize and push:

```bash
cd github/whisperx-gx10
git init
git lfs install
git add .
git commit -m "WhisperX GX10 portable container"
git remote add origin git@github.com:YOUR_USER/YOUR_REPO.git
git push -u origin main
```
