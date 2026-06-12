---
tags: [tooling]
---

# AI Tool Adapters

The `adapters/` directory holds the per-tool instruction files. Each AI tool
reads a different native file; the adapter is the same gate contract phrased for
that tool. At build time they are bundled into the package's `_data/` and
written out by the [[Installer]].

Every adapter restates the [[No Escape Hatches]] rules so the agent cannot mark
a gate green without fixing the underlying error.

See the full list and destinations in [[Supported AI Tools]].

Related: [[Installer]] · [[Supported AI Tools]]
