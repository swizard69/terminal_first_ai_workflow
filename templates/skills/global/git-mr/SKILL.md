---
name: git-mr
description: Git branch, commit, push, and GitLab MR workflow for ai/<task> branches.
---

# git-mr

Use when starting work, before opening an MR, or when asked about git/MR steps.

## Preconditions

- Read `AGENTS.md` and task snapshot.
- `AI_TASK` set (tmux session name or export).
- Branch pattern: `ai/<AI_TASK>` or `ai/<short-description>`.

## Workflow

1. **Branch**
   ```bash
   git fetch origin
   git checkout -b ai/<task>    # from default branch
   ```

2. **Implement** — smallest patch; no unrelated files.

3. **Validate**
   ```bash
   ./scripts/ai-test.local     # if present
   git diff --stat
   ```

4. **Commit**
   ```bash
   git add -p                  # prefer staged hunks
   git commit -m "fix(scope): one-line why"
   ```

5. **Ship** (preferred — agent or human):
   ```bash
   ./scripts/ai-ship -m "feat(scope): one-line why"
   ./scripts/ai-ship -m "feat(scope): one-line why" --mr   # + auto MR if missing (git_flow=mr)
   ```
   Runs tests → commit tracked files → push. With `--mr` (or `AI_SHIP_MR=1`): `glab mr create --fill --yes` when no open MR for the branch.

   **Solo direct-master** (`repo_access=private-solo`, `git_flow=direct-master` in `manifest.md`):
   - push to `master`/`main` allowed; no MR;
   - test on staging (dev-server) before ship.

6. **Snapshot** — update `## Done`, `## Last Validation`, MR URL.

7. **Merge** — human in GitLab when `git_flow=mr` (not used for direct-master).

**Manual push/MR** (if not using `ai-ship --mr`):

```bash
git push -u origin HEAD
glab mr create --fill
```

## Never

- `git push --force` to `main` / `master` / protected branches
- `git commit --no-verify` unless human explicitly allows
- Open MR with failing tests or unstaged debug code

## Output

Report: branch, commits (subjects), test result, MR URL, remaining risks.
