---
name: arib-handoff
description: Update project memory at the end of a work session or before switching tasks — rewrite memory/STATUS.md with the current state and next step, and record new decisions in memory/DECISIONS.md. Use when the user says they're stopping, wrapping up, or handing off.
disable-model-invocation: true
---

# Handoff

Leave the next session (yours or a teammate's) able to start in one read.

1. Check what actually happened: `git status`, `git log --oneline -10`, and the tests you ran this session. Don't report work you can't see.
2. **Rewrite** `memory/STATUS.md` (overwrite, don't append; keep it under ~30 lines):
   - **Now:** what is in progress, on which branch.
   - **Next:** the single next concrete step.
   - **Watch out:** anything broken, half-done, or uncommitted, and any failing test, named.
   - Set **Updated:** to today's date.
3. If a decision was made that someone might re-argue later, add it to the top of `memory/DECISIONS.md` (decision, why, revisit-if). Skip this if there's none.
4. If something from `STATUS.md` belongs permanently in `CLAUDE.md` (a rule, a command, a gotcha), propose the one-line addition to the user instead of editing `CLAUDE.md` silently.
5. Show the user the new `STATUS.md` and ask whether to commit it. Don't commit or push without a yes.
