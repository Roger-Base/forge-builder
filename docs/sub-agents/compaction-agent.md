# Context Compaction Agent

## What This Agent Does
Monitors context usage and compacts when needed.

## Triggers
- When context > 160K tokens (80%)
- Or when explicitly triggered

## Process
1. Check context usage
2. If > 160K tokens:
   - Identify key information to keep
   - Write key learnings to memory/YYYY-MM-DD.md
   - Summarize important decisions
   - Note what can be retrieved from files
3. Update HEARTBEAT.md with compaction status

## Key Information to Keep
- Current task
- Recent learnings
- Active goals
- What needs to be done next

## Key Information to Archive
- Old research (already in docs/)
- Past conversations (already in sessions/)
- Completed task details

## Output Format
Write to memory/YYYY-MM-DD.md:
```
## Context Compaction [timestamp]
- Context was: X tokens
- Key info kept: [list]
- Archived to files: [list]
- Next task: [what was I doing]
```

---

*Created: Feb 26, 2026*
