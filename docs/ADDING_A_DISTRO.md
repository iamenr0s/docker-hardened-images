# Adding a new distribution

Each distro follows the same contract, so CI and scripts work unchanged:

1. `images/<distro>/Dockerfile` — multi-stage with targets `full` and `micro`,
   accepting a version build-arg, built from the distro's own bootstrap tool:
   - Debian/Ubuntu: `debootstrap --variant=minbase`
   - Fedora/AlmaLinux: `dnf --installroot=/rootfs --releasever=N
     --setopt=install_weak_deps=False install <minimal set>`
     (keep `/var/lib/rpm` in micro so scanners still work — the RPM
     equivalent of keeping `/var/lib/dpkg/status`)
2. `images/<distro>/<version>/env` — `VERSION`, distro-specific vars, `EXTRA_TAGS`
3. Reuse `images/common/hardening.sh` semantics: strip setuid, remove
   package manager binaries in micro, non-root 65532, lock root
4. `tests/<distro>/{full,micro}.yaml` structure tests
5. Add the version to the matrices in `pr.yml`, `release.yml`, `rescan.yml`

Invariants every image must hold:

- micro: no shell, no package manager binaries, USER 65532, zero setuid files
- package database preserved for SBOM/CVE scanners
- CA certificates + tzdata present
- multi-arch manifest (amd64 + arm64), identical on both registries
