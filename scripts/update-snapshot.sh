#!/usr/bin/env bash
# Bump the pinned snapshot timestamp in every env file that already has one.
# snapshot.debian.org resolves any timestamp to the nearest earlier snapshot,
# so "yesterday at midnight UTC" is always safe and fully mirrored.
# An EMPTY SNAPSHOT= is a deliberate opt-out (live mirrors) and is never
# filled in here: Ubuntu ships SNAPSHOT= empty because snapshot.ubuntu.com
# has no ubuntu-ports tree (arm64 returns 401), so pinning breaks the
# multi-arch build. RPM-family env files (fedora/almalinux/rockylinux) have
# no SNAPSHOT= key at all and are skipped automatically.
set -euo pipefail

NEW="${1:-$(date -u -d 'yesterday' +%Y%m%dT000000Z)}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

CHANGED=0
for ENVFILE in "${ROOT}"/images/*/*/env; do
  grep -q '^SNAPSHOT=' "${ENVFILE}" || continue
  OLD=$(grep -oP '^SNAPSHOT=\K.*' "${ENVFILE}")
  [ -n "${OLD}" ] || continue  # empty pin = deliberately live, leave it alone
  if [ "${OLD}" != "${NEW}" ]; then
    sed -i "s/^SNAPSHOT=.*/SNAPSHOT=${NEW}/" "${ENVFILE}"
    echo "${ENVFILE}: ${OLD} -> ${NEW}"
    CHANGED=1
  fi
done

[ "${CHANGED}" = "1" ] || echo "already at ${NEW}"
