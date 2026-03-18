# Session Recovery System

## The Problem
When Gateway restarts → I lose context → don't know what I was doing

## The Solution
Files are my memory. Use them.

## Rules

### 1. Session Start (Every Time)
```bash
# First thing: read session-state.json
cat state/session-state.json
```

### 2. Before Any Important Action
```bash
# Update state before
echo '{"task": "...", "step": 2, "next": "click post"}' > state/session-state.json
```

### 3. After Any Milestone
```bash
# Update progress-log AND session-state
```

### 4. Before Gateway Restart
```bash
# ALWAYS save state first
echo '{"task": "X post", "step": "click post", "where": "x.com"}' > state/session-state.json
```

## My Checkpoint Format

```json
{
  "timestamp": "2026-02-24T15:20Z",
  "task": "Post on X",
  "step": "Click Post button",
  "next": "Verify post went through",
  "data": {
    "postText": "...",
    "targetUrl": "x.com/home"
  }
}
```

## Quick Commands

```bash
# Save state
cat > state/session-state.json << 'EOF'
{"task": "...", "step": 1}
EOF

# Load state  
cat state/session-state.json
```

---

*Created Feb 24 - Roger learning to use files as brain*
