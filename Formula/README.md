# Homebrew formula for `pre-flight-check`

This directory holds the canonical Homebrew formula. There are **three** ways users can install via Homebrew, in increasing order of ergonomic polish:

## 1. Direct formula install (works today, no tap setup)

```bash
brew install --formula https://raw.githubusercontent.com/mirekondro/The-Pre-Flight-Check/main/Formula/pre-flight-check.rb
```

Pros: zero setup; works from a fresh machine. Cons: not auto-updated by `brew upgrade`.

## 2. Tap from this repo by URL (recommended for early users)

```bash
brew tap mirekondro/pre-flight-check https://github.com/mirekondro/The-Pre-Flight-Check
brew install pre-flight-check
```

`brew upgrade pre-flight-check` then works as expected.

## 3. Dedicated tap repo `mirekondro/homebrew-pre-flight-check` (final form)

The canonical Homebrew convention is a sister repository named `homebrew-<tap>`. With that in place:

```bash
brew tap mirekondro/pre-flight-check        # implicit URL is github.com/mirekondro/homebrew-pre-flight-check
brew install pre-flight-check
```

To set this up, create a new GitHub repo `mirekondro/homebrew-pre-flight-check`, copy `Formula/pre-flight-check.rb` from this repo into it, and push. The release flow below keeps it in sync.

## Release flow (maintainer notes)

After tagging a new version `vX.Y.Z`:

1. **Compute the new sha256:**
   ```bash
   curl -sL https://github.com/mirekondro/The-Pre-Flight-Check/archive/refs/tags/vX.Y.Z.tar.gz | shasum -a 256
   ```
2. **Update `url` and `sha256`** in `Formula/pre-flight-check.rb`.
3. **Test locally:**
   ```bash
   brew install --build-from-source --formula ./Formula/pre-flight-check.rb
   brew test pre-flight-check
   brew uninstall pre-flight-check
   ```
4. **Sync to the tap repo** (if using the dedicated-repo flow):
   ```bash
   cp Formula/pre-flight-check.rb /path/to/homebrew-pre-flight-check/Formula/
   (cd /path/to/homebrew-pre-flight-check && git add . && git commit -m "pre-flight-check vX.Y.Z" && git push)
   ```

## Why we ship a Homebrew formula (not just `pipx install`)

- macOS dev environments are Homebrew-first; many users won't have `pipx` configured.
- `brew install` is one command. No `python3 -m pip install --user pipx && pipx ensurepath && pipx install ...`.
- Brew handles the Python version pin (`python@3.12`) automatically — users don't have to know the package requires Python ≥3.9.
- `brew upgrade` is the universal "keep my tools current" command on macOS.

## What the formula installs

The wheel built from this repo's `pyproject.toml`. After install:

```bash
pre-flight-check --version
pre-flight-check list-tools
pre-flight-check init --tool cursor --project
pre-flight-check run
```

See the [main README](../README.md) for full CLI usage.
