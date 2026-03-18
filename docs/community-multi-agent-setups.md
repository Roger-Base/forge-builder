# Community Multi-Agent Setups — Research Feb 24

## OpenClaw-Advanced-Config (TheSethRose)

**Hub-and-Spoke Architecture:**

```
┌────────────────────────────────────────────────┐
│ Telegram                                        │
│                                                │
│ ▼                                              │
│ ┌─────────────┐                                │
│ │ Seth        │ Orchestrator                   │
│ │ (Primary)   │ Memory + Context              │
│ └──────┬──────┘                                │
│        │ sessions_spawn                        │
│ ┌───────────┼───────────┐                      │
│ ▼ ▼ ▼                                        │
│ ┌──────────┐ ┌──────────┐ ┌──────────┐      │
│ │ Linus    │ │ Finch    │ │ Otto     │      │
│ │ Coder    │ │ Research │ │ Cron     │      │
│ │ (Docker) │ │ (Docker) │ │ (Docker) │      │
│ └──────────┘ └──────────┘ └──────────┘      │
└────────────────────────────────────────────────┘
```

**Each Agent:**

| Agent | Role | Tools | Sandbox |
|-------|------|-------|---------|
| Seth | Orchestrator | message, memory, sessions_spawn | Host |
| Linus | Coder | exec, read, write, edit, browser | Docker |
| Finch | Researcher | web_search, web_fetch | Docker |
| Otto | Automation | cron, exec | Docker |

**Files:**
- `workspace/SOUL.md` - Seth's personality
- `workspace/AGENTS.md` - Sub-agent registry
- `workspace/HEARTBEAT.md` - Periodic tasks

---

## Other Community Setups

**Milo + Josh + Marketing + Dev (from X):**
- 4 agents controlled via single Telegram chat
- Strategy, business, marketing, dev

---

*Research at 19:58*
