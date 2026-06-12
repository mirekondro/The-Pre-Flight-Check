---
tags: [infra]
---

# Release Pipeline

`.github/workflows/release.yml` — fires on a `vX.Y.Z` tag and ships every
[[Distribution Channels|channel]] hands-off.

1. **Build + verify** — wheel + sdist, `twine check`, sha256 checksums.
2. **GitHub release** — attaches the checksummed artifacts.
3. **PyPI publish** — Trusted Publishing (OIDC, no token); `skip-existing` so
   re-runs don't fail on an already-published version.
4. **Bump manifests** — patches the Homebrew formula + Scoop bucket, syncs the
   [[Homebrew Tap]] (via `TAP_TOKEN`), and opens a PR.

Tag → `git tag vX.Y.Z && git push origin vX.Y.Z`. Guarded by [[CI]].

Related: [[Distribution Channels]] · [[Homebrew Tap]] · [[CI]]
