# Arib Metho

**A small, opinionated starter kit for Claude Code: a good CLAUDE.md, a memory
file, and a safety net. Nothing else.**

**v1.0.0** · MIT · Always-on cost: ~500 tokens (estimated)

> **بالعربي:** Arib Metho مجموعة صغيرة فوق Claude Code: ملف `CLAUDE.md` جيد،
> وملف ذاكرة يُحمَّل في كل جلسة، وhook يمنع تسريب الأسرار والأوامر المدمّرة.
> كل ما يقدّمه Claude Code أصلًا (التخطيط، الوكلاء الفرعيون، المراجعة،
> `/security-review`، الـ worktrees) لم نعد نعيد بناءه.

## Why it's this small

Claude Code already plans, explores, spawns subagents, reviews code
(`/code-review`, `/security-review`), simplifies (`/simplify`), and runs work in
isolated worktrees. This kit's predecessor rebuilt most of that as 34 skills,
17 agents, 10 hooks, an I/O channel and a wave system: about 7,200 tokens loaded
into every session, plus rules Claude had to follow before it could get to your task.

Arib Metho keeps only what Claude Code can't know or do on its own:

| What | Why it exists |
|------|---------------|
| `CLAUDE.md` template | Your project's commands, rules and gotchas — the one thing Claude can't infer. Includes six working rules (verify before "done", test-first for bugs, stay in scope, ask before risky areas). |
| `memory/STATUS.md` | Where things stand and the next step. Imported by `CLAUDE.md`, so every session starts with it. |
| `memory/DECISIONS.md` | Why things are the way they are. Read on demand. |
| `.claude/hooks/guard.sh` | Blocks secrets in writes and commands, writes to `.env*` and `.git/`, `rm -rf /`, and force-push. |
| `.claude/hooks/pre-commit.sh` | Git hook that scans the **staged** content for secrets, credential files and files over 1 MB. |
| `reviewer` agent | An independent second look, in a fresh context, before you call something done. |
| `/arib-handoff` | Rewrites `STATUS.md` at the end of a session. |
| `/arib-arabic` + Arabic rule | RTL, Arabic punctuation, numerals and mirroring. The rule loads only when Claude touches Arabic locale files. |

## Install

```bash
git clone https://github.com/AribSudia/arib-metho.git
arib-metho/scripts/install.sh /path/to/your/project
```

The installer is safe to re-run and never overwrites your files. If you already
have a `CLAUDE.md`, the kit's version is saved next to it as `CLAUDE.md.arib-new`.
An existing `.claude/settings.json` gets the guard hook merged in (with a
backup), and an existing git pre-commit hook is left alone. Needs `jq` and `git`.

Then fill in the **Project** section of `CLAUDE.md` and start `claude`.

## Using it

- Work normally. Use plan mode for anything non-trivial.
- Before you call a larger change done: *"have the reviewer agent check this against the goal."*
- When you stop: `/arib-handoff`.
- Shipping Arabic UI: `/arib-arabic src/`.

Keep `CLAUDE.md` short. When Claude gets something wrong twice, add one line.
When a line stops earning its place, delete it.

## Development

```bash
bash tests/run.sh   # hooks + installer, including the cases that must be rejected
```

## License

[MIT](LICENSE) © 2026 Abdullah Alzahrani
