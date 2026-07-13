#!/usr/bin/env bash
# Apply hardening to a rootfs. Mode 'micro' additionally removes the
# package manager, shells and login tooling for a minimal attack surface.
# Usage: hardening.sh <rootfs-dir> <full|micro>
set -euo pipefail

ROOTFS="${1:?rootfs dir required}"
MODE="${2:?mode required (full|micro)}"

# 1. Remove all setuid/setgid bits (privilege-escalation surface).
# Must fail loudly: a silent no-op here would void the zero-setuid guarantee.
find "${ROOTFS}" -xdev -perm /6000 -type f -exec chmod a-s {} +

# 2. Remove network tooling commonly abused post-compromise
rm -f "${ROOTFS}/usr/bin/wget" "${ROOTFS}/usr/bin/curl" \
      "${ROOTFS}/usr/bin/nc" "${ROOTFS}/usr/bin/netcat" \
      "${ROOTFS}/usr/bin/telnet"

# 3. Lock the root account (must fail loudly, see structure tests)
sed -i 's|^root:[^:]*:|root:*:|' "${ROOTFS}/etc/shadow"

if [ "${MODE}" = "micro" ]; then
  # Remove package management binaries but KEEP /var/lib/dpkg/status
  # so SBOM/CVE scanners (syft, grype, trivy) still identify packages.
  rmr() { rm -rf "${ROOTFS}${1}" 2>/dev/null || true; }

  # apt and friends
  rmr /usr/bin/apt;        rmr /usr/bin/apt-get
  rmr /usr/bin/apt-cache;  rmr /usr/bin/apt-config
  rmr /usr/bin/apt-key;    rmr /usr/bin/apt-mark
  rmr /usr/lib/apt;        rmr /etc/apt
  rmr /var/cache/apt;      rmr /var/lib/apt

  # dpkg binaries (package database is preserved)
  for b in dpkg dpkg-deb dpkg-divert dpkg-query dpkg-split dpkg-statoverride \
           dpkg-trigger dpkg-maintscript-helper update-alternatives; do
    rmr "/usr/bin/${b}"
  done
  # Keep info/*.list: scanners need file-ownership data to tie binaries
  # (e.g. /usr/bin/openssl) to their owning deb — without it grype's
  # binary classifier matches against upstream releases and reports
  # false "fixable" CVEs that Debian has already patched or won't ship.
  find "${ROOTFS}/var/lib/dpkg/info" -type f ! -name '*.list' -delete
  rmr /var/lib/dpkg/updates
  rmr /var/lib/dpkg/triggers
  rmr /usr/share/dpkg

  # shells & interactive login tooling
  for b in bash sh dash login su chsh chfn passwd; do
    rmr "/usr/bin/${b}"; rmr "/bin/${b}"; rmr "/usr/sbin/${b}"
  done
  rmr /etc/skel

  # perl-base is only needed by dpkg tooling we just removed
  rmr /usr/bin/perl
  # the * must stay unquoted so it expands under the rootfs, not literally
  rm -rf "${ROOTFS}"/usr/lib/*/perl-base
fi

echo "hardening (${MODE}) applied: $(du -sh "${ROOTFS}" | cut -f1)"
