---
name: debugging
description: Structured reproduce → isolate → fix → validate debugging workflow.
---

# debugging

Use when fixing bugs, investigating errors, or flaky behavior.

## Process

1. **Reproduce** — exact steps, env (local/docker/prod-readonly logs only).
2. **Collect evidence** — error message, stack, relevant log lines (minimal).
3. **Isolate** — narrow to file/function; form hypothesis.
4. **Fix** — smallest patch; one cause at a time.
5. **Validate** — rerun repro + `./scripts/ai-test.local` if present.

## Tools (pick what fits repo)

```bash
rg -n 'pattern' .
docker compose logs -f --tail=100
docker logs <container>
curl -sS -o /dev/null -w '%{http_code}' URL
./scripts/php-lint file.php    # dev-ai: docker via manifest php_lint_image
./scripts/python-lint file.py
./scripts/node-lint file.ts file.vue   # dev-ai: docker via node_lint_image
./scripts/ai-test.local        # preferred gate after edits
journalctl -u service -n 50    # if applicable
```

## Rules

- No prod writes or `--apply` deploy from agent.
- No broad `grep` across vendor/node_modules without path limit.
- Document root cause in snapshot `## Done` when fixed.

## Output

- root cause (one paragraph)
- fix summary
- commands run + results
- follow-ups if any
