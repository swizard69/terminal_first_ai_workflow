#!/usr/bin/env bash
set -euo pipefail

# PreToolUse guard for Codex + Claude Code (Bash matcher).
# Exit 2 blocks the tool call; stderr is shown to the agent.

INPUT="$(cat)"
CMD="$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null || true)"

case "$CMD" in
  *deploy/deploy.sh*apply*|*deploy.sh*--apply*)
    echo "blocked: prod deploy via agent bash — use human + GitLab CI" >&2
    exit 2
    ;;
esac

if echo "$CMD" | grep -qE '(AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{30,}|-----BEGIN (RSA|OPENSSH) PRIVATE KEY-----)'; then
  echo "blocked: possible secret in command" >&2
  exit 2
fi

exit 0
