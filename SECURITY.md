# Security Policy

## Supported versions

The latest released minor version receives security fixes.

| Version | Supported |
|---------|-----------|
| 1.2.x   | ✅        |
| < 1.2   | ❌        |

## Reporting a vulnerability

Please report security issues **privately** — do not open a public issue.

- Preferred: open a [private security advisory](https://github.com/mirekondro/The-Pre-Flight-Check/security/advisories/new).
- Or email **mirekondro@post.cz** with subject `SECURITY: pre-flight-check`.

Include a description, reproduction steps, and the version/commit affected.
You can expect an acknowledgement within **72 hours** and a fix or mitigation
plan once the report is validated.

## Why the surface is small

`pre-flight-check` ships with **zero runtime dependencies** — the pipeline engine
is a single Python file. It orchestrates your project's existing dev tooling
(`tsc`, `eslint`, `pytest`, `mypy`, …); it does not download or execute remote
code. Distributions are published to PyPI via OIDC Trusted Publishing (no
long-lived API token), and every release artifact carries a published sha256
checksum.
