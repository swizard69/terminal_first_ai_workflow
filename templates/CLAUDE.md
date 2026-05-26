# {{PROJECT_NAME}}

Claude Code adapter — operational entry point only.

## Source of truth

- Rules: `AGENTS.md`
- State: `.ai/SNAPSHOT.md` or `.ai/snapshots/<AI_TASK>.md`
- Project docs: `docs/ai/`

## Start

```bash
export AI_TASK=<task-id>   # optional for single-task repos
scripts/ai-start
```

Read `AGENTS.md` and `docs/ai/*` before editing code.

## Project

- Type: see `manifest.md`
- Architecture: `docs/ai/architecture.md`
