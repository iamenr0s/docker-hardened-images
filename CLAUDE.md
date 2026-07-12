# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Minimal, hardened container base images (currently Debian 12/13) built `FROM scratch` via debootstrap, targeting near-zero CVEs. Multi-arch (amd64+arm64), cosign-signed, syft SBOMs attached, published identically to Docker Hub and Quay.io. This is infrastructure code — no application source; everything is Dockerfiles, bash scripts, YAML policies, and GitHub Actions.

## Commands

Requires: docker (buildx), hadolint, syft, grype, trivy, container-structure-test.

```bash
make all                          # full local pipeline: lint, build, test, sbom, scan (debian 12 micro)
make all VERSION=13 FLAVOR=full   # variables: DISTRO, VERSION, FLAVOR, REGISTRIES
make lint                         # hadolint (config: .hadolint.yaml)
make build                        # scripts/build.sh — buildx, host arch only, --load
make test                         # container-structure-test against tests/<distro>/<flavor>.yaml (runs build first)
make scan                         # grype + trivy; fails on any FIXABLE High/Critical
make push                         # multi-arch build + push to all REGISTRIES
scripts/update-snapshot.sh        # bump SNAPSHOT pin in all images/debian/*/env to yesterday
```

There is no unit test framework; the "tests" are container-structure-test specs asserting image invariants. Run a single flavor's tests with `make test VERSION=12 FLAVOR=micro`. Shell scripts should pass shellcheck (CI runs it on PRs).

## Architecture

The build is a pipeline that all distros must fit:

1. **`images/<distro>/Dockerfile`** — single multi-stage Dockerfile per distro with build targets `full` and `micro` (the flavor IS the buildx `--target`). A `bootstrap` stage debootstraps a minbase rootfs into `/rootfs`, applies security upgrades inside a chroot, then per-flavor `harden-*` stages run `hardening.sh`, and final `FROM scratch` stages copy the rootfs in.
2. **`images/common/build-rootfs.sh`** — debootstrap + apt sources + dpkg path-excludes (docs/man/locales) + nonroot user 65532 + timestamp normalization. Shared across distros.
3. **`images/common/hardening.sh`** — strips all setuid/setgid bits, removes network tooling, locks root; in `micro` mode also removes apt/dpkg binaries, all shells, and perl — but deliberately KEEPS `/var/lib/dpkg/status` so syft/grype/trivy can still inventory packages. Never remove the package DB.
4. **`images/<distro>/<version>/env`** — per-version metadata sourced by `scripts/build.sh`: `SUITE`, `VERSION`, `EXTRA_TAGS`, and the `SNAPSHOT` pin.
5. **`scripts/`** — build.sh (buildx + tag fan-out: micro also gets the bare version tag, EXTRA_TAGS, latest), sbom.sh, scan.sh, sign.sh (cosign keyless, CI-only), update-snapshot.sh.
6. **`policies/`** — grype.yaml and trivy.yaml define the CVE gate; `tests/<distro>/*.yaml` encode the image invariants.

### Reproducibility model (central design constraint)

Every version pins a `SNAPSHOT` timestamp (snapshot.debian.org) in its `env` file. All apt/debootstrap sources resolve through that snapshot, and file mtimes are normalized to it — same commit rebuilds to the same package set. **Package changes only enter through a snapshot-bump commit** (the daily `update-snapshot.yml` workflow opens that PR); this is how security patches arrive. Empty `SNAPSHOT=` means live mirrors (non-reproducible, local experiments only).

### Invariants (enforced by tests/ and CI — do not break)

- micro: no shell, no package manager binaries, `USER 65532:65532`, zero setuid/setgid files
- package database preserved for scanners (`/var/lib/dpkg/status`, or `/var/lib/rpm` for RPM distros)
- CA certificates + tzdata present; multi-arch manifest identical on both registries
- full: root and apt intentionally kept (it's the build-stage flavor)

### CI (.github/workflows/)

- `pr.yml` — hadolint + shellcheck, amd64 build, structure tests, SBOM, grype+trivy gate, dockle
- `release.yml` — push to main: CVE gate, multi-arch push to both registries, cosign sign + attest + verify
- `update-snapshot.yml` (daily) / `nightly.yml` (rebuild + reproducibility check) / `rescan.yml` (6-hourly scan of published tags, opens `security` issues)

New distro versions must be added to the matrices in `pr.yml`, `release.yml`, and `rescan.yml`.

## Conventions

- Adding a distro: follow the contract in `docs/ADDING_A_DISTRO.md` — same targets, same env-file shape, same invariants, reuse `hardening.sh` semantics (RPM distros: `dnf --installroot`, weak deps off, keep `/var/lib/rpm`).
- CVE exceptions go in `policies/grype.yaml` under `ignore:` with a reason **and a review date**. The gate only fails on fixable findings, so exceptions should be rare.
- hadolint DL3008 (pin apt versions) is intentionally ignored — pinning is done via the snapshot, not per-package.
- `CHANGEME` in Makefile/build.sh/.github/CODEOWNERS is the org placeholder; registry config comes from the `REGISTRIES` env var (space-separated repo prefixes).
- Release gating model: pushes to `main` publish signed images unattended. CODEOWNERS requires human review for all code paths but deliberately not `images/<distro>/<version>/env`, so daily snapshot-bump PRs auto-merge. The `release` job runs in the `release` GitHub Environment (secrets scoped to `main`). Don't add code paths to the un-owned set.
