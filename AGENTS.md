# AI agent rules

Provider-neutral contract. Claude/Codex adapters must defer here.

## Scope

- Smallest useful patch; no unrelated rewrites.
- Match existing patterns before introducing new ones.
- Never run destructive commands without explicit confirmation.
- Never push to protected branches; use `ai/<task>` branches.
- Before DB/deploy changes — explain risk and rollback.

## Workflow

1. Run `scripts/ai-start` (or read task snapshot).
2. Read files listed by `scripts/ai-context`.
3. Implement; run focused tests.
4. Update snapshot (`## Done`, `## Last Validation`).
5. `scripts/ai-finish` before detach.

## Output

After changes report:
- files changed and why;
- commands to validate;
- remaining risks.

## PHP validation (dev-ai)

- Host may have **no** `php` CLI — PHP versions live in **docker images per project**.
- **Do not** use host `php -l` or IDE ReadLints as the PHP validation gate.
- After PHP edits: `./scripts/ai-test.local` or `./scripts/php-lint path/to/file.php`.
- Configure `php_lint_image=` (and optional `php_lint_workdir=`) in `manifest.md`.

## Python validation (dev-ai)

- Host may have **no** `python3` — use project docker image when versions differ.
- After Python edits: `./scripts/python-lint path/to/file.py`.
- Configure `python_lint_image=` (and optional `python_lint_workdir=`) in `manifest.md`.

## Frontend / Node validation (dev-ai)

- Host Node version may differ from the project — use docker via `node_lint_image` when needed.
- **Do not** use IDE ESLint/TypeScript diagnostics as the only gate.
- After JS/TS/Vue edits: `./scripts/node-lint path/to/file.ts` and `./scripts/node-lint --typecheck`.
- Before ship: `./scripts/ai-test.local` (lint + typecheck + `npm test`).
- Configure `node_lint_image=`, `node_lint_cmd=`, `node_typecheck_cmd=` in `manifest.md`.
- Style notes: `~/ai/vue-nuxt-style.md` (from `bootstrap-host`).

## Production

- No prod writes from agent shell.
- Deploy only via GitLab/GitHub CI after MR/PR merge.
