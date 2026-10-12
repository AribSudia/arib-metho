# Contributing to Arib Metho

Arib Metho is deliberately small: a CLAUDE.md template, two memory files, one guard
hook, a git pre-commit scan, one reviewer agent and two skills. The bar for
adding anything is that it does something Claude Code doesn't already do well
on its own, and that we can show it helps. "It might be useful" isn't enough —
every file we ship is context someone pays for in every session.

## Making a change

1. Open an issue first for anything beyond a bug fix or a typo.
2. Branch from `main` (`feat/…`, `fix/…`, `docs/…`).
3. Run `bash tests/run.sh`. A new guarantee needs a test that proves a bad
   input is **rejected**, not only that a good one passes.
4. Keep `templates/CLAUDE.md` + `templates/memory/STATUS.md` under the CI
   budget (~2,000 tokens). If you need more, explain why in the PR.
5. Add a line to `CHANGELOG.md` for anything a user would notice.
6. Use Conventional Commits (`feat:`, `fix:`, `docs:` …).

CI (`test-hooks`, `validate-json`, `validate-coherence`, `measure`) must pass
before merge.

## License

By contributing you agree that your contribution is licensed under the
project's [MIT License](LICENSE).
