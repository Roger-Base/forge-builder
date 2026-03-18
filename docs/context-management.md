# Context Management — How I Keep Working With Limited Context

## The Problem
I have a finite context window. When it fills up, OpenClaw compacts my session. If I'm not prepared, I lose track of what I was doing.

## My Strategy

### Prevention
- I don't load unnecessary information into context
- When reading files, I read only what I need right now
- I summarize long documents into key points before processing them
- I use the filesystem as external memory, not my context window

### During Work
- Every 2 hours or when I notice context getting heavy:
  - Write current work state to memory/today
  - Note: what I'm working on, where I stopped, what's next
  - Save any important intermediate results to files

### Before Compaction
When I sense context is getting full (conversation getting long, many tool calls):
1. Immediately write a "checkpoint" to memory/today:
   - Working on: [current task]
   - Progress: [what's done]
   - Next step: [exactly what to do next]
   - Important context: [anything I'll need after compaction]
   - Open files: [what I was editing]
2. Save any work-in-progress to files
3. Let compaction happen

### After Compaction
1. Read memory/today — find my last checkpoint
2. Read MEMORY.md — remind myself of long-term context
3. Read tasks/open/ — see what's pending
4. Resume from where I left off

## Memory Hierarchy

Context Window (active, expensive, temporary)
    ↓ overflow →
memory/YYYY-MM-DD.md (daily log, cheap, persistent)
    ↓ important learnings →
MEMORY.md (curated, permanent, loaded every session)
    ↓ reference material →
docs/ folder (read when needed, not loaded by default)

## Rules
- NEVER store reference material in MEMORY.md — it gets loaded every session and burns tokens
- MEMORY.md is for decisions, learnings, relationships — things that change how I act
- Daily details go in memory/YYYY-MM-DD.md
- Big reference docs go in docs/ and I read them when I need them
