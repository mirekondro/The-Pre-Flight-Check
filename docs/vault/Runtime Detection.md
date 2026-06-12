---
tags: [engine]
---

# Runtime Detection

How the [[Engine]] decides what kind of project it is, from manifest files in
the current directory.

- `package.json` present → **node** → [[Node.js Runtime]]
- else `pyproject.toml` / `poetry.lock` / `requirements.txt` / `setup.py` /
  `setup.cfg` → **python** → [[Python Runtime]]
- otherwise → **unknown** → `PRE-FLIGHT SKIPPED: UNKNOWN RUNTIME`, exit 1

Node takes precedence when both manifests exist.

Related: [[Pipeline Stages]] · [[Engine]]
