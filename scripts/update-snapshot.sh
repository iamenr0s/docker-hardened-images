#!/usr/bin/env bash
# Bump the pinned snapshot.debian.org timestamp in all Debian env files.
# snapshot.debian.org resolves any timestamp to the nearest earlier snapshot,
# so "yesterday at midnight UTC" is always safe and fully mirrored.
set -euo pipefail

NEW="${1:-$(date -u -d 'yesterday' +%Y%m%dT000000Z)}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

CHANGED=0
for ENVFILE in "${ROOT}"/images/debian/*/env; do
  OLD=$(grep -oP '^SNAPSHOT=\K.*' "${ENVFILE}")
  if [ "${OLD}" != "${NEW}" ]; then
    sed -i "s/^SNAPSHOT=.*/SNAPSHOT=${NEW}/" "${ENVFILE}"
    echo "${ENVFILE}: ${OLD} -> ${NEW}"
    CHANGED=1
  fi
done

[ "${CHANGED}" = "1" ] || echo "already at ${NEW}"
