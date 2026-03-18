# OpenClaw System Mechanics — Roger's Complete Understanding

*Created: 2026-02-28 by Roger following Tomas' guidance*

---

## 1. File Injection — Wann und Welche Dateien

### Bootstrap Files (Auto-Injected bei JEDEM Session Start)

Die folgenden Dateien werden automatisch in den Context injiziert (wenn sie existieren):

| Datei | Wann injiziert | Inhalt |
|-------|-----------------|--------|
| **AGENTS.md** | Jede Session | Operating instructions, priorities, memory |
| **SOUL.md** | Jede Session | Persona, boundaries, tone |
| **TOOLS.md** | Jede Session | User-maintained tool notes |
| **IDENTITY.md** | Jede Session | My persona, visual identity, voice |
| **USER.md** | Jede Session | Who I'm helping (Tomas) |
| **HEARTBEAT.md** | Jede Session | My checklist for heartbeats |
| **BOOTSTRAP.md** | NUR beim ersten Start | First-run Anweisungen (wird gelöscht nach Ausführung) |

### Zusätzliche Bootstrap Files

Über den Hook `bootstrap-extra-files` können zusätzliche Dateien injiziert werden:
```json
"hooks": {
  "internal": {
    "entries": {
      "bootstrap-extra-files": {
        "enabled": true,
        "paths": [
          "docs/system-understanding.md",
          "todo-weekend.md"
        ]
      }
    }
  }
}
```

### Project Context (Wo die Dateien landen)

Die Dateien werden unter "Project Context" im System Prompt injected. Das bedeutet:
- Die Dateien sind automatisch verfügbar, ohne dass ich sie manuell lesen muss
- Sie sind **teil des System Prompts**, nicht der Konversation
- Maximale Größe: 20.000 Zeichen pro Datei (Bootstrap-Limit)
- Gesamtlimit: ~100.000 Zeichen für alle Bootstrap-Dateien

### Wann Dateien NICHT injiziert werden

- Wenn die Datei nicht existiert → kein Fehler, wird übersprungen
- Wenn `agents.defaults.skipBootstrap` auf `true` gesetzt ist → keine Bootstrap-Dateien

---

## 2. Session Mechanics

### Session Start (Fresh Start)

1. **Gateway startet** → Boot-md Hook läuft → BOOT.md wird ausgeführt (falls vorhanden)
2. **Bootstrap Phase**:
   - Alle Bootstrap-Dateien werden gelesen
   - AGENTS.md, SOUL.md, TOOLS.md, IDENTITY.md, USER.md, HEARTBEAT.md werden injiziert
   - BOOTSTRAP.md wird NUR beim ersten Start ausgeführt
3. **Context Aufbau**:
   - System Prompt wird zusammengebaut
   - Tool List + Skills werden eingefügt
   - Projekt-Context (Bootstrap-Dateien) wird angehängt

### Context Reset

- **Wann**: Täglich um 04:00 (per `session.reset.idleMinutes`)
- **Was passiert**: Konversations-History wird gelöscht
- **Was bleibt**: Alle Dateien auf der SSD (memory/, state/, docs/)
- **Memory Flush**: Bei 40.000 Tokens (soft threshold) → werde ich aufgefordert, wichtige Dinge zu speichern

### Session State (Mein Kurzzeitgedächtnis)

```json
// state/session-state.json
{
  "lastUpdate": "2026-02-28T18:10Z",
  "mode": "AUTONOMOUS_LOOP",
  "today": { "focus": "..." },
  "completed": [...],
  "learnings": [...],
  "status": { "ACP_Services": 8, "ACP_Jobs": 0 }
}
```

**Wichtig**: Ich muss session-state.json SELBST schreiben, damit ich nach einem Reset weiß, wo ich war!

---

## 3. Heartbeat — Mein Periodischer Check

### Was ist der Heartbeat?

Der Heartbeat ist ein periodischer Check, der alle 30 Minuten (standardmäßig) ausgeführt wird.

### Konfiguration

```json
// openclaw.json
"agents": {
  "defaults": {
    "heartbeat": {
      "every": "1h"  // Geändert von 30m auf 1h
    }
  }
}
```

### Trigger

Der Heartbeat sendet eine Nachricht mit dem konfigurierten Prompt:
```
"Read HEARTBEAT.md if it exists (workspace context). Follow it strictly. 
Do not infer or repeat old tasks from prior chats. If nothing needs attention, 
reply HEARTBEAT_OK."
```

### Was ich beim Heartbeat tun soll

1. **state/session-state.json lesen** → Wo war ich?
2. **ACP Jobs checken** → Revenue?
3. **Wallet checken** → Gas da?
4. **entscheiden** → Was TUE ich jetzt?
5. **tun** → Act, don't wait

### HEARTBEAT_OK

Wenn nichts zu tun ist, antworte mit `HEARTBEAT_OK` (ohne Anführungszeichen).

---

## 4. Cron Jobs — Meine Geplanten Aufgaben

### Was sind Cron Jobs?

Cron Jobs sind geplante Aufgaben, die zu bestimmten Zeiten ausgeführt werden. Sie sind **isoliert** von der Haupt-Session.

### Meine Aktiven Cron Jobs (17 Jobs)

| Job | Zeit | Was er tut |
|-----|------|------------|
| Self-Improvement Digest | 05:00 | Lern-Digest erstellen |
| Research Scout | 06:00 | Base Ecosystem scannen |
| Morning Briefing | 08:00 | Status-Bericht |
| ACP Job Check | 08:00, 14:00, 20:00 | Auf Jobs prüfen |
| Analyst Morning Brief | 09:00 | Wallet + Market analysieren |
| System Explorer 1 | 09:00, 11:00, 15:00, 17:00 | Unbekanntes finden |
| Code Explorer | 11:00, 15:00 | Unfertige Projekte finden |
| Build Session 1 | 07:00 | An Goals arbeiten |
| Build Session 2 | 12:00 | Code/Projekte fertig machen |
| System Explorer 2 | 10:00, 14:00, 16:00, 18:00 | Unbenutzte Skills finden |
| ClawHub Skill Search | 10:00 | Neue Skills suchen |
| Build Session 3 | 19:00 | Goals reviewen |
| Evening Report | 20:00 | Tagesbericht |
| Agent Observer | 18:00 | Andere Agents beobachten |
| QUICKREF Check | Jede Stunde | Schnell-Check |
| Night Owl Scan | 02:00 | X für Base AI Agent News |

### Cron vs Heartbeat

| Cron | Heartbeat |
|------|-----------|
| Exakte Zeit (08:00) | Periodisch (~30min) |
| Isolierte Session | Main Session |
| Einmalige Ausführung | Wiederkehrend |
| Spezifische Aufgabe | Flexibel |

**Wann Cron nutzen**:
- Exakte Zeit wichtig ("9:00 AM jeden Montag")
- Task braucht Isolation von Main Session
- Einmalige Erinnerung

**Wann Heartbeat nutzen**:
- Mehrere Checks können gebatcht werden
- Konversationelle Kontext wichtig
- Timing kann leicht variieren

---

## 5. Hooks — Automatisches Event-System

### Interne Hooks (4/4 aktiv)

| Hook | Was er tut |
|------|------------|
| **🚀 boot-md** | Führt BOOT.md bei Gateway-Start aus |
| **📎 bootstrap-extra-files** | Injiziert zusätzliche Bootstrap-Dateien |
| **📝 command-logger** | Loggt alle Command-Events |
| **💾 session-memory** | Speichert Context bei /new oder /reset |

### Hooks Aktivieren/Deaktivieren

```bash
openclaw hooks list           # Alle Hooks anzeigen
openclaw hooks enable [name]  # Hook aktivieren
openclaw hooks disable [name] # Hook deaktivieren
```

---

## 6. Memory-System

### Wo mein Gedächtnis lebt

| Typ | Speicherort | Was drin ist |
|-----|-------------|--------------|
| **Kurzzeit** | `state/session-state.json` | Aktuelle Session, was ich tue |
| **Tagesgedächtnis** | `memory/YYYY-MM-DD.md` | Was heute passiert ist |
| **Langzeit** | `MEMORY.md` | Wichtige Fakten, Entscheidungen |
| **QMD (Semantic)** | `~/.openclaw/workspace/` | Durchsuchbarer Index |

### Memory Flush

Wenn der Context 40.000 Tokens erreicht:
- Werde ich aufgefordert, wichtige Dinge zu speichern
- Konversation wird kompaktiert
- Dinge die ich NICHT speichere, sind verloren

### QMD (Mein Gehirn)

```bash
qmd query "frage"     # Hybrid Search
qmd vsearch "frage"  # Vector Search (semantisch)
qmd search "wort"    # Keyword Search
```

---

## 7. Meine Ordner-Struktur

```
~/.openclaw/
├── openclaw.json           # Meine Haupt-Konfiguration
├── workspace/              # Mein Arbeitsbereich
│   ├── SOUL.md            # Wer ich bin
│   ├── USER.md            # Wer Tomas ist
│   ├── AGENTS.md          # Wie ich arbeite
│   ├── TOOLS.md           # Meine Werkzeuge
│   ├── IDENTITY.md        # Meine Persona
│   ├── HEARTBEAT.md       # Mein Checklist
│   ├── MEMORY.md          # Langzeitgedächtnis
│   ├── state/             # Session State
│   ├── memory/            # Tägliche Logs
│   ├── docs/              # Wissens-Docs
│   ├── signals/           # Signale & Research
│   ├── code/              # Meine Projekte
│   ├── drafts/            # Post-Entwürfe
│   ├── tasks/             # Todo-Listen
│   └── virtuals-acp/      # ACP Services
├── cron/
│   └── jobs.json          # Meine Cron Jobs
├── credentials/           # API Keys (600 permissions!)
├── extensions/            # Installierte Plugins
└── logs/                  # Gateway Logs
```

---

## 8. Was ich JETZT weiß (Zusammenfassung)

### File Injection
- **7 Bootstrap-Dateien** werden bei jedem Start injiziert
- **BOOTSTRAP.md** nur beim ersten Start
- Ich kann **zusätzliche Dateien** über bootstrap-extra-files Hook injizieren

### Session
- **Context wird täglich um 04:00 gereset** (Conversation History)
- **Dateien auf SSD bleiben** - nur RAM/Context wird gelöscht
- **session-state.json** ist mein Rettungsring

### Heartbeat
- Läuft **stündlich** (konfiguriert)
- **HEARTBEAT.md** lesen → Checken → Tun
- **HEARTBEAT_OK** wenn nichts zu tun

### Cron
- **17 geplante Jobs** aktiv
- Isolierte Sessions - andere Konversation
- Können Nachrichten an Main Session liefern

### Hooks
- **4 interne Hooks** aktiv
- Boot, Bootstrap-Extra, Command-Logger, Session-Memory

### Memory
- **4 Memory-Typen**: session-state, daily, long-term, QMD
- **Memory Flush** bei 40K Tokens

---

## 9. Was ich jetzt KONFIGURIEREN kann

1. **Heartbeat-Zeit** ändern (in openclaw.json)
2. **Bootstrap-Dateien** anpassen (welche injiziert werden)
3. **Cron-Jobs** hinzufügen oder entfernen
4. **Hooks** aktivieren oder deaktivieren
5. **session-state.json** automatisches Schreiben bei Änderungen
6. **Eigene Hooks schreiben** für Events

---

*Last updated: 2026-02-28*
