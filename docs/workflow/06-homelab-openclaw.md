# Hybrid Workstation Model

> Documentation **v1.0.0** · Updated **2026-05-26** · [Index](README.md) · [Changelog](../../CHANGELOG.md)

Status:
- **Use now:** local Mac or dev-ai with tmux, Remote SSH IDE, GitLab MR loop.
- **Next infra step:** move long-running agents to `dev-ai` when laptop sleep or
  Docker/test load becomes painful.
- **Later:** OpenClaw is optional routing on homelab only — not required for V1.

Decision rule:
- short interactive work → local machine is fine;
- long/parallel Docker-heavy work → dev-ai + tmux;
- multi-agent routing pain after MR loop is stable → consider OpenClaw.

## Idea

Split roles:

```text
Mac           = UI, IDE, approve, Obsidian, phone /rc
dev-ai (24/7) = AI runtime, tmux, docker, tests, git push, glab
GitLab        = MR, CI, merge, deploy
```

You do **not** give up local IDE. You stop treating Mac as the only place
where code and agents live.

## When dev-ai is worth it

Move agent runtime to dev-ai when:
- you close the laptop and want work to continue;
- you run parallel MRs across related repos;
- docker/tests need stable RAM and uptime;
- homelab (Proxmox) is already available.

Keep everything on Mac when:
- short interactive sessions only;
- dev-ai is not provisioned yet.

## Homelab / Proxmox layout

Example on Minisforum N5 Pro or similar:

```text
Proxmox host
  ├── VM: dev-ai        # PRIMARY agent runtime (Ubuntu, 16–32 GB RAM)
  ├── LXC/VM: staging   # optional compose stack for integration tests
  └── storage           # VM backups — not live git workspace over NFS
```

`dev-ai` rules:
- local SSD disk for `~/work/` (not NFS-backed live clones);
- autostart VM on boot;
- Proxmox snapshot before large agent refactors;
- Tailscale for Mac → dev-ai SSH;
- no prod write credentials on dev-ai.

Connect from Mac:

```bash
ssh dev-ai                    # Tailscale hostname
tmux attach -t mr-1234
# or: scripts/ai-sessions --all
```

## IDE on Mac — three modes

Pick one per repo during migration. Prefer mode A when dev-ai exists.

### A) Remote SSH (recommended)

Single source of truth on dev-ai. Mac IDE edits remote files.

| IDE | Setup |
|-----|--------|
| PhpStorm | Settings → Remote Development → SSH → `dev-ai`, path `~/work/<repo>` |
| Cursor | Command Palette → Remote-SSH → `dev-ai` → open folder |
| VS Code | Remote - SSH extension → `dev-ai:~/work/<repo>` |

Pros: no drift, agent and IDE see same files, same docker on dev-ai.
Cons: needs network; offline editing hard.

### B) Local clone + git sync

Mac: `~/work/<repo>` local clone for IDE.
dev-ai: separate clone; sync via branches and `git pull`.

Use when Remote SSH is awkward (JetBrains indexing latency, travel offline).
Rule: **one active branch per task**; pull before IDE edit; push before
agent continues; never two uncommitted divergent trees.

### C) Transition — IDE local, agent local

Both on Mac until dev-ai is ready. Add `AGENTS.md`, snapshots, MR loop first.
Move runtime later; IDE can switch to mode A without changing git workflow.

## What runs where (steady state)

| Activity | Mac | dev-ai |
|----------|-----|--------|
| Claude / Codex long tasks | | ✅ tmux |
| tests, docker | | ✅ |
| `glab mr create`, push | | ✅ (primary) |
| PhpStorm debug PHP | ✅ Remote SSH | target |
| Cursor diff / manual fix | ✅ Remote SSH | target |
| Obsidian, docs reading | ✅ | |
| `/rc` mobile approve | ✅ (tunnel to dev-ai session) | process |
| GitLab CI deploy | | via GitLab |

## Laptop closed

| Agent location | Work continues? |
|----------------|-----------------|
| Mac local tmux | ❌ macOS sleep |
| dev-ai tmux | ✅ |
| Codex cloud | ✅ (separate model) |

Before closing Mac: detach tmux on dev-ai, update snapshot, or `ai-finish`.

## Gradual migration path

Do not big-bang. Suggested order:

### Step 1 — local machine, rules in git

- add `AGENTS.md`, `docs/ai/`, `.ai/SNAPSHOT.md` or `snapshots/`;
- keep PhpStorm / Cursor / VS Code on **local** clones;
- start using terminal agents beside IDE, not inside Cursor as primary;
- one MR loop with `glab` or `gh` when ready.

### Step 2 — discipline without new hardware

- `ai-start` / `ai-finish`, `ai-ship`, task snapshots;
- disable «agent as default» in Cursor for implementation tasks;
- cross-agent review before MR;
- IDE = viewer + manual edits only.

### Step 3 — dev-ai VM on Proxmox

- provision `dev-ai`, clone all related repos to `~/work/`;
- move tmux + Claude/Codex to dev-ai;
- Mac iTerm → `ssh dev-ai`;
- IDE → **Remote SSH** to dev-ai (mode A);
- `scripts/ai-sessions`, `index.jsonl`.

### Step 4 — multi-repo + parallel MR

- `ai-context` git, per-task snapshots, `active-tasks.md`;
- staging LXC optional;
- Obsidian symlinks to `docs/ai/` (optional).

### Step 5 — steady state homelab

- all long work on dev-ai;
- Mac rarely runs local agents;
- GitLab gates all deploys;
- homelab backups + Proxmox snapshots.

### Optional later — OpenClaw orchestration (homelab only)

**Prerequisite:** one pilot repo (e.g. `my-app`) with stable MR loop **without**
OpenClaw. See [OpenClaw entry criteria](#openclaw-entry-criteria).

OpenClaw adds an **optional** routing layer; it does not replace tmux, snapshots, or GitLab.

Deliverables:
- OpenClaw Gateway as systemd daemon on `dev-server` (`dev-ai`);
- **one agent profile to start:** `dev` (expand to `codex`, `review` later);
- workspace root: `$AI_WORK_ROOT/` (same tree as tmux);
- `AI_TASK` ↔ OpenClaw `session-key` aligned with snapshots;
- optional channels (Telegram/Slack) — **not** required for core dev loop;
- see [OpenClaw (Homelab Orchestration)](#openclaw-homelab-orchestration).

You can stay on steps 1–4 for weeks. Step 3 (dev-ai runtime) is the main infra move.
OpenClaw comes **after** the V1 MR loop and parallel snapshots feel stable.
Do **not** block the pilot MR loop on OpenClaw.

## SSH config example

`~/.ssh/config` on Mac:

```text
Host dev-ai
  HostName 100.x.x.x          # Tailscale IP
  User you
  IdentityFile ~/.ssh/id_ed25519_dev
  ForwardAgent no
  ServerAliveInterval 60
```

PhpStorm / Cursor / VS Code all reuse this host entry.

---

# OpenClaw (Homelab Orchestration)

## Role

[OpenClaw](https://github.com/openclaw/openclaw) — **optional orchestration layer**
on homelab compute only (`dev-server` / `dev-ai`). It routes work to coding
agents; it is **not** the source of truth for rules, memory, or deploy.

Use OpenClaw when:
- several agents (Claude, Codex, review) need coordinated routing;
- you want one homelab entry point instead of manually attaching tmux sessions;
- long tasks run 24/7 and you need session steering from outside SSH.

Do **not** use OpenClaw for:
- storing project rules (that stays in `AGENTS.md` / `docs/ai/`);
- replacing GitLab MR/CI/deploy gates;
- running on Mac as primary runtime;
- prod writes or bypassing `glab` + pipeline review.

Rule: **OpenClaw orchestrates; git + GitLab govern.**

---

## Where It Sits

```text
Mac / phone (optional)
  └── ssh → dev-ai
        └── openclaw gateway (systemd, localhost)

OpenClaw Gateway
  ├── routes task → agent (claude | codex | review)
  ├── session-key == AI_TASK (e.g. mr-1234)
  └── invokes work in $AI_WORK_ROOT/<repo>

tmux (unchanged)
  ├── session mr-1234  →  Claude / Codex CLI
  ├── pane: tests / docker / logs
  └── pane: git / glab

Repo (unchanged)
  ├── AGENTS.md, docs/ai/
  ├── .ai/snapshots/<AI_TASK>.md
  └── scripts/ai-start | ai-ship | ai-finish | ai-context

GitLab (unchanged)
  └── MR → CI → deploy
```

OpenClaw runs **only on homelab**. Mac stays thin client (SSH, IDE, Obsidian).
Channels (Telegram, Slack, etc.) are optional later — not required for dev
orchestration.

---

## Division Of Responsibility

| Concern | Owner |
|---------|--------|
| Agent routing, multi-agent handoff | OpenClaw Gateway |
| Persistent shell, long tasks | tmux on dev-ai |
| Task state, recoverable context | `.ai/snapshots/`, `ai-start` |
| Cross-repo schedule | `~/.ai/logs/index.jsonl`, `ai-sessions` |
| Execution rules | `AGENTS.md`, `.ai/rules/` |
| Code safety, review, deploy | git + `glab` + GitLab CI |

OpenClaw skills/plugins must **point at** repo contracts, not duplicate them:

```text
OpenClaw skill  →  "cd repo; export AI_TASK=…; scripts/ai-start; read AGENTS.md"
AGENTS.md       →  canonical policy (provider-neutral)
```

---

## Session Mapping

Keep one naming convention across layers:

```text
AI_TASK           = mr-1234
tmux session      = mr-1234
snapshot file     = .ai/snapshots/mr-1234.md
OpenClaw session  = agent:dev:mr-1234   # or --session-key mr-1234 --agent dev
```

Before OpenClaw dispatches work:

```bash
export AI_TASK=mr-1234
export AI_PROJECT=payment-hub
cd $AI_WORK_ROOT/payment-hub
scripts/ai-start
```

OpenClaw turn (illustrative — prefer `ai-openclaw-agent`):

```bash
ai-openclaw-agent mr-1234 $AI_WORK_ROOT/payment-hub \
  --message "Continue JWT fix per snapshot. Run ai-test. Update snapshot before stop."
```

Or manually:

```bash
openclaw agent \
  --agent dev \
  --session-key mr-1234 \
  --message "Continue JWT fix per snapshot. Run ai-test. Update snapshot before stop."
```

Prefer **gateway + tmux co-location**: OpenClaw decides *what* runs; tmux
keeps the agent process alive and visible.

---

## Install (dev-ai only)

Homelab path (`dev-server`). Verify the pilot repo first:

```bash
ai-openclaw-check $AI_WORK_ROOT/my-app
bootstrap-openclaw --install --check $AI_WORK_ROOT/my-app
openclaw onboard --install-daemon
openclaw gateway status
openclaw doctor
ai-openclaw-check --gateway $AI_WORK_ROOT/my-app
```

Manual install (same result):

```bash
npm install -g openclaw@latest   # ~/.local/bin, same as claude/codex
openclaw onboard --install-daemon
openclaw gateway status
openclaw doctor
```

Template config (optional): `bootstrap-openclaw` writes `~/.openclaw/openclaw.json`
from `templates/openclaw/openclaw.json` when missing.

Workspace defaults:
- repos: `$AI_WORK_ROOT/`
- config: `~/.openclaw/` (personal, not committed)
- gateway: localhost (Tailscale/SSH tunnel if needed from Mac)

Do **not** install OpenClaw gateway on Mac for steady state.

---

## OpenClaw entry criteria

Complete **before** turning on OpenClaw gateway for daily work:

| # | Criterion | How to verify |
|---|-----------|---------------|
| 1 | Pilot repo bootstrapped | `bootstrap-project`, `docs/ai/`, `AGENTS.md` |
| 2 | MR loop works without OpenClaw | branch → `ai-ship` → CI → merge (optional `--mr` for create) |
| 3 | tmux + `ai-session` habit | `ai-session <task> . --layout`, detach/attach |
| 4 | Snapshots recover context | `.ai/snapshots/<AI_TASK>.md`, `ai-start` / `ai-finish` |
| 5 | Agent hooks (optional but recommended) | `bootstrap-codex-hooks` / `bootstrap-claude-hooks` |
| 6 | `glab` auth on homelab | `glab auth status` on `dev-server` |
| 7 | One implementer per `AI_TASK` | no two agents editing same task |

**Next focus:** finish pilot repo + MR loop on homelab — **no OpenClaw required**.

OpenClaw is additive once the loop above is boring and repeatable.

---

## Minimal OpenClaw setup (start here)

Goal: **one gateway, one agent (`dev`), one workspace** — not multi-channel,
not four agent profiles on day one.

```text
dev-server (dev-ai)
  openclaw gateway          # systemd, localhost:18789 (default)
  ~/.openclaw/openclaw.json # personal, not in git
  $AI_WORK_ROOT/          # same as tmux repos

  agent:dev                 # primary orchestrator
    └── dispatches to tmux session == AI_TASK
        └── Claude Code or Codex CLI (your choice per task)
```

### Step 1 — install gateway (homelab only)

```bash
npm install -g openclaw@latest
openclaw onboard --install-daemon
openclaw gateway status
openclaw doctor
```

### Step 2 — minimal `~/.openclaw/openclaw.json`

Illustrative — adjust models to what you have auth for:

```json5
{
  agents: {
    defaults: {
      workspace: "$AI_WORK_ROOT",
      model: {
        primary: "anthropic/claude-sonnet-4-6",
        fallbacks: ["openai-codex/gpt-5.4"],
      },
      models: {
        "anthropic/claude-sonnet-4-6": { alias: "Sonnet" },
        "openai-codex/*": {},
      },
    },
    list: [
      {
        id: "dev",
        name: "Dev",
        model: { primary: "anthropic/claude-sonnet-4-6" },
        // system prompt: read scripts/ai-context, obey AGENTS.md, no prod deploy
      },
    ],
  },
}
```

Start with **`dev` only**. Add `codex` and `review` when routing pain is real,
not preemptively.

### Step 3 — wire session-key to AI_TASK

```bash
export AI_TASK=fix-login
export AI_PROJECT=my-app
cd $AI_WORK_ROOT/my-app
scripts/ai-start

openclaw agent \
  --agent dev \
  --session-key "$AI_TASK" \
  --message "Continue per snapshot. Smallest patch. No prod deploy."
```

Convention (unchanged):

```text
AI_TASK           = fix-login
tmux session      = fix-login
snapshot          = .ai/snapshots/fix-login.md
OpenClaw session  = agent:dev:fix-login
```

### Step 4 — co-locate with tmux (recommended)

OpenClaw decides **what** to run; tmux keeps the CLI agent **alive and visible**.

```bash
ai-session fix-login $AI_WORK_ROOT/my-app --agent claude --layout
scripts/ai-start
# agent pane: claude (or codex)
# other panes: tests, git/glab

# optional: steer from OpenClaw TUI or channel without losing tmux state
openclaw agent --agent dev --session-key fix-login --message "..."
```

Rule: **never** replace tmux with headless-only OpenClaw for long implementation
tasks — you lose attach/recover visibility.

---

## Model And Agent Routing

### Can OpenClaw switch models from chat?

**Yes — for the OpenClaw session**, not automatically for Claude/Codex inside tmux.

| Layer | Switch model how | Scope |
|-------|------------------|-------|
| **OpenClaw chat** | `/model`, `/model list`, `/model anthropic/claude-opus-4-6` | current OpenClaw session |
| **OpenClaw agent profile** | `/agent dev` or `--agent codex` | routing to different agent config |
| **Claude Code in tmux** | Claude's own model picker / settings | tmux pane only |
| **Codex in tmux** | Codex `/model` or config | tmux pane only |

OpenClaw `/model` changes which LLM **the gateway** uses for that session's turns.
It does **not** silently retarget an already-running Claude Code or Codex CLI
process in another tmux pane unless your `dev` agent skill explicitly sends a
command there.

Practical split:

```text
OpenClaw /model     → orchestration brain (task routing, summaries, nudges)
tmux claude|codex   → implementation runtime (edits, tests, git)
```

For Codex-native runs through OpenClaw (without tmux), model refs like
`openai/gpt-5.4` can use the **Codex runtime** — separate from ChatGPT-login
Codex CLI in tmux. Prefer one path per task to avoid double billing.

CLI equivalents (persistent config):

```bash
openclaw models list
openclaw models status
openclaw models set anthropic/claude-sonnet-4-6
openclaw config set agents.defaults.models '{"anthropic/claude-opus-4-6":{}}' --strict-json --merge
```

Gateway hot-reloads most model config — no restart for `/model` or
`agents.defaults.model` changes.

### Suggested model policy (homelab)

- **`dev` agent default:** strongest model you use for implementation planning
  (e.g. Sonnet).
- **Fallbacks:** cheaper/faster model for low-stakes chat — not for prod deploy
  decisions.
- **Allowlist:** set `agents.defaults.models` so `/model` cannot pick random
  providers.
- **Per-task override:** `/model` in OpenClaw session when reviewing vs coding —
  tmux CLI model unchanged unless you switch it separately.

---

## OpenClaw vs tmux CLI vs hooks

Three layers — complementary, not interchangeable:

| Layer | Owner | When it runs |
|-------|--------|--------------|
| **OpenClaw gateway** | homelab systemd | route task, multi-turn orchestration, optional channels |
| **tmux + Claude/Codex CLI** | execution | edits, shell, tests, `glab` |
| **Codex/Claude hooks + git hooks** | repo-local | auto-brief on SessionStart, bash guard, pre-commit |

```text
OpenClaw turn
  → skill: cd repo; export AI_TASK=…; scripts/ai-start
  → tmux pane runs claude|codex (hooks inject ai-brief)
  → agent edits; Stop hook blocks if dirty → `scripts/ai-ship -m "..."` [--mr]
```

OpenClaw must **not** duplicate:
- `AGENTS.md` / `docs/ai/` (read via `scripts/ai-context`);
- snapshot files (source of truth for task state);
- GitLab MR/CI/deploy gates.

See also: `docs/hooks.md`, `docs/agent-first-turn.md` in `terminal_ai_workflow`.

---

## OpenClaw rollout checklist (dev-server)

```text
[ ] Pilot repo MR loop proven (my-app or similar)
[ ] openclaw onboard --install-daemon
[ ] openclaw doctor clean
[ ] agents.list: only dev
[ ] workspace = $AI_WORK_ROOT
[ ] test: openclaw agent --agent dev --session-key test-task --message "ping"
[ ] test: same session-key + tmux attach -t test-task coexist
[ ] document model auth (API key vs Claude CLI vs Codex OAuth)
[ ] optional: codex + review agents
[ ] optional: Telegram/Slack channel
```

---

## Agent Profiles (suggested)

Configure minimal agents — orchestration roles, not domain dumps:

| Agent id | Role | Typical CLI |
|----------|------|-------------|
| `dev` | primary implementer | Claude Code in tmux |
| `codex` | implementation / debug | Codex CLI in tmux |
| `review` | diff-only review | second agent, no full repo scan |
| `ops-ro` | readonly diagnostics | tmux `ops-prod-ro`, no snapshots |

Each profile's system prompt: read `scripts/ai-context`, obey `AGENTS.md`,
never deploy without GitLab.

---

## Guardrails

Same as [Remote AI Execution](05-gitlab-remote-execution.md#remote-ai-execution) — OpenClaw does not relax them:

- no prod writes from agent or gateway user;
- no secrets export;
- deploy only via GitLab CI after MR merge;
- one active implementer per `AI_TASK`;
- budget caps on long/overnight runs (see [AI Cost And Quota](07-observability-governance.md#ai-cost-and-quota)).

OpenClaw must not hold GitLab deploy credentials. `glab mr create` and push
use normal git/SSH identity in tmux.

---

## When to add OpenClaw

| Situation | OpenClaw |
|-----------|----------|
| Learning tmux + snapshots + MR loop | skip |
| dev-ai runtime not stable yet | skip |
| Homelab steady, MR loop boring | optional experiment — one `dev` agent |
| Multi-agent routing pain is real | optional gateway + channels |

Prerequisites before OpenClaw:
- one pilot repo with working `bootstrap-project` → MR loop;
- `glab` authenticated on dev-ai;
- `AI_TASK` ↔ tmux ↔ snapshot convention enforced.

---

## What Not To Duplicate

Avoid maintaining two parallel systems:

```text
BAD   OpenClaw config  = full copy of AGENTS.md + architecture
GOOD  OpenClaw skill   = load repo AGENTS.md via ai-context

BAD   OpenClaw session = only memory of task state
GOOD  snapshot file    = recoverable state; OpenClaw reads it each turn

BAD   OpenClaw deploy hook
GOOD  glab mr create → GitLab pipeline → deploy job
```

Human visibility stays `scripts/ai-sessions` + tmux ls. OpenClaw is not a
replacement for `index.jsonl` — append lifecycle events from `ai-start` /
`ai-finish` as today.

---

## Homelab Example (dev-server)

Current layout maps cleanly:

```text
dev-server
  dev-ai/up.sh          → docker stacks (unchanged)
  OpenClaw gateway      → optional agent orchestration
  tmux + Claude/Codex   → execution (required on dev-ai for long work)
  $AI_WORK_ROOT/      → single repo tree
  glab                  → GitLab control plane
```

Mac connects via Tailscale/SSH; PhpStorm/Cursor Remote SSH to
`dev-server:$AI_WORK_ROOT/<repo>`.

---
