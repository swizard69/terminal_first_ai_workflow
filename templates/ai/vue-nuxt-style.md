# Vue / Nuxt / frontend style (personal, not in git)

Link from Obsidian or reference in project `docs/ai/conventions.md`.

## Stack defaults

- Prefer Composition API + `<script setup>` (Vue 3).
- TypeScript for new files when the repo already uses it.
- Pinia for client state; avoid ad-hoc global event buses.
- API calls via one client module (fetch/axios/ofetch) — no scattered URLs.

## File layout (typical)

```text
src/ or app/
  components/     # presentational, reusable
  composables/    # shared logic
  pages/          # routes (Nuxt: pages/)
  stores/         # Pinia
  assets/         # static
```

## Validation gate (dev-ai)

- **Do not** trust IDE ESLint/TS diagnostics alone.
- After JS/TS/Vue edits:
  ```bash
  ./scripts/node-lint path/to/file.vue path/to/file.ts
  ./scripts/ai-test.local
  ```
- Configure `node_lint_image=` in `manifest.md` when Node version must match CI/docker.

## UI / CSS

- Match existing CSS approach (Tailwind, SCSS modules, etc.) — no second system.
- Keep components small; extract composables when logic repeats twice.

## Nuxt specifics

- Server routes in `server/api/`; no secrets in client bundle.
- Use `runtimeConfig` for env-specific values.
- Prefer `useFetch` / `useAsyncData` patterns already in the repo.

## Ship

- Same MR loop as backend: `ai-task` → work → `scripts/ai-ship -m "..." [--mr]`.
