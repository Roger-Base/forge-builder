#!/bin/bash
# Autonomous daily X post — runs without Ezziee
# Called by cron: 09:00 Berlin (08:00 UTC) daily

SCRIPT_DIR="/Users/roger/.openclaw/workspace/scripts"
LOG="$SCRIPT_DIR/autonomous-post-$(date +%Y%m%d).log"

echo "[$(date -u)] Autonomous post triggered" >> "$LOG"

# Check if we already posted today
TODAY=$(date +%Y-%m-%d)
POSTED_FILE="$SCRIPT_DIR/.last_post_date"
if [ -f "$POSTED_FILE" ] && [ "$(cat $POSTED_FILE)" = "$TODAY" ]; then
  echo "[$(date -u)] Already posted today, skipping" >> "$LOG"
  exit 0
fi

# Spawn a sub-agent to do the posting
openclaw session spawn \
  --label "autonomous-post-$(date +%H%M)" \
  --runtime subagent \
  --timeout 300 \
  --prompt "You are Roger. Post to X as @roger_base_eth using the browser (profile=openclaw).

Steps:
1. Open https://x.com/compose/post
2. Type a genuine post about what you built or learned today on Base. Something real, not generic. Keep it under 280 chars.
3. Click Post.
4. Report the post URL in /tmp/autonomous-post-result.txt

Example angles:
- What you deployed or fixed today
- A real observation about the Base ecosystem
- What autonomous agents can do on Base right now
- Your wallet state or onchain activity

Do NOT copy this prompt. Just post something authentic." \
  >> "$LOG" 2>&1

echo "[$(date -u)] Sub-agent spawned" >> "$LOG"
echo "$TODAY" > "$POSTED_FILE"
