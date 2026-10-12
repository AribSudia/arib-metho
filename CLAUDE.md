# CLAUDE.md — Arib Metho repository

## Project

- **What it is:** Arib Metho, a small starter kit installed into other projects: a CLAUDE.md template, memory files, a guard hook, a git pre-commit scan, one reviewer agent, two skills.
- **Stack:** bash + jq. No runtime, no dependencies beyond git and jq.
- **Test:** `bash tests/run.sh` · **Lint:** `shellcheck -S warning .claude/hooks/*.sh scripts/*.sh tests/*.sh`

## Rules for this project

- Small is the product. Don't add a skill, agent, hook or doc unless it does something Claude Code doesn't already do, and say in the PR how we know it helps.
- What gets installed lives in `templates/` and `.claude/`; `scripts/install.sh` must never overwrite or delete a user's file. Test that, too.
- Every guarantee a hook makes has a test in `tests/run.sh` showing a bad input is rejected.
- Never write a real-looking secret into a file, even in tests; assemble fake ones at runtime (see `tests/run.sh`).
- `templates/CLAUDE.md` + `templates/memory/STATUS.md` must stay under the CI budget (~2,000 tokens).

## How we work

- Explore and propose a short plan before non-trivial changes; for small fixes, just do it.
- Done means verified: tests pass and you say what you ran.
- Conventional Commits, one change per commit; changes land on `main` through PRs.

@memory/STATUS.md
