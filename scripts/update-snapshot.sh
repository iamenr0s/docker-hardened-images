#!/usr/bin/env bash
# Bump the pinned snapshot timestamp in every env file that declares one.
# Debian (snapshot.debian.org) and Ubuntu (snapshot.ubuntu.com) both resolve
# any timestamp to the nearest earlier snapshot, so "yesterday at midnight
# UTC" is always safe and fully mirrored on either service.
# RPM-family env files (fedora/almalinux/rockylinux) have no SNAPSHOT= key
# at all (no historical pin, see images/common/build-rootfs-rpm.sh) and are
# skipped automatically — no distro-specific branching needed here.
set -euo pipefail

NEW="${1:-$(date -u -d 'yesterday' +%Y%m%dT000000Z)}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

CHANGED=0
for ENVFILE in "${ROOT}"/images/*/*/env; do
  grep -q '^SNAPSHOT=' "${ENVFILE}" || continue
  OLD=$(grep -oP '^SNAPSHOT=\K.*' "${ENVFILE}")
  if [ "${OLD}" != "${NEW}" ]; then
    sed -i "s/^SNAPSHOT=.*/SNAPSHOT=${NEW}/" "${ENVFILE}"
    echo "${ENVFILE}: ${OLD} -> ${NEW}"
    CHANGED=1
  fi
done

[ "${CHANGED}" = "1" ] || echo "already at ${NEW}"
