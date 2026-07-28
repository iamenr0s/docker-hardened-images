# syntax=docker/dockerfile:1.7
# Hardened minimal CentOS Stream, built from scratch via dnf --installroot.
# Flavors (build targets):
#   full  - dnf + shell present. Use as a build stage or when you must
#           install packages at build time.
#   micro - no package manager, no shell, non-root. Use as the final
#           runtime base. rpmdb is kept so scanners work.
#
# No historical snapshot pin (see images/common/build-rootfs-rpm.sh):
# built from the live dnf repos baked into the centos base image, then
# upgraded to latest at build time. Patches arrive via the nightly rebuild.
#
# docker.io/centos is EOL/unmaintained (deprecated June 2024) - CentOS
# Stream bootstraps from quay.io/centos/centos instead. Its image tags are
# "streamN" but dnf's $releasever must be the bare "N": CentOS Stream's repo
# baseurls/metalinks actually resolve through the custom dnf variable
# $stream (owned by centos-stream-release, /etc/dnf/vars/stream), not
# $releasever — $releasever only shows up in the repo file's display
# name= field. So the FROM line interpolates "stream${VERSION}" while
# build-rootfs-rpm.sh gets the bare VERSION as releasever. See the
# $stream varsdir contingency note below.
#
# ponytail: CentOS Stream defines a custom dnf var ($stream) that
# images/common/build-rootfs-rpm.sh has never had to propagate to the
# installroot before (Fedora/Alma/Rocky use none). The dnf5 branch's
# --use-host-config covers this; the dnf4 branch (CentOS Stream 9 only —
# Stream 10 uses dnf5) passes only -c /etc/dnf/dnf.conf, which may not
# carry varsdir. Not proven broken (Alma/Rocky pass CI on the same dnf4
# path today, but they define no custom vars, so this is untested
# territory). If the initial dnf install resolves a malformed baseurl, add
# --setopt=varsdir=/etc/dnf/vars to the dnf4 HOST_REPOS array in
# build-rootfs-rpm.sh (safe for siblings: Alma/Rocky/Fedora define no
# custom vars, so this is a no-op for them).

ARG VERSION=10

# ------------------------------------------------------------------ bootstrap
FROM quay.io/centos/centos:stream${VERSION} AS bootstrap
ARG VERSION

COPY common/build-rootfs-rpm.sh common/hardening.sh /opt/build/
RUN chmod +x /opt/build/*.sh

RUN /opt/build/build-rootfs-rpm.sh /rootfs "${VERSION}" centos-stream-release

# apply the latest security updates inside the new rootfs before sealing it.
# unlike debootstrap, `dnf --installroot` never leaves a resolv.conf in the
# target (DNS is resolved by the outer dnf process during that step), so
# this chroot has none of its own — seed it from the build host, then
# remove it again so the build host's DNS config never ends up in a
# published image.
RUN cp /etc/resolv.conf /rootfs/etc/resolv.conf \
 && chroot /rootfs sh -c 'dnf upgrade -y && dnf clean all && rm -rf /var/cache/dnf/*' \
 && rm -f /rootfs/etc/resolv.conf

# ------------------------------------------------------------- harden: full
FROM bootstrap AS harden-full
RUN /opt/build/hardening.sh /rootfs full rpm

# ------------------------------------------------------------ harden: micro
FROM bootstrap AS harden-micro
RUN /opt/build/hardening.sh /rootfs micro rpm

# ------------------------------------------------------------------- flavors
FROM scratch AS full
ARG VERSION
COPY --from=harden-full /rootfs /
ENV LANG=C.UTF-8 \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LABEL org.opencontainers.image.title="centos-hardened (full)" \
      org.opencontainers.image.description="Hardened minimal CentOS Stream ${VERSION} with dnf, for build stages" \
      org.opencontainers.image.base.name="scratch" \
      org.opencontainers.image.vendor="hardened-images"
# root is intentional in 'full' so dnf works in downstream build stages
CMD ["/bin/bash"]

FROM scratch AS micro
ARG VERSION
COPY --from=harden-micro /rootfs /
ENV LANG=C.UTF-8 \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LABEL org.opencontainers.image.title="centos-hardened (micro)" \
      org.opencontainers.image.description="Hardened minimal CentOS Stream ${VERSION}: no shell, no package manager, non-root" \
      org.opencontainers.image.base.name="scratch" \
      org.opencontainers.image.vendor="hardened-images"
USER 65532:65532
WORKDIR /home/nonroot
