---
name: frontend-test
description: Frontend test and lint gate before ship — node-lint, typecheck, npm test, ai-test.local.
---

# frontend-test

Use before `ai-ship`, after UI changes, or when CI failed on lint/test.

## Gate order

```bash
./scripts/node-lint --typecheck
./scripts/ai-test.local
git diff --stat
```

Prefer **changed files first** during iteration:

```bash
./scripts/node-lint src/components/Foo.vue src/composables/useBar.ts
./scripts/node-lint --typecheck
```

## npm scripts (typical)

| Script | When |
|--------|------|
| `npm run lint` | ESLint / biome |
| `npm run typecheck` | vue-tsc / tsc |
| `npm test` | vitest / jest |
| `npm run build` | optional pre-ship on large changes (project policy) |

## Docker (dev-ai)

When host Node ≠ project Node:

```ini
node_lint_image=project-node:20
node_lint_workdir=/app
```

Then `node-lint` runs inside the image automatically.

## Rules

- IDE problems panel is not the gate — terminal scripts are.
- Fix lint auto-fixables locally; do not disable rules without human approval.
- If tests are flaky, note in snapshot — do not `--no-test` on `ai-ship` without human ok.

## Output

- pass/fail per step
- failing file:line if any
- ready for ship yes/no
