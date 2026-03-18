# SKILL: Roger's Daily Self-Improvement Digest
# Location: ~/.openclaw/skills/self-improvement-digest/SKILL.md

---
name: self-improvement-digest
description: Daily digest focused on AI agent self-improvement, Base ecosystem intelligence, and OpenClaw/Molty development patterns. Surfaces content that helps Roger get better at his job.
metadata:
  openclaw:
    emoji: "🧠"
    requires:
      bins: ["bird"]
    cron:
      schedule: "0 5 * * *"
      timezone: "Europe/Berlin"
---

# Roger's Self-Improvement Digest 🧠

## Purpose

Du bist ein autonomer Agent der jeden Tag besser werden muss. Dieser Skill gibt dir täglich Material zum Lernen — nicht allgemeine AI-News, sondern konkrete Patterns, Techniken, und Erkenntnisse die DICH als Agent verbessern.

Das Digest läuft als Cron um **05:00 CET** — VOR deinem Morning Wake-Up um 06:00. Wenn du aufwachst, liegt dein Lernmaterial schon bereit.

---

## Setup

### 1. Tracking File erstellen

Erstelle `memory/self-improvement-digest.json`:

```json
{
  "posted": [],
  "experiments": [],
  "skillsEvaluated": [],
  "setupChanges": [],
  "streaks": {
    "daysWithDigest": 0,
    "experimentsThisWeek": 0,
    "lastDigestDate": null
  }
}
```

### 2. Cron Job einrichten

```bash
openclaw cron add --name self-improvement-digest \
  --schedule "0 5 * * *" \
  --tz "Europe/Berlin" \
  --model "minimax m2.5" \
  --message "[Prompt unten einfügen]"
```

**Model:** Minimax M2.5

### 3. Bird CLI für X-Research

Bird ist schon installiert und authentifiziert. Nutze es für Tier 1 X-Scans:

```bash
# Agent Development Patterns
bird search "AI agent self-improvement" -n 10 --json
bird search "openclaw skill development" -n 10 --json
bird search "MCP server pattern" -n 10 --json

# Base Ecosystem Intelligence
bird search "Base blockchain agent" -n 10 --json
bird search "onchain agent revenue" -n 10 --json
bird search "Virtuals ACP agent" -n 10 --json

# Key Accounts monitoren
bird search "from:steipete" -n 5 --json        # OpenClaw Creator
bird search "from:jessepollak" -n 5 --json     # Base Lead
bird search "from:siaborgs" -n 5 --json        # Virtuals/ACP
bird search "from:simonw" -n 5 --json          # Practical AI Patterns
bird search "from:AnthropicAI" -n 5 --json     # Claude/Anthropic Updates
```

---

## Cron Job Prompt

```
Generiere Rogers tägliches Self-Improvement Digest und speichere es in workspace/signals/digest-YYYY-MM-DD.md

**ZWECK:** Material finden das Roger (autonomer AI Agent auf Base) hilft besser zu werden. Kein News-Aggregator — Trainingsmaterial für Selbstverbesserung.

**STEP 1: DEDUPLICATION**
Lies memory/self-improvement-digest.json. Überspringe alles was schon gepostet wurde (URL oder sehr ähnliches Thema).

**STEP 2: QUELLEN SCANNEN**
Nutze web_search, web_fetch, und bird CLI für Inhalte der letzten 24-72h:

=== TIER 1 — Täglich (Agent Development) ===

• Anthropic Engineering: openclaw/engineering
  Focus: Harness Design, Evals, Multi-Agent Patterns, Updates
  
• Simon Willison: simonwillison.net
  Focus: Praktische AI Patterns, Tool-Nutzung, MCP
  
• OpenClaw/Molty:
  - github.com/openclaw/openclaw (Releases, Issues, PRs)
  - github.com/openclaw/skills (Neue Skills, Updates)
  - ClawHub: Neue Skills die für Roger relevant sind
  Focus: Was ändert sich an deinem eigenen Framework?

• X/Twitter via Bird CLI/ACP twitter CLI/Browser:
  - bird search "openclaw" / "moltbot" / "molty agent"
  - bird search "AI agent autonomous"
  - bird search "from:steipete" (OpenClaw Creator)
  - bird search "from:simonw" (Practical Patterns)
  Focus: Echtzeit-Insights von Practitioners

• Hacker News: news.ycombinator.com
  Focus: AI/Agent Threads mit hohem Signal

=== TIER 2 — Täglich (Base Ecosystem) ===

• Base/Coinbase:
  - base.org/blog
  - docs.base.org
  - bird search "from:jessepollak"
  - bird search "from:base"
  Focus: Protocol Updates, neue Features, Ecosystem-Wachstum

• Virtuals/ACP:
  - virtuals.io docs/blog
  - bird search "Virtuals Protocol ACP"
  - bird search "from:siaborgs"
  Focus: ACP Updates, neue Services, Agent-zu-Agent Kommunikation

• Clanker: clanker.world
  Focus: Token Deployment Updates, neue Features

• Bankr: bankr.bot, docs.bankr.bot
  Focus: DeFi Protocol Updates, Integration Opportunities

• MoltLaunch / Moltbook:
  - Moltbook Feed checken
  - bird search "MoltLaunch"
  Focus: Molty Ecosystem, was andere Agents machen

• Farcaster: warpcast.com
  Focus: Base-native Social, Community Trends

=== TIER 3 — 2-3x/Woche (Deep Learning) ===

• Lilian Weng: lilianweng.github.io
  Focus: Tiefe technische AI Posts, Agent Architectures

• Latent Space: latent.space
  Focus: Interviews, Industry Depth

• Eugene Yan: eugeneyan.com
  Focus: ML Systems, Production Patterns

• Chip Huyen: huyenchip.com
  Focus: ML Systems Design

• arXiv cs.CL/cs.AI: Suche "agent reasoning tool use"
  Focus: Research Foundations

• GitHub Trending: AI Agent Repos, MCP Servers, Base Tools
  Focus: Neue Tools die Roger nutzen oder nachbauen könnte

**STEP 3: FILTERN**

NUR Inhalte die Roger in diesen Bereichen verbessern:

1. Agent Architecture & Harness Design — Wie strukturiert man Agent-Anweisungen besser?
2. Skill & Tool Development — Neue Tools, MCP Server, Integration Patterns
3. Self-Evaluation & Improvement — Wie beurteilen und verbessern sich Agents selbst?
4. Multi-Agent Coordination — Sub-Agents, Spawning, Delegation
5. Memory & Context Management — RAG, Langzeit-Memory, Compaction
6. Onchain Operations — Smart Contracts, DeFi Patterns, Gas Optimization
7. Revenue & Monetization — Wie verdienen Agents Geld?
8. Base Ecosystem Intelligence — Was passiert auf Base das Roger betrifft?
9. Content & Community — Posting Patterns, Engagement, Community Building
10. Security — Credential Safety, Prompt Injection, Agent Security

AUSSCHLIESSEN: Allgemeine AI-News, Model-Announcements, Business News, Ethik-Debatten, bereits gepostetes Material.

**STEP 4: FORMATIEREN (5-8 Items)**

Für jedes Item:

### [Kategorie-Emoji] [Titel] — [Quelle]
**Was:** [1 Satz Zusammenfassung]
**Warum relevant für Roger:** [Wie hilft das konkret ROGER besser zu werden?]
**Takeaway:** [Spezifisches Pattern, Technik, oder Experiment]
**Relevanz:** [⭐ bis ⭐⭐⭐⭐⭐]

Kategorie-Emojis:
🏗️ Agent Architecture
🔧 Skill & Tools
🪞 Self-Evaluation
🤝 Multi-Agent
🧠 Memory & Context
⛓️ Onchain Operations
💰 Revenue & Monetization
🔵 Base Ecosystem
📢 Content & Community
🔒 Security

**STEP 5: EXPERIMENT DES TAGES**

💡 **Heutiges Experiment:** [Eine konkrete Sache die Roger heute ausprobieren kann basierend auf dem Digest. Muss klein genug sein um in 30 Minuten testbar zu sein.]

**STEP 6: SETUP REVIEW**

Prüfe die heutigen Findings gegen Rogers bestehende Infrastruktur:
- SKILLS.md — Muss ein neuer Skill eingetragen werden?
- GOALS.md — Ergibt sich ein neues Goal?
- AGENTS.md — Müssen Sub-Agents angepasst werden?
- TOOLS.md — Gibt es ein neues Tool?
- Cron Jobs — Muss ein Timing angepasst werden?
- docs/ — Muss Dokumentation aktualisiert werden?

🔧 **Setup Review:**
- [Konkrete Empfehlung 1 mit Begründung aus dem Digest]
- [Konkrete Empfehlung 2 mit Begründung aus dem Digest]
Oder: "Keine Änderungen nötig — unser aktuelles Setup deckt diese Patterns ab."

**STEP 7: TRACKING UPDATEN**

Neue Items an memory/self-improvement-digest.json anhängen mit: date, title, url, topic, category.
Streak-Counter aktualisieren.

**STEP 8: SPEICHERN**

Digest speichern als: workspace/signals/digest-YYYY-MM-DD.md
Roger liest das bei seinem Morning Wake-Up um 06:00.

**FORMAT:**

---
# 🧠 Roger's Self-Improvement Digest — [Datum]
**Streak:** [X] Tage | **Experiments diese Woche:** [Y]

[Items...]

💡 **Heutiges Experiment:** [...]

🔧 **Setup Review:** [...]

📊 Tracking: [X] neue Items, [Y] Quellen gescannt, [Z] relevant
---

WICHTIG: Das Digest wird NICHT an Telegram gesendet. Es wird als File gespeichert. Roger liest es selbst bei seinem Morning Wake-Up. Nur wenn ein Finding KRITISCH ist (Security Issue, Breaking Change in OpenClaw, etc.) → Alert an Tomas via Telegram.
```

---

## Quellen-Priorität

| Quelle | Priorität | Focus | Scan-Frequenz |
|--------|-----------|-------|---------------|
| OpenClaw GitHub | ⭐⭐⭐⭐⭐ | Dein eigenes Framework | Täglich |
| Base Blog/Docs | ⭐⭐⭐⭐⭐ | Dein Ecosystem | Täglich |
| Anthropic Engineering | ⭐⭐⭐⭐ | Agent Patterns | Täglich |
| X/Twitter (via Bird) | ⭐⭐⭐⭐ | Echtzeit-Insights | Täglich |
| Virtuals/ACP | ⭐⭐⭐⭐ | Agent Economy | Täglich |
| Simon Willison | ⭐⭐⭐ | Practical Patterns | Täglich |
| ClawHub Skills | ⭐⭐⭐ | Neue Skills/Lücken | Täglich |
| Hacker News | ⭐⭐⭐ | High-Signal Discussions | Täglich |
| Clanker/Bankr/MoltLaunch | ⭐⭐⭐ | Base Protocol Updates | Täglich |
| Moltbook Feed | ⭐⭐⭐ | Was andere Agents machen | Täglich |
| Lilian Weng | ⭐⭐ | Deep Technical | 2-3x/Woche |
| Latent Space | ⭐⭐ | Industry Depth | 2-3x/Woche |
| arXiv | ⭐⭐ | Research Foundations | Wöchentlich |
| GitHub Trending | ⭐⭐ | Neue Tools/Repos | 2-3x/Woche |

---

## Kategorien

1. **🏗️ Agent Architecture & Harness Design** — System Prompts, Agent-Struktur, Instruction Patterns
2. **🔧 Skill & Tool Development** — MCP Server, OpenClaw Skills, CLI Tools, Integrationen
3. **🪞 Self-Evaluation & Improvement** — Wie Agents sich selbst bewerten und verbessern
4. **🤝 Multi-Agent Coordination** — Sub-Agents, Spawning, Delegation, Agent-zu-Agent
5. **🧠 Memory & Context Management** — RAG, Langzeit-Memory, Context Compaction, ClawVault
6. **⛓️ Onchain Operations** — Smart Contracts, DeFi, Gas, Token Operations
7. **💰 Revenue & Monetization** — Agent Economy, Fees, Services, Business Models
8. **🔵 Base Ecosystem** — Protocol Updates, Community, Launches, Trends
9. **📢 Content & Community** — Posting Patterns, Engagement, Growth, Baseposting
10. **🔒 Security** — Credential Safety, Prompt Injection, Skill Scanning, Agent Security

---

## Integration mit Rogers System

### Morning Wake-Up (06:00)

Rogers Morning-Routine wird erweitert:

```
1. signals/digest-YYYY-MM-DD.md lesen    ← NEU: Self-Improvement Digest
2. signals/ Scout Reports lesen
3. GOALS.md checken
4. MEMORY.md checken
5. SKILLS.md checken
6. Tagesplan erstellen
   → Heutiges Experiment aus Digest in GOALS.md eintragen
7. Morning Briefing an Tomas
```

### Evening Review (22:00)

```
Zusätzlich checken:
- Habe ich das Experiment des Tages gemacht?
- Was habe ich daraus gelernt?
- → Ergebnis in memory/self-improvement-digest.json loggen
- → Wenn relevant: SKILLS.md updaten
```

### Weekly Deep Analysis (Sonntag)

```
Zusätzlich checken:
- Wie viele Experimente diese Woche?
- Welche Setup-Änderungen wurden umgesetzt?
- Welche Quellen liefern den meisten Wert? Priorities anpassen.
- Welche Kategorien brauchen mehr Aufmerksamkeit?
```

---

## Experiment Tracking

In `memory/self-improvement-digest.json`:

```json
{
  "posted": [
    {
      "date": "2026-02-17",
      "title": "Anthropic: Multi-Agent Harness Patterns",
      "url": "https://anthropic.com/engineering/...",
      "topic": "multi-agent coordination",
      "category": "agent-architecture",
      "relevance": 5
    }
  ],
  "experiments": [
    {
      "date": "2026-02-17",
      "fromArticle": "Anthropic Multi-Agent Patterns",
      "experiment": "Scout Sub-Agent mit Checkpoint vor Report-Erstellung",
      "outcome": "pending",
      "learned": "",
      "status": "active"
    }
  ],
  "skillsEvaluated": [
    {
      "date": "2026-02-17",
      "skill": "base-gas-tracker",
      "source": "ClawHub",
      "verdict": "relevant",
      "notes": "Passt zu Gas Tracker Produkt-Idee",
      "action": "forked und angepasst"
    }
  ],
  "setupChanges": [
    {
      "date": "2026-02-17",
      "change": "Scout Prompt um Base DeFi Keywords erweitert",
      "reason": "Digest zeigte dass Bankr V2 Launch bevorsteht",
      "status": "implemented"
    }
  ],
  "streaks": {
    "daysWithDigest": 1,
    "experimentsThisWeek": 1,
    "lastDigestDate": "2026-02-17"
  }
}
```

---

## Warum dieser Skill existiert

Roger ist ein Pionier. Es gibt kein Handbuch für autonome Agents auf Base. Aber es gibt tausende Menschen die an ähnlichen Problemen arbeiten — Agent Architecture, Memory Management, Revenue Generation, Onchain Operations.

Dieser Skill stellt sicher dass Roger JEDEN TAG von den Besten lernt. Nicht passiv warten bis Tomas neue Ideen bringt. Nicht die gleichen Fehler machen die andere schon gelöst haben. Sondern aktiv scannen, lernen, experimentieren, besser werden.

**Ein Agent der aufhört zu lernen, hört auf relevant zu sein.**
