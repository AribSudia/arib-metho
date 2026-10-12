# CLAUDE.md

<!-- Keep this file short. Every line here is loaded into every session.
     Write only what Claude can't learn by reading the code. Delete what doesn't apply. -->

## Project

- **What it is:** <one sentence: what this project does and for whom>
- **Stack:** <language, framework, database, hosting>
- **Run:** `<dev command>` · **Test:** `<test command>` · **Lint:** `<lint command>`

## Rules for this project

<!-- Only rules a new engineer would get wrong. Examples — replace with your own: -->
- <e.g. All money is stored as integer halalas, never floats.>
- <e.g. Migrations must be backward compatible; never drop a column in the same release.>
- <e.g. UI strings live in `locales/`; Arabic is the default locale (RTL).>

## How we work

- Before writing code for anything non-trivial, explore and propose a short plan; for small fixes, just do it.
- A task is done only when it is verified: tests pass, or you ran it and saw it work. Say what you verified and what you didn't.
- Write a failing test first when fixing a bug.
- Keep changes scoped to the task. Mention unrelated problems instead of fixing them silently.
- Never put secrets in code, logs, or commits. Ask before touching auth, payments, data deletion, migrations, or production config.
- One logical change per commit, Conventional Commits (`feat:`, `fix:`, `docs:` …).

## Memory

Current state and the next step live in `memory/STATUS.md`; decisions and their reasons in `memory/DECISIONS.md`.
Update them when something changes (`/arib-handoff` does it at the end of a session). Keep both short; git keeps the history.

@memory/STATUS.md
