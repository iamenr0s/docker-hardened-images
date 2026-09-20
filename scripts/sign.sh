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
# Registries can lag briefly before a just-pushed signature is listable
# ("no signatures found"), so retry before failing.
for attempt in 1 2 3 4 5; do
  cosign verify \
    --certificate-identity-regexp "https://github.com/.+/.+/\.github/workflows/.+" \
    --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
    "${IMAGE}" > /dev/null && break
  [ "${attempt}" -eq 5 ] && exit 1
  sleep $((attempt * 5))
done
echo "signature verified for ${IMAGE}"
