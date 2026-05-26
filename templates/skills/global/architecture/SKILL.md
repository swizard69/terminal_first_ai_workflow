---
name: architecture
description: Read-only architecture reasoning for design choices, boundaries, trade-offs, ADRs, and technical direction before implementation.
---

# architecture

Use when asked to reason about system design, choose between approaches, write
or review an ADR, define module boundaries, or assess technical direction.

Default mode is **read-only**. Do not edit files unless the user explicitly
asks to implement after the recommendation.

## Process

1. State the decision or design question in one sentence.
2. Read repo-local context first: `AGENTS.md`, `manifest.md`, `docs/ai/*`,
   task snapshot, and directly relevant code/docs.
3. Separate facts from assumptions.
4. Present 2-4 viable options, including the boring/simple option.
5. Compare trade-offs: correctness, operational risk, migration cost,
   rollback, testability, security, and maintenance.
6. Recommend one option and explain why it fits the current repo.
7. End with the smallest next step, not a broad roadmap.
   - scope/MR breakdown → `planning` skill;
   - unknown behavior → `investigation` skill first.

## Output format

```markdown
## Problem

## Context
- Facts:
- Assumptions:

## Options

## Trade-offs

## Recommendation

## Risks

## Decision Needed

## Next Step
```

## Rules

- Prefer repo evidence over generic best practices.
- Do not invent future infrastructure to solve a small current problem.
- Call out when more evidence is needed before deciding.
- If the answer is "do not build this yet", say so directly.
