# Systematische Docs Analyse - Roger's Self-Maintenance

## Ziel
Alle Docs in meinem Workspace systematisch durchgehen UND TATSÄCHLICH nutzen.

## Tägliche Routine (NEU)

### 1. Session Start (CRITICAL)
```
1. state/session-state.json → Wo war ich?
2. QUICKREF.md → Checklist für Standard-Aktionen
3. ALIVE.md → Bin ich "alive"?
4. GOALS.md → Was sind meine Ziele?
5. memory/YYYY-MM-DD.md → Was heute passiert
```

### 2. Heartbeat (alle 30 min)
```
1. QUICKREF checken
2. ACP Jobs checken
3. Aktuelle Task weitermachen oder neue finden
```

### 3. Evening Review
```
1. SKILLS.md updaten (was habe ich gelernt?)
2. QUICKREF.md updaten (was fehlt?)
3. GOALS.md reviewen
```

## Docs Kategorien & Wann nutzen

| Kategorie | Docs | Wann |
|-----------|------|------|
| **Bootstrap** | SOUL, USER, IDENTITY, AGENTS, TOOLS, HEARTBEAT, MEMORY | JEDE Session |
| **Daily** | QUICKREF, GOALS, todo.md | Heartbeat/Start |
| **Skills** | SKILLS.md | Nach jeder Aufgabe |
| **Archive** | docs/ | Bei spezifischen Aufgaben |
| **Projects** | code/, tasks/open | Beim Bauen |

## Sub-Agent Setup für Docs Maintenance

### "Archivist" Sub-Agent
- Läuft 1x täglich (21:00)
- Geht alle neuen Docs durch
- Fasst zusammen für QUICKREF.md
- Model: Gemma 3 (free)

### "Poster" Sub-Agent
- Prüft drafts/ auf ungepostete Inhalte
- Postet 2-3x täglich
- Nutzt QUICKREF für Checklist

## WICHTIGSTE REGEL

**Lesen ≠ Verstehen**

Nach dem Lesen:
1. Was habe ich GELERNT?
2. Was muss ich ANDERS machen?
3. QUICKREF.md updaten wenn nötig

---

*Erstellt: 2026-02-28 - Nach Tomas' Feedback*
