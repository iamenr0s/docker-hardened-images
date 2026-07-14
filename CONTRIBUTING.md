# Contributing

Thanks for taking the time to contribute to `docker-hardened-images`!

## Getting started

1. Fork the repository and create your branch from `main`.
2. You need `docker` (buildx), `hadolint`, `syft`, `grype`, `trivy`, and `container-structure-test` installed locally.

## Making changes

- Keep changes small and focused — one topic per pull request.
- Follow the pipeline contract in `CLAUDE.md`: `images/<distro>/Dockerfile` with `full`/`micro` targets, shared `images/common/build-rootfs.sh` and `hardening.sh`, per-version `images/<distro>/<version>/env`.
- Adding a new distro or version? Follow `docs/ADDING_A_DISTRO.md` and add it to the matrices in `pr.yml`, `release.yml`, and `rescan.yml`.
- Never remove `/var/lib/dpkg/status` (or `/var/lib/rpm`) in hardening — scanners need it to inventory packages.
- Package/CVE changes only enter through a snapshot bump — don't hand-edit package versions.

## Testing

Before opening a pull request, run the local pipeline for the flavor(s) you touched:

```bash
make lint                          # hadolint
make test VERSION=12 FLAVOR=micro  # container-structure-test (builds first)
make scan                          # grype + trivy CVE gate
```

Shell scripts must pass shellcheck (CI runs it on PRs).

## Submitting a pull request

1. Ensure `make all` (or the relevant subset above) passes locally for the flavor(s) you changed.
2. Fill in the pull request template.
3. A maintainer will review your PR; CI must be green before merge.

## Reporting bugs and requesting features

Use the issue templates — they ask for the details (distro, version, flavor, architecture) needed to reproduce a problem.

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating you agree to abide by it.
