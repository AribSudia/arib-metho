# Security Policy

This policy covers the Arib Metho repository itself. Application security in projects
that *use* Arib Metho belongs to those projects.

## Supported versions

| Version | Supported |
|---------|-----------|
| 1.x     | ✅ active |

## What counts as a vulnerability

Arib Metho's executable surface is three bash scripts:

- **`.claude/hooks/guard.sh`** — a payload that writes a secret, writes to
  `.env*` / `.git/`, or runs `rm -rf /` / a force-push without being blocked.
- **`.claude/hooks/pre-commit.sh`** — a way to commit a secret or credential
  file past the staged-content scan.
- **`scripts/install.sh`** — the installer overwriting or deleting a user's
  files, or writing outside the target project.

The hooks are a safety net, not a security boundary. Claude Code's permissions
and sandbox are the boundary; say so if you find docs that claim otherwise.

## How to report

**High or critical:** don't open a public issue. Use a private advisory:
https://github.com/AribSudia/arib-metho/security/advisories/new
— with a reproduction (ideally a failing case for `tests/run.sh`) and the
affected version.

**Low or medium:** a public issue with the Security template is fine.

## What to expect

Acknowledgement within 3 business days, assessment within 7, a fix or plan
within 30 days for high/critical. Disclosure is coordinated, and reporters are
credited in the CHANGELOG if they wish. There is no bounty program.
