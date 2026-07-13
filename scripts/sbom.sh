#!/usr/bin/env bash
# Generate SBOMs (SPDX + CycloneDX) for an image ref using syft.
# Usage: sbom.sh <image-ref> <output-dir>
set -euo pipefail
IMAGE="${1:?image ref required}"
OUT="${2:-sbom}"
mkdir -p "${OUT}"
SAFE="$(echo "${IMAGE}" | tr '/:' '__')"
syft "${IMAGE}" -o spdx-json="${OUT}/${SAFE}.spdx.json"
syft "${IMAGE}" -o cyclonedx-json="${OUT}/${SAFE}.cdx.json"
echo "SBOMs written to ${OUT}/"
