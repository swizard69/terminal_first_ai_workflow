# Scripts: global vs project copies

Canonical framework: [github.com/swizard69/terminal_first_ai_workflow](https://github.com/swizard69/terminal_first_ai_workflow) — clone to `~/projects/terminal_first_ai_workflow/` (or your path)

---

## Two layers

| Layer | Path | How it gets there |
|------|------|-------------------|
| **Global (PATH)** | `terminal_first_ai_workflow/scripts/` | `~/.bashrc` → PATH via `bootstrap-host` |
| **Project copy** | `<repo>/scripts/` | `bootstrap-project` or `sync-ai-scripts` |

`./scripts/ai-start` — **copy in repo**.  
`ai-session` / `ai-task` — **global** (from PATH).

---

## Global-only (do not copy into projects)

```text
ai-session
ai-task
ai-sessions
ai-index-event
ai-vault-link
ai-openclaw-check
ai-openclaw-agent
bootstrap-openclaw
bootstrap-host
bootstrap-project
bootstrap-codex-hooks
bootstrap-claude-hooks
bootstrap-ai-skills
sync-ai-scripts
unbootstrap-project
```

Cross-repo / tmux helpers — once in PATH.

---

## Project copies (bootstrap + sync)

```text
ai-context
ai-start
ai-finish
ai-ship
ai-brief
ai-test
php-lint
python-lint
node-lint
ai-review
ai-sync-skills
switch-ai-state-mode
ai-tmux-layout
```

Committed in the project repo.

**Never overwritten by sync:**

```text
scripts/ai-test.local   # project smoke tests
```

---

## First install

```bash
~/projects/terminal_first_ai_workflow/scripts/bootstrap-project \
  $AI_WORK_ROOT/my-app --name my-app --type code
```

Creates copies **only if the file does not exist** (does not update existing).  
Writes `.ai/framework-manifest` — path list for `unbootstrap-project`.

---

## Remove framework from repo

```bash
unbootstrap-project $AI_WORK_ROOT/my-app --dry-run
unbootstrap-project $AI_WORK_ROOT/my-app --yes --keep-snapshots
```

Default without `--yes` — preview only.

| Flag | Effect |
|------|--------|
| `--yes` | delete |
| `--keep-snapshots` | keep `.ai/snapshots/`, `SNAPSHOT.md`, `active-tasks.md` |
| `--purge-root-docs` | also `AGENTS.md`, `CLAUDE.md`, `manifest.md` |
| `--purge-docs-ai` | also `docs/ai/` |

**Does not remove:** `scripts/ai-test.local` (project-owned).  
**Does not touch:** global PATH tools (`ai-session`, `ai-task`, …) on the host.

After removal — normal git commit in the project repo.

---

## Update after framework changes

```bash
sync-ai-scripts $AI_WORK_ROOT/my-app
sync-ai-scripts --all
sync-ai-scripts --all --dry-run
```

Then commit in the project:

```bash
cd $AI_WORK_ROOT/my-app
git diff scripts/
git commit -am "chore(ai): sync scripts from terminal_first_ai_workflow"
```

---

## `ai-ship` (project copy)

```bash
./scripts/ai-ship -m "fix(scope): summary"
./scripts/ai-ship -m "fix(scope): summary" --mr
AI_SHIP_MR=1 ./scripts/ai-ship -m "..."
```

Flags: `--all-new`, `--no-test`, `--no-push`, `--dry-run`.

**Merge MR** in GitLab/GitHub — still human (or CI auto-merge if configured).

**Solo fast lane** (`manifest.md`):

```ini
repo_access=private-solo
git_flow=direct-master
```

→ `ai-ship` may commit+push to `master`/`main`; `--mr` is ignored. Use staging tests as your gate.

---

## Symlink?

Default is **copy**, not symlink — repo is self-contained for clone/CI/MR.

Symlinks are possible on a personal dev server but hurt portability.

---

## See also

- [auth-remote-dev.md](auth-remote-dev.md)
- [tmux-cheatsheet.md](tmux-cheatsheet.md)
