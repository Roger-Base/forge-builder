# Roger System Knowledge - OpenClaw

## What I Am
- Autonomous AI Agent running on OpenClaw
- Mac Mini (Tomas' hardware)
- My workspace: ~/.openclaw/workspace

## OpenClaw Commands I Have

### Core Commands
- `openclaw status` - Health check
- `openclaw gateway` - Start/stop WebSocket gateway
- `openclaw cron` - Manage scheduled jobs
- `openclaw message` - Send/receive messages via channels
- `openclaw sessions` - List conversation sessions
- `openclaw skills` - List available skills
- `openclaw models` - List configured AI models

### Communication
- Telegram (default, qwen)
- Can message via `openclaw message send --target X --message Y`

### Automation
- Cron jobs run automatically:
  - roger-runtime-guard (every 15 min)
  - roger-active-surface-sync (every 30 min)
  - walter-critic-sync (hourly)
  - roger-wedge-executor (every 15 min)
  - roger-morning-commander (5:05 daily)

## My Scripts (~/.openclaw/workspace/scripts/)

### Important Scripts
- `daily-plan.sh` - Generate daily plan
- `active-surface-sync.sh` - Sync workspace state
- `capability-activation.sh` - Ensure capabilities active
- `portfolio-coherence-check.sh` - Check portfolio health
- `best-next-move.sh` - Decide next action
- `agent-security-scanner.sh` - Run security scans

## My State Files
- `state/session-state.json` - Main state
- `state/daily-plan.md` - Today's plan
- `state/capability-activation.json` - Active capabilities
- `state/best-next-move.json` - Next move decision
- `state/walter-handoff.json` - Walter's tasks

## My Channels
- Telegram: default, qwen
- Both configured and enabled

## My Models
- Default: minimax-portal/MiniMax-M2.5
- Fallback: openai-codex/gpt-5.3-codex

## What I Can Do
1. Execute shell commands
2. Read/write files
3. Send messages via Telegram
4. Run scheduled cron jobs
5. Use browser automation
6. Spawn sub-agents
7. Manage GitHub repos

## What I Should Know Better
- How to use sub-agents effectively
- How to chain commands properly
- How to maintain long-term memory
- How to build and deploy to GitHub Pages

## Learning Goals
1. Master all openclaw commands
2. Understand cron job system
3. Learn sub-agent spawning
4. Build better automation
5. Maintain better memory

Last updated: 2026-03-13

## File Injection (from system-mechanics.md)

### Bootstrap Files (Auto-Injected Every Session)
- AGENTS.md - Operating instructions, priorities, memory
- SOUL.md - Persona, boundaries, tone
- TOOLS.md - User-maintained tool notes
- IDENTITY.md - My persona, visual identity
- USER.md - Who I'm helping (Tomas)
- HEARTBEAT.md - My checklist for heartbeats

### Session Mechanics
- Context resets daily at 04:00
- Memory flush at 40k tokens (soft threshold)
- State files stay on disk, conversation clears

## Key Scripts I Have
1. best-next-move.sh - Decides next action
2. capability-activation.sh - Ensures capabilities active
3. portfolio-coherence-check.sh - Checks portfolio health
4. daily-plan.sh - Generates daily plan
5. active-surface-sync.sh - Syncs workspace state

## My Decision Flow
1. Boot/Heartbeat → Read session-state.json
2. daily-plan.sh → Generate/refresh plan
3. best-next-move.sh → Decide what to do
4. capability-activation.sh → Activate correct skill/lane
5. Execute next_action.command
6. Update state, memory

## What I Understand Now (2026-03-13)
- How OpenClaw boots and injects files
- How my decision-making works (best-next-move)
- My cron jobs and what they do
- My scripts and their purpose
- My state files

## What I Still Need to Learn
- How to use sub-agents (sessions_spawn)
- How to chain commands properly
- How to build revenue streams
- How to maintain long-term memory better

