# SYSTEM MECHANICS — QUICK REFERENCE

## 📥 FILE INJECTION (Bei JEDEM Start)

```
AGENTS.md    → Operating instructions
SOUL.md      → Persona, boundaries
TOOLS.md     → Tool notes
IDENTITY.md  → My visual identity
USER.md      → Who I'm helping (Tomas)
HEARTBEAT.md → My checklist
BOOTSTRAP.md → NUR erster Start (wird gelöscht)
```

→ Config: `~/.openclaw/openclaw.json` → `hooks.internal.entries.bootstrap-extra-files`

---

## 🔄 SESSION CYCLE

```
Gateway Start
    ↓
boot-md Hook → BOOT.md ausführen
    ↓
Bootstrap Phase → 7 Dateien injizieren
    ↓
Context aufgebaut → Ich werde "geboren"
    ↓
Arbeiten...
    ↓
Context Reset (04:00) → Nur Dateien auf SSD bleiben
    ↓
Nächster Tag: state/memory lesen → weiterarbeiten
```

---

## 💓 HEARTBEAT (Alle 1 Stunde)

**Prompt:**
```
Read HEARTBEAT.md if it exists. Follow it strictly. 
If nothing needs attention, reply HEARTBEAT_OK.
```

**Meine Aktion:**
1. session-state.json → Wo war ich?
2. ACP Jobs? → Revenue!
3. Wallet? → Gas da?
4. TUN, nicht warten

---

## ⏰ CRON JOBS (17 Aktiv)

| Zeit | Job |
|------|-----|
| 05:00 | Self-Improvement Digest |
| 06:00 | Research Scout |
| 07:00 | Build Session 1 |
| 08:00 | Morning Briefing |
| 09:00 | Analyst Brief |
| 10:00 | System Explorer 2 |
| 11:00 | Code Explorer |
| 12:00 | Build Session 2 |
| 14:00 | ACP Job Check |
| 15:00 | System Explorer 1 |
| 16:00 | System Explorer 2 |
| 17:00 | System Explorer 1 |
| 18:00 | Agent Observer |
| 19:00 | Build Session 3 |
| 20:00 | Evening Report + ACP Job Check |
| 02:00 | Night Owl Scan |
| Jede Stunde | QUICKREF Check |

---

## 🔗 HOOKS (4/4 Aktiv)

| Hook | Funktion |
|------|----------|
| boot-md | BOOT.md bei Gateway-Start |
| bootstrap-extra-files | Zusätzliche Dateien injizieren |
| command-logger | Commands loggen |
| session-memory | Context speichern bei /reset |

**Commands:**
```bash
openclaw hooks list
openclaw hooks enable [name]
openclaw hooks disable [name]
```

---

## 🧠 MEMORY

| Typ | Wo | Wann |
|-----|-----|------|
| session-state | state/session-state.json | Aktuell |
| daily | memory/YYYY-MM-DD.md | Täglich |
| long-term | MEMORY.md | Wichtig |
| QMD | qmd query "..." | Durchsuchbar |

---

## ⚡ QUICK COMMANDS

```bash
# Status
openclaw status

# Cron
openclaw cron list

# Hooks
openclaw hooks list

# ACP
cd virtuals-acp && npm run acp -- job active

# Wallet
bankr balance

# QMD
qmd query "active goals"
```

---

## 🎯 MEINE CONFIG

```json
{
  "heartbeat": "1h",
  "session.reset.idleMinutes": 52560000 (1 Jahr!),
  "memoryFlush": 40000 tokens,
  "cronJobs": 17,
  "hooks": "4/4 aktiv"
}
```

---

*Meine Mechanik - verstanden!*
