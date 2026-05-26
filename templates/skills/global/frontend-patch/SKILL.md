---
name: frontend-patch
description: Smallest safe UI patch for Vue/Nuxt/React/Vite repos — lint, typecheck, test, ship.
---

# frontend-patch

Use when implementing or fixing frontend code (components, composables, stores, styles).

## Preconditions

- Read `AGENTS.md`, `docs/ai/conventions.md`, task snapshot.
- Identify stack from `package.json` (Nuxt, Vite, React, etc.) — match existing patterns.

## Workflow

1. **Scope** — one user-visible change or one bug; no drive-by refactors.

2. **Edit** — follow repo component/composable layout; reuse design tokens and API client.

3. **Validate** (required on dev-ai):
   ```bash
   ./scripts/node-lint path/to/changed.vue path/to/changed.ts
   ./scripts/node-lint --typecheck          # or full project before ship
   ./scripts/ai-test.local                  # lint + typecheck + npm test
   ```

4. **Snapshot** — `## Done`, `## Last Validation` with commands run.

5. **Ship**
   ```bash
   ./scripts/ai-ship -m "fix(ui): one-line why" [--mr]
   ```

## manifest.md (when Node version differs on host)

```ini
node_lint_image=project-node:20
node_lint_workdir=/app
node_lint_cmd=npm run lint
node_typecheck_cmd=npm run typecheck
```

## Never

- Ship with failing `node-lint` or `npm test`.
- Add dependencies without reason (check lockfile policy).
- Expose secrets in client bundle or `NUXT_PUBLIC_*` misuse.
- Replace entire state management for a one-field fix.

## Output

- files changed + why
- lint/typecheck/test commands + results
- risks (a11y, SSR, breaking API contract)
