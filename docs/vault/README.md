# Architecture vault (Obsidian)

An [Obsidian](https://obsidian.md) vault documenting this codebase as an
interlinked knowledge graph. It is committed to the repo, so it stays in sync
with the code via normal git.

## Open it

1. Obsidian → **Open folder as vault** → select this `docs/vault/` folder.
2. Click the **graph view** icon in the left sidebar.
3. Start at **[[Pre-Flight Check]]** (the hub note).

Nodes are colour-grouped by area (engine, cli, distribution, tooling, infra,
docs) via the committed `.obsidian/graph.json`.

## Keeping it in sync

It's plain markdown under git — edit the notes alongside code changes and commit
as usual. For automatic two-way sync from inside Obsidian, install the community
**Obsidian Git** plugin and point it at this repo.

> Per-user state (`workspace.json`, caches) is gitignored; the shared graph and
> plugin config are tracked.
