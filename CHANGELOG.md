# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) · Versioning: [SemVer](https://semver.org/).

## [1.0.0] — 2026-10-12

First release. Arib Metho is a small starter kit for Claude Code, distilled from
the author's earlier, much larger methodology (CCM v4: 34 skills, 17 agents,
10 hooks, ~7,200 always-on tokens). It keeps only what Claude Code can't know or
do on its own.

### Added
- `templates/CLAUDE.md` (~400 tokens, estimated) with six working rules and an
  `@memory/STATUS.md` import, so project status loads natively every session.
- `templates/memory/STATUS.md` (overwrite-style current state) and `DECISIONS.md`.
- `.claude/hooks/guard.sh` — one PreToolUse hook. Blocks secrets in what is about
  to be written or run, writes to `.env*` and `.git/`, `rm -rf` on `/` or `~`, and
  force-push (incl. `+branch`). Fails closed on an unreadable payload.
- `.claude/hooks/pre-commit.sh` — git hook scanning **staged** content for secrets,
  credential files and files over 1 MB (lockfiles excepted).
- `scripts/install.sh` — idempotent installer that never overwrites (writes
  `*.arib-new`), merges the hook into an existing `settings.json` (refuses to touch
  invalid JSON, keeps a backup), respects worktrees and `core.hooksPath`, leaves an
  existing git hook alone, and doesn't block commits on branches without the kit.
- `reviewer` agent, `/arib-handoff`, `/arib-arabic` and a path-scoped Arabic/RTL rule.
- `tests/run.sh` — 60 behaviour tests; every guarantee has a must-reject case.
- CI on Linux and macOS: tests, shellcheck, JSON validity, always-on size budget.
