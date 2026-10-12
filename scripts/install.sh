#!/usr/bin/env bash
# scripts/install.sh — install Arib Metho into a project.
#
#   scripts/install.sh /path/to/project
#
# Safe to re-run. Never overwrites a file you already have: if yours differs
# from Arib Metho's, its copy is written next to it as <file>.arib-new for you to
# merge. An existing .claude/settings.json gets the guard hook merged in
# (backup kept as settings.json.arib-bak).

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${1:-}"
[[ -n "$DEST" && -d "$DEST" ]] || { echo "usage: $0 /path/to/project" >&2; exit 64; }
DEST="$(cd "$DEST" && pwd)"
[[ "$DEST" != "$SRC" ]] || { echo "refusing to install Arib Metho into itself" >&2; exit 64; }
command -v jq >/dev/null || { echo "jq is required (brew install jq | apt-get install -y jq)" >&2; exit 69; }

place() { # place <source> <dest-relative-path>
  local from="$1" to="$DEST/$2"
  mkdir -p "$(dirname "$to")"
  if [[ ! -e "$to" ]]; then
    cp "$from" "$to"; echo "  + $2"
  elif cmp -s "$from" "$to"; then
    echo "  = $2"
  else
    cp "$from" "$to.arib-new"; echo "  ! $2 exists and differs — the Arib Metho version is at $2.arib-new"
  fi
}

echo "Installing Arib Metho into $DEST"

place "$SRC/templates/CLAUDE.md"           CLAUDE.md
place "$SRC/templates/memory/STATUS.md"    memory/STATUS.md
place "$SRC/templates/memory/DECISIONS.md" memory/DECISIONS.md
place "$SRC/.claude/hooks/guard.sh"        .claude/hooks/guard.sh
place "$SRC/.claude/hooks/pre-commit.sh"   .claude/hooks/pre-commit.sh
place "$SRC/.claude/agents/reviewer.md"    .claude/agents/reviewer.md
place "$SRC/.claude/rules/arabic.md"       .claude/rules/arabic.md
for skill in "$SRC"/.claude/skills/arib-*/SKILL.md; do
  name="$(basename "$(dirname "$skill")")"
  place "$skill" ".claude/skills/$name/SKILL.md"
done
chmod +x "$DEST/.claude/hooks/guard.sh" "$DEST/.claude/hooks/pre-commit.sh"

# settings.json: copy, or merge the guard hook into an existing one.
SETTINGS="$DEST/.claude/settings.json"
if [[ ! -e "$SETTINGS" ]]; then
  cp "$SRC/.claude/settings.json" "$SETTINGS"; echo "  + .claude/settings.json"
elif grep -q 'hooks/guard.sh' "$SETTINGS"; then
  echo "  = .claude/settings.json (guard hook already present)"
elif ! jq empty "$SETTINGS" 2>/dev/null; then
  echo "  ! .claude/settings.json is not valid JSON — left untouched. Fix it and re-run," >&2
  echo "    or add the PreToolUse hook from $SRC/.claude/settings.json by hand." >&2
else
  [[ -e "$SETTINGS.arib-bak" ]] || cp "$SETTINGS" "$SETTINGS.arib-bak"
  HOOK="$(jq '.hooks.PreToolUse[0]' "$SRC/.claude/settings.json")"
  jq --argjson h "$HOOK" '.hooks.PreToolUse = ((.hooks.PreToolUse // []) + [$h])' \
    "$SETTINGS" > "$SETTINGS.arib-tmp" && mv "$SETTINGS.arib-tmp" "$SETTINGS"
  echo "  ~ .claude/settings.json (guard hook merged; backup at settings.json.arib-bak)"
fi

# git pre-commit hook — worktree- and core.hooksPath-aware; never clobbers.
if git -C "$DEST" rev-parse --git-dir >/dev/null 2>&1; then
  HOOKS_DIR="$(cd "$DEST" && git rev-parse --git-path hooks)"   # honours worktrees + core.hooksPath
  [[ "$HOOKS_DIR" == /* ]] || HOOKS_DIR="$DEST/$HOOKS_DIR"
  PRE="$HOOKS_DIR/pre-commit"
  if [[ -e "$PRE" ]] && ! grep -q 'arib-pre-commit' "$PRE"; then
    echo "  ! $PRE already exists — add this line to it to enable the Arib Metho scan:"
    echo "      f=\"\$(git rev-parse --show-toplevel)/.claude/hooks/pre-commit.sh\"; [ -x \"\$f\" ] && { \"\$f\" || exit 1; }"
  else
    mkdir -p "$HOOKS_DIR"
    # Branches without Arib Metho (the hooks dir is shared) skip the scan instead of failing.
    printf '#!/usr/bin/env bash\n# arib-pre-commit\nf="$(git rev-parse --show-toplevel)/.claude/hooks/pre-commit.sh"\n[ -x "$f" ] || exit 0\nexec "$f"\n' > "$PRE"
    chmod +x "$PRE"; echo "  + git pre-commit hook ($PRE)"
  fi
else
  echo "  - not a git repo: skipped the pre-commit hook"
fi

if ! grep -q 'memory/STATUS.md' "$DEST/CLAUDE.md"; then
  echo
  echo "Your CLAUDE.md doesn't load the status file yet. Add this line to it:"
  echo "  @memory/STATUS.md"
fi

echo
echo "Done. Next: fill in the Project section of CLAUDE.md, then start Claude Code."
