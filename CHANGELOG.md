# Changelog

All notable changes to **Terminal-First AI Workflow** are documented here.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).  
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-05-26

### Added

- Core CLI: `ai-task`, `ai-session`, `ai-sessions`, `ai-ship`, snapshots, hooks bootstrap.
- Homelab helpers: `ai-vault-link`, `ai-openclaw-check`, `bootstrap-openclaw`, `ai-openclaw-agent`.
- Language lint gates: `php-lint`, `python-lint`, `node-lint`.
- Frontend bootstrap (`--type frontend`), skills `frontend-patch` / `frontend-test`.
- GitHub PR support in `ai-ship --mr` (via `gh`).
- CI: `.github/workflows/ci.yml`, `scripts/ai-test.local`.
- Documentation set `docs/workflow/` with versioning policy (`docs/VERSIONING.md`).

### Changed

- Removed numbered migration **Phase 0–5** jargon from user-facing docs; replaced with plain migration steps.
- README and workflow docs aligned for GitHub + GitLab.

[1.0.0]: https://github.com/swizard69/terminal_first_ai_workflow/releases/tag/v1.0.0
