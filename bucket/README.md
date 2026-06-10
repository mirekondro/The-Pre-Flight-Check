# Scoop bucket for `pre-flight-check`

Windows users can install `pre-flight-check` via [Scoop](https://scoop.sh). This directory holds the canonical manifest.

## Install (works today)

```powershell
# Add the bucket from this repo
scoop bucket add pre-flight-check https://github.com/mirekondro/The-Pre-Flight-Check

# Install
scoop install pre-flight-check
```

`scoop update pre-flight-check` keeps it current. `scoop uninstall pre-flight-check` removes it cleanly.

## What the manifest does

1. Declares `python` as a Scoop dependency — Scoop installs it first if it's missing.
2. Downloads the platform-agnostic wheel from the GitHub release artifact.
3. Verifies the SHA256.
4. Runs `python -m pip install --prefix $dir\app --no-deps` to install the wheel into the Scoop app directory.
5. Exposes `app\Scripts\pre-flight-check.exe` on `PATH` (Scoop creates a shim).

After install:

```powershell
pre-flight-check --version
pre-flight-check list-tools
pre-flight-check init -Tool cursor -Project    # initialise in current repo
pre-flight-check run                            # run the gate
```

## Release flow (maintainer notes)

After tagging `vX.Y.Z`:

1. **Build the wheel** and **upload it as a release artifact** named `pre_flight_check-X.Y.Z-py3-none-any.whl`:
   ```bash
   python -m build --wheel
   gh release upload vX.Y.Z dist/pre_flight_check-X.Y.Z-py3-none-any.whl
   ```
2. **Compute and upload the sha256** so `autoupdate` works:
   ```bash
   shasum -a 256 dist/pre_flight_check-X.Y.Z-py3-none-any.whl \
     | awk '{print $1}' > pre_flight_check.sha256
   gh release upload vX.Y.Z pre_flight_check.sha256
   ```
3. **Update `version`, `url`, and `hash`** in `bucket/pre-flight-check.json` (or let Scoop's `checkver` automation do it).
4. **Test locally on a Windows machine** (or via GitHub Actions windows-latest):
   ```powershell
   scoop install ./bucket/pre-flight-check.json
   pre-flight-check --version
   scoop uninstall pre-flight-check
   ```

## Why we ship a Scoop manifest (not just `pipx install`)

- Windows-native install — no `winget install Python.Python.3.12 && pip install pipx && pipx ensurepath && pipx install ...` chain.
- Scoop auto-resolves Python as a dependency. The user doesn't need a working Python install first.
- `scoop update` is the universal "keep my tools current" command on Windows for dev tooling.
- Uninstall is clean (one `scoop uninstall`, no `pipx` residue).

## Why not winget?

`winget` is fine but its package submission cadence is slower and requires Microsoft's review. We can add a winget manifest later if there's demand — Scoop covers the same audience faster.
