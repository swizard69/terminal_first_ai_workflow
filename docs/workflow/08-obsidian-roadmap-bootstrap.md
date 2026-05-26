# Obsidian Knowledge Base

> Documentation **v1.0.0** · Updated **2026-05-26** · [Index](README.md) · [Changelog](../../CHANGELOG.md)

Status: **recommended practice, not a blocker**. Repo docs remain source of
truth; Obsidian should link or symlink to them instead of duplicating content.

## Why Obsidian

Recommended because:
- markdown-native;
- local-first;
- supports wiki-links;
- graph view;
- searchable;
- git-friendly.

---

# Suggested Vault Structure

```text
AI-Knowledge/
  Architecture/
  Projects/
  Infrastructure/
  AI/
  Decisions/
  Deploy/
  Prompts/
```

---

## Vault vs docs/ai/ — Single Source

Avoid duplicating content between Obsidian vault and per-repo `docs/ai/`.
Two sources of truth = both go stale.

Model: vault aggregates repo docs via symlinks, not copies.

```text
~/obsidian/AI-Knowledge/
  Projects/
    platform/        -> symlink to ~/work/platform/docs/ai/
    infra/           -> symlink to ~/work/infra/docs/ai/
  Architecture/
    cross-repo/      # only content that does NOT belong to any single repo
  Decisions/
    adr-001-...md    # ADRs that span multiple repos
  Prompts/           # personal prompts, not committed
```

Rules:
- repo-owned docs (`architecture.md`, `conventions.md`, `deploy.md`) live in repo;
- vault only adds wiki-links, tags, and cross-repo content;
- never edit symlinked files via Obsidian unless you intend to commit to the repo;
- ADRs that touch multiple repos live in vault, then referenced from each repo's `docs/ai/decisions.md`.

`scripts/ai-vault-link` — symlink `<repo>/docs/ai/` into the vault (global, PATH):

```bash
ai-vault-link $AI_WORK_ROOT/platform
ai-vault-link --all
VAULT=~/obsidian/AI-Knowledge ai-vault-link ./my-app --name my-app
```

See [scripts/ai-vault-link](../../scripts/ai-vault-link).

---

# Cross Links

## Example

```md
# Authentication System

See also:
- [[JWT Architecture]]
- [[Refresh Token Rotation]]
- [[Nuxt Auth Flow]]
- [[NestJS Auth Service]]
```

---

# Important Knowledge Categories

## Architecture

Store:
- architecture decisions;
- ADRs;
- diagrams;
- API contracts.

---

## Infrastructure

Store:
- docker topology;
- server notes;
- backup flows;
- deployment procedures;
- tailscale topology.

---

## AI Prompts

Store:
- debug prompts;
- review prompts;
- refactor prompts;
- deploy prompts.

---

# Long-Term Vision

## Final Form

```text
Mac       = IDE (PhpStorm, Cursor, VS Code), Obsidian, ssh client, /rc
dev-ai    = 24/7 compute (dev-server): tmux, agents, docker, $AI_WORK_ROOT/
OpenClaw  = homelab-only agent orchestration (optional)
Obsidian  = knowledge graph
GitLab    = execution control
tmux      = runtime (on dev-ai)
AGENTS.md = shared agent contract
CLAUDE.md = Claude adapter
Claude    = reasoning agent
Codex     = implementation/debug agent
Git       = safety layer
```

---

# Suggested Next Steps

## Gradual migration

See [Hybrid Workstation Model](06-homelab-openclaw.md#gradual-migration-path) for the full path.
Summary:

```text
Step 1  AGENTS.md + local IDE + terminal agents on Mac
Step 2  snapshots, ai-start/finish, Cursor not primary agent
Step 3  dev-ai VM, Remote SSH IDE, agents on tmux@dev-ai
Step 4  parallel MR snapshots, ai-context, staging LXC
Step 5  steady state — Mac = thin client, homelab = primary runtime
Later   OpenClaw gateway (optional) — after MR loop proven
```

**Recommended focus:** pilot repo + MR loop on homelab — **without OpenClaw first**.
Add OpenClaw when routing pain appears, not on day one.

Skip ahead only when the previous step feels stable.

## V1 Goal

Build a minimal working system before adding more skills or orchestration.
V1 success means the normal task loop is almost entirely driven by three
human-facing commands:

```bash
ai-task <task> <repo> --agent codex --layout
scripts/ai-sessions
scripts/ai-ship -m "type(scope): summary" [--mr]
```

Everything else (`ai-start`, `ai-finish`, `ai-index-event`, `ai-context`,
snapshot paths, `AI_TASK`) is implementation detail unless debugging.

V1 includes:
- `tmux`;
- `glab`;
- repo-local `AGENTS.md`;
- `manifest.md` with `repo_access`;
- `.ai/snapshots/` or `.ai/SNAPSHOT.md` for recoverable task state;
- `scripts/ai-sessions` + `~/.ai/logs/index.jsonl` for cross-task visibility;
- shared `docs/ai/`;
- Obsidian vault linked to repo docs;
- one repeatable MR loop.

Not in V1:
- OpenClaw gateway;
- full command replay / token accounting;
- skill manifests beyond the first useful skills;
- automatic branch pruning;
- multi-agent routing beyond an explicit reviewer pass.

---

## Step 1

Install:

```bash
brew install tmux
brew install glab
```

---

## Step 2

Create:

```text
~/ai/
~/work/
~/obsidian/
```

---

## Step 3

Move projects into:

```text
~/work/platform/
```

---

## Step 4

Create:

```text
AGENTS.md
CLAUDE.md
manifest.md
.ai/snapshots/           # if parallel MRs; else .ai/SNAPSHOT.md is enough
.ai/active-tasks.md      # optional index when using snapshots/
.ai/rules/
.ai/skills/
docs/ai/architecture.md
docs/ai/conventions.md
docs/ai/deploy.md
```

---

## Step 5

Create Obsidian vault:

```text
~/obsidian/AI-Knowledge/
```

---

## Step 6

Start terminal-first workflow:

**Primary path (local Mac or dev-ai):**

```bash
ai-task mr-1234 ~/work/platform --agent codex --layout
# agent works in tmux; hooks load ai-brief
scripts/ai-ship -m "fix(scope): summary" [--mr]
```

On dev-ai, run the same command after connecting:

```bash
ssh dev-ai
ai-task mr-1234 ~/work/platform --agent codex --layout
```

Open PhpStorm / Cursor / VS Code via Remote SSH to the same path on dev-ai.

Manual fallback, not the daily path:

```bash
cd ~/work/platform
export AI_TASK=mr-1234
tmux attach -t mr-1234 || tmux new -s mr-1234
scripts/ai-start
codex
```

---

## Bootstrap Files

Recommended minimal bootstrap (canonical list: [docs/scripts-sync.md](../scripts-sync.md)):

```text
terminal_ai_workflow/scripts/     # global PATH (~/.bashrc)
  ai-session, ai-task, ai-sessions, ai-index-event
  bootstrap-host, bootstrap-project, sync-ai-scripts, ai-vault-link
  ai-openclaw-check, bootstrap-openclaw, ai-openclaw-agent
  bootstrap-codex-hooks, bootstrap-claude-hooks
  bootstrap-ai-skills, bootstrap-ai-skills

<project>/scripts/                # copies (bootstrap-project / sync-ai-scripts)
  ai-context, ai-start, ai-finish, ai-ship, ai-brief, ai-test, php-lint, python-lint, node-lint
  ai-review, ai-sync-skills, switch-ai-state-mode, ai-tmux-layout
  ai-test.local                   # project-only, never overwritten

<project>/.codex/                 # Codex SessionStart + PreToolUse (optional)
<project>/.claude/                # Claude Code hooks in settings.json (optional)

templates/
  AGENTS.md
  CLAUDE.md
  manifest.md
  SNAPSHOT.md
  TASK_SNAPSHOT.md
  active-tasks.md
  MR_DESCRIPTION.md
  skills/global/, skills/project/<name>/   # bootstrap-ai-skills
```

See [docs/scripts-sync.md](../scripts-sync.md) for global vs copy model and updates.

`scripts/ai-task` wraps `ai-session` + branch + `ai-start` for new tasks (global, not copied).
`scripts/ai-ship` automates test + commit + push (+ optional `--mr`); merge stays human.
`scripts/ai-brief` feeds agent hooks; `ai-finish` is checklist/index only.
`scripts/ai-context` should print the files an agent must read before editing.
`scripts/ai-start` and `scripts/ai-finish` must honor `AI_TASK` for parallel MR snapshots.
`scripts/ai-sessions` aggregates tmux, `active-tasks.md`, snapshots, and `~/.ai/logs/index.jsonl`.
`scripts/ai-index-event` appends structured events to the machine-wide index.
`scripts/ai-sync-skills` should sync canonical `.ai/skills/` into provider-specific adapters.
`scripts/sync-ai-scripts` copies updated lifecycle scripts from `terminal_ai_workflow`
into project repos (see [docs/scripts-sync.md](../scripts-sync.md)).
`scripts/switch-ai-state-mode` should switch `repo_access` and update `.gitignore` safely.

---
