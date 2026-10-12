#!/usr/bin/env bash
# .claude/hooks/guard.sh — the one PreToolUse hook Arib Metho ships.
# Blocks (exit 2, reason on stderr) three things that are cheap to catch and
# expensive to miss:
#   1. a secret pasted into a Write/Edit payload or a Bash command
#   2. a write to .env* files or into .git/
#   3. a catastrophic shell command (rm -rf on / or ~, force-push)
# Everything else is left to Claude Code's own permissions and sandbox.
# Fails closed when the payload can't be read: a guard that silently skips is
# worse than none.

set -uo pipefail

block() { printf 'arib-metho guard: %s\n' "$1" >&2; exit 2; }

if ! command -v jq >/dev/null 2>&1; then
  block "jq is required (brew install jq | apt-get install -y jq)."
fi

PAYLOAD="$(cat)"
TOOL="$(jq -r '.tool_name // empty' <<<"$PAYLOAD" 2>/dev/null)" \
  || block "could not parse hook payload."
FILE="$(jq -r '.tool_input.file_path // empty' <<<"$PAYLOAD")"
CMD="$(jq -r '.tool_input.command // empty' <<<"$PAYLOAD")"
# Only the text Claude is about to write or run — not the old_string it is replacing.
CONTENT="$(jq -r '[.tool_input.content, .tool_input.new_string,
                    (.tool_input.edits // [] | .[].new_string),
                    .tool_input.command] | map(select(. != null)) | join("\n")' <<<"$PAYLOAD")"

# 1. Secrets. Test fixtures and *.example files may carry fake keys.
case "/$FILE" in
  */test/*|*/tests/*|*/__tests__/*|*/fixtures/*|*.test.*|*.spec.*|*_test.*|*.example|*.sample|*.template) ;;
  *)
    SECRET_RE='sk-ant-[A-Za-z0-9_-]{20,}|(^|[^A-Za-z0-9_-])sk-(proj-)?[A-Za-z0-9_-]{32,}|gh[pousr]_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{22,}|glpat-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{35}|xox[baprs]-[A-Za-z0-9-]{10,}|[sr]k_live_[0-9A-Za-z]{24,}|npm_[A-Za-z0-9]{36}|-----BEGIN ([A-Z]+ )?PRIVATE KEY-----'
    if grep -Eq -- "$SECRET_RE" <<<"$CONTENT"; then
      block "this $TOOL contains what looks like a secret. Put it in .env (gitignored) and read it from the environment."
    fi
    ;;
esac

# 2. Protected files.
if [[ -n "$FILE" ]]; then
  case "/${FILE#./}" in
    */.env|*/.env.*)
      case "$FILE" in
        *.example|*.sample|*.template) ;;
        *) block "refusing to write $FILE — edit env files yourself." ;;
      esac ;;
    */.git/*) block "refusing to write inside .git/." ;;
  esac
fi

# 3. Catastrophic commands. Each check stays within one command (no ; & |).
if [[ -n "$CMD" ]]; then
  RM_RE='(^|[;&|[:space:]])rm([[:space:]]+-[a-zA-Z-]*)+[[:space:]]+(--[[:space:]]+)?["'"'"']?(/|~|\$HOME|\$\{HOME\})/?\*?["'"'"']?([[:space:];&|]|$)'
  if grep -Eq -- "$RM_RE" <<<"$CMD" && grep -Eq -- '(^|[;&|[:space:]])rm[[:space:]][^;&|]*-[a-zA-Z]*[rR]' <<<"$CMD"; then
    block "refusing to recursively delete / or the home directory."
  fi
  PUSH='git([[:space:]][^;&|]*)?[[:space:]]push'
  if grep -Eq -- "$PUSH"'[^;&|]*[[:space:]](-f|--force)([[:space:];&|]|$)' <<<"$CMD" \
     || grep -Eq -- "$PUSH"'[^;&|]*[[:space:]]\+[^[:space:];&|]' <<<"$CMD"; then
    block "force-push is blocked. Use --force-with-lease on your own branch, or ask the user."
  fi
fi

exit 0
