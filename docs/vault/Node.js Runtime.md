---
tags: [engine]
---

# Node.js Runtime

Builds [[Pipeline Stages]] for a `package.json` project.

- **Package manager** picked from the lockfile: `pnpm-lock.yaml` → pnpm,
  `yarn.lock` → yarn, `package-lock.json` → npm; else first available.
- **Prefers your scripts** — if `package.json` defines `lint`/`typecheck`/`test`,
  it runs `npm run <script>` instead of invoking the tool directly.
- **Placeholder test guard** — the `npm init` default
  (`"no test specified" && exit 1`) is ignored, never a false TEST failure.
- **Audit needs a lockfile** — the SECURITY AUDIT stage is skipped when no
  lockfile is present (npm/pnpm/yarn audit error without one).

Related: [[Runtime Detection]] · [[Pipeline Stages]] · [[Engine]]
