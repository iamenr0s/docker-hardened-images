# Adding a new distribution

Each distro follows the same contract, so CI and scripts work unchanged.
Two families are implemented — deb (Debian, Ubuntu) and rpm (Fedora,
AlmaLinux, RockyLinux) — and a new distro joins whichever family it belongs
to:

1. `images/<distro>/Dockerfile` — multi-stage with targets `full` and
   `micro`, built from the distro's own bootstrap tool:
   - **deb family**: bootstrap `FROM <distro>:${SUITE}`, install the
     distro's keyring package (`debian-archive-keyring` /
     `ubuntu-keyring`), call
     `images/common/build-rootfs-deb.sh /rootfs <distro> <suite> <keyring-path> "${SNAPSHOT}"`.
     Debian and Ubuntu share this one script — see its `case "${DISTRO}"`
     branch for mirror/arch handling (Ubuntu splits live mirrors by arch
     and has no separate security host, unlike Debian).
   - **rpm family**: bootstrap `FROM <distro>:${VERSION}` (dnf's repo
     config is already correct out of the box — no mirror/keyring wiring
     needed), call `images/common/build-rootfs-rpm.sh /rootfs "${VERSION}"`,
     then `chroot /rootfs sh -c 'dnf upgrade -y && dnf clean all && rm -rf /var/cache/dnf/*'`.
     No historical snapshot pin (no public timestamp-mirror service for
     dnf); freshness comes from the build-time `dnf upgrade` plus the
     nightly rebuild. Keep `/var/lib/rpm` in micro so scanners still work —
     the RPM equivalent of keeping `/var/lib/dpkg/status`.
2. `images/<distro>/<version>/env` — deb-family: `SUITE`, `VERSION`,
   `EXTRA_TAGS`, `SNAPSHOT` (empty = live mirrors). rpm-family: `VERSION`,
   `EXTRA_TAGS` — omit `SNAPSHOT=` entirely so `scripts/update-snapshot.sh`
   (which globs `images/*/*/env` and only touches files declaring
   `SNAPSHOT=`) skips it automatically.
3. Reuse `images/common/hardening.sh` semantics: it takes a required 3rd
   arg, `<deb|rpm>` — setuid strip, network-tool removal and root lock are
   family-agnostic; the micro-mode package-manager cleanup branches on
   `PKGFAMILY`.
4. `tests/<distro>/{full,micro}.yaml` structure tests — rpm-family CA
   bundle lives at `/etc/pki/tls/certs/ca-bundle.crt` (not
   `/etc/ssl/certs/ca-certificates.crt` like deb-family).
5. Add the version to the `matrix.include` lists in `pr.yml`, `release.yml`,
   `rescan.yml`, and (deb-family only) confirm `scripts/update-snapshot.sh`
   picks up the new env file (it will, automatically, once `SNAPSHOT=` is
   present).
6. Add a row to the README's "Image catalog" table and "Available Images"
   badge table (reusing `quay-pulls-badge.yml`'s per-distro loop).

Invariants every image must hold:

- micro: no shell, no package manager binaries, `USER 65532:65532`, zero setuid files
- package database preserved for SBOM/CVE scanners (`/var/lib/dpkg/status`
  or `/var/lib/rpm`)
- CA certificates + tzdata present
- multi-arch manifest (amd64 + arm64), identical on both registries
