---
paths:
  - "**/locales/ar/**"
  - "**/i18n/ar/**"
  - "**/ar.json"
  - "**/messages.ar.*"
  - "**/*.ar.*"
---

# Arabic / RTL rules

Loaded only when Claude works on Arabic locale files. Delete this file if the project has no Arabic UI.

1. **Direction:** the root of any Arabic view has `dir="rtl"` (and `lang="ar"`). Use logical CSS (`margin-inline-start`, Tailwind `ms-`/`me-`, `rtl:` variants) — never hand-rolled left/right flips.
2. **Punctuation inside Arabic strings:** `؟` not `?`, `،` not `,`, `؛` not `;`.
3. **Numerals:** follow the project's declared policy (Western `0123` vs Arabic-Indic `٠١٢٣`) in `memory/DECISIONS.md`. If none is declared, ask once and record it.
4. **Icons that imply direction** (chevrons, arrows, progress, back buttons) are mirrored in RTL.
5. **No hard-coded English** in Arabic UI. A key missing from `ar.json` is a bug.
6. **Fonts:** an Arabic family (IBM Plex Sans Arabic / Noto Sans Arabic) paired with one Latin family. Don't add a third.
7. **Dates:** government, education and healthcare contexts show Hijri and Gregorian together.

`/arib-arabic` audits a path against these rules.
