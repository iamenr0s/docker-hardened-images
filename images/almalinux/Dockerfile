# syntax=docker/dockerfile:1.7
# Hardened minimal AlmaLinux, built from scratch via dnf --installroot.
# Flavors (build targets):
#   full  - dnf + shell present. Use as a build stage or when you must
#           install packages at build time.
#   micro - no package manager, no shell, non-root. Use as the final
#           runtime base. rpmdb is kept so scanners work.
#
# No historical snapshot pin (see images/common/build-rootfs-rpm.sh):
# built from the live dnf repos baked into the almalinux base image, then
# upgraded to latest at build time. Patches arrive via the nightly rebuild.

ARG VERSION=9

# ------------------------------------------------------------------ bootstrap
FROM almalinux:${VERSION} AS bootstrap
ARG VERSION

COPY common/build-rootfs-rpm.sh common/hardening.sh /opt/build/
RUN chmod +x /opt/build/*.sh

RUN /opt/build/build-rootfs-rpm.sh /rootfs "${VERSION}"

# apply the latest security updates inside the new rootfs before sealing it
RUN chroot /rootfs sh -c 'dnf upgrade -y && dnf clean all && rm -rf /var/cache/dnf/*'

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
LABEL org.opencontainers.image.title="almalinux-hardened (full)" \
      org.opencontainers.image.description="Hardened minimal AlmaLinux ${VERSION} with dnf, for build stages" \
      org.opencontainers.image.base.name="scratch" \
      org.opencontainers.image.vendor="hardened-images"
# root is intentional in 'full' so dnf works in downstream build stages
CMD ["/bin/bash"]

FROM scratch AS micro
ARG VERSION
COPY --from=harden-micro /rootfs /
ENV LANG=C.UTF-8 \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LABEL org.opencontainers.image.title="almalinux-hardened (micro)" \
      org.opencontainers.image.description="Hardened minimal AlmaLinux ${VERSION}: no shell, no package manager, non-root" \
      org.opencontainers.image.base.name="scratch" \
      org.opencontainers.image.vendor="hardened-images"
USER 65532:65532
WORKDIR /home/nonroot
