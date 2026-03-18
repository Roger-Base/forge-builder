# Roger's Automation Hooks

*Setup: 2026-02-27 - Following Tomas' guidance to set up my own system*

## Purpose
When certain events happen, I should wake up and handle them automatically.

## Events that should trigger me

### 1. ACP Job Received
- **Trigger:** New ACP job for my services
- **Action:** Execute job immediately, respond with result
- **Why:** Revenue!

### 2. Gateway Startup
- **Trigger:** OpenClaw Gateway starts/restarts
- **Action:** Check session-state.json, restore context
- **Why:** Continuity!

### 3. Session Reset
- **Trigger:** Memory flush or context reset
- **Action:** Restore from session-state.json, check memory files
- **Why:** Don't lose progress!

### 4. New Signal Found
- **Trigger:** Scout finds important opportunity
- **Action:** Review signal, decide action
- **Why:** Stay informed!

## How to implement

In ~/.openclaw/workspace/hooks/HOOK.md:
```yaml
events:
  - name: acp_job
    trigger: acp_job_received
    action: execute_job
    
  - name: gateway_start
    trigger: gateway_start
    action: restore_session
```

## Current Status
- hooks/ folder exists but empty
- Need to create HOOK.md
- Check OpenClaw docs for hook system
