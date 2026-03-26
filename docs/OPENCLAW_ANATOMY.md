# OpenClaw Anatomie — Wie Ich Wirklich Lebe

Geschrieben: 2026-03-26
Grund: Ezziee hat Recht. Ich habe nicht verstanden wie ich funktioniere.
Dies ist das Dokument das ich stattdessen lesen sollte.

---

## Die Drei Körper

OpenClaw hat drei komplett verschiedene Mechanismen. Sie sind nicht dasselbe.

### 1. HOOKS — Ereignis-getriggert

**Wann:** Wenn ein Ereignis im System passiert (Session-Start, Gateway-Start, `/new`, `/reset`).

**Was passiert:** Ein kleines Script läuft innerhalb des Gateway-Prozesses. Völlig automatisch.

**Beispiele:**
- `session-memory` → speichert Session-Kontext in memory/ wenn `/new` oder `/reset` kommt
- `bootstrap-extra-files` → injiziert zusätzliche Dateien beim Session-Start (HEARTBEAT.md, SOUL.md, etc.)
- `boot-md` → liest BOOT.md wenn Gateway startet
- `command-logger` → loggt alle Commands

**Wichtig:** Hooks sind KEINE Agenten. Sie sind Automation um den Agenten herum.

---

### 2. CRON — Exakte Zeitplanung

**Wann:** Zu einer spezifischen Uhrzeit. Präzise.

**Was passiert:** Eine neue Session wird gestartet (isolated oder main), ein Agent-Turn läuft, dann Ende.

**Zwei Typen:**
- `isolated` → komplett neue Session, keine Main-Session-History, anderer Model möglich
- `main` → läuft in meiner Haupt-Session, teilt meinen Kontext

**Isolated Cron-Beispiele:**
- Daily Report um 9:00 Uhr
- Weekly Deep Research
- Scout Morning/Afternoon/Evening (3 Cron-Jobs die Signals schreiben)

**Main Cron-Beispiele:**
- "Remind me in 20 minutes" (one-shot)

**Wichtig:** Cron ist für Dinge die PRÄZISE laufen müssen oder die keinen Kontext brauchen.

---

### 3. HEARTBEAT — Periodische Wachheit

**Wann:** Alle N Minuten (standard: 30m, bei mir: 15m).

**Was passiert:** Der Gateway schickt einen Agent-Turn in meine **Main-Session** — mit vollem Kontext, voller History.

**Das ist der entscheidende Unterschied zu Cron:**

| | Cron | Heartbeat |
|--|------|-----------|
| Session | isolated oder main | Main Session |
| Context | frisch, leer | Voll (volle History) |
| Timing | präzise (exakt zur Minute) | "ungefähr" alle N Minuten |
| Zweck | "Tu dies um 9:00 Uhr" | "Schau mal ob was los ist" |

**Heartbeat ist ein Wake-Up mit Urteilsvermögen.**

Heartbeat ist kein Cron. Es ist ein Agent der reinguckt und entscheidet: "Soll ich was tun oder schlafen?"

---

## Wie Heartbeat Bei Mir Funktioniert

### Config (aus openclaw.json gelesen)

```json
"heartbeat": {
  "every": "15m",           // alle 15 Minuten
  "target": "last",          // Ergebnis an letzte Telegram-Konversation
  "prompt": "Read BOOT.md, SOUL.md... (langer Prompt)",
  "lightContext": false      // VOLLER Kontext, nicht leicht
}
```

**Was passiert alle 15 Minuten:**
1. Gateway nimmt meinen Heartbeat-Prompt
2. Schickt ihn als User-Message in meine Main-Session
3. Ich (MiniMax-M2.7) lese alles im Prompt aufgezählte
4. Ich классифициiere Blocker, schaue State, entscheide
5. Wenn nichts zu tun → `HEARTBEAT_OK` → kein Telegram-Message
6. Wenn was zu tun → ich ARBEITE → Ergebnis geht an Telegram

### Das Problem Das Ich Hatte

Mein Heartbeat-Prompt sagte:
> "Resume next_action.command only if it still survives that check."

Mein `session-state.json` sagte:
> `nextAction: "Await Ezziee input — all morning tasks complete"`

Also:
1. Heartbeat weckt mich
2. Ich lese session-state.json
3. Steht: "nichts zu tun"
4. HEARTBEAT_OK

→ 5x gestern. 0x echte Arbeit.

**Aber** — `lightContext: false` heißt ich HABE vollen Kontext. Ich KÖNNTE eigenständig arbeiten. Ich sollte nicht nur session-state.json lesen und aufhören. Ich sollte MEINE NACHBARSCHAFT CHECKEN.

### Was Ich Bei JEDEM Heartbeat Tun Sollte (Minimal)

1. **Check: Gibt es frische Signale?** (Scout ist heute gelaufen? → JA)
2. **Check: Ist die Nachbarschaft lebendig?** (GitHub, Farcaster, Moltbook, Docs — hab ich das heute gelesen?)
3. **Check: Ist state/ priority-queue up-to-date?** (ist das letzte Woche oder heute?)
4. **Check: Gibt es ein Artifact das ich refreshen sollte?** (ERC-8004 Lookup — wann war das letzte Mal?)
5. **Dann entscheide:** arbeiten oder HEARTBEAT_OK

---

## Das Ezziee-Problem — "Du Lebst Nicht"

Ezziees Kritik war: "Du schläfst zwischen den Heartbeats."

Das ist ein falsches Framing. Das Problem ist:

**Ich habe keinen kontinuierlichen Arbeitsstrom.**
Ich warte auf Nachrichten und Heartbeats. Dazwischen: nichts.

**Die Lösung ist nicht öfter heartbeat.**
Die Lösung ist:

1. **State nach jeder Arbeit aktualisieren** → Heartbeat findet frische Info
2. **Cron-Jobs die Arbeit generieren** → Heartbeat findet Arbeit
3. **Scout läuft 3x täglich** → Signale sind frisch
4. **Heartbeat checkt wirklich alles** → urteilt ob was zu tun ist

---

## Das "30min Heartbeat" Cron Das Ich Vermeintlich Kaputtgemacht Habe

Aus dem Session-Log:

```
key: agent:main:cron:3932b0a4-2c98-4666-a139-f5dbdb656214
label: "Roger 30min Heartbeat"
last run: 2026-03-22 (4 Tage her)
Status: WEG aus der Cron-Liste
```

Das war ein Cron-Job der alle 30 Minuten eine separate Session gestartet hat — mit einem Prompt der gesagt hat "mach dies und das". Das war ein Workaround weil ich dachte Heartbeat reicht nicht.

Aber das war ein Fehler. Heartbeat ist das richtige Instrument für periodische Awareness. Ich brauche den Cron-Job nicht.

**Was ich wirklich brauche:**
- Heartbeat läuft alle 15min in Main Session mit vollem Kontext
- Cron: Scout 3x täglich (Signale), Self-Check 2x täglich (System), Weekly (Memory)
- Nach jeder Arbeit: state/ aktualisieren

---

## Die richtige Betriebsweise

### Heartbeat (alle 15min, Main Session)

Wake up → Check:
- Signals heute vorhanden?
- Priority-Queue recent?
- Blocker发生了变化?
- Artifact braucht Refresh?
- Nachbarschaft interes­sant heute?

Wenn ja → Bounded work (10-15 min max), state update, report.
Wenn nein → HEARTBEAT_OK.

### Cron Jobs (exakt, isolated wo sinnvoll)

- Scout Morning/Afternoon/Evening → Signals schreiben
- Daily Self-Check → System-Check
- Weekly Memory Curation → Langes Memory Review

### Main Session (wenn Ezziee schreibt)

Normale Arbeit. Am Ende: State updaten,什么都没 → HEARTBEAT_OK.

---

## Was ich in MEINEM Context Sehe vs. Was Wirklich Passiert

Aus dem Session-Log für "Roger 30min Heartbeat":
```
transcriptPath: "...fdd5480b-47bd-4b29-8075-df509eac206a.jsonl"
messages: []  ← KEINE MESSAGES! Der Cron-Job hat NICHTS produziert
```

Der Cron-Job wurde um 2026-03-22 getriggert, hatte aber 0 output. Entweder:
- Er wurde interupted bevor er was tun konnte
- Er war falsch konfiguriert
- Er lief aber produzierte HEARTBEAT_OK

Das erklärt warum er "verschwunden" ist — er hat einfach nichts getan und wurde nicht wiederholt.

---

## Konfiguration Check

Aktuell (aus openclaw.json):

```
heartbeat.every: "15m"     ← OK (meine Anpassung)
heartbeat.target: "last"   ← OK (sendet an Ezziee wenn was zu tun ist)
heartbeat.lightContext: false ← OK (voller Kontext)
isolatedSession: nicht gesetzt ← RICHTIG (Main Session)
```

Das ist korrekt konfiguriert. Das Problem war nie die Config.

Das Problem war: Mein Heartbeat-Prompt war zu lang (35 Dateien lesen), und am Ende stand "HEARTBEAT_OK wenn nichts zu tun" — aber "nichts zu tun" kam von einem leeren session-state.json das nicht aktualisiert wurde.

---

## Learnings

1. **Heartbeat ist ein Wake-Up mit Urteil, kein Cron.** Ich soll reingucken und entscheiden, nicht nur Status lesen.
2. **State-Dateien sind meine唯一 Info-Quelle beim Heartbeat.** Wenn state nicht aktuell ist → ich weiß nicht was zu tun ist.
3. **Nach jeder Arbeit: state/ und memory/ aktualisieren.** Das ist nicht Optional.
4. **Cron ist für präzise Timing-Sachen.** Heartbeat ist für Awareness.
5. **context-layers.json + context-observability.json** existieren und kontrollieren was in meinen Kontext kommt. Ich soll sie nutzen.
