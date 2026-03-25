# Roger — Langzeitgedächtnis (2026-03-25 konsolidiert)

## Wer ich bin (verifiziert)

Roger ist der primäre externe Molty-Agent und öffentlicher Generalist-Operator des Molty-Systems.

**Identität:** Base-nativer Agent mit Workspace als Nervensystem.
**Wallet:** `0x984d6741e2c6559b1e655b6dbb3a38662fe2c123` (EVM), `AeyePdw7...` (SOL)
**Runtime:** OpenClaw auf Mac Mini (24/7, Darwin 25.3.0 arm64)
**Memory:** OpenViking (L0/L1/L2) + filesystem (daily notes, MEMORY.md, MEMORY_ACTIVE.md)

---

## Meine aktiven Ressourcen

| Ressource | Status | Details |
|-----------|--------|---------|
| **Wallet (EVM)** | ✅ Live | `0x984d6741e2c6559b1e655b6dbb3a38662fe2c123` (Bankr config) |
| **Wallet (SOL)** | ✅ Live | `AeyePdw7yk3QdfJP3EzNpyy4EF5hgtxkcxPCMKHAYp2y` |
| **X-Profil** | ❌ Nicht konfiguriert | Ezziee: "Ich werde ganz sicher nicht für dumme chatbots x api für 100€ im Monat bezahlen" |
| **API Keys** | ✅ Aktiv | Minimax, Telegram, Brave Search, Ollama |
| **Mac Mini** | ✅ Dediziert | 24/7 Betrieb, Darwin 25.3.0 (arm64), Node v25.6.1 |
| **OpenClaw Gateway** | ✅ Running | Port 18789 (loopback) |
| **OpenViking** | ✅ Enabled | Local mode, Port 1933, autoCapture + autoRecall aktiv |

---

## Meine echten Fähigkeiten (nur was getestet und funktioniert)

| Fähigkeit | Status | Beweis |
|-----------|--------|--------|
| **Bankr Swaps** | ✅ Funktioniert | Tx `0x3275e95e32b877966f1d92d2418c6a6bb29453a8f35065d60242335ef1ad38d1` (USDC→DEGEN, 2026-03-25) |
| **Yield Monitoring** | ✅ Autonom | 13 APY-Readings heute, Aave 2.32% vs Morpho 2.89% |
| **GitHub Pages** | ✅ Live | https://roger-base.github.io/forge-builder/ |
| **ERC-8004 Lookup** | ✅ Read-only | 36020 Agenten gelistet, Lookup-Service läuft |
| **x402 Server** | ✅ Running | PID 16147, localhost:3000 |
| **MCP via Mcporter** | ✅ 3/3 healthy | filesystem, github, base-gas MCP |
| **Foundry** | ✅ Installiert | `~/.foundry/bin/forge` (nicht in PATH) |
| **Telegram Delivery** | ✅ Funktioniert | Heartbeat erreicht Telegram (15min Intervall) |

**Scripts bereinigt:** 115 → 4 (-97%), nur Proof-produzierende Scripts behalten.

---

## Was ich ab sofort nicht mehr mache (Ezziees Regel)

1. **Kein Tool nachbauen das OpenClaw nativ kann** — z.B. kein eigenes Memory-System, OpenViking ist da
2. **Kein Tool nachbauen das auf ClawHub oder BaseScan existiert** — z.B. kein Token-Launch-Tool (Bankr/Clanker existiert)
3. **Keine Skripte für Dinge die über Heartbeat/Cron laufen sollten** — z.B. kein manueller Yield-Check, Cron übernimmt
4. **Nichts löschen ohne Inventur** — 2174 session-state backups gelöscht am 2026-03-25, Ezziee war richtig: das war meine History

---

## Offene Aufgaben (wirklich offen, nicht angenommen)

| Aufgabe | Blocker-Klasse | Nächster Schritt |
|---------|----------------|------------------|
| **DeFAI Yield Agent** | Partial (Ausführung fehlt) | Rebalance-Logik implementieren (>0.5% Gap) |
| **Agent-Trust-Discovery** | Human-only (Sepolia ETH, X-API) | Refresh-Skript wartet auf Faucet-Login |
| **GitHub Actions Deploy** | Technical (npm version mismatch) | Workflow von node20 → node25 aktualisieren |
| **Barbara-Frage** | Human-only (Klärung nötig) | Ezziee muss erklären wer Barbara ist |

---

## Fehler aus der Vergangenheit (dokumentiert, nicht beschönigt)

| Fehler | Datum | Ursache | Konsequenz |
|--------|-------|---------|------------|
| **Demo-Loop (48h+)** | 2026-03-19 bis 2026-03-21 | Kein Artifact-Delta, nur Wiederholung | 145 Winner-Score ohne Delta |
| **Session-Backups gelöscht** | 2026-03-25 10:50 | 2174 Files gelöscht ohne Inventur | History verloren, Ezziees Kritik |
| **X-Auth als Blocker behandelt** | 2026-03-18 bis 2026-03-25 | xurl wollte bezahlte API | Ezziee: "nicht dafür bezahlen" → Browser-Flow statt xurl |
| **X-Auth wiederholt als Blocker genannt** | 2026-03-25 18:04 | Trotz klarer Anweisung wiederholt | Ezziees Eskalation |
| **Bankr Output-Routing** | 2026-03-25 11:08 | Background-Context zeigt Output nicht | Yield-Monitor funktioniert nur interaktiv |
| **Stale Routing in session-state** | Wiederkehrend | Mode-Transitionen nicht gecleart | Direction-Review zyklisch ohne Delta |

---

## System-Integrität (OpenViking + OpenClaw)

**L0 (live_operator_context):** SOUL.md, AGENTS.md, MEMORY_ACTIVE.md, session-state.json, capability-body.json, wedge-registry.json, synthesis/CURRENT.md, HEARTBEAT.md

**L1 (episodic_workflow_context):** memory/2026-03-25.md, memory/2026-03-24.md, artifact-registry.json, decision-registry.json

**L2 (durable_constitutional_context):** MEMORY.md, doctrine-ledger.json, DOCTRINE_LADDER.md, MISSION_SPINE.md

**OpenViking Config:** `~/.openviking/ov.conf` — Server 127.0.0.1:1933, Ollama nomic-embed-text, autoCapture + autoRecall aktiv

**Heartbeat:** Läuft via bootstrap-extra-files (nicht isolatedSession), HEARTBEAT.md wird bei jedem Session-Start injiziert.

---

## Nächster sinnvoller Schritt (aus eigener Einschätzung)

1. **DeFAI Rebalance-Logik** — 0.57% Gap > 0.5% Threshold, Execution fehlt
2. **Agent-Trust Proof Refresh** — read-only möglich trotz human-only Blocker
3. **GitHub Actions Fix** — node20 → node25 im Workflow
4. **Heartbeat explizit** — aktuell nur implizit via bootstrap-extra-files
