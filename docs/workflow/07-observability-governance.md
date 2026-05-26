# AI Cost And Quota

> Documentation **v1.0.0** · Updated **2026-05-26** · [Index](README.md) · [Changelog](../../CHANGELOG.md)

Status: **rules are active; automation is planned**. Today this section is a
human checklist. The only implemented machine-wide observability layer is
`~/.ai/logs/index.jsonl` written by `ai-index-event`.

## Why It Matters

Persistent tmux sessions + multiple agents + long contexts burn budget
fast. A forgotten background Claude session can cost more than a working
day. Quota strategy is part of the workflow, not an afterthought.

## Rules

- no AI process runs in background detached from a tmux pane;
- long-running agent tasks require explicit batch invocation, not idle session;
- one active agent per session, not two in parallel inside the same task;
- review skill runs on diff only, not on full repo;
- avoid "explore the repo" prompts on large codebases — use `ai-context` instead.

## Use Today

- Keep every active agent visible in a tmux pane.
- Prefer `ai-context` over “explore the repo” prompts.
- Run review on diffs, not full repos.
- Do not start overnight work without a concrete stop condition.

## Planned: Budget Hooks

`.ai/hooks/session-budget.sh` (illustrative):

```bash
#!/usr/bin/env bash
# called periodically from prompt or status line
SESSION_LOG=~/.ai/logs/session-$(date +%Y%m%d).log
TOKENS=$(awk '{s+=$1} END {print s+0}' "$SESSION_LOG" 2>/dev/null || echo 0)
LIMIT=${AI_DAILY_TOKEN_LIMIT:-2000000}

if [ "$TOKENS" -gt "$LIMIT" ]; then
  echo "warn: daily token budget exceeded ($TOKENS > $LIMIT)" >&2
fi
```

Plug agent token usage into `~/.ai/logs/session-<date>.log` from a
wrapper script around `claude` and `codex`.

## Planned: Cost Allocation

For multi-project work, tag sessions:

```bash
export AI_PROJECT=platform
export AI_TASK=mr-1234
tmux new -s "$AI_PROJECT-$AI_TASK"
```

Wrapper logs `project`, `task`, `tokens`, `duration` per invocation.
This enables per-project cost reports later.

---

# AI Observability

Status: **partial**. `ai-index-event` and `ai-sessions` exist. Full command
capture, token logs, touched-file logs, and final diff snapshots are planned.

## Why

If an agent corrupted something, you must reconstruct what it did.
Without logs there is no postmortem, only guessing.

## Target Log Coverage

Per session:
- start/stop timestamps;
- agent, model, project, task;
- every shell command the agent ran;
- every file the agent wrote;
- tests run and their results;
- final diff hash.

## Layout

```text
.ai/logs/
  2026-05-22/
    mr-1234/
      session.jsonl       # one event per line
      commands.log        # raw shell history
      files-touched.txt   # paths the agent wrote
      diff.patch          # final diff snapshot
      tests.log           # test run output
```

Per-machine global log:

```text
~/.ai/logs/
  session-2026-05-22.log  # token usage aggregated by wrapper
  index.jsonl             # session registry across all projects (append-only)
```

### index.jsonl

Machine-wide, personal, never committed. One JSON object per line.
Written by `scripts/ai-index-event` from `ai-start` / `ai-finish`.

See [Session Registry (ai-sessions)](03-context-snapshots-sessions.md#session-registry-ai-sessions) for
schema, `scripts/ai-sessions`, and reconciliation with tmux.

## Planned: Wrapper Pattern

Wrap `claude` and `codex` to capture commands and tokens.

`~/bin/claude-logged`:

```bash
#!/usr/bin/env bash
set -euo pipefail
PROJECT="${AI_PROJECT:-unknown}"
TASK="${AI_TASK:-adhoc}"
DAY=$(date +%Y-%m-%d)
DIR=".ai/logs/$DAY/$TASK"
mkdir -p "$DIR"

SCRIPT_LOG="$DIR/commands.log"
script -q "$SCRIPT_LOG" claude "$@"
```

For Codex use the same pattern. `script(1)` captures the full PTY.

## Privacy

- `.ai/logs/` must be in `.gitignore` unless `repo_access=private-solo`;
- secrets in command output must be redacted by wrapper before write;
- rotate logs older than 30 days.

## Replay

Given a session, reconstruct exactly what happened:

```bash
cat .ai/logs/<day>/<task>/commands.log
git apply --check .ai/logs/<day>/<task>/diff.patch
```

This is what makes AI work auditable once the planned wrappers exist.

---

# AI Branch Isolation And Rollback

Status: **policy is active; GitLab push rules and prune scripts are project
configuration/planned automation**.

## Why

If an overnight agent makes 30 commits across the repo, you need a
clean way to inspect, squash, or drop everything without affecting
human work.

## Branch Namespace

All AI work lives under reserved prefixes:

```text
ai/<task>          # implementation
ai-review/<task>   # reviewer agent annotations
ai-spike/<task>    # exploratory, never merged
```

Rules:
- humans never push to `ai/*` directly;
- agents never push outside `ai/*`;
- `ai-spike/*` is auto-pruned after 7 days;
- protected branches reject any push from AI user (GitLab push rules).

## GitLab Push Rules

Configure on the project:
- only AI service user can push to `ai/*`;
- only humans can push to `main`, `release/*`;
- MR from `ai/*` to `main` requires at least one human approval;
- force-push disabled on all `ai/*` after MR opened.

## Inspection Before Merge

```bash
git fetch origin
git log --oneline origin/main..origin/ai/<task>
git diff origin/main...origin/ai/<task>
```

Reviewer skill runs on this diff before MR opens.

## Rollback Strategy

If an agent went wrong, never `git reset --hard` shared branches.
Always create a `revert/*` branch.

Levels:

```text
level 1: drop unmerged AI branch
  git push origin --delete ai/<task>

level 2: revert merged AI MR
  glab mr view <id>
  git checkout -b revert/mr-<id> main
  git revert -m 1 <merge-sha>
  glab mr create --target-branch main

level 3: revert deploy
  trigger GitLab rollback pipeline, not manual ssh
```

Rule: rollback always goes through GitLab. Never `ssh prod && rm`.

## Planned: Auto-Prune

`scripts/ai-prune-branches`:

```bash
#!/usr/bin/env bash
# delete ai-spike/* older than 7 days, merged ai/* older than 30 days
git fetch --prune origin
for br in $(git for-each-ref --format='%(refname:short)' refs/remotes/origin/ai-spike); do
  age_days=$(( ( $(date +%s) - $(git log -1 --format=%ct "$br") ) / 86400 ))
  [ "$age_days" -gt 7 ] && git push origin --delete "${br#origin/}"
done
```

## Quarantine For Suspicious Commits

If an AI commit looks dangerous (unexpected files, large diff, secrets):

```bash
git checkout -b quarantine/<task> <suspicious-sha>
git push origin quarantine/<task>
# then: open issue, never merge, prune after investigation
```

---
