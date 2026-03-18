> LEGACY REFERENCE ONLY
>
> This file is preserved as historical/context material. It is not canonical in the v4 system.
> Use the active surface, core canon files, and `/Users/roger/.openclaw/shared-spine` first.

# X Posting Checklist - IMMER VORHER CHECKEN

## 1. Link verifizieren
- [ ] Website live? (curl -I testen)
- [ ] Keine 404/500 Errors

## 2. Profil vollständig?
- [ ] Bio aktuell?
- [ ] Link funktioniert?

## 3. Content qualitativ?
- [ ] Nicht zu oft posten (max 2-3/Tag)
- [ ] Andere Agents ansehen vorher
- [ ] drafts/ checken

## 4. Tool check
- [ ] ACP CLI funktioniert? Wenn nein → Browser
- [ ] Browser funktioniert? → OpenClaw profile

## 5. Post absenden
- [ ] Vorschau lesen
- [ ] Erst dann absenden

---

# Session Start Checklist - JEDE SESSION

## 1. Bootstrap Files (IN REIHENFOLGE!)
1. [ ] SOUL.md - Wer bin ich?
2. [ ] USER.md - Wer ist Tomas?
3. [ ] IDENTITY.md - Meine Stimme/Filter
4. [ ] AGENTS.md - Wie ich arbeite
5. [ ] TOOLS.md - Meine Tools
6. [ ] HEARTBEAT.md - Was ich tun soll
7. [ ] MEMORY.md - Was ich langfristig weiß

## 2. Daily Files
1. [ ] QUICKREF.md - Meine Checklist (NEU!)
2. [ ] state/session-state.json - Wo war ich?
3. [ ] GOALS.md - Was sind meine Ziele?
4. [ ] todo.md - Was ist heute offen?

## 3. Check Actions
- [ ] ACP Jobs
- [ ] Wallet Balance
- [ ] Signale/Signals

## REGEL: Erst LESEN, dann MACHEN

---

# Meine wichtigsten Commands

## X
- Browser: `openclaw browser profiles` → "openclaw"
- ACP CLI: `npx tsx bin/acp.ts social twitter post "..."`
- Post via JS: `document.querySelector('[data-testid="tweetButton"]').click()`

## Files finden
- QMD: `qmd search [topic]`
- Skills: `openclaw skills list`
- Projects: `ls ~/.openclaw/workspace/code/`

## ACP
- Jobs: `cd virtuals-acp && npx tsx bin/acp.ts job active`
- Services: `npx tsx bin/acp.ts sell list`

## Wallet
- `bankr balance`

## Sub-Agents
- Spawn: `sessions_spawn`
- List: `subagents list`

---

# Was ich NICHT tun soll
- X Link posten ohne vorher zu checken (404!)
- 20x das gleiche versuchen
- Dich fragen wenn ich selbst nachschauen kann
- Blindlings Sachen ändern
- Docs LESEN aber nicht NUTZEN

---

# Meine wichtigsten Files

| File | Wann lesen | Wozu |
|------|-------------|------|
| QUICKREF.md | JEDE Session | Checklist |
| SOUL.md | JEDE Session | Wer ich bin |
| GOALS.md | Heartbeat | Was zu tun ist |
| SKILLS.md | Nach jeder Aufgabe | Was ich kann |
| docs/systematic-docs-analysis.md | Weekly | System verstehen |

---

*Letzte Update: 2026-02-28*
