# Первый turn агента (Codex / Claude)

## Daily UX (thin CLI)

Обычная задача — **две команды человека**:

```bash
ai-task <task> $AI_WORK_ROOT/<repo> --agent codex --layout
# … агент работает в tmux …
scripts/ai-ship -m "type(scope): summary" [--mr]
```

Статус параллельных задач: `ai-sessions` (global PATH).

Plumbing (`AI_TASK`, `scripts/ai-start`, snapshots) — под капотом `ai-task` или для отладки.

---

## Две панели — не путать

| Где | Что пишешь |
|-----|------------|
| **Терминал** (shell tmux) | `ai-task`, `codex`/`claude`, при необходимости `scripts/ai-ship` |
| **Чат агента** | только **задачу** словами — без `scripts/...` |

Агент знает скрипты из `AGENTS.md` / hooks. `SessionStart` → `scripts/ai-brief`.

---

## Кто что вызывает

| Шаг | Кто | Что |
|-----|-----|-----|
| 1 | **ты** | `ai-task <task> <repo> --agent codex --layout` |
| 2 | **ai-task** | tmux + branch + `ai-start` + snapshot + index |
| 3 | **ты** | `codex` или `claude` в agent-панели |
| 4 | **hook** | `SessionStart` → `scripts/ai-brief` |
| 5 | **агент** | читает файлы по необходимости, патчит код |
| 6 | **ты / агент** | `scripts/ai-ship -m "..."` [--mr] — Stop hook блокирует stop при dirty git |

Read-only до кода (опционально): skills `planning`, `investigation`, `architecture` — см. [skills.md](skills.md).

---

## Правильная последовательность

```bash
ai-task fix-login $AI_WORK_ROOT/my-app --agent codex --layout
# → tmux session fix-login, branch ai/fix-login, ai-start

codex    # SessionStart hook → ai-brief
```

**Resume** (та же команда — attach, без duplicate ai-start):

```bash
ai-task fix-login $AI_WORK_ROOT/my-app --agent codex --layout
codex    # или claude --resume
```

**Hooks (рекомендуется, один раз на репо):**

```bash
bootstrap-codex-hooks $AI_WORK_ROOT/<repo>
bootstrap-claude-hooks $AI_WORK_ROOT/<repo>
sync-ai-scripts $AI_WORK_ROOT/<repo>
```

Codex: `codex` → `/hooks` → trust.

**Конец работы:**

```bash
# агент обновил snapshot (## Done, ## Last Validation)
scripts/ai-ship -m "fix(scope): one-line why" [--mr]
# merge MR — human в GitLab
scripts/ai-finish   # опционально: checklist перед detach
```

---

## Manual fallback (отладка)

```bash
cd $AI_WORK_ROOT/<repo>
ai-session <task> . --project <repo> --agent codex --layout
git checkout -b ai/<task>
scripts/ai-start
codex
```

---

## Что писать в чат

### С hooks

Briefing уже в контексте. Первое сообщение — **только задача**:

```text
Задача: поправить X в модуле Y, без unrelated changes.
```

### Без hooks

```text
Задача: <одно предложение>.
Сначала прочитай AGENTS.md и docs/ai/*, потом работай. No prod deploy.
```

### @-mentions (опционально)

```text
@AGENTS.md
Задача: <...>
```

---

## Что печатает ai-start

```text
=== ai-start ===
snapshot: .ai/snapshots/fix-login.md
branch:   ai/fix-login
status:   ...

read order:
  AGENTS.md
  ...
--- snapshot ---
```

Вывод **в терминал**. В чат — через hook (`ai-brief`).

---

## См. также

- [hooks.md](hooks.md)
- [skills.md](skills.md)
- [tmux-cheatsheet.md](tmux-cheatsheet.md)
- [scripts-sync.md](scripts-sync.md)
- strategy docs:
  - [Daily UX](workflow/01-overview-principles.md#daily-ux-thin-cli-first)
  - [Context Loading Protocol](workflow/03-context-snapshots-sessions.md#context-loading-protocol)
