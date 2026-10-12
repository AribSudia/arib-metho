---
name: arib-arabic
description: Audit Arabic UI for RTL direction, Arabic punctuation, numeral policy, icon mirroring, hard-coded English and font pairing. Use before merging UI work that ships Arabic text, or when asked to check Arabic/RTL quality.
argument-hint: "[path]"
---

# Arabic / RTL audit

Audit `$ARGUMENTS` (default: the whole repo, excluding `node_modules`, build output and lockfiles) against `.claude/rules/arabic.md`.

1. **Find Arabic content.** Files containing characters in U+0600–U+06FF, plus `ar` locale files. If there are none, report "no Arabic content found" and stop. Do not invent findings.
2. **Direction.** Every view or layout that renders Arabic sets `dir="rtl"` (or derives it from the locale). Flag physical `left`/`right`/`ml-`/`pr-` styling in RTL views where a logical equivalent exists.
3. **Punctuation.** Latin `?` `,` `;` inside Arabic strings → `؟` `،` `؛`.
4. **Numerals.** Read the numeral policy in `memory/DECISIONS.md`. If none is declared, report that once (INFO). If one is declared, flag strings that break it.
5. **Mirroring.** Directional icons (Chevron, Arrow, Caret, Back) without an RTL flip.
6. **Hard-coded English** in components that render for the Arabic locale; keys present in `en` but missing from `ar`.
7. **Fonts.** Arabic font family declared; no third sans-serif family.

## Report

Lead with the verdict, then findings, most severe first:

```
Arabic/RTL audit — <path>: PASS | WARN | BLOCK
BLOCK  src/app/layout.tsx:12  Arabic layout has no dir="rtl"  → add dir from locale
WARN   locales/ar.json:44     "هل أنت متأكد?" uses Latin "?"   → "؟"
INFO   no numeral policy in memory/DECISIONS.md
```

BLOCK = missing RTL direction on an Arabic view. Everything else is WARN or INFO. Offer to fix the findings; don't fix them without being asked.
