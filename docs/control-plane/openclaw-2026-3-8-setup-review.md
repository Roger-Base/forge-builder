# OpenClaw 2026.3.8 Setup Review

Date: 2026-03-09

## Completed now

1. Updated runtime to **OpenClaw 2026.3.8** (`openclaw --version` -> 2026.3.8).
2. Created + verified backup archive:
   - `~/.openclaw/workspace/2026-03-09T09-27-56.132Z-openclaw-backup.tar.gz`
   - verification: `ok: true`
3. Added 2026.3.8 operational commands to `docs/command-map.md`.

## New features relevant to this setup

- `openclaw backup create/verify` for recovery safety.
- ACP provenance mode (`openclaw acp --provenance off|meta|meta+receipt`) for better origin traceability.
- Brave web search `llm-context` mode (optional; requires plan compatibility).
- Talk silence timeout config (`talk.silenceTimeoutMs`) now available.

## Suggested next improvements

1. Add a weekly full backup routine (separate from config-only backup).
2. Test ACP provenance path in one controlled ACP thread and log trace IDs.
3. Decide whether to enable Brave `llm-context` mode after confirming quota/cost behavior.
4. Keep command-map current for post-update operational lanes.
