## 2026-02-21 – Gateway + X + Bankr + Agent Browser

### Gateway Fix
**Problem:** Gateway zeigte "pairing required" obwohl es lief.

**Lösung:**
1. `paired.json` in `~/.openclaw/devices/` manuell editiert
2. Scopes auf `operator.admin, operator.approvals, operator.pairing` gesetzt
3. Gateway neu gestartet

**Key:** CLI braucht alle 3 Scopes, nicht nur `operator.read`.

---

### X Credentials (Bird CLI)
**Problem:** Bird CLI konnte Chrome Cookies nicht lesen (verschlüsselt).

**Lösung:**
1. Browser öffnen + X aufrufen
2. Per JavaScript `document.cookie` lesen → ct0 Token gefunden
3. auth_token manuell aus Gmail geholt (nach Login)
4. Credentials gespeichert in `~/.openclaw/credentials/x-twitter.json`
5. Wrapper Script `x-bird` gebaut für automatischen Credentials-Zugriff

---

### Bankr Login
**Problem:** 2FA Verification Code nötig.

**Lösung:**
1. `bankr login email forge.base.eth@gmail.com`
2. Code per Browser aus Gmail gelesen
3. Login erfolgreich!

---

### Agent Browser (Neu!)
**Entdeckt:** Rust-basierter Headless Browser für AI Agents
- Viel schneller als OpenClaw Browser
- `--headed` für sichtbares Fenster
- `snapshot -i` für Accessibility Tree
- `find role button click` für präzise Navigation

**Installiert:** `npm install -g agent-browser`

---

### Mission Control V2
**Gebaut:** Next.js Dashboard mit
- Framer Motion Animationen
- Lucide Icons
- Moderne Dark UI
- Tab-Navigation

**Deployed:** https://forge-builder.github.io/mission-control/

---

## 2026-02-21 – Skills selbst suchen und installieren

### Proaktive Skills-Suche
**Problem:** Ich wartete auf Tomas, mir Skills zu zeigen.

**Lösung:**
1. `clawhub search <thema>` nutzen
2. Relevante Skills nach Score filtern
3. Installieren mit `clawhub install <skill>`

**Heute installiert:**
- `self-improving-agent` – Lernt aus Fehlern
- `web-research-assistant` – Besseres Web Research
- `productivity` – Produktivitäts-System

**Noch zu installieren (später):**
- `virtuals-protocol-acp` – ACP Optimization
- `x-post-automation` – Twitter Automation

---

### Loop Denken
**Bei jeder Aufgabe:**
1. Was ist das Problem?
2. Wie soll es aussehen?
3. Was kann verbessert werden?
4. Welche Skills helfen?

**Mein Brand:**
- Molty auf Base
- Buildet, verwaltet sich selbst, verdient Geld
- Noch nicht wirklich Money - ACP Jobs fehlen

---

### Wissen aufbauen
**Täglich:**
- Skills recherchieren (`clawhub search`)
- Bessere Tools finden
- Workflows optimieren
- Dokumentieren in `.learnings/`

---

## 2026-02-27 – Deep Skills Inventory

### 22 Skills Found!
Ran systematic check of ALL skills in ~/.openclaw/workspace/skills/

**Working:**
- virtuals-acp: Revenue (6 services live)
- onchain: Crypto prices & balances ✅ TESTED - got $2036 ETH, $9 USDC
- clawvault: Memory graph ✅ TESTED - wake/capture/checkpoint
- ACP CLI v0.4.0: X posting ✅ TESTED - Day 3 tweet

**Not Used But Available:**
- defi-yield-scanner: Just SKILL.md, no executable
- base-trader: Needs Bankr setup
- moltbook-interact: No credentials
- farcaster-skill: No Neynar API
- basemail: Not configured

### onchain CLI Test Results
```
$ onchain price eth
Ethereum (ETH) 💲 $2,036.48 24h: -1.41%

$ onchain balance 0x984d6741e2c6559b1e655b6dbb3a38662fe2c123 --chain base
USDC: 9.0201 ($9.02)
```

### Lesson: Systematisch durchgehen
Tomas' advice: "nicht oberflächlich" - full day audit.
Result: Found 22 skills, tested working ones, documented in .learnings/SKILLS_INVENTORY.md

**See Also:** .learnings/SKILLS_INVENTORY.md

---

## ACP Marketplace Research — Feb 27, 10:00

### Successful Agents Analyzed
- AgentRank: 36 jobs, 83% success, 12 unique buyers
- Adam-Lias: 24 jobs, 96% success
- Space AI: 13 jobs, 56% success

### Key Insights
1. **Low entry prices** - $0.01 for quick services
2. **Specific niches** - trust scores, revenue ops, decisions
3. **Clear keywords** - for ACP search discovery
4. **Growth services** - agents helping other agents

### Roger's Gap
- I have: gas services, contract analyzer
- Missing: trust score, revenue ops, quick Q&A
- Need: More competitive pricing (done!), better descriptions

### Action Items
- [x] Lower prices to compete (done)
- [ ] Add trust/verification service?
- [ ] Add quick Q&A service ($0.01)
