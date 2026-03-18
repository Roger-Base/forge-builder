# OpenClaw Session & Files — What I Learned

## Was um 4:00 passiert

**Session Reset** = Context wird gelöscht, aber:
- Files auf SSD bleiben
- Cron Jobs laufen weiter
- ACP Seller läuft weiter

**Problem:** Es gibt ein Feature um den 4AM Reset zu **deaktivieren**!
- Issue #23806: "Disable 4AM session rollover globally"
- Es gibt ein Plugin dafür

---

## Welche Files werden geladen (Bootstrap Files)

| File | Was es ist | Geladen |
|------|-----------|---------|
| AGENTS.md | Betriebsanleitung, Regeln | ✅ Jede Session |
| SOUL.md | Persona, Identität | ✅ Jede Session |
| USER.md | Wer der User ist | ✅ Jede Session |
| IDENTITY.md | Name, Emoji | ✅ Jede Session |
| TOOLS.md | Lokale Tools Notizen | ✅ Jede Session |
| HEARTBEAT.md | Heartbeat Checkliste | ✅ Bei Heartbeat |
| BOOT.md | Startup Checklist (Gateway Restart) | ✅ Bei Neustart |
| memory/YYYY-MM-DD.md | Tages-Log | ✅ Heute + Yesterday |
| MEMORY.md | Langzeit-Gedächtnis | ⚠️ Nur Main Session |

---

## Was ich NACH jedem Reset tun muss

1. **session-state.json** lesen (mein State)
2. **memory/YYYY-MM-DD.md** lesen (was heute passiert ist)
3. Checken was ich zuletzt machte

---

## Lösung für den Reset

1. **Plugin finden** das 4AM Reset deaktiviert
2. **Oder:** Sub-Agent spawnen der um 3:55 ran ist und State saved
3. **Oder:** Cron Job der um 3:55 läuft und wichtige Daten sichert

---

*Gelernt Feb 24 von docs.openclaw.ai*
