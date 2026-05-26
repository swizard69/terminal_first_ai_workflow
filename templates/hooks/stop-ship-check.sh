#!/usr/bin/env bash
set -euo pipefail

# Stop hook: block agent turn end while git tree is dirty (push agent to ai-ship first).

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  exit 0
fi

dirty=false
if ! git diff --quiet 2>/dev/null; then dirty=true; fi
if ! git diff --cached --quiet 2>/dev/null; then dirty=true; fi

if [ "$dirty" = true ]; then
  cat >&2 <<EOF
blocked: uncommitted changes in $(basename "$ROOT")

Before stopping:
  1. ./scripts/ai-test.local   # or ai-test
  2. ./scripts/ai-ship -m "type(scope): summary" [--mr]
     (or commit manually; ai-finish for checklist only)

Merge MR and deploy --apply remain human-only.
EOF
  exit 2
fi

exit 0
