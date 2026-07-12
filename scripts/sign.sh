#!/usr/bin/env bash
# Keyless-sign an image and attach SBOM + provenance attestations.
# Must run in CI with OIDC (GitHub Actions: permissions id-token: write).
# Usage: sign.sh <image-ref@digest> <spdx-sbom-file>
set -euo pipefail
IMAGE="${1:?image ref with digest required}"
SBOM="${2:?spdx sbom file required}"

export COSIGN_YES=true

cosign sign "${IMAGE}"
cosign attest --predicate "${SBOM}" --type spdxjson "${IMAGE}"

echo "==> verifying signature"
cosign verify \
  --certificate-identity-regexp "https://github.com/.+/.+/\.github/workflows/.+" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  "${IMAGE}" > /dev/null
echo "signature verified for ${IMAGE}"
