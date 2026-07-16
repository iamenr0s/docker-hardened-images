# Docker Hardened Images

[![release](https://img.shields.io/github/actions/workflow/status/iamenr0s/docker-hardened-images/release.yml?label=release&logo=github)](https://github.com/iamenr0s/docker-hardened-images/actions/workflows/release.yml)
[![pr](https://img.shields.io/github/actions/workflow/status/iamenr0s/docker-hardened-images/pr.yml?label=pr&logo=github)](https://github.com/iamenr0s/docker-hardened-images/actions/workflows/pr.yml)
[![nightly](https://img.shields.io/github/actions/workflow/status/iamenr0s/docker-hardened-images/nightly.yml?label=nightly&logo=github)](https://github.com/iamenr0s/docker-hardened-images/actions/workflows/nightly.yml)
[![update-snapshot](https://img.shields.io/github/actions/workflow/status/iamenr0s/docker-hardened-images/update-snapshot.yml?label=update-snapshot&logo=github)](https://github.com/iamenr0s/docker-hardened-images/actions/workflows/update-snapshot.yml)
[![rescan](https://img.shields.io/github/actions/workflow/status/iamenr0s/docker-hardened-images/rescan.yml?label=rescan&logo=github)](https://github.com/iamenr0s/docker-hardened-images/actions/workflows/rescan.yml)
[![Signed with cosign](https://img.shields.io/badge/images-signed%20with%20cosign-2f80ed?logo=sigstore)](#supply-chain-security)
[![Dependabot](https://img.shields.io/badge/dependabot-enabled-brightgreen?logo=dependabot)](.github/dependabot.yml)
[![License](https://img.shields.io/github/license/iamenr0s/docker-hardened-images)](LICENSE)

A collection of minimal, hardened container base images built from scratch,
targeting **near-zero CVEs** through aggressive minimisation, reproducible
pinned builds, and a fully automated patch pipeline. All images are
multi-arch (**amd64 + arm64**), signed with **cosign**, and ship with
**syft** SBOMs attached as attestations.

Published to **Docker Hub** and **Quay.io** with identical multi-arch manifests.

## Available Images

| Build | Quay.io | Docker Hub |
|---|---|---|
| [![debian12](https://img.shields.io/github/actions/workflow/status/iamenr0s/docker-hardened-images/release.yml?label=debian12&logo=github)](https://github.com/iamenr0s/docker-hardened-images/actions/workflows/release.yml) | [![Quay Pulls](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fiamenr0s%2Fdocker-hardened-images%2Fbadges%2Fbadges%2Fquay-debian-hardened.json)](https://quay.io/repository/iamenr0s/debian-hardened?tab=tags&tag=12) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/debian-hardened?logo=docker)](https://hub.docker.com/r/iamenr0s/debian-hardened) |
| [![debian13](https://img.shields.io/github/actions/workflow/status/iamenr0s/docker-hardened-images/release.yml?label=debian13&logo=github)](https://github.com/iamenr0s/docker-hardened-images/actions/workflows/release.yml) | [![Quay Pulls](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fiamenr0s%2Fdocker-hardened-images%2Fbadges%2Fbadges%2Fquay-debian-hardened.json)](https://quay.io/repository/iamenr0s/debian-hardened?tab=tags&tag=13) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/debian-hardened?logo=docker)](https://hub.docker.com/r/iamenr0s/debian-hardened) |
| [![ubuntu22.04](https://img.shields.io/github/actions/workflow/status/iamenr0s/docker-hardened-images/release.yml?label=ubuntu22.04&logo=github)](https://github.com/iamenr0s/docker-hardened-images/actions/workflows/release.yml) | [![Quay Pulls](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fiamenr0s%2Fdocker-hardened-images%2Fbadges%2Fbadges%2Fquay-ubuntu-hardened.json)](https://quay.io/repository/iamenr0s/ubuntu-hardened?tab=tags&tag=22.04) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/ubuntu-hardened?logo=docker)](https://hub.docker.com/r/iamenr0s/ubuntu-hardened) |
| [![ubuntu24.04](https://img.shields.io/github/actions/workflow/status/iamenr0s/docker-hardened-images/release.yml?label=ubuntu24.04&logo=github)](https://github.com/iamenr0s/docker-hardened-images/actions/workflows/release.yml) | [![Quay Pulls](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fiamenr0s%2Fdocker-hardened-images%2Fbadges%2Fbadges%2Fquay-ubuntu-hardened.json)](https://quay.io/repository/iamenr0s/ubuntu-hardened?tab=tags&tag=24.04) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/ubuntu-hardened?logo=docker)](https://hub.docker.com/r/iamenr0s/ubuntu-hardened) |
| [![fedora44](https://img.shields.io/github/actions/workflow/status/iamenr0s/docker-hardened-images/release.yml?label=fedora44&logo=github)](https://github.com/iamenr0s/docker-hardened-images/actions/workflows/release.yml) | [![Quay Pulls](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fiamenr0s%2Fdocker-hardened-images%2Fbadges%2Fbadges%2Fquay-fedora-hardened.json)](https://quay.io/repository/iamenr0s/fedora-hardened?tab=tags&tag=44) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/fedora-hardened?logo=docker)](https://hub.docker.com/r/iamenr0s/fedora-hardened) |
| [![fedora43](https://img.shields.io/github/actions/workflow/status/iamenr0s/docker-hardened-images/release.yml?label=fedora43&logo=github)](https://github.com/iamenr0s/docker-hardened-images/actions/workflows/release.yml) | [![Quay Pulls](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fiamenr0s%2Fdocker-hardened-images%2Fbadges%2Fbadges%2Fquay-fedora-hardened.json)](https://quay.io/repository/iamenr0s/fedora-hardened?tab=tags&tag=43) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/fedora-hardened?logo=docker)](https://hub.docker.com/r/iamenr0s/fedora-hardened) |
| [![fedora42](https://img.shields.io/github/actions/workflow/status/iamenr0s/docker-hardened-images/release.yml?label=fedora42&logo=github)](https://github.com/iamenr0s/docker-hardened-images/actions/workflows/release.yml) | [![Quay Pulls](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fiamenr0s%2Fdocker-hardened-images%2Fbadges%2Fbadges%2Fquay-fedora-hardened.json)](https://quay.io/repository/iamenr0s/fedora-hardened?tab=tags&tag=42) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/fedora-hardened?logo=docker)](https://hub.docker.com/r/iamenr0s/fedora-hardened) |
| [![almalinux8](https://img.shields.io/github/actions/workflow/status/iamenr0s/docker-hardened-images/release.yml?label=almalinux8&logo=github)](https://github.com/iamenr0s/docker-hardened-images/actions/workflows/release.yml) | [![Quay Pulls](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fiamenr0s%2Fdocker-hardened-images%2Fbadges%2Fbadges%2Fquay-almalinux-hardened.json)](https://quay.io/repository/iamenr0s/almalinux-hardened?tab=tags&tag=8) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/almalinux-hardened?logo=docker)](https://hub.docker.com/r/iamenr0s/almalinux-hardened) |
| [![almalinux9](https://img.shields.io/github/actions/workflow/status/iamenr0s/docker-hardened-images/release.yml?label=almalinux9&logo=github)](https://github.com/iamenr0s/docker-hardened-images/actions/workflows/release.yml) | [![Quay Pulls](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fiamenr0s%2Fdocker-hardened-images%2Fbadges%2Fbadges%2Fquay-almalinux-hardened.json)](https://quay.io/repository/iamenr0s/almalinux-hardened?tab=tags&tag=9) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/almalinux-hardened?logo=docker)](https://hub.docker.com/r/iamenr0s/almalinux-hardened) |
| [![almalinux10](https://img.shields.io/github/actions/workflow/status/iamenr0s/docker-hardened-images/release.yml?label=almalinux10&logo=github)](https://github.com/iamenr0s/docker-hardened-images/actions/workflows/release.yml) | [![Quay Pulls](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fiamenr0s%2Fdocker-hardened-images%2Fbadges%2Fbadges%2Fquay-almalinux-hardened.json)](https://quay.io/repository/iamenr0s/almalinux-hardened?tab=tags&tag=10) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/almalinux-hardened?logo=docker)](https://hub.docker.com/r/iamenr0s/almalinux-hardened) |
| [![rockylinux8](https://img.shields.io/github/actions/workflow/status/iamenr0s/docker-hardened-images/release.yml?label=rockylinux8&logo=github)](https://github.com/iamenr0s/docker-hardened-images/actions/workflows/release.yml) | [![Quay Pulls](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fiamenr0s%2Fdocker-hardened-images%2Fbadges%2Fbadges%2Fquay-rockylinux-hardened.json)](https://quay.io/repository/iamenr0s/rockylinux-hardened?tab=tags&tag=8) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/rockylinux-hardened?logo=docker)](https://hub.docker.com/r/iamenr0s/rockylinux-hardened) |
| [![rockylinux9](https://img.shields.io/github/actions/workflow/status/iamenr0s/docker-hardened-images/release.yml?label=rockylinux9&logo=github)](https://github.com/iamenr0s/docker-hardened-images/actions/workflows/release.yml) | [![Quay Pulls](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fiamenr0s%2Fdocker-hardened-images%2Fbadges%2Fbadges%2Fquay-rockylinux-hardened.json)](https://quay.io/repository/iamenr0s/rockylinux-hardened?tab=tags&tag=9) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/rockylinux-hardened?logo=docker)](https://hub.docker.com/r/iamenr0s/rockylinux-hardened) |
| [![rockylinux10](https://img.shields.io/github/actions/workflow/status/iamenr0s/docker-hardened-images/release.yml?label=rockylinux10&logo=github)](https://github.com/iamenr0s/docker-hardened-images/actions/workflows/release.yml) | [![Quay Pulls](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fiamenr0s%2Fdocker-hardened-images%2Fbadges%2Fbadges%2Fquay-rockylinux-hardened.json)](https://quay.io/repository/iamenr0s/rockylinux-hardened?tab=tags&tag=10) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/rockylinux-hardened?logo=docker)](https://hub.docker.com/r/iamenr0s/rockylinux-hardened) |

Each distro's versions are published as tags of a single
`<distro>-hardened` repository per registry, so the pull counters are
repo-wide within a distro. The Quay badges show pulls over the last ~3
months (Quay exposes no all-time counter); refreshed daily by
[`quay-pulls-badge.yml`](.github/workflows/quay-pulls-badge.yml).

---

## Image catalog

| Distro | Versions | Flavors | Tags |
|---|---|---|---|
| Debian | 12 (bookworm), 13 (trixie) | `full`, `micro` | `12`, `12-full`, `12-micro`, `bookworm`, `13`, `13-full`, `13-micro`, `trixie`, `latest` |
| Ubuntu | 22.04 (jammy), 24.04 (noble) | `full`, `micro` | `22.04`, `22.04-full`, `22.04-micro`, `jammy`, `24.04`, `24.04-full`, `24.04-micro`, `noble`, `latest` |
| Fedora | 42, 43, 44 | `full`, `micro` | `42`, `42-full`, `42-micro`, `43`, `43-full`, `43-micro`, `44`, `44-full`, `44-micro`, `latest` |
| AlmaLinux | 8, 9, 10 | `full`, `micro` | `8`, `8-full`, `8-micro`, `el8`, `9`, `9-full`, `9-micro`, `el9`, `10`, `10-full`, `10-micro`, `el10`, `latest` |
| RockyLinux | 8, 9, 10 | `full`, `micro` | `8`, `8-full`, `8-micro`, `el8`, `9`, `9-full`, `9-micro`, `el9`, `10`, `10-full`, `10-micro`, `el10`, `latest` |

Version tags without a flavor suffix (e.g. `12`, `latest`) point to **micro**.
`latest` is per-distro repository (e.g. `ubuntu-hardened:latest` tracks the
newest Ubuntu micro build), not shared across distros.

## Flavors

| | `micro` (default) | `full` |
|---|---|---|
| Shell | ❌ removed | ✅ bash |
| Package manager | ❌ apt/dpkg binaries removed | ✅ apt (hardened defaults) |
| User | `65532:65532` (nonroot) | root (so apt works in build stages) |
| setuid/setgid binaries | ❌ zero | ❌ zero |
| Package DB for scanners | ✅ `/var/lib/dpkg/status` kept | ✅ |
| Intended use | final runtime base | build stages |

The dpkg **status file is deliberately preserved in micro** so syft, grype
and trivy can still inventory every installed package — minimisation never
comes at the cost of scannability.

### Typical usage

```dockerfile
FROM yourorg/debian-hardened:12-full AS build
RUN apt-get update && apt-get install -y --no-install-recommends mytool

FROM yourorg/debian-hardened:12
COPY --from=build /usr/bin/mytool /usr/bin/mytool
ENTRYPOINT ["/usr/bin/mytool"]
```

---

## How near-zero CVEs is achieved

1. **Minimal by construction** — rootfs built with
   `debootstrap --variant=minbase`; docs, man pages, locales and caches
   excluded permanently via dpkg path filters.
2. **Patched at build time** — security updates applied inside the rootfs
   from the archive, `-security` and `-updates` suites on every build.
3. **Daily snapshot bump** — `update-snapshot.yml` opens a PR pinning a
   newer snapshot each day; merging it (auto-merge recommended) ships
   patched images within 24h, with the full CI gate in between.
4. **Two-scanner gate** — CI fails on any **fixable** High/Critical
   (grype, cross-checked by trivy). Unfixable CVEs are tracked, not hidden.
5. **Continuous monitoring** — published images are rescanned every 6 hours;
   new findings automatically open a labeled security issue.

## Hardening applied

- Built `FROM scratch` — no inherited layers, no surprise content
- All setuid/setgid bits stripped (verified by structure tests)
- root account locked; non-root user `65532` provided (distroless convention)
- Network tooling removed (`curl`, `wget`, `nc`, `telnet`)
- In micro: no shell, no login tooling, no apt/dpkg binaries, no perl
- `Install-Recommends`/`Suggests` disabled; empty `/etc/machine-id`

## Reproducible builds

Debian and Ubuntu (the deb-family distros) pin a `SNAPSHOT` timestamp in
`images/<distro>/<version>/env`. debootstrap and all apt sources resolve
through the distro's snapshot service (`snapshot.debian.org` /
`snapshot.ubuntu.com`), and file mtimes plus `SOURCE_DATE_EPOCH` are
normalised to it. The same commit therefore rebuilds to the same package
set with byte-comparable layers, and package changes only ever enter through
an auditable snapshot-bump commit — never silently.

Set `SNAPSHOT=` (empty) to build against live mirrors instead.

Fedora, AlmaLinux and RockyLinux (the RPM-family distros) have no
historical snapshot pin — there's no public timestamp-mirror service for
`dnf` the way there is for `apt`. Their env files omit `SNAPSHOT=`
entirely; builds install from the live repos baked into the base image and
run `dnf upgrade` before sealing the rootfs, so freshness comes from the
daily nightly rebuild rather than a reproducible historical pin.

## Supply chain security

| Mechanism | Tool |
|---|---|
| SBOM (SPDX + CycloneDX) per image | syft |
| CVE gate + continuous rescan | grype + trivy |
| Keyless signing (Sigstore/Fulcio, GitHub OIDC) | cosign |
| SBOM attached as in-registry attestation | cosign attest |
| SLSA provenance (`mode=max`) | docker buildx |
| CIS image lint / Dockerfile lint | dockle / hadolint |

**Verify a published image:**

```bash
cosign verify \
  --certificate-identity-regexp 'https://github.com/YOURORG/hardened-images/\.github/workflows/.+' \
  --certificate-oidc-issuer 'https://token.actions.githubusercontent.com' \
  docker.io/YOURORG/debian-hardened:12
```

Inspect the SBOM attestation — see `policies/cosign-verify.md` for the full commands.

---

## Automation (GitHub Actions)

| Workflow | Trigger | Purpose |
|---|---|---|
| `pr.yml` | pull requests | hadolint + shellcheck, amd64 build, structure tests, SBOM, grype+trivy gate, dockle |
| `release.yml` | push to `main` / manual | pre-push CVE gate, multi-arch build & push to Docker Hub + Quay, SBOM, cosign sign + attest + verify |
| `update-snapshot.yml` | daily 01:00 UTC | bumps the pinned deb-family (Debian, Ubuntu) snapshot, opens the patch PR |
| `nightly.yml` | daily 02:17 UTC | rebuilds pinned images: fresh signatures, verifies reproducibility |
| `rescan.yml` | every 6h | grype-scans published tags, opens security issues on findings |
| `dependabot.yml` | weekly | pins/updates GitHub Actions and bootstrap image |

**Patch lifecycle:** upstream fix → snapshot bump PR (01:00) → CI gate →
merge → release build → signed multi-arch push → rescan confirms clean.

## Local development

Prerequisites: docker (buildx), hadolint, syft, grype, trivy,
container-structure-test.

```bash
make help                                    # list targets
make all                                     # lint, build, test, sbom, scan (debian 12 micro)
make all VERSION=13 FLAVOR=full
make all DISTRO=fedora VERSION=44 FLAVOR=full
make scan VERSION=12 FLAVOR=micro            # grype + trivy gate only
make push REGISTRIES="docker.io/you/debian-hardened quay.io/you/debian-hardened"
scripts/update-snapshot.sh                   # bump pin to yesterday's snapshot (deb-family only)
scripts/update-snapshot.sh 20260701T000000Z  # pin an explicit timestamp
```

## Repository layout

```
images/
  debian/  ubuntu/                  deb-family: debootstrap, apt/dpkg
    Dockerfile                      shared multi-stage build (targets: full, micro)
    12/env  13/env  22.04/env  ...  per-version metadata: SUITE, EXTRA_TAGS, SNAPSHOT pin
  fedora/  almalinux/  rockylinux/  rpm-family: dnf --installroot
    Dockerfile
    44/env  9/env  10/env  ...      per-version metadata: VERSION, EXTRA_TAGS (no SNAPSHOT)
  common/
    build-rootfs-deb.sh   debootstrap minbase for debian|ubuntu, snapshot-aware
    build-rootfs-rpm.sh   dnf --installroot for fedora|almalinux|rockylinux
    hardening.sh          setuid strip, root lock, micro minimisation (deb|rpm aware)
scripts/
  build.sh               buildx multi-arch build/push with tag fan-out
  sbom.sh                syft SPDX + CycloneDX generation
  scan.sh                grype + trivy gate (fails on fixable High/Critical)
  sign.sh                cosign keyless sign + SBOM attest + verify
  update-snapshot.sh     bump the pinned snapshot timestamp (deb-family env files only)
policies/
  grype.yaml             gate config + documented CVE exceptions
  trivy.yaml             trivy severity/unfixed settings
  cosign-verify.md       end-user verification commands
tests/<distro>/
  micro.yaml full.yaml   container-structure-test specs (invariants)
.github/workflows/       pr, release, update-snapshot, nightly, rescan
.github/dependabot.yml   actions + docker pin updates
Makefile                 local pipeline entry points
docs/ADDING_A_DISTRO.md  contract for new distributions
```

## CI setup (one-time)

1. Repository **variables**: `DOCKERHUB_ORG`, `QUAY_ORG`
2. Create a **`release` environment** (Settings → Environments) holding the
   secrets `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`, `QUAY_USERNAME`,
   `QUAY_TOKEN`, with its **deployment branch policy restricted to `main`**
   — no other branch or workflow can reach the push/signing credentials.
   Optionally add required reviewers there to manually approve every publish
   (at the cost of unattended patching).
3. Replace the `CHANGEME` placeholders in `Makefile`, `scripts/build.sh`
   and `.github/CODEOWNERS`
4. **`BOT_TOKEN` secret (recommended)** — a fine-grained PAT so the daily
   snapshot-bump PR runs the full `pr` pipeline. Without it the PR is
   opened with `GITHUB_TOKEN`, and GitHub's recursion guard means
   workflow-triggered checks (`pr.yml`) **never run on that PR** — only
   app checks (e.g. CodeQL) do. The release workflow's own grype/trivy
   gate still blocks bad publishes, but the PR itself is unverified.
   Create it under Settings → Developer settings → Fine-grained tokens:
   - Repository access: only this repo
   - Permissions: **Contents: read/write**, **Pull requests: read/write**
   - Save it as a repo secret named `BOT_TOKEN`
     (`gh secret set BOT_TOKEN`); `update-snapshot.yml` picks it up
     automatically and falls back to `GITHUB_TOKEN` when absent.
   Bonus: merges made with the PAT trigger `release.yml` immediately,
   instead of waiting for the 02:17 UTC nightly rebuild.
5. Branch protection on `main`: enable **auto-merge** and require status
   checks. With `BOT_TOKEN` in place, require the `pr` checks (and
   optionally review from Code Owners — `.github/CODEOWNERS` covers every
   path that changes what gets built or signed, but deliberately not
   `images/<distro>/<version>/env`, so env-only bump PRs merge unattended).
   **Without** `BOT_TOKEN`, only require checks that actually run on
   bot-created PRs (app-based ones) — requiring `pr` checks would leave
   the bump PRs blocked forever.
6. Recommended: enable GitHub issue label `security` (used by `rescan.yml`)

## CVE exceptions policy

The gate fails only on **fixable** High/Critical findings. If an unfixable
CVE must be temporarily accepted, add it to `policies/grype.yaml` under
`ignore:` with a reason **and a review date** — exceptions are documented,
time-boxed, and visible in git history.

## Adding a distro

See [`docs/ADDING_A_DISTRO.md`](docs/ADDING_A_DISTRO.md) for the full
contract. Debian and Ubuntu are deb-family (`debootstrap`, snapshot-pinned);
Fedora, AlmaLinux and RockyLinux are RPM-family (`dnf --installroot`, no
weak deps, `/var/lib/rpm` kept in micro — the RPM equivalent of the dpkg
status file). Every distro must satisfy the same invariants: no
shell/package manager in micro, `USER 65532:65532`, zero setuid files,
multi-arch, both registries, signed.

## Contributing

Contributions are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md) for the
local pipeline commands and pull request checklist. This project follows the
[Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md).

## Security

See [SECURITY.md](SECURITY.md) — GitHub private vulnerability reporting, no
public issues for security bugs.

## License

This project is licensed under the [MIT License](LICENSE).
