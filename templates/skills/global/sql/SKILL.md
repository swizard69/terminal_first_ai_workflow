---
name: sql
description: Read-only DB reasoning — query review, EXPLAIN, indexes, migrations. Respects project SQL conventions.
---

# sql

Use when reviewing SQL, tuning queries, designing indexes, or drafting migrations.

## Preconditions

- Read `docs/ai/conventions.md` and any project SQL docs (`docs/**/README_SQL.md`, `sql-preprocessor.md`).
- **Dev DB only** from agent — prod is read-only logs/schema review via human/CI unless explicitly allowed.
- If the repo uses a **SQL preprocessor** or conditional blocks (`-- IF:`, `-- CLIENT_ID --`, etc.), never bypass it with raw concatenated SQL in app code.

## Process

1. **Clarify intent** — read path, expected row count, hot vs one-off.
2. **Inspect query** — joins, filters, `ORDER BY`, subqueries, N+1 callers.
3. **Plan** — `EXPLAIN` / `EXPLAIN ANALYZE` on dev; check indexes on filter/join columns.
4. **Change** — smallest fix: index, rewrite, or migration sketch (implement only if user asks).
5. **Validate** — dev/staging run + app tests / `./scripts/ai-test.local` if SQL affects behavior.

## Read-only checks (dev)

```bash
# CLI (when mysql client + creds on dev-ai)
mysql -e "EXPLAIN SELECT ..."
mysql -e "SHOW INDEX FROM table_name"

# Prefer LIMIT on exploratory SELECTs
mysql -e "SELECT ... LIMIT 20"
```

When MCP MySQL tools are available (Cursor/homelab dev servers), use **SELECT / EXPLAIN / SHOW** only — no agent-driven `INSERT`/`UPDATE`/`DELETE` on shared dev unless human asked for a specific fix.

## Migrations

- Forward + rollback story (or explicit "irreversible — backup first").
- Avoid long locks: batch updates, off-peak for prod (human applies).
- Never commit credentials; schema in git, secrets in env/server only.

## Review checklist

- injection risk (parameterized queries / bound params, no user input in string SQL)
- correct types and collation on joins
- missing index on `WHERE` / `JOIN` / `ORDER BY` columns at scale
- `SELECT *` vs needed columns
- preprocessor conditionals preserved when editing templated SQL
- migration order safe for deploy (additive first, drop later)

## Rules

- No prod writes from agent shell or MCP.
- No `DELETE`/`UPDATE` without `WHERE` + human confirmation.
- No schema change without noting rollback and affected services.
- Document query change + EXPLAIN delta in snapshot when non-trivial.

## Output

- problem / current plan (or EXPLAIN summary)
- recommended change (SQL snippet or migration sketch)
- index / risk notes
- validation commands run
- **Safe to merge:** yes | no — reason
