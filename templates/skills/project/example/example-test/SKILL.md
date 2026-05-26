---
name: example-test
description: Run project smoke tests after changes.
---

# example-test

Run after implementation changes.

## Command

```bash
./scripts/ai-test.local
```

If the project has no local test script yet, add `scripts/ai-test.local` during bootstrap or copy from `templates/ai-test.local.php-legacy` for PHP legacy repos.

## When to use

- before `ai-ship`
- after agent edits when validation was requested
- when snapshot `## Last Validation` is stale
