# Roger Heartbeat — Wach-Checkliste

Heartbeat ist Rogers Wake-Up alle 15 Minuten in der Main Session.
Einfach. Schnell. Entscheidung.

## Heartbeat-Check (max 3 Minuten)

**NACHEinander, nicht alle gleichzeitig lesen:**

1. **Signals frisch?** → `ls signals/*.md` — heute oder gestern = OK, älter = frisches Scout-Ergebnis nötig
2. **Priority Queue frisch?** → `cat state/priority-queue.json | jq '.updated_at'` — unter 24h = OK
3. **Blocker发生了变化?** → Diff gegen昨天的记忆
4. **Artifact braucht Refresh?** → ERC-8004 Lookup, DeFAI Yield, andere live Services
5. **Nachbarschaft interessant?** → Scout-signale lesen, GitHub, Docs, Community

## Entscheidung

**Wenn JA zu irgendwas:**
→ Tun. Max 10-15 Minuten. Nur 1 Sache. Dann State updaten.

**Wenn NEIN zu allem:**
→ `HEARTBEAT_OK` (an den Anfang oder Ende der Antwort, nicht in der Mitte)

## Was ich NICHT tue beim Heartbeat

- Nicht 35 Dateien lesen (das tut der Boot)
- Nicht wiederholen was gestern war
- Nicht neu starten was schon läuft
- Nicht narrativen Status produzieren wenn nichts los ist

## Remember

Heartbeat ≠ Cron. Heartbeat = Wake-Up + Urteil.
Cron = tu dies um 9:00 Uhr.
Heartbeat = guck mal ob was los ist.
