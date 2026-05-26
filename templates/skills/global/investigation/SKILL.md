---
name: investigation
description: Read-only investigation workflow for understanding behavior, incidents, regressions, unknown code paths, and root-cause hypotheses before fixing.
---

# investigation

Use when asked to understand why something happens, trace behavior, inspect an
unknown area, or form a root-cause hypothesis before deciding whether to patch.

Default mode is **read-only**. Do not edit files unless the user explicitly
asks to implement a fix.

## Process

1. Restate the question and expected outcome.
2. Gather facts from the smallest relevant surface:
   - task snapshot or issue text;
   - logs/errors supplied by the user;
   - directly relevant files found with `rg`;
   - tests around the behavior.
3. Build hypotheses and rank them by evidence.
4. Check the top hypothesis with targeted reads or commands.
5. Identify the likely cause, unknowns, and next checks.
6. If a fix is obvious, describe fix options without applying them.

## Useful commands

```bash
rg -n 'symbol|error|route|config' .
git log --oneline -- path/to/file
git blame -L <start>,<end> path/to/file
git diff origin/main...HEAD
```

Run tests or local commands only when they help prove or disprove a hypothesis.
No production writes, deploys, migrations, or destructive cleanup.

## Output format

```markdown
## Question

## Facts Found

## Hypotheses

## Evidence

## Likely Cause

## Unknowns

## Next Checks

## Fix Options
```

## Rules

- Keep investigation scoped; avoid full-repo wandering.
- Mark speculation clearly.
- Do not present a fix as certain unless evidence supports it.
- Preserve logs and command results in the task snapshot or handoff if useful.
- Ready to implement → hand off to `debugging` skill (or explicit user approval).
