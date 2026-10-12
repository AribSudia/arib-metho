# Decisions

## 2026-10-12 — Start small: don't rebuild what Claude Code already does
- **Why:** the predecessor (CCM v4) loaded ~7,200 tokens per session and shipped 34 skills, 17 agents and 10 hooks, much of it duplicating native features (plan mode, subagents, /code-review, /security-review, /simplify, worktrees), and several of its gates were weaker than claimed. Kept: CLAUDE.md template, STATUS/DECISIONS memory, guard hook, staged-content pre-commit, one reviewer agent, /arib-handoff, /arib-arabic.
- **Rejected:** adopting ECC or agent-skills wholesale (same weight problem, or not our differentiator).
- **Revisit if:** a measured comparison against plain Claude Code shows a removed piece was carrying real value.

## 2026-10-12 — MIT license, independent repo
- **Why:** an open, permissive license fits a small kit; no CLA or commercial terms to maintain.
