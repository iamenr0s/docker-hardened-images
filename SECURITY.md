# Security Policy

## Supported Versions

Only the `latest` tag of each image (and the current Debian version's bare-version tag) receives security fixes. Images are rebuilt daily via the snapshot-bump and nightly workflows.

| Version | Supported |
| ------- | --------- |
| `latest` tag | ✅ |
| Current major version tags (e.g. `12`, `13`) | ✅ |
| Older / pinned snapshot tags | ❌ |

## Reporting a Vulnerability

Please **do not** open a public issue for security vulnerabilities.

Instead, report them privately via [GitHub private vulnerability reporting](https://github.com/iamenr0s/docker-hardened-images/security/advisories/new).

Include a description of the issue, steps to reproduce, and the affected image/tag/flavor/architecture if relevant.

You can expect an initial response within 7 days. Once the issue is confirmed, a fix will be released as soon as practical (via the CVE gate and release pipeline) and you will be credited in the release notes unless you prefer otherwise.

## Automated scanning

Published images are rescanned every 6 hours (`rescan.yml`); newly discovered CVEs automatically open a `security`-labeled issue.
