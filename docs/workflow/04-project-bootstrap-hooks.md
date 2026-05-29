# Project Bootstrap And Hooks

> Documentation **v1.0.0** · Updated **2026-05-26** · [Index](README.md) · [Changelog](../../CHANGELOG.md)

Status: **implemented enough for V1**. `bootstrap-project`, `sync-ai-scripts`,
`ai-start`, `ai-brief`, `ai-finish`, `ai-ship`, Codex hooks, and Claude hooks
exist. Use [Quickstart](00-quickstart.md) for daily commands.

## Global AI Context

Suggested layout for shared conventions outside any single repo:


```text
~/ai/
  global-rules.md
  php-style.md
  vue-nuxt-style.md
  nestjs-style.md
  sql-preprocessor.md
  vue-nuxt-style.md
  prompts/
    debug.md
    refactor.md
    review.md
```

---

## Purpose

Contains:
- coding conventions;
- architecture decisions;
- infra notes;
- preferred patterns;
- prompting templates.

---

# Project Structure

## Single Project

```text
project/
  AGENTS.md
  CLAUDE.md
  manifest.md
  .ai/
    snapshots/             # one file per parallel MR / task
    active-tasks.md        # optional index
    SNAPSHOT.md            # optional single-task legacy
    handoff/
    skills/
      debug/
      review/
      deploy/
    rules/
    hooks/
    logs/
  docs/
    ai/
      architecture.md
      deploy.md
      conventions.md
      context-load-order.md
  scripts/
    ai-context
    ai-start
    ai-finish
    ai-ship
    ai-brief
    ai-test
    php-lint
    python-lint
    node-lint
    switch-ai-state-mode
```

---

## Multi-Project Workspace

```text
~/work/
  ai-context/
    global-rules.md
    shared-conventions.md
    architecture.md
    api-contracts.md

  platform/
    frontend/
    backend/
    shared/
```

---

# Monorepo Strategy

## Recommended For

Especially useful for:
- Nuxt;
- NestJS;
- shared DTO;
- shared contracts;
- infra automation.

---

## Example

```text
platform/
  AGENTS.md
  CLAUDE.md

  frontend/
  backend/
  shared/

  docs/
    ai/
      architecture.md
      decisions.md
      deploy.md
      api-contracts.md
```

---

# AGENTS.md

## Purpose

Central rules for all AI agents.

---

## Example

```md
# AI agent rules

- Do not rewrite unrelated code.
- Always inspect existing patterns before editing.
- Prefer small patches.
- Never run destructive commands without explicit confirmation.
- Before changing DB or deploy logic, explain the risk.
- After changes, show:
  - files changed
  - reason
  - commands to test
```

---

# Lessons From Claude Code Starter

## Repository

Reference:

- https://github.com/alexeykrol/claude-code-starter

---

## Good Ideas

Useful concepts:
- `CLAUDE.md` as a short project passport, not a huge rule dump;
- `manifest.md` with explicit `project_name`, `project_type`, `repo_access`;
- modular `rules`, `skills`, `agents`, `hooks`;
- `SNAPSHOT.md` as recoverable project/session state;
- additive installer/migration instead of overwriting existing files;
- `repo_access` modes to avoid leaking agent memory into shared/public repos;
- hooks as background guardrails, not absolute enforcement.

---

## What To Reuse

Adapt the starter ideas into provider-neutral names:

```text
.claude/rules/       -> .ai/rules/
.claude/skills/      -> .ai/skills/
.claude/hooks/       -> .ai/hooks/
.claude/SNAPSHOT.md  -> .ai/SNAPSHOT.md
CLAUDE.md            -> provider adapter / project passport
AGENTS.md            -> generic agent contract
manifest.md          -> project metadata and repo_access
```

Core rule:
- `AGENTS.md` is the source of truth;
- `CLAUDE.md` is required, but only as a Claude-specific adapter;
- Claude-specific features must degrade cleanly for other agents.

Keep `CLAUDE.md` thin:
- project purpose;
- architecture summary;
- key contracts;
- pointer to `AGENTS.md`;
- pointer to `.ai/SNAPSHOT.md`.

Keep operational logic in:
- `AGENTS.md`;
- `.ai/rules/`;
- `.ai/skills/`;
- scripts.

---

## Repo Access Modes

Use explicit repository mode:

```text
repo_access=private-solo
repo_access=private-shared
repo_access=public
```

Meaning:
- `private-solo`: AI state may be committed if useful;
- `private-shared`: AI state stays local unless intentionally shared;
- `public`: AI state, logs, snapshots and private prompts stay local.

Never commit:
- `.env*`;
- keys and certificates;
- credentials;
- local databases;
- raw dumps;
- agent local logs;
- personal notes.

If AI state was already pushed to shared/public remote, `.gitignore` is not enough. Remove from index or rewrite/start fresh branch.

---

## Session State

Use task snapshots for long sessions and context recovery.

Single active MR:

```text
.ai/SNAPSHOT.md
```

Several parallel MRs (recommended when running multiple tmux sessions):

```text
.ai/snapshots/mr-1234.md
.ai/snapshots/mr-5678.md
.ai/active-tasks.md          # short index
```

Snapshot body sections:

```md
## Current State
## Done
## In Progress
## Known Issues
## Next Steps
## Last Validation
```

Update the **current task** snapshot:
- after meaningful work blocks;
- before switching to another tmux session / `AI_TASK`;
- after subagent work;
- at session finish.

Commit snapshots only when `repo_access` allows it.

Chat context lives in the agent process; tmux keeps it alive. Snapshots
replace chat memory after compaction, new session, or next-day attach.

---

## Start / Finish / Ship Skills

Lifecycle scripts (see [docs/scripts-sync.md](../scripts-sync.md)):

Daily commands:

`ai-task` (global PATH):
- primary entry point for humans;
- one-shot: `ai-session` + `git checkout -b ai/<task>` + `ai-start` + optional `--layout`;
- resume: same command attaches to existing tmux session (no duplicate `ai-start`).

`ai-sessions`:
- primary status command for humans;
- show tmux live sessions, repo `active-tasks.md`, snapshots, recent index;
- `--all` scans `~/work/*`; `--reconcile` flags stale index entries.

`ai-ship` (project copy):
- primary exit path for human-reviewed work;
- test → `ai-finish` index hook → commit tracked changes → push;
- `--mr` or `AI_SHIP_MR=1` → `glab mr create --fill --yes` if no open MR;
- merge MR in GitLab stays human.

Plumbing commands:

`ai-start`:
- resolve snapshot via `AI_TASK` → `.ai/snapshots/<task>.md`, else `.ai/SNAPSHOT.md`;
- append `start` or `attach` to `~/.ai/logs/index.jsonl` via `ai-index-event`;
- read `AGENTS.md`;
- check `git status`;
- check recent commits;
- print snapshot and report current state briefly.

`ai-brief`:
- compact briefing for agent hooks (`SessionStart` → Codex/Claude);
- snapshot excerpt + reminder to run tests and `ai-ship` at end.

`ai-finish`:
- checklist before detach (index event, snapshot sections);
- does **not** replace commit/push — use `ai-ship` for that.

See [Parallel MR Snapshots](03-context-snapshots-sessions.md#parallel-mr-snapshots) and
[Session Registry (ai-sessions)](03-context-snapshots-sessions.md#session-registry-ai-sessions).

---

## Hooks Model

Hooks are useful only as guardrails.

Good hook use:
- remind to update snapshot;
- warn before production files;
- block obvious secret commits;
- log session checkpoints;
- restore context after compaction.

Bad hook use:
- hidden deploys;
- automatic destructive cleanup;
- automatic broad staging;
- replacing GitLab CI gates.

### Example: pre-commit secret guard

`.ai/hooks/pre-commit-secret-guard.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# block obvious secrets in staged diff
PATTERN='(AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{30,}|-----BEGIN (RSA|OPENSSH) PRIVATE KEY-----|password\s*=\s*["'\''][^"'\'']{6,})'

if git diff --cached -U0 | rg -n --pcre2 "$PATTERN"; then
  echo "blocked: possible secret in staged changes" >&2
  exit 1
fi
```

Wire it via `git config core.hooksPath .ai/hooks` or symlink to
`.git/hooks/pre-commit`.

### Example: snapshot reminder hook

`.ai/hooks/post-commit-snapshot-reminder.sh`:

```bash
#!/usr/bin/env bash
if [ -n "${AI_TASK:-}" ] && [ -f ".ai/snapshots/${AI_TASK}.md" ]; then
  SNAP=".ai/snapshots/${AI_TASK}.md"
elif [ -f .ai/SNAPSHOT.md ]; then
  SNAP=.ai/SNAPSHOT.md
else
  exit 0
fi

AGE=$(( ( $(date +%s) - $(stat -f %m "$SNAP") ) / 60 ))
if [ "$AGE" -gt 60 ]; then
  echo "warn: $SNAP not updated for ${AGE}m — run ai-finish" >&2
fi
```

Rule: hooks must `exit 0` unless they intentionally block. Never run
network calls or deploys from hooks.

---

## Recommendation

Do NOT blindly install everywhere.

Recommended approach:

```bash
bash /path/to/claude-code-starter/init-project.sh --mode init --type code
```

Then:
- review generated files;
- keep useful patterns;
- rename Claude-specific pieces into `.ai/` where possible;
- keep `AGENTS.md` provider-independent;
- commit only after checking `repo_access`.

---

## Remove Framework From Repo

Bootstrap is additive; removal is explicit:

```bash
unbootstrap-project $AI_WORK_ROOT/<repo> --dry-run
unbootstrap-project $AI_WORK_ROOT/<repo> --yes --keep-snapshots
```

Uses `.ai/framework-manifest` when present (written by `bootstrap-project` and hook
installers). See [scripts-sync.md](../scripts-sync.md#remove-framework-from-repo).

Global tools (`ai-session`, `ai-task`, skills in `~/ai/skills/`) are **not** in the repo
and stay on the host.

---

## Important

Do not become Claude-specific.

Keep:
- AGENTS.md generic;
- shared rules provider-independent;
- CLAUDE.md as adapter, not source of truth;
- markdown portable.

---
