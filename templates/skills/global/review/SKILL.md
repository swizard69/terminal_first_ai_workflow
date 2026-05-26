---
name: review
description: Diff-only code review before MR — security, regressions, style, merge safety.
---

# review

Use when asked to review changes, before MR, or as second agent on same branch.

## Scope

- **Diff only** — `git diff`, `git diff origin/main...HEAD`, or MR diff.
- Do **not** full-repo exploration unless diff references unknown files.

## Process

1. Get diff:
   ```bash
   git diff --stat
   git diff origin/main...HEAD    # or merge-base target
   ```

2. Check:
   - security (injection, secrets, auth bypass)
   - behavior change vs intent in snapshot/issue
   - style consistency with surrounding code
   - backward compatibility / rollback
   - tests adequate for change size

3. Cross-read only files **touched or directly imported** by diff.

## Output format

```markdown
## Risks
- ...

## Suggested Changes
- ...

## Blocking Issues
- ... (empty if none)

## Safe To Merge
yes | no — reason
```

## Never

- Approve prod deploy or `--apply` scripts
- Request unrelated refactors
- Block on nitpicks when change is minimal and tested
