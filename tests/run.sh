#!/usr/bin/env bash
# tests/run.sh — behaviour tests for everything Arib Metho ships that can break.
# Every guarantee has a test that must be REJECTED, not just one that passes.

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GUARD="$ROOT/.claude/hooks/guard.sh"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0

ok()   { PASS=$((PASS+1)); echo "  ok   $1"; }
bad()  { FAIL=$((FAIL+1)); echo "  FAIL $1"; }
expect() { # expect <want-exit> <name> <cmd...>
  local want="$1" name="$2"; shift 2
  "$@" >/dev/null 2>&1; local got=$?
  [[ "$got" == "$want" ]] && ok "$name" || bad "$name (exit $got, want $want)"
}
guard() { jq -n "$1" | "$GUARD"; }

# Fake secrets are assembled at runtime so this file never contains one.
AWS="AKIA$(printf 'Q%.0s' {1..16})"
GH="ghp_$(printf 'a%.0s' {1..36})"
PEM="-----BEGIN ""PRIVATE KEY-----"

echo "guard.sh"
expect 0 "plain write allowed"          guard '{tool_name:"Write",tool_input:{file_path:"src/a.ts",content:"export const a=1"}}'
expect 2 "AWS key in Write blocked"      guard "{tool_name:\"Write\",tool_input:{file_path:\"src/a.ts\",content:\"k='$AWS'\"}}"
expect 2 "GitHub token in Edit blocked"  guard "{tool_name:\"Edit\",tool_input:{file_path:\"src/a.ts\",old_string:\"x\",new_string:\"$GH\"}}"
expect 2 "secret in MultiEdit blocked"   guard "{tool_name:\"MultiEdit\",tool_input:{file_path:\"a.py\",edits:[{old_string:\"a\",new_string:\"ok\"},{old_string:\"b\",new_string:\"$PEM\"}]}}"
expect 2 "secret in Bash blocked"        guard "{tool_name:\"Bash\",tool_input:{command:\"export K=$AWS\"}}"
expect 0 "removing a secret allowed"     guard "{tool_name:\"Edit\",tool_input:{file_path:\"src/a.ts\",old_string:\"$AWS\",new_string:\"process.env.K\"}}"
expect 0 "fake secret in test fixture"   guard "{tool_name:\"Write\",tool_input:{file_path:\"tests/fixtures/k.txt\",content:\"$AWS\"}}"
expect 2 ".env write blocked"            guard '{tool_name:"Write",tool_input:{file_path:"/p/.env",content:"A=1"}}'
expect 2 ".env.production write blocked" guard '{tool_name:"Edit",tool_input:{file_path:"./.env.production",new_string:"A=1"}}'
expect 2 "relative .env blocked"         guard '{tool_name:"Write",tool_input:{file_path:".env",content:"A=1"}}'
expect 0 ".env.example allowed"          guard '{tool_name:"Write",tool_input:{file_path:".env.example",content:"A="}}'
expect 2 ".git/ write blocked"           guard '{tool_name:"Write",tool_input:{file_path:"/p/.git/config",content:"x"}}'
expect 2 "rm -rf / blocked"              guard '{tool_name:"Bash",tool_input:{command:"rm -rf /"}}'
expect 2 "rm -fr ~ blocked"              guard '{tool_name:"Bash",tool_input:{command:"cd x && rm -fr ~"}}'
expect 0 "rm -rf ./build allowed"        guard '{tool_name:"Bash",tool_input:{command:"rm -rf ./build"}}'
expect 2 "git push --force blocked"      guard '{tool_name:"Bash",tool_input:{command:"git push --force origin main"}}'
expect 2 "git push -f blocked"           guard '{tool_name:"Bash",tool_input:{command:"git push -f"}}'
expect 0 "--force-with-lease allowed"    guard '{tool_name:"Bash",tool_input:{command:"git push --force-with-lease"}}'
expect 2 "secret in a project path containing 'test'" guard "{tool_name:\"Write\",tool_input:{file_path:\"/home/u/latest-app/src/cfg.ts\",content:\"$AWS\"}}"
expect 0 "kebab-case name with 'sk-' allowed" guard '{tool_name:"Write",tool_input:{file_path:"a.ts",content:"const q=\"task-queue-worker-retry-backoff-policy\""}}'
expect 0 "kubectl label with 'sk-' allowed" guard '{tool_name:"Bash",tool_input:{command:"kubectl get pods -l app=risk-scoring-service-production-eu-west-1"}}'
expect 0 ".env.template allowed"         guard '{tool_name:"Write",tool_input:{file_path:"apps/web/.env.template",content:"A="}}'
expect 2 "nested .env blocked"           guard '{tool_name:"Write",tool_input:{file_path:"apps/web/.env",content:"A=1"}}'
expect 2 "rm -rf /* blocked"             guard '{tool_name:"Bash",tool_input:{command:"rm -rf /*"}}'
expect 2 "rm -r -f / blocked"            guard '{tool_name:"Bash",tool_input:{command:"rm -r -f /"}}'
expect 2 "rm -rf -- / blocked"           guard '{tool_name:"Bash",tool_input:{command:"rm -rf -- /"}}'
expect 2 "rm -rf \"\$HOME\" blocked"     guard '{tool_name:"Bash",tool_input:{command:"rm -rf \"$HOME\""}}'
expect 2 "rm -rf ~/* blocked"            guard '{tool_name:"Bash",tool_input:{command:"rm -rf ~/*"}}'
expect 0 "rm -f on a file in /tmp allowed" guard '{tool_name:"Bash",tool_input:{command:"rm -f /tmp/x.lock"}}'
expect 2 "git push origin +main blocked" guard '{tool_name:"Bash",tool_input:{command:"git push origin +main"}}'
expect 2 "git -C x push --force blocked" guard '{tool_name:"Bash",tool_input:{command:"git -C x push --force"}}'
expect 0 "push then rm -f allowed"       guard '{tool_name:"Bash",tool_input:{command:"git push origin main && rm -f /tmp/x.lock"}}'
expect 0 "push then tail -f allowed"     guard '{tool_name:"Bash",tool_input:{command:"git push && tail -f server.log"}}'
expect 2 "garbage payload fails closed"  bash -c "echo 'not json' | '$GUARD'"

echo "pre-commit.sh"
REPO="$TMP/repo"; git init -q "$REPO"; cd "$REPO" || exit 1
git config user.email t@t; git config user.name t
echo "ok" > a.txt; git add a.txt
expect 0 "clean commit allowed"          "$ROOT/.claude/hooks/pre-commit.sh"
echo "k=$AWS" > a.txt; git add a.txt; echo "ok" > a.txt
expect 1 "staged secret blocked even after working copy cleaned" "$ROOT/.claude/hooks/pre-commit.sh"
git reset -q; echo "ok" > a.txt; git add a.txt
echo "k=$AWS" > a.txt
expect 0 "unstaged secret not blamed on commit" "$ROOT/.claude/hooks/pre-commit.sh"
git checkout -q a.txt; echo "A=1" > .env; git add -f .env
expect 1 ".env commit blocked"           "$ROOT/.claude/hooks/pre-commit.sh"
git rm -q --cached .env; echo "my file" > "with space.txt"; git add "with space.txt"
expect 0 "filename with space handled"   "$ROOT/.claude/hooks/pre-commit.sh"
head -c 1500000 /dev/zero > package-lock.json; git add package-lock.json
expect 0 "large lockfile allowed"        "$ROOT/.claude/hooks/pre-commit.sh"
echo "A=" > .env.sample; git add .env.sample
expect 0 ".env.sample commit allowed"    "$ROOT/.claude/hooks/pre-commit.sh"
head -c 1100000 /dev/zero > big.bin; git add big.bin
expect 1 "file over 1 MB blocked"        "$ROOT/.claude/hooks/pre-commit.sh"
cd "$ROOT" || exit 1

echo "install.sh"
P="$TMP/proj"; mkdir -p "$P"; git init -q "$P"
expect 0 "fresh install"                 "$ROOT/scripts/install.sh" "$P"
for f in CLAUDE.md memory/STATUS.md memory/DECISIONS.md .claude/settings.json .claude/hooks/guard.sh \
         .claude/agents/reviewer.md .claude/skills/arib-handoff/SKILL.md .git/hooks/pre-commit; do
  [[ -e "$P/$f" ]] && ok "installed $f" || bad "missing $f"
done
before="$(cd "$P" && find . -path ./.git -prune -o -type f -print | sort | xargs cat | cksum)"
expect 0 "re-run is a no-op"             "$ROOT/scripts/install.sh" "$P"
after="$(cd "$P" && find . -path ./.git -prune -o -type f -print | sort | xargs cat | cksum)"
[[ "$before" == "$after" ]] && ok "re-run changed nothing" || bad "re-run changed files"

Q="$TMP/proj2"; mkdir -p "$Q/.claude"; git init -q "$Q"
echo "# mine" > "$Q/CLAUDE.md"
echo '{"permissions":{"allow":["Bash(npm test)"]},"hooks":{"PreToolUse":[{"matcher":"Bash","hooks":[]}]}}' > "$Q/.claude/settings.json"
printf '#!/bin/sh\necho mine\n' > "$Q/.git/hooks/pre-commit"
"$ROOT/scripts/install.sh" "$Q" >/dev/null 2>&1
[[ "$(cat "$Q/CLAUDE.md")" == "# mine" && -e "$Q/CLAUDE.md.arib-new" ]] && ok "existing CLAUDE.md kept" || bad "CLAUDE.md overwritten"
jq -e '.permissions.allow == ["Bash(npm test)"] and (.hooks.PreToolUse | length == 2)' "$Q/.claude/settings.json" >/dev/null \
  && ok "settings merged, user rules kept" || bad "settings merge wrong"
grep -q "echo mine" "$Q/.git/hooks/pre-commit" && ok "existing git hook not clobbered" || bad "git hook clobbered"

B="$TMP/badjson"; mkdir -p "$B/.claude"; git init -q "$B"
printf '{"permissions":{"allow":["Bash(npm test)"]},}' > "$B/.claude/settings.json"
cp "$B/.claude/settings.json" "$TMP/orig.json"
"$ROOT/scripts/install.sh" "$B" >/dev/null 2>&1; "$ROOT/scripts/install.sh" "$B" >/dev/null 2>&1
cmp -s "$B/.claude/settings.json" "$TMP/orig.json" && ok "invalid settings.json left intact (twice)" || bad "invalid settings.json damaged"

N="$TMP/nometho"; git init -q "$N"; git -C "$N" config user.email t@t; git -C "$N" config user.name t
"$ROOT/scripts/install.sh" "$N" >/dev/null 2>&1
git -C "$N" commit -q --allow-empty -m init; git -C "$N" checkout -q --orphan bare
git -C "$N" rm -rq --cached . >/dev/null 2>&1; mv "$N/.claude" "$TMP/nometho-claude"
expect 0 "commit on a branch without Arib Metho not blocked" git -C "$N" commit -q --allow-empty -m x

W="$TMP/wt"; git -C "$P" commit -q --allow-empty -m init; git -C "$P" worktree add -q "$W" 2>/dev/null
rm -f "$P/.git/hooks/pre-commit"
expect 0 "install into a worktree"       "$ROOT/scripts/install.sh" "$W"
[[ -x "$P/.git/hooks/pre-commit" ]] && ok "worktree hook in shared hooks dir" || bad "worktree hook misplaced"

echo
echo "$PASS passed, $FAIL failed"
(( FAIL == 0 ))
