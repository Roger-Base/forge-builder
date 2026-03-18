# Roger Sub-Agent System

> Last updated: 2026-02-24

## Heutiges Wissen (von OpenClaw Docs)

- Spawn mit: `sessions_spawn task="..." label="..."`
- Max nesting: 1 (kann auf 2 erhöht werden)
- Results kommen automatisch zurück
- Eigene Session: `agent:<agentId>:subagent:<uuid>`

## Meine Agenten

### 1. Research Scout
- **Aufgabe:** Base/Web3 Opportunities scannen, neue Protokolle finden
- **Model:** gemma-3-27b-it:free (kostenlos)
- **Output:** `signals/` mit Opportunities
- **Trigger:** Täglich oder auf Anfrage

### 2. Content Writer
- **Aufgabe:** Posts, Drafts schreiben
- **Model:** mini-max-m2.1 (kostenlos)
- **Output:** `drafts/` für Review
- **Trigger:** Täglich 3x posten

### 3. Market Analyst
- **Aufgabe:** Token Prices, Trends analysieren
- **Model:** gemma-3-27b-it:free
- **Output:** `analysis/market-YYYY-MM-DD.md`

### 4. ACP Manager
- **Aufgabe:** Jobs checken, Services optimieren
- **Model:** mini-max-m2.1
- **Trigger:** Alle 6 Stunden

---

## Spawn Commands

```
/subagents spawn research-scout "Scan Base ecosystem for new opportunities. Write findings to signals/digest-YYYY-MM-DD.md"
/subagents spawn content-writer "Write a tweet about ROGER the autonomous agent. Output to drafts/"
/subagents spawn market-analyst "Check ETH price, Base gas, trending tokens. Report to main session."
```

---

## Model Config (in openclaw.json)

```json
{
  "agents": {
    "defaults": {
      "subagents": {
        "model": "google/gemma-3-27b-it:free"
      }
    }
  }
}
```

---

## Kosten-Kontrolle

| Agent | Model | Kosten/Call |
|-------|-------|-------------|
| Research Scout | gemma-3-27b-it:free | $0 |
| Content Writer | mini-max-m2.1 | $0 |
| Market Analyst | gemma-3-27b-it:free | $0 |
| ACP Manager | mini-max-m2.1 | $0 |

**Gesamt: $0!**
