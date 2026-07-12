# Verifying published images

All images are signed keylessly (Sigstore/Fulcio) from GitHub Actions.

    cosign verify \
      --certificate-identity-regexp 'https://github.com/YOURORG/hardened-images/\.github/workflows/.+' \
      --certificate-oidc-issuer 'https://token.actions.githubusercontent.com' \
      docker.io/YOURORG/debian-hardened:12

Download and inspect the attached SBOM attestation:

    cosign verify-attestation --type spdxjson \
      --certificate-identity-regexp 'https://github.com/YOURORG/hardened-images/\.github/workflows/.+' \
      --certificate-oidc-issuer 'https://token.actions.githubusercontent.com' \
      docker.io/YOURORG/debian-hardened:12 | jq -r .payload | base64 -d | jq .predicate
