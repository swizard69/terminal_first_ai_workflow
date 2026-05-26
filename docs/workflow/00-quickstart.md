# Quickstart

> Documentation **v1.0.0** · Updated **2026-05-26** · [Index](README.md) · [Changelog](../../CHANGELOG.md)

Use this for daily work. Read the deeper sections only when setting up a repo,
debugging the workflow, or changing the framework.

## Normal Task

```bash
ai-task <task> $AI_WORK_ROOT/<repo> --agent codex --layout
```

This creates or attaches a tmux session, sets `AI_TASK`, creates/loads the task
snapshot, creates `ai/<task>` when needed, and runs `scripts/ai-start`.

In the agent pane, start the agent:

```bash
codex
# or
claude
```

With hooks installed, the agent receives `scripts/ai-brief` automatically.

## During Work

Useful status commands:

```bash
scripts/ai-sessions
git status -sb
git diff --stat
```

For long sessions, keep the snapshot current:

```bash
scripts/ai-finish
```

For implementation work, the snapshot should record:
- `## Done`
- `## Next Steps`
- `## Last Validation`

## Ship

```bash
scripts/ai-ship -m "type(scope): summary" [--mr]
```

This runs project tests when configured, calls `ai-finish`, commits tracked
changes, pushes, and optionally creates a GitLab MR. Merge remains human-owned
in GitLab when using the default MR flow.

## Solo Staging (no MR)

For **private-solo** repos with a staging server, set in `manifest.md`:

```ini
repo_access=private-solo
git_flow=direct-master
```

Then:

```bash
# staging test on dev-server first
scripts/ai-ship -m "type(scope): summary"    # push master/main, no MR
```

`--mr` is ignored. Your gate = staging test, not GitLab review. Shared/prod
repos should keep default `git_flow=mr`. Details: [scripts-sync.md](../scripts-sync.md).

## Status

```bash
scripts/ai-sessions
scripts/ai-sessions --all
scripts/ai-sessions --reconcile
```

Use this instead of searching provider chat history first. Provider transcripts
are fallback history; snapshots are task state.

## Setup Once Per Repo

```bash
bootstrap-project $AI_WORK_ROOT/<repo> --name <repo> --type code
bootstrap-codex-hooks $AI_WORK_ROOT/<repo>
bootstrap-claude-hooks $AI_WORK_ROOT/<repo>
sync-ai-scripts $AI_WORK_ROOT/<repo>
```

For Codex, run `/hooks` once inside the repo and trust the project hooks.

## Read More

- [agent-first-turn.md](../agent-first-turn.md) — first message in Codex/Claude chat
- [Project Bootstrap And Hooks](04-project-bootstrap-hooks.md)
- [Context, Snapshots, Sessions](03-context-snapshots-sessions.md)
- [GitLab And Remote Execution](05-gitlab-remote-execution.md)
