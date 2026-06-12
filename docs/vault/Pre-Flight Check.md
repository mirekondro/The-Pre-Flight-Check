---
tags: [moc]
aliases: [Home, Overview]
---

# ✈️ Pre-Flight Check

The map of this codebase. Open the **graph view** (left sidebar → graph icon)
to see how the pieces connect.

A fail-fast quality gate for AI coding agents: **Typecheck → Lint → Test →
Security Audit**, run before any task is marked done.

## Core

- [[Engine]] — the pipeline that runs the gates (`run-pipeline.py`)
- [[CLI]] — the `pre-flight-check` console script (`cli.py`)
- [[Installer]] — deploys adapter files into a project (`installer.py`)

## How a run works

[[Runtime Detection]] → [[Pipeline Stages]] → halt on first failure → emit the
[[No Escape Hatches|failure block]] the agent must fix.

## Reaching users

- [[Supported AI Tools]] via [[AI Tool Adapters]]
- [[Distribution Channels]] shipped by the [[Release Pipeline]]
- [[CI]] guards every change
- [[Website]] presents the project

## Principles

- [[No Escape Hatches]] — green means *fixed*, not suppressed.
- Zero runtime dependencies — the [[Engine]] is one vanilla-Python file.
