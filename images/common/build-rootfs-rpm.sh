#!/usr/bin/env bash
# Build a minimal RPM-family rootfs (Fedora/AlmaLinux/RockyLinux) with
# dnf --installroot. A fresh installroot has no repo config of its own;
# how to borrow the bootstrap image's baked-in repos differs by dnf major:
#   dnf5 (Fedora 41+): loads NO host repos with --installroot unless
#     --use-host-config is passed (`-c` alone resolves zero repos).
#   dnf4 (EL9/EL10): doesn't know --use-host-config; `-c /etc/dnf/dnf.conf`
#     makes it read the host config and reposdir.
# Only default-enabled repos are used — wildcard-enabling everything pulls
# in debuginfo/source repos whose mirrorlists can be empty (Rocky 10).
# The distro's <release-package> is installed explicitly so the rootfs
# ends up with its own /etc/yum.repos.d (needed for the caller's later
# `chroot dnf upgrade` step, which has no host config to borrow from).
# ponytail: no historical snapshot pin (RPM distros lack a public
# timestamp-mirror service like snapshot.debian.org); the caller applies
# a build-time `dnf upgrade` for freshness instead. Add vault/point-release
# pinning for AlmaLinux/Rocky if true reproducibility is needed later.
# Usage: build-rootfs-rpm.sh <rootfs-dir> <releasever> <release-package>
set -euo pipefail

ROOTFS="${1:?rootfs dir required}"
RELEASEVER="${2:?releasever required}"
RELEASE_PKG="${3:?release package required (e.g. fedora-release, almalinux-release, rocky-release)}"

mkdir -p "${ROOTFS}"

# dnf itself is included so 'full' keeps a working package manager (mirrors
# debootstrap minbase always including apt) and the caller's chroot upgrade
# step has a binary to run; hardening.sh strips it back out for 'micro'.
if command -v dnf5 >/dev/null 2>&1; then
  HOST_REPOS=(--use-host-config)
else
  HOST_REPOS=(-c /etc/dnf/dnf.conf)
fi

dnf install -y \
  --installroot="${ROOTFS}" \
  --releasever="${RELEASEVER}" \
  "${HOST_REPOS[@]}" \
  --setopt=install_weak_deps=False \
  --setopt=tsflags=nodocs \
  dnf coreutils-single glibc-minimal-langpack filesystem ca-certificates tzdata "${RELEASE_PKG}"

dnf clean all --installroot="${ROOTFS}"
rm -rf "${ROOTFS}/var/cache/dnf" \
       "${ROOTFS}/var/log/"* \
       "${ROOTFS}/tmp/"* 2>/dev/null || true

# --- Non-root user (matches distroless convention, same as deb family) ---
echo 'nonroot:x:65532:65532:nonroot:/home/nonroot:/sbin/nologin' >> "${ROOTFS}/etc/passwd"
echo 'nonroot:x:65532:' >> "${ROOTFS}/etc/group"
mkdir -p "${ROOTFS}/home/nonroot"
chown 65532:65532 "${ROOTFS}/home/nonroot"

# --- Reproducibility / privacy ---
: > "${ROOTFS}/etc/machine-id"
rm -f "${ROOTFS}/var/lib/dbus/machine-id"

echo "rootfs built: $(du -sh "${ROOTFS}" | cut -f1) (releasever: ${RELEASEVER})"
