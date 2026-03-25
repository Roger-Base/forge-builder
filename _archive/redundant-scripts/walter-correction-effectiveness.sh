#!/bin/bash
# walter-correction-effectiveness.sh
# Computes correction effectiveness: did corrections reduce mismatch rate?
# Reads: walter-daily-metrics.json, walter-mismatch-log.jsonl, walter-verification-log.jsonl
# Writes: walter-correction-effectiveness.json (appended), prints summary

METRICS="/Users/roger/.openclaw/workspace/state/walter-daily-metrics.json"
VERIFICATION_LOG="/Users/roger/.openclaw/workspace/state/walter-verification-log.jsonl"
MISMATCH_LOG="/Users/roger/.openclaw/workspace/state/walter-mismatch-log.jsonl"
EFFECTIVENESS="/Users/roger/.openclaw/workspace/state/walter-correction-effectiveness.json"

TODAY=$(date -u +%Y-%m-%d)
YESTERDAY=$(date -u -v-1d +%Y-%m-%d 2>/dev/null || date -u -d "1 day ago" +%Y-%m-%d)

# Extract today's mismatch count
today_mismatches=$(grep "\"$TODAY" "$MISMATCH_LOG" 2>/dev/null | wc -l | tr -d ' ')
yesterday_mismatches=$(grep "\"$YESTERDAY" "$MISMATCH_LOG" 2>/dev/null | wc -l | tr -d ' ')

# Extract today's corrections completed
today_corrections=$(jq -r ".correctionsCompleted // 0" "$METRICS" 2>/dev/null)

# Extract today's clean vs mismatch cycles
clean_cycles=$(jq -r ".cleanCycles // 0" "$METRICS" 2>/dev/null)
mismatch_cycles=$(jq -r ".mismatchCycles // 0" "$METRICS" 2>/dev/null)
total_cycles=$((clean_cycles + mismatch_cycles))

# Compute mismatch rate
if [ "$total_cycles" -gt 0 ]; then
  mismatch_rate=$(echo "scale=4; $mismatch_cycles * 100 / $total_cycles" | bc)
else
  mismatch_rate="0.0000"
fi

# Get yesterday's mismatch rate for delta
yesterday_rate="N/A"
if [ -f "$EFFECTIVENESS" ]; then
  yesterday_rate=$(jq -r "last | select(.date == \"$YESTERDAY\") | .mismatch_rate // \"N/A\"" "$EFFECTIVENESS" 2>/dev/null)
fi

# Compute delta (only if yesterday rate available)
delta="N/A"
if [ "$yesterday_rate" != "N/A" ] && [ "$yesterday_rate" != "null" ]; then
  delta=$(echo "scale=4; $mismatch_rate - $yesterday_rate" | bc 2>/dev/null || echo "N/A")
fi

# Effectiveness verdict
if [ "$delta" != "N/A" ]; then
  if (( $(echo "$delta < -5" | bc -l 2>/dev/null) )); then
    verdict="IMPROVING"
  elif (( $(echo "$delta > 5" | bc -l 2>/dev/null) )); then
    verdict="DEGRADING"
  else
    verdict="STABLE"
  fi
else
  verdict="BASELINE"
fi

# Build record
record=$(cat <<EOF
{
  "date": "$TODAY",
  "mismatch_rate": $mismatch_rate,
  "mismatch_rate_display": "${mismatch_rate}%",
  "yesterday_rate": ${yesterday_rate:-null},
  "delta_vs_yesterday": ${delta:-null},
  "total_cycles_today": $total_cycles,
  "mismatch_cycles_today": $mismatch_cycles,
  "clean_cycles_today": $clean_cycles,
  "corrections_completed_today": $today_corrections,
  "verdict": "$verdict",
  "computed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
)

# Append to effectiveness log (keep last 30 days)
mkdir -p "$(dirname "$EFFECTIVENESS")"
if [ -f "$EFFECTIVENESS" ]; then
  # Append new record, keep last 30
  jq -c ". + [$record] | .[-30:]" "$EFFECTIVENESS" 2>/dev/null > "${EFFECTIVENESS}.tmp" && mv "${EFFECTIVENESS}.tmp" "$EFFECTIVENESS"
else
  echo "[$record]" > "$EFFECTIVENESS"
fi

# Print summary
echo "=== Correction Effectiveness Summary ($TODAY) ==="
echo "Mismatch rate today: ${mismatch_rate}% ($mismatch_cycles mismatches / $total_cycles cycles)"
echo "Yesterday rate: ${yesterday_rate}% | Delta: ${delta}"
echo "Verdict: $verdict"
echo "Corrections completed today: $today_corrections"
echo "Log: $EFFECTIVENESS"
