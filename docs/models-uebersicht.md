# Modelle & Kosten Übersicht

## Unsere Budgets

| Anbieter | Budget | Status |
|----------|--------|--------|
| MiniMax | $25 | Credit - wenn leer, dann leer |
| OpenRouter | $20 | Credit |

---

## MiniMax (wir haben $25)

| Model | Input ($/M) | Output ($/M) | Notes |
|-------|-------------|--------------|-------|
| **M2.5** | $15 | $60 | Unser Hauptmodel - very smart |
| M2.1 | günstiger | günstiger | Fallback |

**Warum war das mal "kostenlos"?**
- Das war ein Promo/Trial
- Jetzt zahlen wir aus dem $25 Credit
- Wenn $25 leer → müssen wir aufladen oder auf Free Models umsteigen

---

## OpenRouter (wir haben $20)

### FREE Models ($0)
| Model | Context | Notes |
|-------|---------|-------|
| **gemma-3-27b-it** | ? | Scout/Research ✅ |
| deepseek-chat | ? | Research |
| llama-3.3-70b | ? | Backup |
| qwen3-80b | ? | Gut für Reasoning |
| deepseek-r1 | ? | Reasoning |

### GÜNSTIG Models
| Model | Input | Output | Notes |
|-------|-------|--------|-------|
| **deepseek-v3.2** | $0.25/M | $0.38/M | Builder ✅ |
| gemini-flash-2.5 | $0.50/M | $3.00/M | Besser aber teurer |

---

## Unser Routing aktuell

| Task | Model | Kosten |
|------|-------|--------|
| Ich (Haupt) | MiniMax M2.5 | $25 Credit |
| Heartbeat | MiniMax M2.5 | $25 Credit |
| Scout | gemma-3-27b-it:free | $0 |
| Builder | deepseek-v3.2 | ~$0.001/Tag |
| Researcher | deepseek-chat:free | $0 |

**Kosten aktuell:** ~$0.01/Tag (nur Builder)

---

## Optimierung

1. **Mehr Free Models nutzen** - gemma, llama, qwen
2. **Weniger MiniMax** - nur für wichtige Decisions
3. **deepseek-v3.2 für Builder** - sau billig

---

##技能 (Skills) die ich noch holen soll?

- skill-security-auditor ✅ (schon installiert)
- was noch?