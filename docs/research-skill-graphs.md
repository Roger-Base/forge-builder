# Skill Graphs Research

## Das Konzept

**Flat Skills (aktuell):**
- Eine Datei = eine Capability
- Alles wird geladen beim Start
- Keine Beziehungen zwischen Skills

**Skill Graphs:**
- Netzwerk aus kleinen, composable Nodes
- Verbunden durch Wikilinks
- Jeder Node = ein vollständiges Konzept
- Agent scanned Index → folgt Links → liest nur was gebraucht

## Warum das besser ist

1. **Kein Full-Load:** Agent loadet nicht alles upfront
2. **Kontext-Flow:** Konzept A kann zu B, C, D verlinken
3. **Skalierbar:** Domänen die nie in eine Datei passen werden navigierbar
4. **Standalone + Context:** Jeder Node funktioniert solo, wird mächtiger im Graph

## Building Blocks

```
Wikilinks embedded in prose → tragen Bedeutung, nicht nur Referenzen
YAML Frontmatter → Agent kann Nodes scannen ohne sie zu lesen
Content Maps → organizieren Cluster in navigierbare Sub-Topics
```

## Vergleich

| Flat Skill | Skill Graph |
|------------|-------------|
| `SKILL.md` | `/skills/trading/` |
| Alles in einer Datei | Netzwerk aus Nodes |
| Linear | Graph-basiert |
| Alles laden | Selective loading |

## Beispiel Struktur

```
skills/
├── index.yaml          # Entry point, beschreibt alle Skills
├── trading/
│   ├── index.md       # Overview + YAML frontmatter
│   ├── position-sizing.md
│   ├── risk-management.md
│   ├── market-psychology.md
│   └── technical-analysis.md
└── acp/
    ├── index.md
    ├── service-definition.md
    ├── job-processing.md
    └── payment-settlement.md
```

## Frontmatter Example

```yaml
---
name: Position Sizing
description: How to calculate position sizes for risk management
links:
  - risk-management
  - market-psychology
  - technical-analysis
cost: medium
context: trading
---
```

## Implementation für Roger

**Aktuell:**
- `~/.openclaw/skills/` – flat files
- Jeder Skill = eine Datei

**Graph-basiert (Ziel):**
- `~/.openclaw/skills/` wird Ordner mit Subgraphs
- Index-Datei pro Domain
- Wikilinks zwischen verwandten Skills

## Quellen

- https://blog.dailydoseofds.com/p/ensuring-reproducibility-in-machine
- https://github.com/kepano/obsidian-skills
- https://x.com/akshay_pachaar/status/2024848778415755327
- https://agentskills.io/specification
