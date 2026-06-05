#!/usr/bin/env bash
# Compiles the CUDA gust-tile kernel into a shared library.
#
# Usage:
#   ./build.sh              # defaults to sm_86 (RTX 3060 / Ampere)
#   CUDA_ARCH=sm_75 ./build.sh  # override for other GPUs
#
# Output: libgust_tile_gpu.so next to this script.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARCH="${CUDA_ARCH:-sm_86}"

cd "$SCRIPT_DIR"
nvcc -arch="${ARCH}" -shared -fPIC -O3 -o libgust_tile_gpu.so gust_tile.cu
echo "Built: ${SCRIPT_DIR}/libgust_tile_gpu.so  (arch=${ARCH})"
