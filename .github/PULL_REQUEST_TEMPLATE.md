# Pull Request

## Description

What does this PR change and why?

## Type of change

- [ ] Bug fix
- [ ] New feature
- [ ] Documentation
- [ ] CI / tooling
- [ ] New distro / version

## Checklist

- [ ] `make lint` passes (hadolint + shellcheck)
- [ ] `make test VERSION=<version> FLAVOR=<flavor>` passes for the affected image(s)
- [ ] `make scan` passes with no new fixable High/Critical CVEs
- [ ] New distros/versions are added to the matrices in `pr.yml`, `release.yml`, and `rescan.yml`
- [ ] Follows the [contributing guidelines](../CONTRIBUTING.md)

## Related issues

Closes #
