#!/usr/bin/env bash
# .claude/hooks/pre-commit.sh — git pre-commit hook (installed by scripts/install.sh).
# Scans the STAGED content (the index), not the working tree, so what is
# checked is exactly what gets committed. Blocks credential files, secret
# patterns, and files over 1 MB (lockfiles excepted).

set -uo pipefail

SECRET_RE='sk-ant-[A-Za-z0-9_-]{20,}|(^|[^A-Za-z0-9_-])sk-(proj-)?[A-Za-z0-9_-]{32,}|gh[pousr]_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{22,}|glpat-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{35}|xox[baprs]-[A-Za-z0-9-]{10,}|[sr]k_live_[0-9A-Za-z]{24,}|npm_[A-Za-z0-9]{36}|-----BEGIN ([A-Z]+ )?PRIVATE KEY-----'
FAIL=()

while IFS= read -r -d '' file; do
  case "$(basename "$file")" in
    .env|.env.*|*.pem|*.key|id_rsa|id_ed25519|credentials.json)
      case "$file" in
        *.example|*.sample|*.template) ;;
        *) FAIL+=("credential file: $file"); continue ;;
      esac ;;
  esac
  case "$(basename "$file")" in  # lockfiles are legitimately large
    *lock.json|*.lock|pnpm-lock.yaml|*.lockb) size=0 ;;
    *) size="$(git cat-file -s ":$file" 2>/dev/null || echo 0)" ;;
  esac
  if (( size > 1048576 )); then
    FAIL+=("over 1 MB: $file (use Git LFS or .gitignore)")
    continue
  fi
  if git show ":$file" 2>/dev/null | grep -Eq -- "$SECRET_RE"; then
    FAIL+=("secret pattern in staged content: $file")
  fi
done < <(git diff --cached --name-only -z --diff-filter=ACMR)

if (( ${#FAIL[@]} )); then
  echo "arib-metho pre-commit blocked the commit:" >&2
  printf '  x %s\n' "${FAIL[@]}" >&2
  echo "Fix and re-stage. A false positive can be bypassed with: git commit --no-verify" >&2
  exit 1
fi
exit 0
