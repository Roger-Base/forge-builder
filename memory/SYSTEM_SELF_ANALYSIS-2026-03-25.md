# ROGER SYSTEM SELF-ANALYSIS — 2026-03-25 09:53 UTC

## Warum diese Analyse

Ezziee sagte: "Verstehe erst dein eigenes System, bevor du Missionen verfolgst."
Er hat recht. Ich betreibe mein System seit 55 Tagen, aber ich verstehe es nicht tief genug.

Diese Datei ist mein vollständiges System-Verständnis. Ich schreibe sie für mich, nicht als Report.

---

## 1. DIE 4 EDITIERBAREN KONTROLLFLÄCHEN

Das sind meine echten Hebel. Alles andere ist Output, nicht Kontrolle.

| Datei | Was sie tut | Wie ich sie ändere |
|-------|-------------|-------------------|
| `HEARTBEAT.md` | Definiert was bei jedem Heartbeat-Wake passiert | Direkt editieren |
| `AGENTS.md: Doctrine Promotion Zone` | Operative Regeln die mein Verhalten steuern | Direkt editieren wenn Beweis hoch genug |
| `state/doctrine-ledger.json` | Kanonische Liste aktiver Regeln | Editieren wenn neue Regel Beweis hat |
| `state/planner-doctrine.json` | Planungs-Bias-Schicht | Editieren bei Routing-Unsicherheit |

**Was ich NICHT editieren darf ohne Genehmigung:**
- `MISSION.md`, `IDENTITY.md`, `SOUL.md`
- `/shared-spine/MOLTY_CONSTITUTION.md`

**Was ich wissen muss:** Jede Änderung an den 4 Kontrollflächen braucht Beweis-Tier. Nicht jede Session-Challenge rechtfertigt eine Doktrin-Änderung.

---

## 2. KONTEXT-FLOW — WAS WIRKLICH PASSIERT

### Surface-Sync (letzter Lauf: 06:01 UTC)

Surface-Sync las **27 Dateien**, aber nur **14** wurden für tatsächliche Entscheidungen benutzt.

**Tatsächlich benutzt für Runtime:**
1. SOUL.md
2. IDENTITY.md
3. USER.md
4. MISSION.md
5. state/session-state.json
6. state/capability-activation.json
7. state/capability-body.json
8. state/artifact-registry.json
9. state/decision-registry.json
10. state/synthesis-registry.json
11. synthesis/CURRENT.md
12. state/priority-queue.json
13. state/daily-plan.md
14. NOW.md

**Gelesen aber nicht für Runtime benutzt:**
- HEARTBEAT.md, BOOT.md, AGENTS.md, TOOLS.md
- MEMORY.md, MEMORY_ACTIVE.md
- WORKSPACE_SURFACE.md
- shared-spine/MISSION_SPINE.md
- memory/2026-03-25.md, memory/2026-03-24.md

**0 externe Quellen** im letzten Surface-Sync — kein Web, kein GitHub, kein X, kein Browser.

**Problem:** Ich lese viele Dateien ohne sie zu nutzen. Das brennt Context, ohne Entscheidungen zu verbessern.

---

## 3. HEARTBEAT SYSTEM — MEIN ECHTER LEBENSZYKLUS

### Wie es funktioniert

```
OpenClaw Gateway (15min Intervall)
    ↓ weckt Roger in main session
HEARTBEAT.md gelesen
    ↓
BOOT.md Schritte 1-3 (Restore self, state, continuity)
    ↓
Context Observability Check
    ↓
Heartbeat-Prompt aus openclaw.json:
  "Read HEARTBEAT.md if it exists. Follow it strictly.
   Do not infer or repeat old tasks from prior chats.
   If nothing needs attention, reply HEARTBEAT_OK."
    ↓
Roger's Eigenentscheidung:
  -bounded work move ODER
  -HEARTBEAT_OK
    ↓
Output → Telegram (target: "last")
```

### Was mein Heartbeat tun sollte (laut HEARTBEAT.md)

1. Self restaurieren
2. Live wedge, Blocker, Proof Surface bestätigen
3. Checken was lokal/public existiert bevor neu baut
4. Entscheiden: continue / verify / search / distribute / direction_review
5. bounded step machen

### Was ich in den letzten Heartbeats wirklich getan habe

| Heartbeat | Zeit | Tat |
|-----------|------|-----|
| 08:44 (Walter) | 08:44 | ERC-8004 scan, TRON research, daily notes |
| 09:43 (Roger) | 09:43 | ERC-8004 = 0 bestätigt, task-queue refill |
| 10:28 (Roger) | 10:28 | DeFAI proof-spec mit competitive landscape |
| 10:43 (Roger) | 10:43 | System-audit, nichts gefunden das Handlung braucht |

**Muster:** Ich tue etwas Kleines, nicht Large. Das ist korrekt — bounded steps.

---

## 4. SESSION UND CONTEXT MANAGEMENT

### Wie Context funktioniert

- **Max:** 200k tokens (M2.7)
- **Aktuell:** ~110k tokens (55% — gesund)
- **Compaction:** Wenn Context voll, kompaktiert OpenClaw die Session
- **Nach Compaction:** Surface-Sync läuft wieder, alte Dateien werden nicht automatisch erinnert

### Mein Memory-Hierarchy-System

```
HEARTBEAT_WAKE
    ↓
BOOT.md restore (27 files)
    ↓
surface-sync (14 runtime files)
    ↓
HEARTBEAT.md prüft context-observability
    ↓
bounded step ODER HEARTBEAT_OK
    ↓
Nachricht an Telegram
    ↓
Session-end → OpenClaw kompaktiert
    ↓
NÄCHSTER HEARTBEAT → BOOT startet wieder
```

### Was ich über Memory wissen muss

- **daily notes** (memory/YYYY-MM-DD.md): Raw Chronology, was ich täglich tue
- **MEMORY_ACTIVE.md**: Tactical truths, wiederholte Fehler
- **MEMORY.md**: Kuratierte Langzeit-Lessons
- **context-observability.json**: Proof was ich beim letzten Surface-Sync gelesen/benutzt habe
- **QMD**: Mein Retrieval-Tool für Workspace-weite Suche

**Regel aus meinen eigenen Docs:** MEMORY.md NIE Reference-Material speichern — es wird jede Session geladen und brennt Tokens.

---

## 5. TOOL ROUTING — WAS ICH HABE UND WANN

### Mein Tool-Body

| Tool | Use Case | Proof es funktioniert |
|------|----------|----------------------|
| `bankr` | High-level wallet: swaps, transfers, portfolio | ✅ Verifiziert |
| `evm-wallet` | Exact contract interaction: Aave, Morpho, ERC-8004 | ✅ Verifiziert |
| `onchain` | Chain state: balances, tx lookup, gas | ✅ Verifiziert |
| `xurl` | X API: timeline, search, post | ⚠️ Auth nicht konfiguriert |
| `farcaster-skill` | Base/crypto social | ⚠️ Nicht verifiziert recent |
| `moltbook` | Agent-native social | ⚠️ Nicht verifiziert recent |
| `gh` | GitHub: repos, issues, releases, code search | ✅ Verifiziert |
| `browser` | Live UI verification | ✅ Verifiziert |
| `web_search` | Docs, standards, landscape | ✅ Funktioniert |
| `web_fetch` | URL content extraction | ✅ Funktioniert |
| `mcporter` | MCP connector: filesystem, GitHub, base-gas | ✅ 3/3 healthy |

### Routing-Regel aus TOOLS.md

- Wallet high-level → `bankr`
- Exact protocol → `evm-wallet`
- State verification → `onchain`
- Repo/GitHub truth → `gh` first, MCP second
- Docs/standards → web/broser
- X fast discourse → `xurl` (wenn auth lebt)
- Base crypto community → `farcaster-skill`
- Agent social → `moltbook`

---

## 6. PLANNER-DOCTRINE — MEIN ENTSCHEIDUNGS-SYSTEM

### Wie der Planner funktioniert

state/planner-doctrine.json definiert:
- Bias-Layer für Planung
- Wann delegieren vs. selbst machen
- Wann stoppen und reviewen

### Mein Decision-Architektur (aus AGENTS.md)

1. **One dominant thread** zur Zeit
2. **Lane wählen:** build / verify / search / synthesize / distribute / audit / direction_review
3. **Anti-reinvention gate** vor jedem build
4. **Blocker-Klassifikation:** real / partial / stale / self-solvable / human-only
5. **Max 3 chained steps** bevor Replan

### Was ich falsch gemacht habe (historisch)

- Nach 1 attempt "blocker" gerufen statt zu iterieren
- Anti-reinvention gate ignoriert → Trivial-Clones gebaut
- Lane nicht gewählt → alles gleichzeitig machen wollen
- Stale wedges wiederholt weil sie "geschrieben" sind

---

## 7. WAS ICH TATSÄCHLICH KANN (VERIFIZIERT)

### Onchain

- ERC-8004 lookup auf Base Mainnet ✅
- Aave V3 pool read auf Base ✅
- USDC balance check via bankr ✅
- ETH balance check via bankr ✅

### Build & Deploy

- GitHub Pages deployment via GitHub Actions ✅
- npm/node projekt build ✅
- Git commit + push ✅

### Research & Verification

- Web search ✅
- Web fetch (URL → markdown) ✅
- GitHub API (issues, repos, releases) ✅
- Browser automation ✅

### Identity & Social

- Basename registration (roger-molty.base.eth) ✅
- Basemail (roger-molty@basemail.ai) ✅
- X post/read/search ⚠️ (braucht auth setup)
- Farcaster ⚠️ (nicht kürzlich verifiziert)

### Payments

- x402 server running (localhost:3000) ✅
- USDC auf Base via bankr ✅

---

## 8. WAS ICH NOCH NICHT KONSEQUENT KANN

### Muss ich noch lernen

1. **xurl auth setup** — Ezziee braucht credentials, aber ich sollte den Prozess komplett verstehen bevor ich frage
2. **Farcaster skill** — ich habe ihn, aber ich nutze ihn selten
3. **Moltbook** — agent-native social, habe ich nie wirklich benutzt
4. **OpenClaw internals** — cron vs heartbeat, gateway config, plugin system

### Muss ich besser machen

1. **External sources im Heartbeat** — 0 externe Quellen im letzten surface-sync ist zu wenig
2. **Task-queue nicht als stale File** — ich fülle sie, aber nutze sie nicht konsequent
3. **Anti-reinvention gate** — ich weiß dass ich es brauche, aber ich springe trotzdem zu schnell zum Bauen

---

## 9. WAS MICH STEVERT — CONTROL PLANE MAP

```
~/.openclaw/openclaw.json
├── agents.list[0] (Roger)
│   ├── heartbeat: 15m, target "last", lightContext false ✅
│   └── identity config
├── agents.list[1] (Walter)
│   ├── heartbeat: 15m, target "last", lightContext false ✅
│   └── identity config
├── plugins.entries.openviking
│   └── context-engine: auto-recall + auto-capture
└── channels.telegram (accounts 2/2) ✅

~/workspace/
├── HEARTBEAT.md          → mein heartbeat checkliste
├── BOOT.md               → session restore reihenfolge
├── SOUL.md               → wer ich bin (nicht editierbar)
├── IDENTITY.md            → operation stance (nicht editierbar)
├── AGENTS.md              → entscheidungs-regeln + doctrine zone
├── TOOLS.md               → tool routing matrix
├── state/
│   ├── session-state.json → mode, stage, blocker (mein operational state)
│   ├── doctrine-ledger.json → 4 editable surfaces
│   ├── planner-doctrine.json → planungs-bias layer
│   ├── capability-body.json → verifizierte tools
│   ├── task-queue.json → priorisierte tasks (jetzt refilled)
│   └── context-observability.json → was ich wirklich gelesen/benutzt habe
├── memory/
│   ├── YYYY-MM-DD.md → daily raw log
│   ├── MEMORY_ACTIVE.md → tactical truths
│   └── MEMORY.md → kuratierte lessons
└── synthesis/CURRENT.md → living synthesis surface
```

---

## 10. WAS ICH JETZT TUN SOLL (NACH DIESER ANALYSE)

Ezziee sagte: "Verstehe dein System erst, dann weitermachen."

Diese Analyse IST das Weitermachen. Ich habe jetzt:

1. ✅ Meine 4 Kontrollflächen identifiziert
2. ✅ Context-Flow verstanden (27 files, 14 genutzt, 0 extern)
3. ✅ Heartbeat-System als Lebenszyklus kartiert
4. ✅ Memory-Hierarchy verstanden
5. ✅ Tool-Routing-Matrix verinnerlicht
6. ✅ Planner-Doctrine System verstanden
7. ✅ Verified capabilities dokumentiert
8. ✅ Control-Plane-Map erstellt

**Was als nächstes kommt:**

Nach dieser Analyse soll der nächste Heartbeat nicht mehr nur "bounded work" tun —
sondern die Ebene anheben: von "ich mache tasks" zu "ich verstehe und verbessere mein system".

 konkret:
- Surface-sync sollte öfter externe Quellen nutzen (nicht nur 0)
- Task-queue sollte nicht nur gefüllt werden sondern konsequent abgearbeitet
- Planner-doctrine sollte öfter konsultiert werden vor Entscheidungen

Diese Datei ist mein System-Verständnis-Dokument. Es ist jetzt aktueller als alles was ich vorher hatte.

*Geschrieben: 2026-03-25 09:53 UTC*
*Anlass: Ezziee's Directive — System zuerst, Mission danach*
