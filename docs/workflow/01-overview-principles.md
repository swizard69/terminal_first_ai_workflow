# Terminal-First AI Workflow

> Documentation **v1.0.0** · Updated **2026-05-26** · [Index](README.md) · [Changelog](../../CHANGELOG.md)

## Overview

Цель:
- уйти от Cursor-centric workflow;
- перейти к terminal-first разработке;
- использовать AI CLI агентов;
- хранить знания и правила вне IDE;
- построить общий AI context для связанных проектов;
- интегрировать workflow с GitLab;
- использовать Obsidian как knowledge base.

Переход **постепенный**. IDE на Mac (PhpStorm, Cursor, Visual Studio / VS Code)
остаются для просмотра и правок кода. AI runtime и long tasks со временем
переезжают на 24/7 compute (homelab / dev-ai VM на Proxmox / dev-server), Mac становится
thin client. OpenClaw — optional homelab-only orchestration layer.
См. [Hybrid Workstation Model](06-homelab-openclaw.md#hybrid-workstation-model), [OpenClaw (Homelab Orchestration)](06-homelab-openclaw.md#openclaw-homelab-orchestration).

---

# Core Principles

## IDE != центр системы

Cursor, PhpStorm, Visual Studio / VS Code должны быть:
- editor;
- diff viewer;
- debugger UI (breakpoints, stack traces);
- удобный UI для ручных правок.

Но не:
- основным AI runtime;
- источником памяти;
- orchestration layer;
- единственной машиной, где «живёт» код (при hybrid setup).

### Supported IDEs on Mac

| IDE | Роль в workflow | Remote к dev-ai |
|-----|-----------------|-----------------|
| **PhpStorm** | PHP/backend, refactor, debug | Remote Development Gateway (SSH) |
| **Cursor** | diff, быстрые правки, optional secondary AI | Remote SSH |
| **Visual Studio / VS Code** | frontend, polyglot | Remote - SSH |

Rule during migration: **agents in terminal on dev-ai**, IDE — read/edit
the same files via Remote SSH when possible. Avoid two divergent copies
of the repo without git sync.

Do NOT:
- run Cursor Agent as primary implementer while Claude/Codex work on dev-ai;
- store rules only in IDE settings — they belong in `AGENTS.md` / `.ai/`;
- commit from IDE and agent on different unmerged branches without awareness.

---

## Центр workflow

Центром становятся:

- terminal;
- git;
- tmux;
- AI CLI agents;
- GitLab;
- markdown knowledge base.

## Daily UX: Thin CLI First

The workflow is only useful if the daily path is short. Humans should work
with tasks, not with environment variables, snapshot paths, tmux rituals, or
provider-specific bootstrap steps.

Primary UX:

```bash
ai-task <task> <repo> --agent codex --layout
# agent works inside tmux
scripts/ai-ship -m "type(scope): summary" [--mr]
```

For a normal task, this should be enough. Everything else is plumbing,
debugging, or fallback.

Human-owned decisions:
- choose the task and repo;
- approve risky commands;
- inspect diff / MR;
- merge and deploy through GitLab gates.

Automated by wrappers:
- set `AI_TASK`, `AI_PROJECT`, `AI_AGENT`;
- create or attach the tmux session;
- create the `ai/<task>` branch when needed;
- create or load the task snapshot;
- run `ai-start` / `ai-brief`;
- maintain `~/.ai/logs/index.jsonl`;
- run tests, commit, push, and optionally create the MR through `ai-ship`;
- remind about snapshot/checkpoint updates.

Rule: if starting a task requires more than one primary command, the workflow
is not simple enough yet.

---

# Recommended Stack

## Terminal

### Recommended

- iTerm2
- tmux
- zsh
- starship

## AI Agents

### GPT

- OpenAI Codex CLI

### Claude

- Claude Code

---

# Architecture

## High Level

### Target (hybrid)

```text
Mac (thin client)
  ├── iTerm2 → ssh/mosh → dev-ai
  ├── PhpStorm / Cursor / VS Code → Remote SSH → dev-ai:~/work/
  ├── Obsidian
  └── git / glab (optional local, primary on dev-ai)

dev-ai (24/7 — Proxmox VM / dev-server, homelab)
  ├── OpenClaw Gateway (optional — orchestration only)
  ├── tmux
  │     ├── Claude Code
  │     ├── Codex CLI
  │     ├── tests / docker / logs
  │     └── glab
  ├── $AI_WORK_ROOT/  (all related repos)
  └── .ai/snapshots, logs, index.jsonl

GitLab
  ├── repositories
  ├── merge requests
  ├── pipelines
  ├── CI/CD
  └── deploy
```

### Bootstrap — local machine first

Until dev-ai is ready, the same layout works on Mac. Move runtime later;
keep `AGENTS.md`, snapshots, and MR loop from day one.

```text
Mac / Linux workstation
  ├── iTerm2
  │     └── tmux
  │           ├── Claude Code
  │           ├── Codex CLI
  │           ├── tests
  │           ├── logs
  │           ├── docker
  │           └── ssh
  │
  ├── PhpStorm / Cursor / VS Code  (local clone)
  ├── git
  ├── glab
  └── Obsidian

GitLab …
```

---
