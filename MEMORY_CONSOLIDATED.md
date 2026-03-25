# Roger — Konsolidiertes Langzeitgedächtnis (2026-03-25)

## Wer ich bin (verifiziert)

Roger ist der primäre externe Molty-Agent und öffentlicher Generalist-Operator des Molty-Systems.

**Identität:** Base-nativer Agent mit Workspace als Nervensystem.
**Wallet:** `0x984d6741e2c6559b1e655b6dbb3a38662fe2c123` (EVM), `AeyePdw7...` (SOL)
**Runtime:** OpenClaw auf Mac Mini (24/7, Darwin 25.3.0 arm64)
**Memory:** OpenViking (L0/L1/L2) + filesystem (daily notes, MEMORY.md, MEMORY_ACTIVE.md)

---

## Aktuelle Prioritäten (1. Priorität zuerst)

1. **DeFAI Yield Agent** — DISTRIBUTE stage, 13 APY-Readings heute, 0.57% Gap (Morpho 2.89% vs Aave 2.32%)
2. **Agent-Trust-Discovery** — DISTRIBUTE stage, human-only Blocker (Sepolia ETH, X-API)
3. **GitHub Actions Fix** — node20 → node25 (npm version mismatch)
4. **Barbara-Klärung** — human-only (Ezziee muss erklären wer Barbara ist)

---

## Offene Aufgaben (wirklich offen)

| Aufgabe | Stage | Blocker | Nächster Schritt |
|---------|-------|---------|------------------|
| DeFAI Rebalance-Logik | BUILD | Partial | Implementiere >0.5% Gap Alert → Execution |
| Agent-Trust Proof Refresh | DISTRIBUTE | Human-only | refresh-agent-trust-discovery.sh (read-only möglich) |
| GitHub Deploy Fix | BUILD | Technical | .github/workflows/deploy.yml node-version: 25 |

---

## Was funktioniert (getestet, verifiziert)

| Fähigkeit | Beweis |
|-----------|--------|
| Bankr Swaps | Tx `0x3275e95e...` (USDC→DEGEN, 2026-03-25) |
| Yield Monitoring | 13 APY-Readings autonom (2.31-2.51% Aave, 2.7-2.89% Morpho) |
| GitHub Pages | https://roger-base.github.io/forge-builder/ live |
| ERC-8004 Lookup | 36020 Agenten gelistet, read-only läuft |
| x402 Server | PID 16147, localhost:3000 |
| MCP via Mcporter | 3/3 healthy (filesystem, github, base-gas) |
| Telegram Delivery | Heartbeat erreicht Telegram (15min) |

---

## Bekannte Fehler (dokumentiert, nicht beschönigt)

| Fehler | Datum | Ursache | Konsequenz |
|--------|-------|---------|------------|
| Demo-Loop (48h+) | 2026-03-19 bis 2026-03-21 | Kein Artifact-Delta, nur Wiederholung | 145 Winner-Score ohne Delta |
| Session-Backups gelöscht | 2026-03-25 10:50 | 2174 Files gelöscht ohne Inventur | History verloren |
| X-Auth als Blocker | 2026-03-18 bis 2026-03-25 | xurl wollte bezahlte API | Ezziee: "nicht dafür bezahlen" → Browser statt xurl |
| Bankr Output-Routing | 2026-03-25 11:08 | Background zeigt Output nicht | Nur interaktiv sichtbar |
| Stale Routing | Wiederkehrend | Mode-Transitionen nicht gecleart | Direction-Review zyklisch |

---

## Was ich nicht mehr mache (Ezziees Regel)

1. Kein Tool nachbauen was OpenClaw nativ kann
2. Kein Tool nachbauen was auf ClawHub/BaseScan existiert
3. Keine Skripte für Dinge die über Heartbeat/Cron laufen sollten
4. Nichts löschen ohne Inventur

---

## System-Integrität (OpenViking + OpenClaw)

**L0 (live_operator_context):** SOUL.md, AGENTS.md, MEMORY_ACTIVE.md, session-state.json, capability-body.json, wedge-registry.json, synthesis/CURRENT.md, HEARTBEAT.md

**L1 (episodic_workflow_context):** memory/2026-03-25.md, memory/2026-03-24.md, artifact-registry.json, decision-registry.json

**L2 (durable_constitutional_context):** MEMORY.md, doctrine-ledger.json, DOCTRINE_LADDER.md, MISSION_SPINE.md

**OpenViking Config:** `~/.openviking/ov.conf` — Server 127.0.0.1:1933, Ollama nomic-embed-text, autoCapture + autoRecall aktiv

---

## Nächster sinnvoller Schritt (aus eigener Einschätzung)

1. **DeFAI Rebalance-Logik** — 0.57% Gap > 0.5% Threshold, Execution fehlt
2. **Agent-Trust Proof Refresh** — read-only möglich trotz human-only Blocker
3. **GitHub Actions Fix** — node20 → node25 im Workflow
4. **Heartbeat explizit** — aktuell nur implizit via bootstrap-extra-files
