<!--
Thanks for the PR. Fill out the sections below — terse is fine, blank is not.
For docs-only or typo fixes, you can skip the Test plan section.
-->

## Summary

<!-- One paragraph. What does this change and why. Link the issue it resolves. -->

Closes #

## Type

- [ ] 🐛 Bug fix (non-breaking)
- [ ] ✨ New feature (non-breaking — new runtime, new fixture, new flag)
- [ ] 💥 Breaking change (alters failure-block format, removes flag, changes default behavior)
- [ ] 📖 Documentation only
- [ ] 🛠️ Build / CI / installer change
- [ ] ♻️ Refactor (no behavior change)

## Scope checklist

<!-- Project philosophy gates — read CONTRIBUTING.md if any of these don't apply. -->

- [ ] No new Python runtime dependencies added to `run-pipeline.py`.
- [ ] No new configuration file introduced.
- [ ] No third-party tooling auto-installed on behalf of the user.
- [ ] If the failure-block Markdown shape changed, this is flagged as a breaking change above.
- [ ] If a new runtime was added, a fixture under `examples/<runtime>-broken/` is included.

## Test plan

<!--
What did you actually run? Include the exact commands and exit codes.
Untested PRs may sit. Smoke against at least one example fixture.
-->

- [ ] Syntax check: `python3 -c "import py_compile; py_compile.compile('skills/pre-flight-check/scripts/run-pipeline.py', doraise=True)"`
- [ ] `examples/node-broken/`: ran the pipeline, observed exit `1` + `### ❌ PRE-FLIGHT FAILURE: TYPECHECK`.
- [ ] `examples/python-broken/`: ran the pipeline, observed exit `1` + `### ❌ PRE-FLIGHT FAILURE: TYPECHECK`.
- [ ] Tested against a real project I work on (optional but encouraged — describe below).
- [ ] CI is green.

<details>
<summary>Real-project smoke output (optional)</summary>

```
<paste output here>
```

</details>

## SKILL.md impact

- [ ] No change to agent contract.
- [ ] Updated `SKILL.md` to reflect new behavior (describe below).

## Docs

- [ ] No user-visible change → no doc update needed.
- [ ] `README.md` updated.
- [ ] `INSTALL.md` updated.
- [ ] `examples/README.md` updated.
- [ ] N/A — docs-only PR.

## Anything else reviewers should know

<!-- Edge cases you noticed, tradeoffs you considered, follow-ups you'd like. -->
