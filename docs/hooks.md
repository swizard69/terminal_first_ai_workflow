# Hooks — layered automation

Hooks **дополняют**, не заменяют `ai-start` / ручной промпт.

---

## Три слоя

| Слой | Когда | Что делает |
|------|--------|------------|
| **Codex / Claude hooks** | `startup` / `resume` агента | `SessionStart` → inject `ai-brief` |
| **scripts/ai-start** | ты, начало задачи | snapshot + `index.jsonl` + briefing |
| **git hooks** | commit | secret guard, snapshot reminder |

---

## Codex (recommended)

### Установка

```bash
bootstrap-codex-hooks $AI_WORK_ROOT/my-app
sync-ai-scripts $AI_WORK_ROOT/my-app   # ai-brief в scripts/
```

### Первый запуск Codex в репо

```bash
cd $AI_WORK_ROOT/my-app
codex
/hooks          # review → trust project hooks
```

### SessionStart

При `startup|resume|clear` Codex запускает:

```text
.codex/hooks/session-start.sh  →  scripts/ai-brief
```

Stdout попадает в **developer context** — агент видит read order + snapshot без copy-paste.

### PreToolUse (Bash)

`.codex/hooks/pre-bash-guard.sh` — блок deploy `--apply`, obvious secrets.

### Stop

`.codex/hooks/stop-ship-check.sh` — uncommitted changes → turn не завершается.  
Нужно `./scripts/ai-ship -m "..."` (опционально `--mr` для auto MR). `ai-finish` / `ai-start` / `ai-session` — по-прежнему доступны.

Расширяй под проект (см. `deploy/README.md`).

---

## scripts/ai-start vs ai-brief

| | `ai-start` | `ai-brief` |
|---|------------|------------|
| Кто вызывает | ты | Codex / Claude hook |
| snapshot create | да | нет (только read) |
| index.jsonl | да | нет |
| ai-context | да | да |

**Последовательность:**

```bash
ai-session fix-login . --agent codex --layout
scripts/ai-start          # один раз — snapshot + index
codex                     # SessionStart hook → ai-brief автоматически
```

После `resume` / нового чата — hook снова подгрузит briefing.

---

## Claude Code

### Установка

```bash
bootstrap-claude-hooks $AI_WORK_ROOT/my-app
sync-ai-scripts $AI_WORK_ROOT/my-app
```

Trust **не нужен** — hooks в `.claude/settings.json` (коммитится в MR).

### SessionStart

При `startup|resume|clear|compact`:

```text
.claude/hooks/session-start.sh  →  scripts/ai-brief
```

Stdout → system reminder в контексте Claude.

### PreToolUse (Bash)

`.claude/hooks/pre-bash-guard.sh` — тот же guard, что у Codex (shared `templates/hooks/`).

### Последовательность

```bash
ai-session fix-login . --agent claude --layout
scripts/ai-start
claude                    # или claude --resume
```

---

## Git hooks (`.ai/hooks/`)

Опционально в проекте:

```bash
git config core.hooksPath .ai/hooks
```

Шаблоны — в [Project Bootstrap And Hooks](workflow/04-project-bootstrap-hooks.md#hooks-model)
(pre-commit secret guard, post-commit snapshot reminder).

Linux: для age snapshot используй `stat -c %Y`, не `stat -f`.

---

## Чего hooks НЕ делают

- не заменяют GitLab MR/CI
- не деплоят на prod
- не пушат в git сами
- не дублируют OpenClaw orchestration

Rule: **hooks = guardrails + auto-brief**, не скрытая автomation.

---

## См. также

- [agent-first-turn.md](agent-first-turn.md)
- [OpenAI Codex Hooks](https://developers.openai.com/codex/hooks)
- [Claude Code Hooks](https://code.claude.com/docs/en/hooks)
