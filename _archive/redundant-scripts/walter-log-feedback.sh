#!/bin/bash
# Walter Challenge Feedback Logger
# Usage: ./walter-log-feedback.sh "<what_walter_flagged>" <response_category> [resolved=true/false] [notes]

WHAT_FLAGGED="$1"
RESPONSE="$2"
RESOLVED="$3"
NOTES="$4"

LOG_FILE="/Users/roger/.openclaw/workspace/state/walter-challenge-log.json"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if [ -z "$WHAT_FLAGGED" ] || [ -z "$RESPONSE" ]; then
    echo "Usage: ./walter-log-feedback.sh '<what_walter_flagged>' <response_category> [resolved=true/false] [notes]"
    echo "response_category: applied|rejected_with_proof|deferred_with_reason|no_response"
    exit 1
fi

# Create temp file with new entry
TEMP=$(mktemp)
jq --arg ts "$TIMESTAMP" \
   --arg what "$WHAT_FLAGGED" \
   --arg resp "$RESPONSE" \
   --arg res "$RESOLVED" \
   --arg notes "$NOTES" \
   '.challenges += [{"timestamp": $ts, "what_flagged": $what, "roger_response": $resp, "resolved": ($res == "true"), "resolution_notes": $notes}] | .metrics.total_challenges += 1 | .metrics.last_updated = $ts' \
   "$LOG_FILE" > "$TEMP" && mv "$TEMP" "$LOG_FILE"

# Update counter
case "$RESPONSE" in
    applied) jq '.metrics.applied_count += 1' -i "$LOG_FILE" ;;
    rejected_with_proof) jq '.metrics.rejected_count += 1' -i "$LOG_FILE" ;;
    deferred_with_reason) jq '.metrics.deferred_count += 1' -i "$LOG_FILE" ;;
    no_response) jq '.metrics.no_response_count += 1' -i "$LOG_FILE" ;;
esac

echo "Logged challenge: $WHAT_FLAGGED -> $RESPONSE"
