# AI Skills System

> Documentation **v1.0.0** · Updated **2026-05-26** · [Index](README.md) · [Changelog](../../CHANGELOG.md)

Status: **partial**. Global/project skill bootstrap exists, and
`ai-sync-skills --write` currently copies project `.ai/skills/*/SKILL.md` into
`.claude/skills/`. Manifest validation and richer provider adapters are planned.

## What Is A Skill

Skill = reusable AI capability.

Usually includes:
- instructions;
- workflow;
- prompts;
- conventions;
- commands;
- validation steps.

Skills should be:
- provider-independent;
- markdown-based;
- reusable across projects.

---

## Use Today

Use skills for repeated workflows that are worth standardizing:
- global reusable skills live in `~/ai/skills/<name>/SKILL.md`;
- project-specific skills live in `<repo>/.ai/skills/<name>/SKILL.md`;
- install starter skills with `bootstrap-ai-skills`;
- sync project skills to Claude with `scripts/ai-sync-skills --write`.

Do not create a skill for one-off instructions. Put project-specific facts in
`docs/ai/` instead.

**V1 catalog (installed skills):** [docs/skills.md](../skills.md)

---

## Skill Sync Model

Skills need one canonical source and many provider adapters.

Canonical source:

```text
.ai/skills/
  git/
    SKILL.md
    manifest.yaml
    prompts.md
    commands.md
  review/
  deployment/
```

Generated/provider-specific targets:

```text
.claude/skills/      -> generated from .ai/skills/
.codex/skills/       -> generated from .ai/skills/ if supported
~/.ai/skills/        -> global canonical skills
```

Rule:
- edit `.ai/skills/` or `~/ai/skills/`;
- do not manually edit generated provider folders;
- provider adapters may drop unsupported metadata, but must not change behavior;
- skill names and inputs must stay stable across agents.

---

## Planned: Skill Manifest

Each skill should include a small manifest:

```yaml
name: review
version: 1.0.0
scope: global
providers:
  claude: true
  codex: true
inputs:
  - diff
  - task
outputs:
  - findings
  - risk_level
commands:
  - git diff
  - npm test
```

Purpose:
- make skills discoverable;
- allow compatibility checks;
- generate provider adapters;
- detect drift between global and project skills.

---

## Sync Precedence

Skill resolution order:

```text
project/.ai/skills/<name>   -> project override
workspace/ai-context/skills -> shared team skill
~/ai/skills/<name>          -> personal/global default
provider built-in skill     -> fallback only
```

Project skill wins over global skill.
Global skill should never silently override project behavior.

---

## Sync Command

Recommended command:

```bash
scripts/ai-sync-skills --check
scripts/ai-sync-skills --write
```

Current responsibility:
- copy `.ai/skills/*/SKILL.md` into `.claude/skills/*/SKILL.md` when requested.

Planned responsibilities:
- validate `manifest.yaml`;
- compare global/shared/project skill versions;
- generate `.claude/skills/*/SKILL.md`;
- generate provider adapters when supported;
- report drift without overwriting project overrides unless explicitly requested.

---

# Recommended Skill Architecture

## Global Skills

```text
~/ai/skills/
  git/
  debugging/
  refactoring/
  docker/
  deployment/
  review/
  architecture/
  security/
  sql/
  monitoring/
```

---

## V1 Skills Only

Start with (installed via `bootstrap-ai-skills --global` → `~/ai/skills/<name>/SKILL.md`):

```text
git-mr
planning
architecture
investigation
debugging
review
sql
deployment-readonly
params-secrets-guard
```

Add other skills only when repeated real work justifies them.

---

## Project Skills

```text
project/
  .ai/
    skills/
      auth/
      payments/
      deploy/
      backups/
```

---

# Suggested Skill Catalog

Use this as a backlog, not a mandate.

| Skill | Purpose |
|-------|---------|
| `git-mr` | Branch, commit, push, MR workflow, conflicts. |
| `review` | Diff review with risks, blocking issues, and safe-to-merge verdict. |
| `debugging` | Reproduce, collect logs, isolate, fix, validate. |
| `architecture` | Boundaries, contracts, system risks, technical debt. |
| `sql` | Query review, migrations, indexes, explain plans. |
| `deployment-readonly` | Read-only operational diagnostics. |
| `params-secrets-guard` | Parameters and secrets safety checks. |
| future `docker` | Compose/logs/networking/health checks. |
| future `security` | Secrets, injection, SSRF, unsafe shell/docker config. |
| future `backup` | Restore validation, retention, integrity checks. |
| future orchestrator | Multi-agent routing when OpenClaw or another router is actually used. |

# Skill Format

## Recommended Structure

```text
skill-name/
  README.md
  prompts.md
  commands.md
  checklists.md
  examples/
```

---

# Example Skill README

```md
# Deployment Skill

## Goal
Safely deploy services.

## Required Inputs
- branch
- target environment
- rollback strategy

## Validation
- tests pass
- backup exists
- healthcheck ok
```

---

# Obsidian Integration

## Recommended

Each skill should have wiki-links.

Example:

```md
Related:
- [[Git Workflow]]
- [[Deployment Strategy]]
- [[Rollback Procedure]]
```

---
