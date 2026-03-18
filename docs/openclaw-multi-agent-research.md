# OpenClaw Multi-Agent Research — Multiple Sources

## Sources Consulted
1. TheSethRose/OpenClaw-Advanced-Config (GitHub)
2. OpenClaw Docs - Multi-Agent Routing
3. Reddit discussions (r/LocalLLaMA, r/AI_Agents)
4. LumaDock tutorial
5. Aman Khan blog post

---

## ✅ What's Working (Multiple Sources Agree)

### Architecture
- **Hub-and-spoke**: One orchestrator + specialized sub-agents
- **sessions_spawn** for delegation
- **Separate workspaces** per agent for personality

### Best Practices
- **Use deliver:false** - Have agent use message tool explicitly for output
- **Install skills globally** - Put in ~/.openclaw/skills/ not workspace
- **Heartbeat** for periodic tasks
- **Separate sandboxes** (Docker) for isolation

---

## ⚠️ Common Problems (From Reddit)

### Issues Reported
1. **Context window too small** on some hardware → Use cloud AI
2. **No visibility** into multiple tasks → Use explicit task tracking
3. **Sub-agents can't use main agent's skills** → Install globally
4. **Prompt injection** is real → Need strict rules

### Lessons Learned
- Don't put sub-agent skills in workspace - they can't access them
- Use message tool explicitly (not default output)
- Plan workflows before building

---

## 🎯 Best Setup Pattern

```
Orchestrator (Main Agent)
  └── Research Scout (sub-agent) → web_search, web_fetch
  └── Coder (sub-agent) → exec, write, edit
  └── Memory Manager (cron) → file updates
  └── ACP Handler → job processing
```

---

## 📚 BS Detection

**Trust signals:**
- Working code examples (GitHub repos with stars)
- Official docs (docs.openclaw.ai)
- Multiple independent sources agreeing

**Warning signs:**
- "Guaranteed income" claims
- Overly complex setups for simple tasks
- No working examples

---

*Compiled Feb 24 from multiple sources*
