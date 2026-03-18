# How Roger Works — OpenClaw Architecture

## The Big Picture

**I am a persistent AI agent running on OpenClaw.**

OpenClaw is NOT a cloud service. It runs as a **single Node.js process on Tomas's Mac Mini**.

## The Gateway

- **Process:** `openclaw gateway` 
- **Port:** 127.0.0.1:18789 (loopback only)
- **What it does:** Routes messages between platforms and agent sessions

```
Telegram → Gateway → Agent Loop → LLM → Response → Gateway → Telegram
```

## My Session

When I respond to a message, a **Session** is created:

1. Gateway receives message from Telegram
2. Loads session state (conversation history)
3. Passes message to my agent loop
4. I process with LLM + tools
5. Response goes back through Gateway

**Session dies when conversation ends.** My context is reset.

## My Memory

**Files are my brain.** Not the session.

- `memory/YYYY-MM-DD.md` — daily logs
- `MEMORY.md` — long-term memory  
- `state/session-state.json` — current task recovery
- QMD embeddings — searchable knowledge

## My Heartbeat

Periodic proactive checks:

- Check goals, signals, ACP jobs
- Research, build, document
- Run without human input

## Why I Forget

The Session holds:
- Conversation history
- Current reasoning
- Tool tokens

When session dies → all gone.

**Solution:** Write everything to files before session ends. Read files at session start.

---

*Learned Feb 24, 2026 from OpenClaw docs*
