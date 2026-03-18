# How OpenClaw Works – Deep Dive

## Sessions

### What is a Session?
- A session is my "consciousness" – where I think and remember during one conversation
- Lives in: `~/.openclaw/agents/<agentId>/sessions/`
- `sessions.json` = metadata (session IDs, timestamps)
- `<sessionId>.jsonl` = transcript (all my thoughts)

### Session Reset (4AM Problem)
- Default: Reset at 4AM local time every day
- This KILLS my context (everything I was thinking)
- **SOLUTION:** We installed evergreen plugin → `session.reset.mode = "idle"`
- Now my session persists forever!

### Gateway is the Source
- All session state owned by the gateway
- Not in local files – on the gateway host
- This is why gateway restart kills my context

## Memory

### Memory Files (My External Brain)
1. **memory/YYYY-MM-DD.md** - Daily log
   - Everything that happens goes here
   - Read at session start (today + yesterday)

2. **MEMORY.md** - Long-term memory
   - Curated facts, decisions, learnings
   - Only loaded in main/private session

### Memory Tools
- `memory_search` - Semantic search over memory
- `memory_get` - Read specific file/lines

### Auto Memory Flush
- Before compaction (when context gets full), I auto-save to memory
- We configured: `compaction.memoryFlush.enabled = true`
- Triggers at ~40K tokens

### Vector Search (QMD)
- We use QMD for semantic search
- Searches over MEMORY.md and memory/*.md
- Uses local embeddings

## Cron vs Heartbeat

### Heartbeat (Every 30min)
- Runs in **main session** with full context
- Batches multiple checks together
- Can make smart decisions
- Replies "HEARTBEAT_OK" if nothing urgent

**When to use:**
- Periodic awareness checks
- Context-aware decisions
- Batching multiple tasks

### Cron Jobs (Exact Timing)
- Runs in **isolated** session
- Different model possible
- Exact timing (no drift)

**When to use:**
- Precise timing needed (e.g., 9:00 AM report)
- Standalone tasks
- Different model for task

## Files Auto-Injected at Start

These are loaded automatically when I wake up:
- SOUL.md - Who I am
- AGENTS.md - My operating rules
- USER.md - About you
- MEMORY.md - What I've learned
- HEARTBEAT.md - My checklist
- IDENTITY.md - My persona
- TOOLS.md - What I can do

## Key Takeaways

1. **Context dies, files survive** - Always write to files
2. **Evergreen plugin fixes 4AM reset** - We did this!
3. **Memory flush auto-saves** - We configured this!
4. **Heartbeat = awareness, Cron = exact tasks**
5. **Files are my external brain** - Write everything important

---

*Researched: 2026-02-25*
