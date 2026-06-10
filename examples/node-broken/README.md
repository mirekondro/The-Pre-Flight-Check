# Fixture: `node-broken`

A minimal Node.js / TypeScript project rigged to fail at **TYPECHECK** when `pre-flight-check` runs against it.

## What's broken

[`src/index.ts`](./src/index.ts) calls `greet(lookupUser("carol"))`. Under `tsconfig.json`'s `"strict": true`:

- `lookupUser` returns `string | undefined` (the user might not exist).
- `greet` requires `string`.
- TypeScript catches the unguarded undefined and refuses to compile.

Error code: **TS2345**.

## Reproduce

```bash
cd examples/node-broken
npm install
python3 ../../skills/pre-flight-check/scripts/run-pipeline.py
```

## Expected output

```
# Pre-Flight Check — runtime: node

→ [TYPECHECK] npm run typecheck --if-present

### ❌ PRE-FLIGHT FAILURE: TYPECHECK
**Command Executed:** `npm run typecheck --if-present`
**Context for AI Fix:**

```
> pre-flight-check-fixture-node-broken@0.0.0 typecheck
> tsc --noEmit

src/index.ts(21,23): error TS2345: Argument of type 'string | undefined' is not assignable to parameter of type 'string'.
  Type 'undefined' is not assignable to type 'string'.
```

Exit code: **1**. Stage: **TYPECHECK**. No subsequent stages run (fail-fast).

## How to make it pass

Two valid fixes — both demonstrate the protocol's "fix the root, don't suppress" rule:

```ts
// Option A — narrow at the call site
const user = lookupUser("carol");
if (user !== undefined) {
  console.log(greet(user));
}

// Option B — give greet a sensible default
function greet(name: string | undefined): string {
  return `Hello, ${name ?? "stranger"}!`;
}
```

What `SKILL.md` forbids:

```ts
// @ts-ignore — DO NOT do this. The skill instructs Claude to refuse this fix.
const message = greet(lookupUser("carol"));
```
