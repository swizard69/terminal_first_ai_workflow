# tmux — шпаргалка (terminal-first workflow)

Config: `config/tmux.conf` → `~/.tmux.conf`

Prefix: **Ctrl+a** (не Ctrl+b)

---

## Сессии

| Действие | Команда |
|----------|---------|
| **Новая задача (рекомендуется)** | `ai-task <task> $AI_WORK_ROOT/<repo> --agent codex --layout` |
| Новая задача (ручной режим) | `ai-session <task> …` + `scripts/ai-start` |
| Список | `tmux ls` |
| Подключиться | `tmux attach -t <task>` / `tmux a -t <task>` |
| Отсоединиться (сессия живёт) | **Ctrl+a** `d` |
| Убить сессию | `tmux kill-session -t <task>` |
| Обзор задач | `ai-sessions` / `ai-sessions --all` |

Имя сессии = `AI_TASK` (например `fix-login`).

**Новая задача** — **новое имя** (не reuse старой сессии на `master`):

```bash
ai-task api-v2 $AI_WORK_ROOT/my-app --agent codex --layout
```

1 task = 1 session = 1 branch `ai/<task>` = 1 snapshot.

---

## Panes (окна внутри сессии)

| Действие | Клавиши |
|----------|---------|
| Влево / вниз / вверх / вправо | **Ctrl+a** `h` `j` `k` `l` |
| Клик мышью | включено (`mouse on`) |
| Split вертикально | **Ctrl+a** `\|` |
| Split горизонтально | **Ctrl+a** `-` |
| Resize pane | **Ctrl+a** `H` `J` `K` `L` (Shift) |
| Zoom pane (на весь экран / обратно) | **Ctrl+a** `z` |
| Закрыть pane | `exit` / **Ctrl+d** / **Ctrl+a** `x` |
| Pane → отдельное window | **Ctrl+a** `!` |
| Цикл по panes | **Ctrl+a** `o` |
| Последний активный pane | **Ctrl+a** `;` |
| Показать номера panes | **Ctrl+a** `q` (потом цифра) |
| Поменять panes местами | **Ctrl+a** `{` `}` |
| Переключить layout | **Ctrl+a** `Space` |
| Literal Ctrl+a в shell (начало строки) | **Ctrl+a** **Ctrl+a** |

Layout 3 panes: `scripts/ai-tmux-layout` или `ai-session ... --layout`

```text
+----------+----------+
| agent    | tests    |
+----------+          |
| git/glab |          |
+----------+----------+
```

---

## Windows (вкладки внутри сессии)

| Действие | Клавиши |
|----------|---------|
| Новое window | **Ctrl+a** `c` |
| Следующее / предыдущее | **Ctrl+a** `n` / `p` |
| Window по номеру | **Ctrl+a** `1`–`9` (base-index 1) |
| Список windows | **Ctrl+a** `w` |
| Переименовать | **Ctrl+a** `,` |
| Убить window | **Ctrl+a** `&` |

---

## Copy mode (scrollback)

Вход: **Ctrl+a** `[`. Режим vi (`mode-keys vi` в конфиге).

| Действие | Клавиши |
|----------|---------|
| Начать selection | `v` |
| Скопировать и выйти | `y` |
| Поиск вперёд / назад | `/` / `?` |
| Выйти без копирования | `q` |
| Вставить буфер tmux | **Ctrl+a** `]` |
| Scroll | колёсико мыши (mouse on) |

---

## Shell (readline, не tmux)

| Действие | Клавиши |
|----------|---------|
| Начало / конец строки | **Ctrl+a** / **Ctrl+e** |
| Прервать процесс | **Ctrl+c** |
| Поиск по history | **Ctrl+r** |

---

## Служебное

| Действие | Клавиши |
|----------|---------|
| Command prompt | **Ctrl+a** `:` |
| Все bindings | **Ctrl+a** `?` |
| Выбор сессии | **Ctrl+a** `s` |

---

## AI workflow в tmux

```bash
cd $AI_WORK_ROOT/<repo>
ai-session <task> . --project <repo> --agent claude --layout

scripts/ai-start      # контекст + snapshot (AI_TASK = имя сессии)
                      # внутри вызывает ai-context — см. agent-first-turn.md
claude                # или codex — pane agent

# другие panes
./scripts/ai-test.local
git status -sb && glab mr list

scripts/ai-finish     # перед detach / концом дня
```

---

## Несколько терминалов

Один `tmux attach -t <task>` — одна сессия, много клиентов.

```bash
# окно 1 и окно 2 — оба:
tmux attach -t fix-login
```

Отцепить чужой клиент и подключить себя:

```bash
tmux attach -d -t fix-login
```

---

## Reload config

```bash
tmux source-file ~/.tmux.conf
```

---

## Частые ошибки

| Проблема | Решение |
|----------|---------|
| `can't find session: fix-login-1` | `tmux ls` — exact name (`fix-login`) |
| `ai-start`: set AI_TASK | `export AI_TASK=<task>` or work inside tmux (session name) |
| Codex/Claude OAuth on remote dev | see [auth-remote-dev.md](auth-remote-dev.md) — SSH tunnel |
| Обновить scripts в проекте | `sync-ai-scripts .` или `--all` — см. [scripts-sync.md](scripts-sync.md) |
| Первое сообщение в Codex/Claude | [agent-first-turn.md](agent-first-turn.md) |
