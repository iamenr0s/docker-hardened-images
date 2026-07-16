# syntax=docker/dockerfile:1.7
# Hardened minimal Ubuntu, built from scratch via debootstrap.
# Flavors (build targets):
#   full  - apt/dpkg + shell present. Use as a build stage or when you
#           must install packages at build time.
#   micro - no package manager, no shell, non-root. Use as the final
#           runtime base. dpkg status file is kept so scanners work.

ARG SUITE=noble
# snapshot.ubuntu.com timestamp; empty = live mirrors (non-reproducible)
ARG SNAPSHOT=

# ------------------------------------------------------------------ bootstrap
FROM ubuntu:${SUITE} AS bootstrap
ARG SUITE
ARG SNAPSHOT

RUN apt-get update \
 && apt-get install -y --no-install-recommends debootstrap ca-certificates ubuntu-keyring \
 && rm -rf /var/lib/apt/lists/*

COPY common/build-rootfs-deb.sh common/hardening.sh /opt/build/
RUN chmod +x /opt/build/*.sh

RUN /opt/build/build-rootfs-deb.sh /rootfs ubuntu "${SUITE}" /usr/share/keyrings/ubuntu-archive-keyring.gpg "${SNAPSHOT}"

# apply the latest security updates inside the new rootfs before sealing it.
# debootstrap copies the build host's /etc/resolv.conf into the rootfs (a
# well-known debootstrap side effect, needed for this chroot's own network
# access) but never removes it — strip it after so the build host's DNS
# config never ends up in a published image.
RUN chroot /rootfs sh -c 'apt-get update && apt-get -y upgrade && apt-get clean && rm -rf /var/lib/apt/lists/*' \
 && rm -f /rootfs/etc/resolv.conf

# ------------------------------------------------------------- harden: full
FROM bootstrap AS harden-full
RUN /opt/build/hardening.sh /rootfs full deb

# ------------------------------------------------------------ harden: micro
FROM bootstrap AS harden-micro
RUN /opt/build/hardening.sh /rootfs micro deb

# ------------------------------------------------------------------- flavors
FROM scratch AS full
ARG SUITE
COPY --from=harden-full /rootfs /
ENV LANG=C.UTF-8 \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LABEL org.opencontainers.image.title="ubuntu-hardened (full)" \
      org.opencontainers.image.description="Hardened minimal Ubuntu ${SUITE} with apt, for build stages" \
      org.opencontainers.image.base.name="scratch" \
      org.opencontainers.image.vendor="hardened-images"
# root is intentional in 'full' so apt works in downstream build stages
CMD ["/bin/bash"]

FROM scratch AS micro
ARG SUITE
COPY --from=harden-micro /rootfs /
ENV LANG=C.UTF-8 \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LABEL org.opencontainers.image.title="ubuntu-hardened (micro)" \
      org.opencontainers.image.description="Hardened minimal Ubuntu ${SUITE}: no shell, no package manager, non-root" \
      org.opencontainers.image.base.name="scratch" \
      org.opencontainers.image.vendor="hardened-images"
USER 65532:65532
WORKDIR /home/nonroot
