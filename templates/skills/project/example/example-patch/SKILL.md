---
name: example-patch
description: Safe minimal patches for a sample app — no drive-by refactors.
---

# example-patch

Use for code changes in a project bootstrapped with the `example` skill profile.

## Rules

1. **Smallest patch** — match existing style in the repo.
2. **No unrelated refactors** — no framework migrations in drive-by changes.
3. **Security** — escape output, validate input; no secrets in repo.
4. **Tests** — run `./scripts/ai-test.local` when configured.

## Typical validation

```bash
./scripts/ai-test.local
```

## Output

Files changed, why, test result, deploy impact (if any).
