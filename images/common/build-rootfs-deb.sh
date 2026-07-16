#!/usr/bin/env bash
# Build a minimal deb-family (Debian or Ubuntu) rootfs with debootstrap
# (minbase variant). If SNAPSHOT is provided, the build is fully pinned to
# a snapshot mirror (reproducible: same inputs -> same package set).
# Usage: build-rootfs-deb.sh <rootfs-dir> <debian|ubuntu> <suite> <keyring-path> [snapshot-timestamp]
set -euo pipefail

ROOTFS="${1:?rootfs dir required}"
DISTRO="${2:?distro required (debian|ubuntu)}"
SUITE="${3:?suite required (e.g. bookworm, noble)}"
KEYRING="${4:?keyring path required}"
SNAPSHOT="${5:-}"

case "${DISTRO}" in
  debian)
    if [ -n "${SNAPSHOT}" ]; then
      MIRROR="https://snapshot.debian.org/archive/debian/${SNAPSHOT}"
      SEC_MIRROR="https://snapshot.debian.org/archive/debian-security/${SNAPSHOT}"
    else
      MIRROR="http://deb.debian.org/debian"
      SEC_MIRROR="http://security.debian.org/debian-security"
    fi
    ;;
  ubuntu)
    # Ubuntu splits the live archive by architecture (amd64/i386 vs
    # everything else), unlike Debian's single deb.debian.org host.
    ARCH="$(dpkg --print-architecture)"
    case "${ARCH}" in
      amd64|i386) LIVE_HOST="archive.ubuntu.com" ;;
      *)          LIVE_HOST="ports.ubuntu.com" ;;
    esac
    if [ -n "${SNAPSHOT}" ]; then
      # snapshot.ubuntu.com serves one unified archive tree (security
      # updates land in the same repo as main on Ubuntu, unlike Debian).
      MIRROR="https://snapshot.ubuntu.com/ubuntu/${SNAPSHOT}"
    else
      MIRROR="http://${LIVE_HOST}/ubuntu"
    fi
    SEC_MIRROR="${MIRROR}"
    ;;
  *)
    echo "unsupported distro: ${DISTRO}" >&2
    exit 1
    ;;
esac

# snapshot Release files carry an expired Valid-Until by design; the archive
# signatures themselves are the originals and still verify, so GPG stays ON.
[ -n "${SNAPSHOT}" ] && export DEBOOTSTRAP_CHECK_VALID_UNTIL=no

debootstrap \
  --variant=minbase \
  --include=ca-certificates,tzdata,netbase \
  --components=main \
  --keyring="${KEYRING}" \
  "${SUITE}" "${ROOTFS}" "${MIRROR}"

# --- apt sources inside the rootfs (archive + security, pinned if SNAPSHOT) ---
OPTS=""
[ -n "${SNAPSHOT}" ] && OPTS="[check-valid-until=no]"
cat > "${ROOTFS}/etc/apt/sources.list" << SRC
deb ${OPTS} ${MIRROR} ${SUITE} main
deb ${OPTS} ${SEC_MIRROR} ${SUITE}-security main
deb ${OPTS} ${MIRROR} ${SUITE}-updates main
SRC

# --- Reduce future footprint: never install docs/locales again ---
mkdir -p "${ROOTFS}/etc/dpkg/dpkg.cfg.d"
cat > "${ROOTFS}/etc/dpkg/dpkg.cfg.d/01-nodoc" << 'CFG'
path-exclude /usr/share/doc/*
path-include /usr/share/doc/*/copyright
path-exclude /usr/share/man/*
path-exclude /usr/share/info/*
path-exclude /usr/share/locale/*
path-include /usr/share/locale/locale.alias
path-exclude /usr/share/lintian/*
CFG

mkdir -p "${ROOTFS}/etc/apt/apt.conf.d"
cat > "${ROOTFS}/etc/apt/apt.conf.d/01-hardened" << 'CFG'
APT::Install-Recommends "false";
APT::Install-Suggests "false";
APT::Get::AutomaticRemove "true";
Acquire::Languages "none";
CFG

# --- Strip content already installed by debootstrap ---
rm -rf "${ROOTFS}/usr/share/doc/"* \
       "${ROOTFS}/usr/share/man/"* \
       "${ROOTFS}/usr/share/info/"* \
       "${ROOTFS}/usr/share/lintian" \
       "${ROOTFS}/var/cache/apt/"* \
       "${ROOTFS}/var/lib/apt/lists/"* \
       "${ROOTFS}/var/log/"* \
       "${ROOTFS}/tmp/"* 2>/dev/null || true

find "${ROOTFS}/usr/share/locale" -mindepth 1 -maxdepth 1 \
  ! -name 'locale.alias' -exec rm -rf {} + 2>/dev/null || true

# --- Non-root user (matches distroless convention) ---
echo 'nonroot:x:65532:65532:nonroot:/home/nonroot:/usr/sbin/nologin' >> "${ROOTFS}/etc/passwd"
echo 'nonroot:x:65532:' >> "${ROOTFS}/etc/group"
mkdir -p "${ROOTFS}/home/nonroot"
chown 65532:65532 "${ROOTFS}/home/nonroot"

# --- Reproducibility / privacy ---
: > "${ROOTFS}/etc/machine-id"
rm -f "${ROOTFS}/var/lib/dbus/machine-id"

# Normalise timestamps for byte-reproducible layers
if [ -n "${SNAPSHOT}" ]; then
  EPOCH=$(date -u -d "${SNAPSHOT:0:8} ${SNAPSHOT:9:2}:${SNAPSHOT:11:2}:${SNAPSHOT:13:2}" +%s)
  find "${ROOTFS}" -xdev -newermt "@${EPOCH}" -exec touch --no-dereference --date="@${EPOCH}" {} + 2>/dev/null || true
fi

echo "rootfs built: $(du -sh "${ROOTFS}" | cut -f1) (mirror: ${MIRROR})"
