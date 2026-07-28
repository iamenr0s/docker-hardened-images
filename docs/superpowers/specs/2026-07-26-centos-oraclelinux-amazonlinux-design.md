# Extend build: CentOS Stream, Oracle Linux, Amazon Linux

## Context

The project currently builds two distro families through a shared contract
documented in `docs/ADDING_A_DISTRO.md`: deb (Debian, Ubuntu) and rpm
(Fedora, AlmaLinux, RockyLinux). This adds three more rpm-family distros.

## Out of scope

- **CloudLinux** — no official Docker Hub base image; repos are
  commercial/license-gated (built for cPanel hosting). Dropped for this
  round; revisit only if a licensed repo mirror becomes available.
- **Talos Linux** — not a package-based distro. No shell, no package
  manager, built via its own Go/Bazel toolchain, and already ships as its
  own minimal immutable OS. Doesn't fit the debootstrap/dnf-installroot
  hardening pipeline this repo uses. Dropped for this round.

## Scope

Five new version images, all joining the existing **rpm family** (reusing
`images/common/build-rootfs-rpm.sh` and `images/common/hardening.sh`
unchanged):

| Distro | Versions | Base image | Release package |
|---|---|---|---|
| CentOS Stream | 9, 10 | `quay.io/centos/centos:stream9` / `stream10` | `centos-stream-release` |
| Oracle Linux | 8, 9 | `oraclelinux:8` / `9` | `oraclelinux-release-el8` / `oraclelinux-release-el9` |
| Amazon Linux | 2023 | `amazonlinux:2023` | unresolved — see risks |

`docker.io/centos` is confirmed EOL/unmaintained (last meaningful update
2020, deprecated June 2024) — CentOS Stream must bootstrap from
`quay.io/centos/centos` instead, which is a deviation from the existing
distros' `FROM <distro>:${VERSION}` pattern (needs a full registry path).
Oracle Linux and Amazon Linux both have actively maintained official
Docker Hub images.

## Files added per distro

Following the existing Fedora/AlmaLinux/RockyLinux pattern exactly:

1. `images/<distro>/Dockerfile` — copy of `images/fedora/Dockerfile`,
   swapping `FROM`, the release-package argument to
   `build-rootfs-rpm.sh`, and the OCI labels.
2. `images/<distro>/<version>/env` — `VERSION`, `EXTRA_TAGS=`, no
   `SNAPSHOT=` line at all (matches rpm-family convention — RPM distros
   have no historical snapshot-mirror service; `scripts/update-snapshot.sh`
   globs `images/*/*/env` and only touches files declaring `SNAPSHOT=`, so
   omitting it means these are automatically skipped by the daily bump).
3. `tests/<distro>/{full,micro}.yaml` — container-structure-test specs,
   copied from `tests/fedora/*.yaml` (CA bundle path
   `/etc/pki/tls/certs/ca-bundle.crt`, `/var/lib/rpm` preserved, etc. —
   same rpm-family invariants).

**No changes to `build-rootfs-rpm.sh` or `hardening.sh`** — both are
already parameterized by release-package and branch on `dnf4`/`dnf5` and
`PKGFAMILY`, which is the point of the existing contract.

## CI and docs wiring

- Add matrix entries for all 5 new distro/version pairs to
  `.github/workflows/pr.yml`, `release.yml`, and `rescan.yml`
  `matrix.include` lists.
- Add rows to the README's image catalog table and the per-distro CVE
  badge table (reusing the existing `quay-pulls-badge.yml` per-distro
  loop pattern).

## Known risks / open questions

These can't be resolved without a live build — there's no local Docker
Desktop in this environment, so the first CI run on the PR is the actual
verification step, consistent with how this project has resolved similar
per-distro quirks before (EL8 missing `findutils`, Rocky/Alma mirrorlist
lag).

1. **CentOS Stream `--releasever` value**: the base image tag is
   `stream9`/`stream10`, but dnf's `$releasever` macro (used in mirror
   URLs like `.../9-stream/BaseOS/...`) likely needs to be `9`/`10`, not
   `stream9`. May require the env file or Dockerfile to carry the
   numeric releasever separately from the image tag.
2. **Amazon Linux has no standalone release package** like
   `fedora-release`/`almalinux-release`/`rocky-release` — AWS's own
   bootstrap docs skip that step entirely, and it's unconfirmed whether
   `dnf --installroot` ends up with a working
   `/etc/yum.repos.d/amazonlinux.repo` inside the installroot (needed for
   the later `chroot dnf upgrade` step). It's also unconfirmed whether
   `coreutils-single` (an EL/Fedora split package) exists in AL2023's
   repos — Amazon Linux may need `coreutils` instead, and possibly a
   distro-specific branch in `build-rootfs-rpm.sh` if the repo-config
   step doesn't just work. This is the highest-risk distro of the three
   and most likely to need a follow-up commit after the first CI failure.
3. Oracle Linux and CentOS Stream are structurally closer to the existing
   Alma/Rocky recipe and are lower risk.

## Testing / verification

- `make lint` (hadolint) and `make test VERSION=<v> FLAVOR=<full|micro>`
  locally where possible (build stage requires Docker, unavailable in
  this session).
- Push as a PR and rely on `pr.yml`: hadolint, amd64 build, structure
  tests, SBOM, grype+trivy CVE gate, dockle.
- Iterate on any CI failures per the risks above before merging.
