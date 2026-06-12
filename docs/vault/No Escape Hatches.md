---
tags: [engine]
---

# No Escape Hatches

The core principle: **green means the bug is fixed, not hidden.**

On failure, the [[Engine]] emits a structured Markdown block naming the stage,
the exact command, and the tool output — the file, line, and rule the agent
must address:

```
### ❌ PRE-FLIGHT FAILURE: TYPECHECK
**Command Executed:** `npx --no-install tsc --noEmit`
**Context for AI Fix:**
src/auth/session.ts(42,18): error TS2345: …
```

The shape of this block is a **public contract** — changing it is a major
version bump.

Every [[AI Tool Adapters|adapter]] forbids the obvious cheats: `// @ts-ignore`,
`# type: ignore`, deleting failing tests, adding to ignore lists. Fix the error
or the gate stays red.

Related: [[Pipeline Stages]] · [[Engine]]
