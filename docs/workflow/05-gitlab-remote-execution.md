# GitLab Integration

> Documentation **v1.0.0** · Updated **2026-05-26** · [Index](README.md) · [Changelog](../../CHANGELOG.md)

## GitLab Is The Control Layer

AI agents should NOT directly own production workflow.

GitLab remains:
- source of truth;
- review system;
- CI/CD controller;
- deployment gate.

---

# Recommended Flow

```text
issue / task
  ↓
feature branch
  ↓
AI Agent
  ↓
tests / lint
  ↓
self-review
  ↓
commit
  ↓
push
  ↓
Merge Request
  ↓
CI/CD
  ↓
review
  ↓
merge
  ↓
deploy
```

---

# MR Loop

## Standard Loop

```text
1. understand issue
2. create branch (ai/<task>) — or `ai-task <id> <repo> --layout`
3. load context (AGENTS.md, task snapshot, docs/ai/) — `scripts/ai-start`
4. primary agent makes smallest useful patch
5. run focused tests
6. inspect diff
7. cross-agent review (second agent reads diff)
8. ship: `scripts/ai-ship -m "..."` [--mr]  (test + commit + push + optional MR)
9. watch pipeline
10. fix CI / review comments
11. merge MR (human)
12. update task snapshot; `ai-finish` before detach if needed
```

### Solo direct-master (optional)

When `manifest.md` has `repo_access=private-solo` and `git_flow=direct-master`:

```text
1. ai-task or work on master
2. implement + staging test on homelab
3. scripts/ai-ship -m "..."   → push master, no MR
4. deploy --apply when ready (human)
```

Use for solo pilots (e.g. my-app). Keep `git_flow=mr` (default) for shared or
prod-heavy repos (ms/spc/ls).

## Agent Rules

- never push directly to protected branches **unless** `git_flow=direct-master` in a private-solo repo;
- never deploy without GitLab gate;
- never hide failing tests;
- always include validation commands in MR description;
- prefer several small MRs over one large mixed MR.

## Cross-Agent Review

Single-agent self-review is weak. Use a second agent before opening MR.

Pattern:

```text
implementer agent   -> writes patch, runs tests
reviewer agent      -> reads diff, runs review skill
human               -> resolves disagreement, opens MR
```

Recommended pairing:
- Codex implements, Claude reviews (architecture, risks);
- Claude implements, Codex reviews (correctness, edge cases);
- never same agent in same session as both implementer and reviewer.

Reviewer reads:
- `git diff <base>...HEAD`;
- touched test files;
- `docs/ai/conventions.md`;
- task snapshot (`.ai/snapshots/<task>.md` or `.ai/SNAPSHOT.md`) for intent.

Reviewer output goes to `.ai/handoff/review.md` with:

```md
## Risks
## Blocking Issues
## Suggested Changes
## Safe To Merge: yes|no
```

Rule: MR cannot be opened if reviewer says `Safe To Merge: no`,
unless a human explicitly overrides.

---

# Git Workflow

## Example

```bash
git checkout -b ai/fix-auth
claude
npm test
git diff
git add -p
git commit -m "Fix auth refresh"
git push
```

---

# glab CLI

## Recommended

Install:

```bash
brew install glab
```

Login:

```bash
glab auth login --hostname gitlab.example.com
```

Useful commands:

```bash
glab mr create
glab mr view
glab pipeline status
glab pipeline view
```

---

# Remote AI Execution

## Powerful Pattern

Run agents directly on remote infrastructure.

Example:

```bash
ssh dev-server
tmux
claude
```

Benefits:
- local access to docker;
- local logs;
- direct filesystem access;
- persistent execution.

---

## Guardrails

Remote AI execution should default to non-prod.

Allowed:
- dev/staging hosts;
- readonly production diagnostics;
- logs, metrics, container status;
- explicit operator-approved commands.

Not allowed without explicit confirmation:
- production writes;
- database migrations;
- destructive docker commands;
- secrets export;
- backups/downloads with sensitive data;
- deploy or rollback.

Recommended setup:
- separate SSH user for AI work;
- least-privilege tokens;
- command allowlist for production diagnostics;
- tmux session named by task or MR;
- full shell history retained.

---

## Technical Enforcement

Pure "guidelines" are not enough. Enforce via OS, not policy.

### Separate AI user

```bash
# on remote host
useradd -m -s /bin/bash ai-ro
mkdir -p /home/ai-ro/.ssh
# install only the AI public key, never password auth
```

### Restricted sudoers for readonly prod

`/etc/sudoers.d/ai-ro`:

```text
# allow ai-ro to read logs and inspect docker, nothing else
ai-ro ALL=(root) NOPASSWD: /usr/bin/docker ps, \
  /usr/bin/docker logs *, \
  /usr/bin/docker stats --no-stream, \
  /usr/bin/journalctl -u *, \
  /usr/bin/tail -n * /var/log/*

# explicit deny via command shape (no shell, no pipes from sudo)
Defaults:ai-ro !env_keep, requiretty=false, lecture=never
```

Rule: never give AI user `ALL` even with `NOPASSWD`. Always enumerate.

### Forced-command SSH key

For production diagnostics where AI must only run one tool, pin the key:

`~ai-ro/.ssh/authorized_keys`:

```text
command="/usr/local/bin/ai-diag",no-port-forwarding,no-agent-forwarding,no-X11-forwarding,no-pty ssh-ed25519 AAAA... ai-ro@workstation
```

`/usr/local/bin/ai-diag` validates `$SSH_ORIGINAL_COMMAND` against an
allowlist and rejects anything else.

### Allowlist wrapper

`/usr/local/bin/ai-diag`:

```bash
#!/usr/bin/env bash
set -euo pipefail
cmd="${SSH_ORIGINAL_COMMAND:-}"

case "$cmd" in
  "docker ps"|"docker stats --no-stream") ;;
  "docker logs "*) ;;
  "journalctl -u "*" --since "*) ;;
  "tail -n "*" /var/log/"*) ;;
  *) echo "denied: $cmd" >&2; exit 1 ;;
esac

exec bash -c "$cmd"
```

### Production write path

Production writes go through GitLab CI only:
- agent opens MR;
- pipeline runs deploy job;
- deploy job uses its own service account, not AI user;
- AI user has no deploy credentials at all.

---
