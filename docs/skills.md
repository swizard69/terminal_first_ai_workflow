# Skills

Reusable agent workflows as `SKILL.md`. Scripts (`ai-start`) are **not** skills.

---

## Layers

| Layer | Path | Install |
|-------|------|---------|
| Global | `~/ai/skills/<name>/SKILL.md` | `bootstrap-ai-skills --global` |
| Project | `<repo>/.ai/skills/<name>/SKILL.md` | `bootstrap-ai-skills --project <name> <repo>` |
| Claude adapter | `<repo>/.claude/skills/` | `scripts/ai-sync-skills --write` |

Project overrides global when names collide — prefer unique project skill names.

---

## V1 catalog

**Global** (`templates/skills/global/`):

- `git-mr` — branch, `ai-ship` (+ optional `--mr`), merge human
- `planning` — read-only task/MR plan before implementation
- `architecture` — read-only design choices, boundaries, trade-offs, ADRs
- `investigation` — read-only behavior/root-cause investigation before fixing
- `review` — diff-only review template
- `debugging` — reproduce → fix → validate
- `sql` — read-only query review, EXPLAIN, indexes, migrations (dev only)
- `deployment-readonly` — dry-run deploy, no `--apply`
- `params-secrets-guard` — never commit params.yaml / deploy.env

**Example project profile** (`templates/skills/project/example/`):

- `example-test` — `./scripts/ai-test.local`
- `example-patch` — minimal patch rules for a sample app

Copy the `example/` folder when adding your own project profile.

---

## Install

```bash
# global once per user
bootstrap-ai-skills --global

# pilot repo (auto-detect profile from dirname if it exists)
bootstrap-ai-skills --project example $AI_WORK_ROOT/my-app
bootstrap-ai-skills $AI_WORK_ROOT/my-app
```

---

## Discovery

`scripts/ai-context` prints skill paths (global + project).

Invoke in chat: Claude `/git-mr` or natural language referencing skill name.

Codex: no native skills — agent reads paths from context or `@` files.

---

## Add a project profile

1. Add `templates/skills/project/<repo-name>/*/SKILL.md` in this framework repo (or only in your project under `.ai/skills/`).
2. `bootstrap-ai-skills --project <repo-name> $AI_WORK_ROOT/<repo>`

---

## See also

- [Recommended Skill Architecture](workflow/09-skills-system.md#recommended-skill-architecture)
- [scripts-sync.md](scripts-sync.md)
