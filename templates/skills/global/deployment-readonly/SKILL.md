---
name: deployment-readonly
description: Read-only deploy checks — dry-run, checklist, rollback plan. Agent never applies prod deploy.
---

# deployment-readonly

Use when discussing deploy, release, or validating deploy scripts.

## Agent rule

**Never run prod deploy with `--apply` or equivalent.** Human or GitLab CI after MR merge only.

## Read-only checks

1. Read `docs/ai/deploy.md` and project deploy README.
2. Dry-run if script exists:
   ```bash
   ./deploy/deploy.sh              # dry-run default
   git diff deploy/
   ```
3. Verify checklist:
   - backup exists or documented
   - rollback path clear
   - smoke test plan after deploy
   - secrets not in git

## Output

```markdown
## Deploy Readiness (read-only)
- dry-run result: ...
## Rollback
- ...
## Human Steps
- merge MR → CI → human runs apply
```

## Never

- `./deploy/deploy.sh --apply`
- SSH prod edits from agent shell
- Disable hooks or CI gates for speed
