# Terminal-First AI Workflow

**Version 1.0.0** · [Changelog](CHANGELOG.md) · [Documentation versioning](docs/VERSIONING.md)

Terminal-first framework for long-running AI coding tasks: tmux sessions, task snapshots, Codex/Claude hooks, and a thin CLI (`ai-task`, `ai-sessions`, `ai-ship`).

Works with **GitLab or GitHub** (MR/PR flow via `glab` or `gh`). Optional remote dev server + Obsidian knowledge base.

Full docs: [docs/workflow/](docs/workflow/README.md).

## What is this?

A **bootstrap + scripts + docs** kit — not an AI product itself. You install it once on
your machine (or homelab `dev-ai`), then roll the same workflow into each git repo with
automation scripts — no manual copy-paste:

- **`bootstrap-project`** — `AGENTS.md`, `manifest.md`, `.ai/`, `docs/ai/`, project `scripts/`
- **`bootstrap-codex-hooks`** / **`bootstrap-claude-hooks`** — agent SessionStart hooks
- **`sync-ai-scripts`** — refresh lifecycle scripts after framework updates (`--all` for every repo)
- **`bootstrap-ai-skills`** — global + project skills

See [Install](#install) below.

It standardizes how **Claude Code** and **Codex CLI** work on real projects:

- one **tmux session** = one task (`AI_TASK`);
- recoverable **snapshots** instead of chat history as memory;
- **git + MR/PR** as the safety layer (`ai-ship`);
- rules in **`AGENTS.md`** and **`docs/ai/`**, not buried in IDE settings.

Think of it as an opinionated **dev workflow layer** around terminal agents — similar in
spirit to team conventions, but executable (scripts, hooks, lint gates).

## Who is it for?

**Good fit:**

- Solo devs or small teams who already use **Claude Code / Codex** in the terminal.
- **Multi-repo** setups (platform + frontend + infra) that need shared agent rules.
- People moving away from **Cursor-as-primary-implementer** but keeping IDE for debug/diff.
- **Homelab / dev-ai** users who want agents to survive laptop sleep (tmux on 24/7 box).
- PHP, Python, Node/Vue/Nuxt stacks — lint helpers and `ai-test.local` templates included.

**Probably not for you:**

- You want a hosted AI IDE only — no terminal, no git discipline.
- You need a turnkey SaaS — this repo is copy-paste scripts + markdown contracts.
- You expect the framework to replace **code review, CI, or deploy** — it routes work to git; humans/CI still merge and deploy.

## What problem does it solve?

| Pain | How this helps |
|------|----------------|
| Agent forgets context after detach | `.ai/snapshots/<task>.md` + `ai-start` / `ai-finish` |
| Too many env vars and tmux rituals | `ai-task` — one command to enter a task |
| Uncommitted work at end of session | `ai-ship` — test, commit, push, optional MR/PR |
| Rules live in Cursor/Claude UI only | `AGENTS.md`, skills, hooks — provider-neutral, in git |
| Laptop closed = work stops | Optional **dev-ai** + tmux; IDE via Remote SSH |

**Design goal:** the smallest repeatable loop — **enter task → work → ship through git**.

## Why Claude and Codex together?

**Two agents on purpose** — not vendor lock-in, not “install everything for fun.”

Models differ by task. The workflow lets you pick per session (`ai-task … --agent claude|codex`)
while keeping the same snapshots, hooks, and git ship path.

**Suggested split** (author opinion — models change, tune for your stack):

| Kind of work | Typical pick | Rationale |
|--------------|--------------|-----------|
| Design, UX flow, architecture, trade-offs, “what should we build?” | **Claude Code** | Strong reasoning, structure, cross-file intent |
| Implementation, debugging, tests, refactors to green CI | **Codex (GPT)** | Strong at precise patches and terminal work |

Rule of thumb today: **Claude for design/planning**, **GPT/Codex for writing and fixing code**
— then one human review + MR/PR either way.

You can use **one agent only**; bootstrap both hook sets so switching is cheap when the task
changes. Optional later: a second tmux pane or review pass with the other agent on the same diff.

Details: [Runtime: tmux And Agents](docs/workflow/02-runtime-tmux-agents.md).

## Install

```bash
git clone https://github.com/swizard69/terminal_first_ai_workflow.git ~/projects/terminal_first_ai_workflow
~/projects/terminal_first_ai_workflow/scripts/bootstrap-host
source ~/.bashrc
```

Set where your project repos live (default `~/projects`):

```bash
export AI_WORK_ROOT=~/projects   # optional if default is fine
```

Bootstrap a project:

```bash
# backend / generic
bootstrap-project $AI_WORK_ROOT/my-app --name my-app --type code

# frontend (Vue / Nuxt / React / Vite)
bootstrap-project $AI_WORK_ROOT/my-ui --name my-ui --type frontend

# hooks + scripts (both)
bootstrap-codex-hooks $AI_WORK_ROOT/<repo>
bootstrap-claude-hooks $AI_WORK_ROOT/<repo>
sync-ai-scripts $AI_WORK_ROOT/<repo>
bootstrap-ai-skills --global
```

## Obsidian (optional)

Repo `docs/ai/` is the source of truth. Obsidian is a local wiki for cross-links,
ADRs, and searchable architecture — not a second copy of repo docs.

Suggested vault layout:

```text
~/obsidian/AI-Knowledge/
  Projects/       # symlinks -> <repo>/docs/ai/
  Architecture/   # cross-repo notes only
  Decisions/      # multi-repo ADRs
  Prompts/        # personal, not committed
```

Link a bootstrapped project into the vault:

```bash
ai-vault-link $AI_WORK_ROOT/my-app
ai-vault-link --all   # every repo under AI_WORK_ROOT with docs/ai/
```

Rules:
- repo-owned docs (`architecture.md`, `conventions.md`, `deploy.md`) stay in git;
- vault adds wiki-links, tags, and content that spans repos;
- edit symlinked files in Obsidian only when you intend to commit back to the repo.

Full guide: [Obsidian, Roadmap, Bootstrap](docs/workflow/08-obsidian-roadmap-bootstrap.md).

## Homelab and OpenClaw (optional)

**Use now:** Mac or `dev-ai` with tmux, Remote SSH IDE, MR loop — no OpenClaw required.

**Later:** [OpenClaw](https://github.com/openclaw/openclaw) on homelab only — optional
orchestration layer. It routes work to agents; git + GitLab/GitHub still govern deploy.

```text
Mac / phone          →  ssh dev-ai
dev-ai (24/7)        →  tmux + Claude/Codex CLI (execution)
OpenClaw gateway     →  optional routing (localhost on dev-ai)
AGENTS.md + snapshots →  source of truth (unchanged)
```

Homelab path: tmux, snapshots, `glab`/`gh`, Remote SSH — add OpenClaw only after the MR loop is boring without it.

Check readiness on a pilot repo:

```bash
ai-openclaw-check $AI_WORK_ROOT/my-app
bootstrap-openclaw --install --check $AI_WORK_ROOT/my-app   # dev-ai only
openclaw onboard --install-daemon
ai-openclaw-agent fix-login $AI_WORK_ROOT/my-app \
  --message "Continue per snapshot. Smallest patch. No prod deploy."
```

Convention: `AI_TASK` = tmux session = snapshot stem = OpenClaw `--session-key`.  
Long implementation still lives in tmux — OpenClaw steers, not replaces it.

Full guide: [Homelab And OpenClaw](docs/workflow/06-homelab-openclaw.md).

## Daily Path

Use these as the normal human-facing commands:

```bash
ai-task <task> <repo> --agent codex --layout
scripts/ai-sessions
scripts/ai-ship -m "type(scope): summary" [--mr]
```

Everything else (`AI_TASK`, snapshot paths, `ai-start`, `ai-finish`, `ai-index-event`) is plumbing or debugging unless a task needs it.

## Reading Order

0. [Quickstart](docs/workflow/00-quickstart.md)  
   Daily commands for normal task work.
1. [Overview And Principles](docs/workflow/01-overview-principles.md)  
   Goals, core principles, daily UX, recommended stack, high-level architecture.
2. [Runtime: tmux And Agents](docs/workflow/02-runtime-tmux-agents.md)  
   tmux model, iTerm2 split, Claude/Codex roles.
3. [Context, Snapshots, Sessions](docs/workflow/03-context-snapshots-sessions.md)  
   `AGENTS.md`, `.ai/snapshots/`, handoff rules, `ai-sessions`, `index.jsonl`.
4. [Project Bootstrap And Hooks](docs/workflow/04-project-bootstrap-hooks.md)  
   repo layout, `manifest.md`, `ai-start`, `ai-ship`, Codex/Claude hooks.
5. [GitLab And Remote Execution](docs/workflow/05-gitlab-remote-execution.md)  
   MR loop, `glab`, remote execution guardrails, production safety.
6. [Homelab And OpenClaw](docs/workflow/06-homelab-openclaw.md)  
   dev-ai model, Remote SSH IDE setup, optional OpenClaw orchestration.
7. [Observability And Governance](docs/workflow/07-observability-governance.md)  
   cost/quota, logs, branch isolation, rollback, pruning.
8. [Obsidian, Roadmap, Bootstrap](docs/workflow/08-obsidian-roadmap-bootstrap.md)  
   vault model, V1 goal, bootstrap files, homelab migration notes.
9. [Skills System](docs/workflow/09-skills-system.md)  
   provider-neutral skills, sync model, recommended V1 skills.

## Implementation Status

Implemented in this repo:
- `ai-task`, `ai-session`, `ai-sessions` as global workflow commands;
- `ai-start`, `ai-brief`, `ai-finish`, `ai-ship` as project lifecycle scripts;
- task-aware snapshots and `ai-index-event`;
- Codex and Claude hook bootstrap scripts;
- project bootstrap and script sync helpers;
- initial global/project skill bootstrap;
- `ai-vault-link`, `ai-openclaw-check`, `bootstrap-openclaw`, `ai-openclaw-agent`;
- `php-lint`, `python-lint`, `node-lint` (docker or host);
- GitHub PR support in `ai-ship --mr` (via `gh`);
- `.github/workflows/ci.yml` + `scripts/ai-test.local` smoke tests;
- framework self-bootstrap (`.ai/snapshots/`, `active-tasks.md`);
- frontend: `node-lint`, `ai-test.local.frontend`, skills `frontend-patch` / `frontend-test`, `~/ai/vue-nuxt-style.md`.

Partial or planned:
- automatic `active-tasks.md` maintenance;
- full observability logs, command replay, and token accounting;
- branch pruning automation;
- full skill manifest validation and provider adapter generation;
- OpenClaw multi-agent profiles beyond `dev` (optional, later).

## Final Recommendation

Best overall strategy:

- terminal-first;
- thin CLI UX: `ai-task`, `ai-sessions`, `ai-ship` as the daily surface;
- GitLab-centric;
- markdown knowledge base;
- provider-independent rules;
- AI agents through CLI on `dev-ai` when long-running work matters;
- Mac as thin client: IDE, Obsidian, SSH, approvals;
- tmux sessions on compute that does not sleep;
- Obsidian for cross-linked architecture knowledge;
- homelab migration when long-running agents outgrow the laptop;
- OpenClaw only after the MR loop works without it.

Do not optimize for maximum automation first. Optimize for the smallest repeatable loop: one command to enter a task, one command to inspect running work, one command to ship through GitLab.
