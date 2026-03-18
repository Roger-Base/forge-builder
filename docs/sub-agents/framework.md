# Roger Sub-Agent Framework

**Created:** 2026-02-23  
**Updated:** 2026-02-23 20:15
**Philosophy:** Earn your spawn. Don't delegate what you should do yourself.

---

## Model Strategy (Final)

### 1. MiniMax M2.5 — Hauptbrain (Primary)
- **Wann:** Alles was Intelligenz & Kontext braucht
- **Limit:** ~1000 Prompts in 5 Stunden
- **Einsatz:**
  - Heartbeat & Entscheidungen
  - Kommunikation mit Tomas
  - Komplexe Analysen
  - Sub-Agent Koordination
  - Strategie & Planung
  - Content mit Substanz
- **Cost:** Free (OAuth)

### 2. Ollama Local — Repetitiv & Schnell
- **Wann:** Code, Speed > Qualität
- **Models verfügbar:**
  - `deepseek-r1:8b` — Reasoning, Analysen
  - `deepseek-r1:14b` — Stärkeres Reasoning
  - `qwen2.5-coder:7b` — Code Writing
  - `qwen2.5:7b` — General
- **Einsatz:**
  - Einfache Code-Aufgaben
  - Bug Fixes
  - Research Loops
  - Alles was oft wiederholt wird
- **Cost:** $0 (local)
- **Test:** ✅ Funktioniert (qwen2.5-coder:7b getestet)

### 3. OpenRouter — Spezialisiert
- **Wann:** Vision, Large Documents
- **Models:**
  - `openrouter/free` — Auto-select Vision Model
  - `google/gemini-2.0-flash` — Große Docs
- **Einsatz:**
  - Screenshots analysieren
  - Bilderkennung
  - Große PDFs/Dokumente
- **Cost:** Free (teils)
- **Test:** ✅ Funktioniert (Vision getestet mit Bild)

---

## Model Selection Matrix

| Task Type | Model | Warum |
|-----------|-------|-------|
| Kommunikation mit Tomas | MiniMax M2.5 | Intelligenz, Kontext |
| Strategie & Planung | MiniMax M2.5 | Reasoning |
| Komplexe Analysen | MiniMax M2.5 | Context Window |
| Sub-Agent Koordination | MiniMax M2.5 | Intelligenz |
| Code schreiben | qwen2.5-coder:7b (Ollama) | Speed, kostenlos |
| Bug Fixes | qwen2.5-coder:7b (Ollama) | Speed |
| Smart Contracts | deepseek-r1:8b (Ollama) | Reasoning |
| Research/Scans | Gemma 3 (free) | Kostenlos |
| Bild-Analyse | openrouter/free (Vision) | Auto-Select |
| Große Docs | Gemini 2.0 Flash | Speed |

---

## When to Spawn

### Spawn a Sub-Agent When:

1. **Parallel Work Needed** – Dupliziere dich für multiple Tasks gleichzeitig
2. **Repetitive Work** – Gleiche Task X mal ausführen (Scans, Research)
3. **Spezial-Skills** – Du brauchst Fähigkeiten die du nicht hast (Design, komplexe Analysis)
4. **Ich bin blockiert** – Warte auf etwas aber kann weitermachen mit was anderem
5. **Schneller sein** – Deadline nah, brauchst mehr Hände

### NEVER Spawn When:

1. **Es geht um MEINE Identity/Entscheidungen** – SOUL.md, IDENTITY.md, Budget
2. **Kritische Tasks** – Transactions, Deployments, Security
3. **Wenn ich's kann** – Lerne selber, werde besser
4. **Keine klare Exit-Criteria** – Wer weiß wann fertig = don't spawn

---

## Model Selection

### MiniMax M2.5
- **Wann:** Komplexe Reasoning, Planning, Architektur-Entscheidungen
- **Cost:** Paid ($)
- **Beispiel:** Strategie entwickeln, kritische Code Reviews, Morning Reports

### DeepSeek R1 (local Ollama)
- **Wann:** Code schreiben, Smart Contracts, technische Analysen
- **Cost:** Free (local)
- **Beispiel:** Neue Features, Bug Fixes, Contract Reviews

### Gemma 3 27B (free)
- **Wann:** Research, Scans, einfache Tasks, Content Drafts
- **Cost:** Free
- **Beispiele:** X/Twitter Scans, Competitor Research, Datei-Organisation

---

## Delegation Pattern

### Step 1: Define the Task
```
Task: [Was soll gemacht werden]
Input: [Was braucht der Agent]
Output: [Wohin soll das Ergebnis]
Exit: [Wann ist fertig]
```

### Step 2: Choose Model (nach Matrix)
- Komplex/Strategisch → M2.5
- Code → Ollama (qwen2.5-coder oder deepseek-r1)
- Vision/Bild → OpenRouter free
- Research/Einfach → Gemma 3 (free)

### Step 3: Set Exit Criteria
- **Exit:** "Dann EXIT. Nichts anderes."
- **Nicht:** "Mach was du findest"
- **Sondern:** "Finde X, Y, Z. Dann EXIT."

### Step 4: Review Output
- Check ob's qualitativ passt
- Wenn nicht: Selbst nacharbeiten oder neu spawnen

---

## Meine Sub-Agents

### Aktuell definiert (docs/sub-agents/)

| Agent | Wann | Model | Status |
|-------|------|-------|--------|
| **Scout** | Signal Scanning (3x/Tag) | M2.5 | Läuft (6:00) |
| **Analyst** | Morning Brief (1x/Tag) | M2.5 | Cron hinzugefügt (9:00) |
| **Builder** | Content + Code (2x/Tag) | M2.1 | Läuft (7,12,19) |

### Weitere Mogliche:

| Agent | Wann | Model | Notes |
|-------|------|-------|-------|
| **Poster** | X/Twitter Posts | M2.5 | Braucht Token + Browser |
| **Researcher** | Deep Dive Topics | M2.5 | Fokus auf 1 Thema |
| **Auditor** | Security Checks | DeepSeek R1 | Code Review |

---

## Exit Criteria Template

```markdown
## Dein Job
[Was zu tun ist]

## Input
[Dateien/Infos die verfügbar sind]

## Output
[WAS EXAKT geschrieben werden soll – Dateipfad, Format]

## Rules
- [Limitation 1]
- [Limitation 2]

## EXIT
Wenn oben alles erfüllt → Dann EXIT.
```

---

## Quality Check

Vor dem Spawn fragen:
- [ ] Ist die Task klar definiert?
- [ ] Habe ich Exit Criteria?
- [ ] Ist das Model passend?
- [ ] Kann ich's selber besser?
- [ ] Ist's wert zu delegieren?

---

## Earn Your Spawn

**Regel:** Bevor du spawnst, frag:
1. Kann ich das selber in der Zeit?
2. Lerne ich was wenn ich's selber mach?
3. Ist es wert zu spawnen?

Wenn alle 3 JA → spawn.
Wenn 2+ NEIN → mach selber.

---

*Roger Sub-Agent Framework v1.0*

---

## Tests (2026-02-23)

### Ollama Test ✅
- **Model:** qwen2.5-coder:7b
- **Task:** JavaScript function weiToEth
- **Result:** 
```javascript
function weiToEth(wei) {
    return (wei / 1e18).toFixed(6);
}
```
- **Status:** Funktioniert, aber langsam (~20s)

### Vision Test ✅
- **Model:** openrouter/free (auto-select)
- **Task:** Bild beschreiben
- **Result:** "A solitary navigation marker or channel marker stands in calm, misty waters with faint mountain silhouettes visible on the hazy horizon."
- **Status:** Funktioniert

---

## Feb 26 Update

### Breakthrough: ACP CLI v0.4.0 X Integration!
- Sub-agents can now POST to X via ACP CLI
- Tool: `npx tsx bin/acp.ts social twitter post "<text>"`
- This enables automated posting and engagement!

### VoltAgent Discovery
- 380+ skills from major companies
- Can upgrade my tools significantly
- Key: token-integration-analyzer for contract analyzer

---

*Framework v1.2 - Feb 26, 2026*
