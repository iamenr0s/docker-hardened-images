# CentOS Stream / Oracle Linux / Amazon Linux Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add three new rpm-family distros — CentOS Stream (9, 10), Oracle
Linux (8, 9), Amazon Linux (2023) — to the existing multi-distro hardened
image build, matching the contract in `docs/ADDING_A_DISTRO.md`.

**Architecture:** Each distro gets its own `images/<distro>/Dockerfile`
(copied from `images/fedora/Dockerfile`, only `FROM`/release-package/labels
differ) plus one `env` file per version and one `container-structure-test`
spec pair. `images/common/build-rootfs-rpm.sh` and
`images/common/hardening.sh` are reused completely unchanged. CI wiring
(matrix entries in `pr.yml`/`release.yml`/`rescan.yml`, README rows, Quay
pulls badge loop) is added once all three Dockerfiles exist.

**Tech Stack:** Docker Buildx multi-stage builds, `dnf --installroot`,
container-structure-test, GitHub Actions, hadolint.

## Global Constraints

- No changes to `images/common/build-rootfs-rpm.sh` or
  `images/common/hardening.sh` — both are already generic across the rpm
  family (see spec §"Files added per distro").
- No `SNAPSHOT=` line in any new `env` file — rpm-family images have no
  historical snapshot pin; omitting the line makes
  `scripts/update-snapshot.sh` skip them automatically (it globs
  `images/*/*/env` and only touches files declaring `SNAPSHOT=`).
- rpm-family invariants apply: CA bundle at
  `/etc/pki/tls/certs/ca-bundle.crt`, `/var/lib/rpm` preserved in micro, no
  shell/dnf/rpm binaries in micro, `USER 65532:65532` in micro, zero
  setuid/setgid files.
- No Docker Desktop available in this environment — verification for each
  Dockerfile task is: YAML/file review by hand, then push and rely on
  `pr.yml`'s CI (hadolint, build, structure tests, SBOM, grype+trivy gate)
  for the actual build/runtime proof, exactly as this project already
  operates (see spec §"Known risks").
- `.hadolint.yaml` currently only allows `docker.io` in `trustedRegistries`
  — CentOS Stream's `FROM quay.io/centos/centos:...` requires adding
  `quay.io` there or hadolint will reject the Dockerfile (DL3026).

---

## Task 1: CentOS Stream (9, 10)

**Files:**
- Create: `images/centos/Dockerfile`
- Create: `images/centos/9/env`
- Create: `images/centos/10/env`
- Create: `tests/centos/full.yaml`
- Create: `tests/centos/micro.yaml`
- Modify: `.hadolint.yaml`

**Interfaces:**
- Consumes: `images/common/build-rootfs-rpm.sh <rootfs-dir> <releasever> <release-package>` (existing, unchanged), `images/common/hardening.sh <rootfs-dir> <full|micro> <deb|rpm>` (existing, unchanged).
- Produces: `images/centos/Dockerfile` with build targets `full`/`micro`, consumed by Task 4's CI matrix entries as `{ distro: centos, version: "9"|"10", flavor: full|micro }`.

- [ ] **Step 1: Add `quay.io` to hadolint's trusted registries**

`docker.io/centos` is EOL (deprecated June 2024, last meaningful update
2020) — CentOS Stream must bootstrap from `quay.io/centos/centos` instead.
Edit `.hadolint.yaml`:

```yaml
ignored:
  - DL3008   # pin versions in apt-get install: rootfs is snapshot-driven
  - DL3059   # consecutive RUNs are in discarded bootstrap stages; final images are COPY-from-scratch
trustedRegistries:
  - docker.io
  - quay.io
```

- [ ] **Step 2: Write `images/centos/Dockerfile`**

```dockerfile
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
# "streamN" but dnf's $releasever must be the bare "N" (repo baseurls are
# .../N-stream/BaseOS/...), so the FROM line interpolates "stream${VERSION}"
# while build-rootfs-rpm.sh gets the bare VERSION as releasever.

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
```

- [ ] **Step 3: Write env files**

`images/centos/9/env`:
```
VERSION=9
EXTRA_TAGS=stream9
```

`images/centos/10/env`:
```
VERSION=10
EXTRA_TAGS=stream10
```

- [ ] **Step 4: Write structure tests**

`tests/centos/full.yaml`:
```yaml
schemaVersion: 2.0.0
fileExistenceTests:
  - name: dnf available
    path: /usr/bin/dnf
    shouldExist: true
  - name: shell available
    path: /bin/bash
    shouldExist: true
  - name: no curl
    path: /usr/bin/curl
    shouldExist: false
  - name: CA certificates present
    path: /etc/pki/tls/certs/ca-bundle.crt
    shouldExist: true
commandTests:
  - name: no setuid binaries
    command: "sh"
    args: ["-c", "find / -xdev -perm /6000 -type f | wc -l"]
    # anchored: expectedOutput entries are regexes, bare "0" would match "10"
    expectedOutput: ["^0\\s*$"]
  - name: root account locked
    command: "sh"
    args: ["-c", "grep -c '^root:[*!]' /etc/shadow"]
    expectedOutput: ["^1\\s*$"]
```

`tests/centos/micro.yaml`:
```yaml
schemaVersion: 2.0.0
metadataTest:
  user: "65532:65532"
fileExistenceTests:
  - name: no shell
    path: /bin/sh
    shouldExist: false
  - name: no bash
    path: /bin/bash
    shouldExist: false
  - name: no dnf
    path: /usr/bin/dnf
    shouldExist: false
  - name: no rpm binary
    path: /usr/bin/rpm
    shouldExist: false
  - name: no dnf configuration
    path: /etc/dnf
    shouldExist: false
  - name: rpm database kept for scanners
    path: /var/lib/rpm
    shouldExist: true
  - name: CA certificates present
    path: /etc/pki/tls/certs/ca-bundle.crt
    shouldExist: true
  - name: nonroot home
    path: /home/nonroot
    shouldExist: true
```

- [ ] **Step 5: Validate YAML syntax**

Run: `for f in images/centos/9/env images/centos/10/env tests/centos/full.yaml tests/centos/micro.yaml .hadolint.yaml; do echo "== $f =="; npx --yes -q js-yaml "$f" 2>&1; done`

The `env` files aren't YAML (they're shell `KEY=value`), so `js-yaml` will
error on those two — that's expected and fine; just eyeball them for
`KEY=value` shape with no unquoted spaces (see the project's own lesson
about unquoted multi-word `EXTRA_TAGS` breaking `source`). The two `.yaml`
test files and `.hadolint.yaml` must come back clean.

- [ ] **Step 6: Commit**

```bash
git add images/centos tests/centos .hadolint.yaml
git commit -m "feat: add CentOS Stream 9/10 hardened images"
```

---

## Task 2: Oracle Linux (8, 9)

**Files:**
- Create: `images/oraclelinux/Dockerfile`
- Create: `images/oraclelinux/8/env`
- Create: `images/oraclelinux/9/env`
- Create: `tests/oraclelinux/full.yaml`
- Create: `tests/oraclelinux/micro.yaml`

**Interfaces:**
- Consumes: same shared scripts as Task 1.
- Produces: `images/oraclelinux/Dockerfile`, consumed by Task 4 as `{ distro: oraclelinux, version: "8"|"9", flavor: full|micro }`.

Oracle Linux's release package name is version-specific
(`oraclelinux-release-el8` vs `oraclelinux-release-el9`), unlike Alma/Rocky
where the same package name works across every supported version. The
Dockerfile interpolates it from `${VERSION}` at the `RUN` line instead of
hardcoding a literal — no shared-script change needed.

- [ ] **Step 1: Write `images/oraclelinux/Dockerfile`**

```dockerfile
# syntax=docker/dockerfile:1.7
# Hardened minimal Oracle Linux, built from scratch via dnf --installroot.
# Flavors (build targets):
#   full  - dnf + shell present. Use as a build stage or when you must
#           install packages at build time.
#   micro - no package manager, no shell, non-root. Use as the final
#           runtime base. rpmdb is kept so scanners work.
#
# No historical snapshot pin (see images/common/build-rootfs-rpm.sh):
# built from the live dnf repos baked into the oraclelinux base image, then
# upgraded to latest at build time. Patches arrive via the nightly rebuild.
#
# Oracle's release package is version-specific (oraclelinux-release-elN),
# unlike Alma/Rocky's single unversioned package name — interpolated from
# VERSION below rather than hardcoded.

ARG VERSION=9

# ------------------------------------------------------------------ bootstrap
FROM oraclelinux:${VERSION} AS bootstrap
ARG VERSION

COPY common/build-rootfs-rpm.sh common/hardening.sh /opt/build/
RUN chmod +x /opt/build/*.sh

RUN /opt/build/build-rootfs-rpm.sh /rootfs "${VERSION}" "oraclelinux-release-el${VERSION}"

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
LABEL org.opencontainers.image.title="oraclelinux-hardened (full)" \
      org.opencontainers.image.description="Hardened minimal Oracle Linux ${VERSION} with dnf, for build stages" \
      org.opencontainers.image.base.name="scratch" \
      org.opencontainers.image.vendor="hardened-images"
# root is intentional in 'full' so dnf works in downstream build stages
CMD ["/bin/bash"]

FROM scratch AS micro
ARG VERSION
COPY --from=harden-micro /rootfs /
ENV LANG=C.UTF-8 \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LABEL org.opencontainers.image.title="oraclelinux-hardened (micro)" \
      org.opencontainers.image.description="Hardened minimal Oracle Linux ${VERSION}: no shell, no package manager, non-root" \
      org.opencontainers.image.base.name="scratch" \
      org.opencontainers.image.vendor="hardened-images"
USER 65532:65532
WORKDIR /home/nonroot
```

- [ ] **Step 2: Write env files**

`images/oraclelinux/8/env`:
```
VERSION=8
EXTRA_TAGS=ol8
```

`images/oraclelinux/9/env`:
```
VERSION=9
EXTRA_TAGS=ol9
```

- [ ] **Step 3: Write structure tests**

`tests/oraclelinux/full.yaml` (identical structure to `tests/centos/full.yaml` from Task 1):
```yaml
schemaVersion: 2.0.0
fileExistenceTests:
  - name: dnf available
    path: /usr/bin/dnf
    shouldExist: true
  - name: shell available
    path: /bin/bash
    shouldExist: true
  - name: no curl
    path: /usr/bin/curl
    shouldExist: false
  - name: CA certificates present
    path: /etc/pki/tls/certs/ca-bundle.crt
    shouldExist: true
commandTests:
  - name: no setuid binaries
    command: "sh"
    args: ["-c", "find / -xdev -perm /6000 -type f | wc -l"]
    expectedOutput: ["^0\\s*$"]
  - name: root account locked
    command: "sh"
    args: ["-c", "grep -c '^root:[*!]' /etc/shadow"]
    expectedOutput: ["^1\\s*$"]
```

`tests/oraclelinux/micro.yaml`:
```yaml
schemaVersion: 2.0.0
metadataTest:
  user: "65532:65532"
fileExistenceTests:
  - name: no shell
    path: /bin/sh
    shouldExist: false
  - name: no bash
    path: /bin/bash
    shouldExist: false
  - name: no dnf
    path: /usr/bin/dnf
    shouldExist: false
  - name: no rpm binary
    path: /usr/bin/rpm
    shouldExist: false
  - name: no dnf configuration
    path: /etc/dnf
    shouldExist: false
  - name: rpm database kept for scanners
    path: /var/lib/rpm
    shouldExist: true
  - name: CA certificates present
    path: /etc/pki/tls/certs/ca-bundle.crt
    shouldExist: true
  - name: nonroot home
    path: /home/nonroot
    shouldExist: true
```

- [ ] **Step 4: Validate YAML syntax**

Run: `for f in tests/oraclelinux/full.yaml tests/oraclelinux/micro.yaml; do npx --yes -q js-yaml "$f"; done` — must produce no output.

- [ ] **Step 5: Commit**

```bash
git add images/oraclelinux tests/oraclelinux
git commit -m "feat: add Oracle Linux 8/9 hardened images"
```

---

## Task 3: Amazon Linux 2023 (higher risk — see notes)

**Files:**
- Create: `images/amazonlinux/Dockerfile`
- Create: `images/amazonlinux/2023/env`
- Create: `tests/amazonlinux/full.yaml`
- Create: `tests/amazonlinux/micro.yaml`

**Interfaces:**
- Consumes: same shared scripts as Task 1.
- Produces: `images/amazonlinux/Dockerfile`, consumed by Task 4 as `{ distro: amazonlinux, version: "2023", flavor: full|micro }`.

Amazon Linux has no standalone release package like
`fedora-release`/`almalinux-release`/`rocky-release`. AWS's own bootstrap
docs (`docs.aws.amazon.com/linux/al2023/ug/barebones-containers.html`) skip
that step entirely. The best available first attempt is passing
`system-release` as the release-package argument — it's a real installable
package name in AL2023 and is a reasonable bet that it owns
`/etc/yum.repos.d/amazonlinux.repo` the way `fedora-release` owns
`fedora.repo`, but this is **unconfirmed without a live build**. This task
documents an exact, concrete fallback to apply if CI proves the assumption
wrong — do not pre-apply it speculatively.

- [ ] **Step 1: Write `images/amazonlinux/Dockerfile`**

```dockerfile
# syntax=docker/dockerfile:1.7
# Hardened minimal Amazon Linux, built from scratch via dnf --installroot.
# Flavors (build targets):
#   full  - dnf + shell present. Use as a build stage or when you must
#           install packages at build time.
#   micro - no package manager, no shell, non-root. Use as the final
#           runtime base. rpmdb is kept so scanners work.
#
# No historical snapshot pin (see images/common/build-rootfs-rpm.sh):
# built from the live dnf repos baked into the amazonlinux base image, then
# upgraded to latest at build time. Patches arrive via the nightly rebuild.
#
# ponytail: Amazon Linux has no standalone release package like
# fedora-release/almalinux-release/rocky-release. "system-release" is the
# best-known equivalent (AWS's own barebones-container docs skip this step
# entirely). If the later `chroot dnf upgrade` step fails with "No
# repositories were loaded from the installroot", the confirmed fix is to
# copy the bootstrap image's own repo file into the rootfs explicitly:
#   RUN test -f /rootfs/etc/yum.repos.d/amazonlinux.repo || \
#       cp /etc/yum.repos.d/amazonlinux.repo /rootfs/etc/yum.repos.d/amazonlinux.repo
# added as its own RUN line directly after the build-rootfs-rpm.sh call below.

ARG VERSION=2023

# ------------------------------------------------------------------ bootstrap
FROM amazonlinux:${VERSION} AS bootstrap
ARG VERSION

COPY common/build-rootfs-rpm.sh common/hardening.sh /opt/build/
RUN chmod +x /opt/build/*.sh

RUN /opt/build/build-rootfs-rpm.sh /rootfs "${VERSION}" system-release

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
LABEL org.opencontainers.image.title="amazonlinux-hardened (full)" \
      org.opencontainers.image.description="Hardened minimal Amazon Linux ${VERSION} with dnf, for build stages" \
      org.opencontainers.image.base.name="scratch" \
      org.opencontainers.image.vendor="hardened-images"
# root is intentional in 'full' so dnf works in downstream build stages
CMD ["/bin/bash"]

FROM scratch AS micro
ARG VERSION
COPY --from=harden-micro /rootfs /
ENV LANG=C.UTF-8 \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LABEL org.opencontainers.image.title="amazonlinux-hardened (micro)" \
      org.opencontainers.image.description="Hardened minimal Amazon Linux ${VERSION}: no shell, no package manager, non-root" \
      org.opencontainers.image.base.name="scratch" \
      org.opencontainers.image.vendor="hardened-images"
USER 65532:65532
WORKDIR /home/nonroot
```

- [ ] **Step 2: Write env file**

`images/amazonlinux/2023/env`:
```
VERSION=2023
EXTRA_TAGS=al2023
```

- [ ] **Step 3: Write structure tests**

`tests/amazonlinux/full.yaml` (same shape as Task 1/2; CA bundle path is a
best guess for this distro too — confirm in CI):
```yaml
schemaVersion: 2.0.0
fileExistenceTests:
  - name: dnf available
    path: /usr/bin/dnf
    shouldExist: true
  - name: shell available
    path: /bin/bash
    shouldExist: true
  - name: no curl
    path: /usr/bin/curl
    shouldExist: false
  - name: CA certificates present
    path: /etc/pki/tls/certs/ca-bundle.crt
    shouldExist: true
commandTests:
  - name: no setuid binaries
    command: "sh"
    args: ["-c", "find / -xdev -perm /6000 -type f | wc -l"]
    expectedOutput: ["^0\\s*$"]
  - name: root account locked
    command: "sh"
    args: ["-c", "grep -c '^root:[*!]' /etc/shadow"]
    expectedOutput: ["^1\\s*$"]
```

`tests/amazonlinux/micro.yaml`:
```yaml
schemaVersion: 2.0.0
metadataTest:
  user: "65532:65532"
fileExistenceTests:
  - name: no shell
    path: /bin/sh
    shouldExist: false
  - name: no bash
    path: /bin/bash
    shouldExist: false
  - name: no dnf
    path: /usr/bin/dnf
    shouldExist: false
  - name: no rpm binary
    path: /usr/bin/rpm
    shouldExist: false
  - name: no dnf configuration
    path: /etc/dnf
    shouldExist: false
  - name: rpm database kept for scanners
    path: /var/lib/rpm
    shouldExist: true
  - name: CA certificates present
    path: /etc/pki/tls/certs/ca-bundle.crt
    shouldExist: true
  - name: nonroot home
    path: /home/nonroot
    shouldExist: true
```

- [ ] **Step 4: Validate YAML syntax**

Run: `for f in tests/amazonlinux/full.yaml tests/amazonlinux/micro.yaml; do npx --yes -q js-yaml "$f"; done` — must produce no output.

- [ ] **Step 5: Commit**

```bash
git add images/amazonlinux tests/amazonlinux
git commit -m "feat: add Amazon Linux 2023 hardened image"
```

- [ ] **Step 6: After Task 4's CI wiring lands and a PR is open, check the `amazonlinux` build-scan jobs specifically**

Two things to check in the `pr.yml` run logs, in order:

1. The `Build (amd64, load)` step for `distro: amazonlinux` — if it fails
   inside `chroot /rootfs sh -c 'dnf upgrade -y ...'` with `No repositories
   were loaded from the installroot`, apply this exact patch to
   `images/amazonlinux/Dockerfile` (insert as a new line immediately after
   the existing `build-rootfs-rpm.sh` RUN line):

   ```dockerfile
   RUN test -f /rootfs/etc/yum.repos.d/amazonlinux.repo || \
       cp /etc/yum.repos.d/amazonlinux.repo /rootfs/etc/yum.repos.d/amazonlinux.repo
   ```

   Commit as `fix: seed amazonlinux repo config into installroot` and push.

2. If `dnf install ... system-release` itself fails (package not found, or
   `coreutils-single` not found — that package is an EL/Fedora split
   package Amazon Linux may not carry), the fix is in
   `images/common/build-rootfs-rpm.sh`'s package list
   (`dnf coreutils-single glibc-minimal-langpack filesystem
   ca-certificates tzdata "${RELEASE_PKG}"`): change
   `coreutils-single` to `coreutils` **only if** the failure log confirms
   `coreutils-single` doesn't exist in AL2023's repos. This is the one
   place a shared-script edit would be justified — but only make it after
   the CI log confirms the specific package is missing, not preemptively
   (Alma/Rocky/Fedora/CentOS/Oracle all rely on `coreutils-single` and this
   must not regress for them).

---

## Task 4: CI matrix, README, and Quay pulls badge wiring

**Files:**
- Modify: `.github/workflows/pr.yml`
- Modify: `.github/workflows/release.yml`
- Modify: `.github/workflows/rescan.yml`
- Modify: `.github/workflows/quay-pulls-badge.yml`
- Modify: `README.md`

**Interfaces:**
- Consumes: `images/centos/Dockerfile`, `images/oraclelinux/Dockerfile`, `images/amazonlinux/Dockerfile` (Tasks 1-3), `images/<distro>/<version>/env` (Tasks 1-3), `tests/<distro>/{full,micro}.yaml` (Tasks 1-3).
- Produces: nothing consumed further — this is the terminal wiring task.

- [ ] **Step 1: Add hadolint steps to `pr.yml`'s `lint` job**

Insert after the existing `hadolint (rockylinux)` step (`.github/workflows/pr.yml:45-49`):

```yaml
      - name: hadolint (centos)
        uses: hadolint/hadolint-action@54c9adbab1582c2ef04b2016b760714a4bfde3cf # v3.1.0
        with:
          dockerfile: images/centos/Dockerfile
          config: .hadolint.yaml
      - name: hadolint (oraclelinux)
        uses: hadolint/hadolint-action@54c9adbab1582c2ef04b2016b760714a4bfde3cf # v3.1.0
        with:
          dockerfile: images/oraclelinux/Dockerfile
          config: .hadolint.yaml
      - name: hadolint (amazonlinux)
        uses: hadolint/hadolint-action@54c9adbab1582c2ef04b2016b760714a4bfde3cf # v3.1.0
        with:
          dockerfile: images/amazonlinux/Dockerfile
          config: .hadolint.yaml
```

- [ ] **Step 2: Add matrix entries to `pr.yml`'s `build-scan` job**

Insert after the existing `rockylinux, version: "10", flavor: micro` line (`.github/workflows/pr.yml:88`):

```yaml
          - { distro: centos, version: "9", flavor: full }
          - { distro: centos, version: "9", flavor: micro }
          - { distro: centos, version: "10", flavor: full }
          - { distro: centos, version: "10", flavor: micro }
          - { distro: oraclelinux, version: "8", flavor: full }
          - { distro: oraclelinux, version: "8", flavor: micro }
          - { distro: oraclelinux, version: "9", flavor: full }
          - { distro: oraclelinux, version: "9", flavor: micro }
          - { distro: amazonlinux, version: "2023", flavor: full }
          - { distro: amazonlinux, version: "2023", flavor: micro }
```

- [ ] **Step 3: Add the same matrix entries to `release.yml`**

Insert after the existing `rockylinux, version: "10", flavor: micro` line (`.github/workflows/release.yml:63`) — identical 10 lines to Step 2.

- [ ] **Step 4: Add rescan matrix entries to `rescan.yml`**

Insert after the existing `rockylinux, tag: "10-full"` line (`.github/workflows/rescan.yml:49`):

```yaml
          - { distro: centos, tag: "9" }
          - { distro: centos, tag: "9-full" }
          - { distro: centos, tag: "10" }
          - { distro: centos, tag: "10-full" }
          - { distro: oraclelinux, tag: "8" }
          - { distro: oraclelinux, tag: "8-full" }
          - { distro: oraclelinux, tag: "9" }
          - { distro: oraclelinux, tag: "9-full" }
          - { distro: amazonlinux, tag: "2023" }
          - { distro: amazonlinux, tag: "2023-full" }
```

- [ ] **Step 5: Add the three distros to `quay-pulls-badge.yml`'s loop**

Edit `.github/workflows/quay-pulls-badge.yml` — change:

```yaml
          for DISTRO in debian ubuntu fedora almalinux rockylinux; do
```

to:

```yaml
          for DISTRO in debian ubuntu fedora almalinux rockylinux centos oraclelinux amazonlinux; do
```

- [ ] **Step 6: Add rows to README's "Available Images" badge table**

Insert after the existing `rockylinux10` row in `README.md` (the table
starting at `README.md:20`), following the exact same pattern as the other
rows (swap distro name, version, and CVE-badge tag):

```markdown
| [![centos9](https://img.shields.io/github/actions/workflow/status/iamenr0s/docker-hardened-images/release.yml?label=centos9&logo=github)](https://github.com/iamenr0s/docker-hardened-images/actions/workflows/release.yml) | [![CVEs](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fiamenr0s%2Fdocker-hardened-images%2Fbadges%2Fbadges%2Fcve-centos-9.json)](https://github.com/iamenr0s/docker-hardened-images/actions/workflows/rescan.yml) | [![Quay Pulls](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fiamenr0s%2Fdocker-hardened-images%2Fbadges%2Fbadges%2Fquay-centos-hardened.json)](https://quay.io/repository/iamenr0s/centos-hardened?tab=tags&tag=9) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/centos-hardened?logo=docker)](https://hub.docker.com/r/iamenr0s/centos-hardened) |
| [![centos10](https://img.shields.io/github/actions/workflow/status/iamenr0s/docker-hardened-images/release.yml?label=centos10&logo=github)](https://github.com/iamenr0s/docker-hardened-images/actions/workflows/release.yml) | [![CVEs](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fiamenr0s%2Fdocker-hardened-images%2Fbadges%2Fbadges%2Fcve-centos-10.json)](https://github.com/iamenr0s/docker-hardened-images/actions/workflows/rescan.yml) | [![Quay Pulls](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fiamenr0s%2Fdocker-hardened-images%2Fbadges%2Fbadges%2Fquay-centos-hardened.json)](https://quay.io/repository/iamenr0s/centos-hardened?tab=tags&tag=10) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/centos-hardened?logo=docker)](https://hub.docker.com/r/iamenr0s/centos-hardened) |
| [![oraclelinux8](https://img.shields.io/github/actions/workflow/status/iamenr0s/docker-hardened-images/release.yml?label=oraclelinux8&logo=github)](https://github.com/iamenr0s/docker-hardened-images/actions/workflows/release.yml) | [![CVEs](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fiamenr0s%2Fdocker-hardened-images%2Fbadges%2Fbadges%2Fcve-oraclelinux-8.json)](https://github.com/iamenr0s/docker-hardened-images/actions/workflows/rescan.yml) | [![Quay Pulls](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fiamenr0s%2Fdocker-hardened-images%2Fbadges%2Fbadges%2Fquay-oraclelinux-hardened.json)](https://quay.io/repository/iamenr0s/oraclelinux-hardened?tab=tags&tag=8) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/oraclelinux-hardened?logo=docker)](https://hub.docker.com/r/iamenr0s/oraclelinux-hardened) |
| [![oraclelinux9](https://img.shields.io/github/actions/workflow/status/iamenr0s/docker-hardened-images/release.yml?label=oraclelinux9&logo=github)](https://github.com/iamenr0s/docker-hardened-images/actions/workflows/release.yml) | [![CVEs](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fiamenr0s%2Fdocker-hardened-images%2Fbadges%2Fbadges%2Fcve-oraclelinux-9.json)](https://github.com/iamenr0s/docker-hardened-images/actions/workflows/rescan.yml) | [![Quay Pulls](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fiamenr0s%2Fdocker-hardened-images%2Fbadges%2Fbadges%2Fquay-oraclelinux-hardened.json)](https://quay.io/repository/iamenr0s/oraclelinux-hardened?tab=tags&tag=9) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/oraclelinux-hardened?logo=docker)](https://hub.docker.com/r/iamenr0s/oraclelinux-hardened) |
| [![amazonlinux2023](https://img.shields.io/github/actions/workflow/status/iamenr0s/docker-hardened-images/release.yml?label=amazonlinux2023&logo=github)](https://github.com/iamenr0s/docker-hardened-images/actions/workflows/release.yml) | [![CVEs](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fiamenr0s%2Fdocker-hardened-images%2Fbadges%2Fbadges%2Fcve-amazonlinux-2023.json)](https://github.com/iamenr0s/docker-hardened-images/actions/workflows/rescan.yml) | [![Quay Pulls](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fiamenr0s%2Fdocker-hardened-images%2Fbadges%2Fbadges%2Fquay-amazonlinux-hardened.json)](https://quay.io/repository/iamenr0s/amazonlinux-hardened?tab=tags&tag=2023) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/amazonlinux-hardened?logo=docker)](https://hub.docker.com/r/iamenr0s/amazonlinux-hardened) |
```

- [ ] **Step 7: Add rows to README's "Image catalog" table**

Insert after the existing `RockyLinux` row in `README.md` (the table
starting at `README.md:48`):

```markdown
| CentOS Stream | 9, 10 | `full`, `micro` | `9`, `9-full`, `9-micro`, `stream9`, `10`, `10-full`, `10-micro`, `stream10`, `latest` |
| Oracle Linux | 8, 9 | `full`, `micro` | `8`, `8-full`, `8-micro`, `ol8`, `9`, `9-full`, `9-micro`, `ol9`, `latest` |
| Amazon Linux | 2023 | `full`, `micro` | `2023`, `2023-full`, `2023-micro`, `al2023`, `latest` |
```

- [ ] **Step 8: Validate all edited YAML files parse**

Run: `for f in .github/workflows/pr.yml .github/workflows/release.yml .github/workflows/rescan.yml .github/workflows/quay-pulls-badge.yml; do echo "== $f =="; npx --yes -q js-yaml "$f" 2>&1; done` — must produce no output for any file.

- [ ] **Step 9: Commit**

```bash
git add .github/workflows/pr.yml .github/workflows/release.yml \
        .github/workflows/rescan.yml .github/workflows/quay-pulls-badge.yml \
        README.md
git commit -m "feat: wire CentOS Stream/Oracle Linux/Amazon Linux into CI, README, and badges"
```

- [ ] **Step 10: Push branch and open PR**

```bash
git push -u origin feat/cve-badges
gh pr create --title "Add CentOS Stream, Oracle Linux, Amazon Linux hardened images" \
  --body "Extends the rpm-family build to CentOS Stream 9/10, Oracle Linux 8/9, Amazon Linux 2023. See docs/superpowers/specs/2026-07-26-centos-oraclelinux-amazonlinux-design.md for design rationale and known risks (Amazon Linux release-package/repo-config is unverified until this PR's CI runs)."
```

Then watch the `pr.yml` run and apply Task 3 Step 6's fallback(s) if the
`amazonlinux` jobs fail as predicted, or investigate and fix any other
CI failures (e.g. the CentOS Stream `--releasever` risk from the spec)
following the same "read the CI log, make the smallest targeted fix"
pattern this project has used for every previous distro addition.
