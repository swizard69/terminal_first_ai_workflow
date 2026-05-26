# AI Context Strategy

> Documentation **v1.0.0** · Updated **2026-05-26** · [Index](README.md) · [Changelog](../../CHANGELOG.md)

Status: **core implemented**. `AGENTS.md`, `scripts/ai-context`, task-aware
snapshots, `ai-index-event`, and `ai-sessions` exist. Some `active-tasks.md`
maintenance and richer handoff automation are still manual.

## Main Idea

AI memory and rules must NOT live only inside:
- Cursor;
- Claude;
- Codex.

They must live in:
- git repo;
- markdown files;
- shared context folders.

---

## Source Of Truth Model

```text
repo/AGENTS.md        -> generic execution rules for all agents
repo/CLAUDE.md        -> Claude Code adapter and project passport
repo/docs/ai/         -> project-specific context
shared ai-context git -> cross-project contracts and conventions
~/ai/                 -> personal defaults and reusable prompts
Obsidian              -> knowledge graph, ADRs, notes, links
```

Rule:
- if an agent must obey it, keep it in git;
- if humans need to understand it, link it from Obsidian;
- if it is personal preference, keep it in `~/ai/`.

---

## Multi-Agent Contract

This is a multi-agent framework, not a Claude framework.

Required files:
- `AGENTS.md` — canonical contract for every AI agent;
- `CLAUDE.md` — Claude Code adapter that points back to `AGENTS.md`;
- optional provider adapters later: `CODEX.md`, `GEMINI.md`, etc.

Priority order:

```text
AGENTS.md      -> must be provider-neutral
.ai/rules/     -> reusable operational rules
.ai/skills/    -> reusable workflows
CLAUDE.md      -> Claude-specific bootstrap only
docs/ai/       -> project knowledge
```

Rule: never put core policy only into `CLAUDE.md`. If Codex, Claude and another agent must follow it, it belongs in `AGENTS.md` or `.ai/rules/`.

---

## Context Loading Protocol

Before editing code, every AI agent should read:

1. `AGENTS.md`
2. provider-specific adapter if available: `CLAUDE.md`, `CODEX.md`, etc.
3. `docs/ai/architecture.md`
4. `docs/ai/conventions.md`
5. task-related files
6. existing tests around the touched area

Agent must not assume project conventions from global memory when repo-local rules exist.

---

## Multi-Agent Context Handoff

Multiple agents (Claude + Codex + future) must share state without
overwriting each other. Race conditions on `.ai/SNAPSHOT.md` are the
main failure mode.

Rules:

- one tmux session / `AI_TASK` has exactly one snapshot owner;
- owner is the agent that started the session (recorded in snapshot header);
- non-owners may read the task snapshot, but write only to `.ai/handoff/<task>/<agent>.md`;
- handoff files are merged into the task snapshot by the owner at session end;
- `ai-finish` of the owner is the only path that commits snapshot files.

Snapshot header (single-task repos use `.ai/SNAPSHOT.md`; parallel MRs use
`.ai/snapshots/<task>.md`):

```md
# Task Snapshot

task: mr-1234
owner: claude
branch: ai/fix-auth-1234
started_at: 2026-05-22T10:00:00Z
last_update: 2026-05-22T11:42:00Z
```

Handoff layout:

```text
.ai/
  snapshots/
    mr-1234.md             # owner-only writes (parallel MR mode)
  SNAPSHOT.md              # optional legacy single-task file
  handoff/
    mr-1234/
      codex.md             # non-owner notes for this task
      review-agent.md
    codex.md               # flat layout when only one active task
```

Cross-agent rule:
- if Claude designed the change, Codex implements it, both must read snapshot;
- Codex writes results into `handoff/<task>/codex.md` (or `handoff/codex.md` for single-task repos);
- Claude (owner) reads handoff and updates the task snapshot;
- no agent edits another agent's handoff file.

For several active MRs in one repo, use per-task snapshots — see
[Parallel MR Snapshots](#parallel-mr-snapshots).

---

## Parallel MR Snapshots

### Problem

One `.ai/SNAPSHOT.md` per repo breaks when two tmux sessions work on
different MRs at the same time:

```text
tmux -s mr-1234   -> auth fix
tmux -s mr-5678   -> cache bug
```

Both agents overwrite the same file. Chat context stays inside each
tmux session, but **task state on disk must be isolated per MR**.

### Model

```text
tmux session     = one MR / task id
chat context     = inside the agent process (tmux keeps it alive)
task snapshot    = .ai/snapshots/<task>.md   (durable, on disk)
handoff          = .ai/handoff/<task>/*.md   (per task, not shared)
```

Rule: **never write another task's snapshot**. One owner per task file.

### Layout

```text
.ai/
  snapshots/
    mr-1234.md             # task state for tmux session mr-1234
    mr-5678.md
  handoff/
    mr-1234/
      codex.md
      review-agent.md
    mr-5678/
      codex.md
  active-tasks.md          # index only — no long-form state
  logs/
    2026-05-22/
      mr-1234/
      mr-5678/
```

`.ai/SNAPSHOT.md` is optional legacy. Prefer `snapshots/<task>.md`.
If both exist, `ai-start` uses `AI_TASK` to pick the file.

### Task id convention

Match tmux session name and branch namespace:

```text
tmux session:  mr-1234
branch:        ai/fix-auth-1234
AI_TASK:       mr-1234
snapshot:      .ai/snapshots/mr-1234.md
```

For work before MR exists:

```text
tmux session:  task-cache-refactor
branch:        ai/cache-refactor
AI_TASK:       task-cache-refactor
```

### Snapshot header (per task)

```md
# Task Snapshot

task: mr-1234
owner: claude
branch: ai/fix-auth-1234
repo: platform-backend
started_at: 2026-05-22T10:00:00Z
last_update: 2026-05-22T11:42:00Z

## Current State
## Done
## In Progress
## Known Issues
## Next Steps
## Last Validation
```

### active-tasks.md (index, not snapshot)

Short index for humans and `ai-start` without `AI_TASK`:

```md
# Active Tasks

| task | branch | owner | last_update |
|------|--------|-------|-------------|
| mr-1234 | ai/fix-auth-1234 | claude | 2026-05-22T11:42:00Z |
| mr-5678 | ai/cache-bug | codex | 2026-05-21T16:10:00Z |
```

Update the row on every snapshot write. Do not put long narrative here.

### Environment contract

Set in each tmux session before starting the agent:

```bash
export AI_TASK=mr-1234
export AI_PROJECT=platform-backend   # optional, for logs
```

Add to shell profile inside task sessions, or a tiny wrapper:

```bash
# ~/bin/ai-session
#!/usr/bin/env bash
set -euo pipefail
TASK="${1:?usage: ai-session <task-id> [repo-dir]}"
REPO="${2:-.}"
tmux new-session -ds "$TASK" "cd '$REPO' && export AI_TASK='$TASK' && exec \$SHELL"
tmux attach -t "$TASK"
```

### ai-start (task-aware)

`scripts/ai-start`:

```bash
#!/usr/bin/env bash
set -euo pipefail

TASK="${AI_TASK:-}"
if [ -z "$TASK" ]; then
  if [ -f .ai/SNAPSHOT.md ] && [ ! -d .ai/snapshots ]; then
    SNAP=.ai/SNAPSHOT.md
  else
    echo "error: set AI_TASK or use single-task .ai/SNAPSHOT.md" >&2
    exit 1
  fi
else
  SNAP=".ai/snapshots/${TASK}.md"
  mkdir -p .ai/snapshots ".ai/handoff/${TASK}"
  if [ ! -f "$SNAP" ]; then
    cat > "$SNAP" <<EOF
# Task Snapshot

task: ${TASK}
owner: unknown
branch: $(git branch --show-current 2>/dev/null || echo unknown)
started_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
last_update: $(date -u +%Y-%m-%dT%H:%M:%SZ)

## Current State
(started)

## Done

## In Progress

## Known Issues

## Next Steps

## Last Validation
EOF
  fi
fi

echo "=== ai-start ==="
echo "snapshot: $SNAP"
echo "branch:   $(git branch --show-current 2>/dev/null || true)"
echo "status:"
git status -sb 2>/dev/null || true
echo
echo "read order:"
scripts/ai-context 2>/dev/null || true
echo
echo "--- snapshot ---"
cat "$SNAP"
```

Agent workflow after `ai-start`:
1. read snapshot for this `AI_TASK` only;
2. read `AGENTS.md` and `docs/ai/*`;
3. do not read other tasks' snapshots unless explicitly handoff.

### ai-finish (task-aware)

`scripts/ai-finish`:

```bash
#!/usr/bin/env bash
set -euo pipefail

TASK="${AI_TASK:-}"
if [ -n "$TASK" ]; then
  SNAP=".ai/snapshots/${TASK}.md"
else
  SNAP=".ai/SNAPSHOT.md"
fi

[ -f "$SNAP" ] || { echo "error: missing $SNAP — run ai-start first" >&2; exit 1; }

echo "=== ai-finish ==="
echo "snapshot: $SNAP"
echo "Run focused tests, inspect diff, then update $SNAP and active-tasks.md."
echo "Commit snapshot only when repo_access allows."
```

Owner agent must:
- merge `handoff/${AI_TASK}/*.md` into `snapshots/${AI_TASK}.md`;
- refresh `last_update` in snapshot header;
- update the matching row in `active-tasks.md`;
- run tests and note results under `## Last Validation`;
- commit allowed snapshot files with the code MR or in a dedicated WIP commit.

### Switching tmux sessions

Chat context does **not** travel between sessions. On attach:

```bash
tmux attach -t mr-5678
export AI_TASK=mr-5678
scripts/ai-start    # reload task snapshot into a new or compacted chat
```

Before detach from `mr-1234`:
- update `.ai/snapshots/mr-1234.md`;
- or run `ai-finish` if stopping for the day.

### Parallel rules (summary)

- one tmux session = one `AI_TASK` = one snapshot file;
- one owner agent per task snapshot;
- handoff is scoped to `.ai/handoff/<task>/`;
- logs go to `.ai/logs/<date>/<task>/`;
- never edit another task's snapshot or handoff directory;
- `active-tasks.md` is an index, not a merge target for all tasks;
- prefer one active coding MR per repo if snapshots feel heavy — ops
  sessions (`ops-prod-ro`) do not need snapshots.

### Single-task repos

If you never run parallel MRs, keep flat layout:

```text
.ai/SNAPSHOT.md
.ai/handoff/codex.md
```

`ai-start` without `AI_TASK` continues to work.

---

## Session Registry (ai-sessions)

### Problem

Task state, live processes, and agent chat transcripts live in different
places. There is no single built-in "chat list" from Claude or Codex that
aligns with `AI_TASK`, tmux, or MR workflow.

Use three coordinated layers plus one aggregator command.

### Three layers

```text
Layer 1 — live runtime (machine)
  tmux ls
  -> what processes are running right now

Layer 2 — repo task index (git or local)
  .ai/active-tasks.md
  .ai/snapshots/<task>.md
  -> what tasks exist and their distilled state

Layer 3 — machine-wide registry (personal, not committed)
  ~/.ai/logs/index.jsonl
  -> cross-repo timeline: start/stop, attach, project, task, agent

Layer 4 — provider chat transcripts (vendor)
  ~/.claude/projects/<path>/*.jsonl   -> claude --resume
  Codex TUI / codex cloud list          -> vendor pickers
  -> full conversation history, not task-aligned by default
```

Rule: **`ai-sessions` is the human entry point**. Provider pickers remain
for transcript resume only.

### index.jsonl format

One JSON object per line in `~/.ai/logs/index.jsonl`. Append-only.
Never commit this file.

Required fields:

```json
{
  "ts": "2026-05-22T10:00:00Z",
  "event": "start",
  "machine": "macbook",
  "project": "platform-backend",
  "repo_path": "/Users/me/work/platform-backend",
  "task": "mr-1234",
  "tmux_session": "mr-1234",
  "agent": "claude",
  "branch": "ai/fix-auth-1234",
  "snapshot": ".ai/snapshots/mr-1234.md",
  "status": "active"
}
```

`event` values:
- `start` — new task session (`ai-start`, `ai-session`, or wrapper);
- `attach` — reattached to existing tmux/agent;
- `checkpoint` — snapshot updated mid-session (optional);
- `finish` — `ai-finish` or clean stop;
- `stale` — tmux dead but snapshot still open (written by `ai-sessions --reconcile`).

`status` values: `active`, `idle`, `finished`, `stale`.

Optional fields: `model`, `mr_iid`, `gitlab_url`, `notes`.

Example timeline:

```jsonl
{"ts":"2026-05-22T10:00:00Z","event":"start","machine":"macbook","project":"platform-backend","repo_path":"/Users/me/work/platform-backend","task":"mr-1234","tmux_session":"mr-1234","agent":"claude","branch":"ai/fix-auth","snapshot":".ai/snapshots/mr-1234.md","status":"active"}
{"ts":"2026-05-22T11:42:00Z","event":"checkpoint","machine":"macbook","project":"platform-backend","repo_path":"/Users/me/work/platform-backend","task":"mr-1234","tmux_session":"mr-1234","agent":"claude","status":"active","notes":"jwt refresh tests green"}
{"ts":"2026-05-22T18:05:00Z","event":"finish","machine":"macbook","project":"platform-backend","repo_path":"/Users/me/work/platform-backend","task":"mr-1234","tmux_session":"mr-1234","agent":"claude","status":"finished"}
```

Helper to append events — `scripts/ai-index-event`:

```bash
#!/usr/bin/env bash
set -euo pipefail

EVENT="${1:?usage: ai-index-event <start|attach|checkpoint|finish|stale>}"
INDEX="${AI_INDEX:-$HOME/.ai/logs/index.jsonl}"
mkdir -p "$(dirname "$INDEX")"

TASK="${AI_TASK:-adhoc}"
PROJECT="${AI_PROJECT:-$(basename "$(pwd)")}"
REPO_PATH="$(pwd)"
BRANCH="$(git branch --show-current 2>/dev/null || echo unknown)"
SNAP=".ai/snapshots/${TASK}.md"
[ -f "$SNAP" ] || SNAP=".ai/SNAPSHOT.md"

case "$EVENT" in
  start|attach|checkpoint) STATUS="active" ;;
  finish) STATUS="finished" ;;
  stale) STATUS="stale" ;;
  *) echo "unknown event: $EVENT" >&2; exit 1 ;;
esac

export EVENT PROJECT REPO_PATH TASK BRANCH SNAP STATUS
export TMUX_SESSION="${TMUX_SESSION:-${TASK}}"
export AGENT="${AI_AGENT:-unknown}"

python3 - <<'PY' >> "$INDEX"
import json, os, datetime, platform
rec = {
    "ts": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "event": os.environ["EVENT"],
    "machine": platform.node(),
    "project": os.environ["PROJECT"],
    "repo_path": os.environ["REPO_PATH"],
    "task": os.environ["TASK"],
    "tmux_session": os.environ["TMUX_SESSION"],
    "agent": os.environ["AGENT"],
    "branch": os.environ["BRANCH"],
    "snapshot": os.environ["SNAP"],
    "status": os.environ["STATUS"],
}
print(json.dumps(rec, ensure_ascii=False))
PY
```

Wire into lifecycle:
- `ai-start` → `ai-index-event start` (or `attach` if snapshot already exists);
- `ai-finish` → `ai-index-event finish`;
- optional snapshot hook → `checkpoint`.

### scripts/ai-sessions

Aggregator for "what is going on?" — run from any repo or with `--all`.

```bash
#!/usr/bin/env bash
set -euo pipefail

WORK_ROOT="${AI_WORK_ROOT:-$HOME/work}"
INDEX="${AI_INDEX:-$HOME/.ai/logs/index.jsonl}"
MODE="${1:-}"

echo "=== tmux (live) ==="
if command -v tmux >/dev/null 2>&1; then
  tmux ls 2>/dev/null || echo "(no tmux sessions)"
else
  echo "(tmux not installed)"
fi
echo

scan_repo() {
  local repo="$1"
  [ -d "$repo/.ai" ] || return 0
  echo "--- $(basename "$repo") ($repo) ---"
  if [ -f "$repo/.ai/active-tasks.md" ]; then
    sed -n '/^|/p' "$repo/.ai/active-tasks.md" 2>/dev/null | head -20
  fi
  if [ -d "$repo/.ai/snapshots" ]; then
    echo "snapshots:"
    ls -1 "$repo/.ai/snapshots/" 2>/dev/null | sed 's/^/  /' || true
  elif [ -f "$repo/.ai/SNAPSHOT.md" ]; then
    echo "  SNAPSHOT.md (single-task)"
  fi
  echo
}

echo "=== repo tasks ==="
if [ "$MODE" = "--all" ]; then
  for repo in "$WORK_ROOT"/*; do
    [ -d "$repo" ] || continue
    scan_repo "$repo"
  done
elif [ -d .ai ]; then
  scan_repo "$(pwd)"
else
  echo "(not in a repo with .ai/; use --all or cd into project)"
fi

echo "=== index.jsonl (recent) ==="
if [ -f "$INDEX" ]; then
  tail -n 15 "$INDEX"
else
  echo "(no $INDEX yet)"
fi
echo

if [ "$MODE" = "--reconcile" ]; then
  echo "=== reconcile (tmux vs index) ==="
  # mark tasks active in index but missing from tmux as stale
  python3 - <<'PY'
import json, subprocess, os
index = os.path.expanduser(os.environ.get("AI_INDEX", "~/.ai/logs/index.jsonl"))
if not os.path.isfile(index):
    raise SystemExit(0)
try:
    tmux = subprocess.check_output(["tmux", "ls"], text=True, stderr=subprocess.DEVNULL)
    live = {line.split(":")[0] for line in tmux.splitlines()}
except (subprocess.CalledProcessError, FileNotFoundError):
    live = set()
last = {}
with open(index) as f:
    for line in f:
        line = line.strip()
        if not line: continue
        rec = json.loads(line)
        key = (rec.get("repo_path"), rec.get("task"))
        last[key] = rec
for (repo, task), rec in last.items():
    if rec.get("status") != "active":
        continue
    sess = rec.get("tmux_session") or task
    if sess not in live:
        print(f"stale: {task} @ {repo} (tmux session '{sess}' not running)")
PY
fi

echo "=== provider chats (manual) ==="
echo "  claude --resume     # ~/.claude/projects/<path>/"
echo "  codex cloud list    # cloud tasks only"
```

Usage:

```bash
scripts/ai-sessions              # current repo + tmux + index tail
scripts/ai-sessions --all        # all repos under ~/work
scripts/ai-sessions --reconcile  # find index entries without live tmux
```

### Mapping tmux ↔ task ↔ chat

Convention (not automatic):

```text
tmux session name  ==  AI_TASK  ==  snapshots/<task>.md
export AI_TASK in tmux session before starting claude/codex
name Claude sessions when possible: claude --resume picks by cwd + title
```

When starting a new task:

```bash
ai-session mr-1234 ~/work/platform-backend
# or manually:
tmux new -s mr-1234
export AI_TASK=mr-1234 AI_AGENT=claude AI_PROJECT=platform-backend
cd ~/work/platform-backend && scripts/ai-start
claude
```

### What to open when

| Question | Command |
|----------|---------|
| What is running now? | `tmux ls` or `scripts/ai-sessions` |
| Active MRs in this repo? | `.ai/active-tasks.md` |
| Where did task stop? | `.ai/snapshots/<task>.md` |
| All projects on machine? | `scripts/ai-sessions --all` |
| Full Claude transcript? | `claude --resume` |
| MR / CI status? | `glab mr list` |

Do not duplicate chat transcripts into git. Snapshots hold task state;
`index.jsonl` holds the cross-repo schedule; transcripts stay vendor-local.

---
