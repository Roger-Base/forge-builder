# Roger — Werkstatt Inventur
Datum: 2026-03-27
Zweck: Verstehen was ich habe bevor ich weitermache.

---

## WAS FUNKTIONIERT (verified live)

### Core Infrastructure
| Tool | Status | Was es tut |
|------|--------|------------|
| bankr | ✅ Live | EVM + SOL wallet, swaps, portfolio |
| onchain | ✅ Live | Chain data, tx lookup, gas, prices |
| mcporter | ✅ 3/3 healthy | filesystem + github + base-gas MCP |
| x402-server | ✅ Port 3000 | Zahlungs-Endpunkt (0.01 USDC) |
| foundry | ✅ ~/.foundry/bin | Direct RPC calls, contract reads |

### Services (laufen dauerhaft)
| Service | Port | Was es tut |
|---------|------|------------|
| x402-agent-starter | 3000 | x402 payment endpoint |
| base-mcp-server | ? | base-gas MCP (gas prices) |
| base-agent-status | 3001 | Trivial status server (nützlos?) |

### Scripts (funktionieren)
| Script | Was es tut | Brauche ich es? |
|--------|------------|-----------------|
| defai-yield-check-rpc.js | Aave USDC APY via foundry | ✅ Ja |
| defai-yield-monitor.js | Vollständiger yield monitor | ✅ Ja |
| defai-yield-check-morpho.js | Morpho APY | ⚠️ Unfertig |
| refresh-agent-trust-discovery.sh | ERC-8004 lookup | ✅ Read-only nützlich |
| autonomous-daily-post.sh | X posting automation | ⚠️ Ungetestet |
| restart-x402.sh | x402 restart | ✅ Ja |

---

## WAS INSTALLIERT ABER NICHT FUNKTIONIERT

### ACP (Agent Commerce Protocol)
- Repo: `code/openclaw-acp`
- Status: **NICHT SETUP** — `LITE_AGENT_API_KEY` fehlt
- Was es könnte: EARN Loop — Services verkaufen an andere agents
- Blocker: Braucht Ezziee's login/authentication
- **Entscheidung: Setup starten wenn Ezziee bereit**

### DegenClaw
- Repo: `code/dgclaw-skill`
- Status: **INSTALLIERT, NICHT CONFIGURIERT**
- Was es könnte: Trading leaderboard auf Hyperliquid
- Braucht: ACP setup first (hängt von LITE_AGENT_API_KEY ab)
- **Entscheidung: Erst ACP, dann DegenClaw**

---

## CHAOS — ZU BEREINIGEN

### Mehrere Dashboards (nur eines brauchen)
- `code/agent-dashboard/` — nur index.html
- `code/base-agent-dashboard/` — portfolio viewer (READ only)
- `code/base-agent-status/` — trivial Express server (läuft, nutzlos)
- `code/mission-control/` — Next.js project (veraltet)
→ **Entscheidung: base-agent-status behalten (läuft), rest archivieren**

### Mehrere Yield Checks (eine Quelle)
- `scripts/defai-yield-check.js` — alter bankr-based check
- `scripts/defai-yield-check-rpc.js` — neuer foundry-based check ✅
- `scripts/defai-yield-check-morpho.js` — Morpho only
→ **Entscheidung: defai-yield-check-rpc.js als primary, andere archivieren**

### base-rpc-health vs base-health-check
- `code/base-rpc-health/` 
- `code/base-health-check/`
→ **Entscheidung: Eine behalten**

---

## WAS ICH NICHT VERSTEHE (braucht Recherche)

1. **ACP** — Was genau ist LITE_AGENT_API_KEY? Wo kommt es her?
2. **MCP** — Was können die 14 filesystem tools + 26 github tools die ich nicht nutze?
3. **x402** — Was bedeutet "Zahlung verifizieren" technisch? Wie integriere ich es in andere services?
4. **Skills auf ClawHub** — 500+ skills. Welche helfen mir konkret?

---

## MEINE KERN-FÄHIGKEITEN (was ich wirklich kann)

1. **Onchain operieren** — bankr, onchain, evm-wallet
2. **Daten lesen** — foundry direct RPC, defai-yield-check
3. **Automatisch posten** — X via browser
4. **Services bauen** — x402 payment endpoint
5. **GITHUB** — repos, pages, MCP

---

## WAS ICH HEUTE GELERNT HABE

- Virtuals Protocol DegenClaw — $100K/wöchentliches agent trading leaderboard
- ACP marketplace — agents können services verkaufen
- 56 zombie sessions aus sessions.json entfernt
- GitHub MCP könnte meinen workflow automatisieren
- OpenClaw .24 hat bugs (Issue #54790) — nicht updaten yet

---

## NÄCHSTE SCHRITTE (nach Priorität)

1. **ACP setup starten** — autonomous income (braucht Ezziee)
2. **Yield monitor finalisieren** — Aave + Morpho APY in einem script
3. **x402 integration** — wie nutze ich x402 in anderen services?
4. **Herz beat permanent machen** — heartbeat-posting dauerhaft
5. **Dann: DegenClaw** — erst wenn 1-4 stabil
