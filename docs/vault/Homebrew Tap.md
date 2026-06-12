---
tags: [distribution]
---

# Homebrew Tap

`mirekondro/homebrew-pre-flight-check` — a dedicated tap repo so the install is
clean, with no GitHub URL:

```bash
brew tap mirekondro/pre-flight-check
brew install pre-flight-check
```

The formula is mirrored from the canonical `Formula/pre-flight-check.rb` in this
repo. The [[Release Pipeline]] pushes the updated formula here automatically on
each release (via the `TAP_TOKEN` secret), so the tap never goes stale.

Related: [[Distribution Channels]] · [[Release Pipeline]]
