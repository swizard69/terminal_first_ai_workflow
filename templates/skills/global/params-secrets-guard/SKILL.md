---
name: params-secrets-guard
description: Never commit or deploy secrets — params.yaml, deploy.env, prod configs.
---

# params-secrets-guard

Apply in **all** repos, especially those with deploy configs or legacy deploy scripts.

## Never commit

- `deploy/deploy.env`
- `params.yaml`, `params.*.yaml` with API keys
- `config/config_prod.yaml`, `.env`, `*.pem`, `*.key`
- SSH passwords in any tracked file

## Never deploy via agent

- Anything in `deploy/deploy.protect`
- `params.yaml` on prod (server-local)
- `deploy.env`

## If agent needs config context

- Read `deploy/README.md`, `deploy.env.example`, `params.dev-ai.yaml` (dev only)
- Describe changes needed; human edits prod files on server

## Pre-commit sanity

```bash
git diff --cached --name-only | grep -E 'deploy\.env|params\.yaml|config_prod|\.pem$' && echo STOP
```

Use project git hooks if configured (`.ai/hooks/`).
