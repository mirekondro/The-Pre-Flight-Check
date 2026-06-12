# Changelog

All notable changes to `pre-flight-check` are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
The shape of the `### ❌ PRE-FLIGHT FAILURE` Markdown block is part of the public
contract — any change to it is a **major** version bump.

## [Unreleased]

### Added
- Automated release pipeline (`.github/workflows/release.yml`): tagging `vX.Y.Z`
  builds the wheel + sdist, verifies them with `twine check`, attaches them with
  sha256 checksums to the GitHub release, and publishes to PyPI via Trusted
  Publishing (OIDC, no API-token secret).
- `CHANGELOG.md`, `SECURITY.md`, and Dependabot config.
- `.gitattributes` enforcing `eol=lf` to stop CRLF drift breaking bash CI on Windows.

### Fixed
- **Engine on Windows:** Node stages (`npm`/`npx`/`yarn`/`pnpm`/`tsc`/`eslint`)
  no longer fail with "command not found". The engine resolves each executable
  via `shutil.which()` and runs `.cmd`/`.bat` shims through the command
  interpreter, which `CreateProcess` cannot exec directly.
- **No false `SECURITY AUDIT` failure:** the audit stage is skipped when no
  lockfile is present (`npm`/`pnpm`/`yarn audit` error without one).
- **No false `TEST` failure:** the `npm init` placeholder test script
  (`echo "Error: no test specified" && exit 1`) is ignored.
- CI `package-smoke` on `windows-latest`: the pipx round-trip temp dir is now
  created and consumed in a single bash step, avoiding the missing `/tmp` mount
  in a fresh Git Bash shell.

## [1.2.0] - 2026-06-10

### Added
- Package-manager distribution: Homebrew formula, Scoop bucket, and the Claude
  Code plugin marketplace.
- pipx-installable `pre-flight-check` CLI (`init`, `uninstall`, `list-tools`,
  `--version`).

## [1.1.0] - 2026-06-10

### Added
- Multi-tool support: native adapter delivery for Codex/AGENTS.md, Gemini CLI,
  Cursor, Copilot, Windsurf, Cline, Kiro, Roo, and the Agent Skills standard.

## [1.0.0] - 2026-06-10

### Added
- Initial release: fail-fast Typecheck → Lint → Test → Security Audit pipeline
  for Node.js and Python, delivered as a Claude Code skill.

[Unreleased]: https://github.com/mirekondro/The-Pre-Flight-Check/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/mirekondro/The-Pre-Flight-Check/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/mirekondro/The-Pre-Flight-Check/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/mirekondro/The-Pre-Flight-Check/releases/tag/v1.0.0
