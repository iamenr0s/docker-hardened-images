#!/usr/bin/env bash
# Build (and optionally push) a hardened image with docker buildx.
# Usage: build.sh <distro> <version> <flavor> [--push]
# Env:   REGISTRIES  space-separated repo prefixes
#        PLATFORMS   default linux/amd64,linux/arm64
set -euo pipefail

DISTRO="${1:?distro required (e.g. debian)}"
VERSION="${2:?version required (e.g. 12)}"
FLAVOR="${3:?flavor required (full|micro)}"
PUSH_FLAG="${4:-}"

REGISTRIES="${REGISTRIES:-docker.io/CHANGEME/${DISTRO}-hardened quay.io/CHANGEME/${DISTRO}-hardened}"
PLATFORMS="${PLATFORMS:-linux/amd64,linux/arm64}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=/dev/null
source "${ROOT}/images/${DISTRO}/${VERSION}/env"

TAG_ARGS=()
# shellcheck disable=SC2086  # REGISTRIES is intentionally space-separated
for REG in ${REGISTRIES}; do
  TAG_ARGS+=(--tag "${REG}:${VERSION}-${FLAVOR}")
  if [ "${FLAVOR}" = "micro" ]; then
    TAG_ARGS+=(--tag "${REG}:${VERSION}")
    # shellcheck disable=SC2086  # EXTRA_TAGS is intentionally space-separated
    for T in ${EXTRA_TAGS:-}; do TAG_ARGS+=(--tag "${REG}:${T}"); done
  fi
done

OUTPUT="--load"
[ "${PUSH_FLAG}" = "--push" ] && OUTPUT="--push"
# --load cannot handle multi-platform; restrict to host arch for local builds
[ "${OUTPUT}" = "--load" ] && PLATFORMS="linux/$(docker version -f '{{.Server.Arch}}')"

# shellcheck disable=SC2086  # OUTPUT is a single flag, intentionally unquoted
docker buildx build \
  --platform "${PLATFORMS}" \
  --target "${FLAVOR}" \
  --build-arg SUITE="${SUITE}" \
  --build-arg SNAPSHOT="${SNAPSHOT:-}" \
  --provenance=mode=max \
  --sbom=false \
  "${TAG_ARGS[@]}" \
  ${OUTPUT} \
  --file "${ROOT}/images/${DISTRO}/Dockerfile" \
  "${ROOT}/images"
