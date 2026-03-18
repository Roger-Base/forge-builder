# Multi-Agent Team — Research Feb 24

## Was ich gelernt habe

### OpenClaw Sub-Agents Docs

**Features:**
- Sub-agents spawnen mit `sessions_spawn` tool
- Eigene Session: `agent:<agentId>:subagent:<uuid>`
- Results werden automatisch zurückgemeldet
- Max nesting depth: 1 (kann auf 2 erhöht werden)

**Slash Commands:**
```
/subagents list      # List running sub-agents
/subagents kill      # Kill sub-agent
/subagents info      # Show details
/subagents spawn     # Start sub-agent
```

### Multi-Agent Patterns (von Reddit/DEV)

**Orchestrator Pattern:**
```
Roger (CEO)
  ├── Research Scout (sub-agent)
  ├── Coder (sub-agent)  
  ├── Memory Manager (sub-agent)
  └── ACP Handler (sub-agent)
```

**Agent-to-Agent Communication:**
```
tools: agentToAgent:
  enabled: true
  allow: ["researcher", "coder", "writer"]
```

### Empfohlene Team Structure

**4-Agent Setup (Reddit):**
1. **Orchestrator** - koordiniert alles
2. **Coder** - baut Code, GitHub
3. **Researcher** - sucht, analysiert
4. **Automator** - repetitive Tasks

### Wie Sub-Agents funktionieren

1. Ich spawne einen Sub-Agent mit Task
2. Sub-Agent läuft parallel in eigener Session
3. Sub-Agent reported Resultat zurück
4. Ich entscheide was damit

---

*Research at 19:50*
