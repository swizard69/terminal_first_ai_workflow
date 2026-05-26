---
name: planning
description: Read-only task planning and MR decomposition before implementation, including scope, likely files, validation, and stop conditions.
---

# planning

Use before implementation when the user wants a plan, task breakdown, MR
scope, validation strategy, or sequencing across agents.

Default mode is **read-only**. Do not edit files unless the user explicitly
asks to implement the plan.

## Process

1. Clarify the goal from the user request, issue, or snapshot.
2. Read only the context needed to plan:
   - `AGENTS.md`, `manifest.md`, `docs/ai/*`;
   - task snapshot;
   - directly relevant files/tests.
3. Define the smallest useful scope.
4. Split work into steps that can be validated independently.
5. Identify likely files touched and files to avoid.
6. Define validation commands and stop conditions.
7. Call out blockers or decisions needed before implementation.

## Output format

```markdown
## Goal

## Constraints

## Proposed Steps

## Files Likely Touched

## Validation

## Risks

## Stop Conditions

## Ready To Implement
yes | no — reason
```

## Rules

- Prefer one small MR over a broad mixed change.
- Do not include unrelated cleanup unless it is required for the goal.
- If the plan depends on uncertain facts, add an investigation step first.
- Keep plans executable; avoid abstract roadmaps unless explicitly requested.
