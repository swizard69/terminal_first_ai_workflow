# tmux

> Documentation **v1.0.0** · Updated **2026-05-27** · [Index](README.md) · [Changelog](../../CHANGELOG.md)

## What is tmux

`tmux` = terminal multiplexer.

Позволяет:
- иметь несколько shell одновременно;
- делить экран;
- держать persistent sessions;
- reconnect после disconnect;
- запускать long-running tasks.

---

## Why tmux matters for AI

AI agents:
- долго работают;
- запускают тесты;
- анализируют repo;
- делают refactoring;
- запускают docker commands.

Нельзя терять сессии из-за:
- закрытия iTerm2;
- disconnect SSH.

**MacBook sleep останавливает локальные агенты.** tmux на Mac не переживает
system sleep. For overnight / closed-lid work, run tmux + agents on **dev-ai**
(24/7 compute), not on the laptop. See
[Hybrid Workstation Model](06-homelab-openclaw.md#hybrid-workstation-model).

---

## Example Workflow

Prefer named sessions per task instead of cramming many panes into one window.
5+ panes in a single window do not work on a 13" laptop.

Recommended pattern:

```bash
tmux new -s mr-1234        # one session per MR / task
tmux new -s ops-prod-ro    # readonly prod diagnostics
tmux new -s infra-docker   # long-running infra work
tmux ls                    # list sessions
tmux attach -t mr-1234     # resume
```

Inside a task session, 2-3 panes is enough:

```text
session mr-1234
  pane 1 -> claude or codex
  pane 2 -> tests / build / logs
  pane 3 -> git / glab
```

Naming rule:
- `mr-<id>` for MR work;
- `ops-<env>-<mode>` for ops sessions;
- `infra-<area>` for infrastructure;
- avoid generic names like `work`, `tmp`.

---

## Basic Commands

Install:

```bash
brew install tmux
```

Start:

```bash
tmux
```

Detach:

```text
Ctrl+b d
```

Attach:

```bash
tmux attach
```

---

# iTerm2 vs tmux

## iTerm2

Provides:
- UI;
- tabs;
- windows;
- fonts;
- clipboard;
- mouse;
- split panes.

---

## tmux

Provides:
- persistent runtime;
- sessions;
- reconnect;
- remote execution;
- process persistence.

---

## Correct Model

```text
iTerm2 = UI
tmux   = runtime/workspace
```

---

# AI Agents

Both **Claude Code** and **Codex CLI** are first-class. The framework does not pick a
winner — you choose per task (`ai-task … --agent claude|codex`). Same repo rules
(`AGENTS.md`), same snapshot, same `ai-ship`.

**Practical split (opinion, models evolve):**

- **Claude** — design, architecture, product/UX decisions, large refactors, unknown codebases.
- **Codex (GPT)** — implementation, debugging, tests, shell automation, small targeted patches.

Many teams use Claude to **plan** and Codex to **implement**, then ship through git.

---

## Claude Code

Best for:
- architecture and design reasoning;
- large repos and cross-project changes;
- refactoring plans and trade-off analysis;
- understanding unknown codebases.

---

## Codex CLI

Best for:
- writing and fixing code under test;
- precise patches;
- debugging;
- shell automation;
- targeted fixes and CI greening.

---
