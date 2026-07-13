#!/usr/bin/env bash
# Scan an image with grype and trivy. Fails on fixable High/Critical.
# Usage: scan.sh <image-ref> [sbom-file]
set -euo pipefail
IMAGE="${1:?image ref required}"
SBOM="${2:-}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> grype"
TARGET="${IMAGE}"
[ -n "${SBOM}" ] && TARGET="sbom:${SBOM}"
grype "${TARGET}" \
  --config "${ROOT}/policies/grype.yaml" \
  --fail-on high \
  --only-fixed

echo "==> trivy"
trivy image \
  --config "${ROOT}/policies/trivy.yaml" \
  --severity HIGH,CRITICAL \
  --ignore-unfixed \
  --exit-code 1 \
  --scanners vuln,secret \
  "${IMAGE}"

echo "==> scan passed: no fixable HIGH/CRITICAL vulnerabilities"
