#!/usr/bin/env bash
# walter-horizon-scanner.sh
# Forecasting layer: predicts which capability gaps are most likely to matter
# in the next 24-48h based on trend analysis, not just historical signals.
# Runs before self-improvement cycle. Updates walter-improvement-priorities.json.
#
# Walter — Internal self-improvement tool
# Stage 5 gap: reactive-only self-improvement → anticipatory self-improvement

set -euo pipefail

STATE_DIR="${STATE_DIR:-$HOME/.openclaw/workspace/state}"
SCRIPT_DIR="${SCRIPT_DIR:-$HOME/.openclaw/workspace/scripts}"

# ── State files ──────────────────────────────────────────────────────────────

RCA_FILE="$STATE_DIR/walter-rca-findings.json"
ESCALATIONS_FILE="$STATE_DIR/walter-escalations.json"
LESSONS_FILE="$STATE_DIR/walter-lessons-learned.json"
CRITIQUE_FILE="$STATE_DIR/walter-critique-accuracy.json"
PRIORITIES_FILE="$STATE_DIR/walter-improvement-priorities.json"
GAP_DB="$STATE_DIR/walter-capability-gaps.json"
LOG_FILE="$STATE_DIR/walter-horizon-log.jsonl"

# ── Load Python json reader (stdlib only, bash 3.2 compatible) ───────────────

python_json() {
    python3 - "$@" <<'PYEOF'
import json, sys
def read_json(path):
    try:
        with open(path) as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return None
action = sys.argv[1]
if action == "read":
    result = read_json(sys.argv[2])
    print(json.dumps(result if result else {}))
elif action == "write":
    data = json.loads(sys.argv[3])
    with open(sys.argv[2], "w") as f:
        json.dump(data, f, indent=2)
PYEOF
}

# ── Timestamps ────────────────────────────────────────────────────────────────

NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
NOW_TS="$(date -u +%s)"

log_event() {
    local level="$1"
    local message="$2"
    local horizon="$3"
    local urgency="$4"
    echo "{\"ts\":\"$NOW\",\"level\":\"$level\",\"message\":\"$message\",\"horizon_hours\":$horizon,\"urgency\":$urgency}" >> "$LOG_FILE"
}

mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

# ── 1. Trend analysis: RCA severity × recency × frequency ─────────────────────

rca_trend_score=0
rca_trend_detail=""

if [[ -f "$RCA_FILE" ]]; then
    RCA_JSON=$(python_json read "$RCA_FILE")
    if [[ -n "$RCA_JSON" && "$RCA_JSON" != "{}" ]]; then
        # Count open HIGH/CRITICAL findings and weight by recency
        SEVERITY_WEIGHT='{"CRITICAL":10,"HIGH":7,"MEDIUM":4,"LOW":1}'
        open_count=$(echo "$RCA_JSON" | python3 - "$SEVERITY_WEIGHT" <<'PYEOF'
import json, sys
data = json.load(sys.stdin)
sev_map = json.loads(sys.argv[1])
score = 0
details = []
for k, v in (data.get("findings", {}) or data.get("rca_findings", {}) or {}).items():
    if isinstance(v, dict) and v.get("status") == "open":
        sev = v.get("severity", "LOW")
        weight = sev_map.get(sev, 1)
        age_str = v.get("timestamp", "")
        # Age recency multiplier
        score += weight * 2  # base weight
        age_h = v.get("age_hours", 0)
        if age_h < 2:
            score += weight  # fresh bonus
        details.append(f"{k[:8]}:{sev}")
print(f"score={score} detail={','.join(details)}")
PYEOF
)
        rca_trend_score=$(echo "$open_count" | sed 's/score=\([0-9]*\).*/\1/')
        rca_trend_detail=$(echo "$open_count" | sed 's/.*detail=\(.*\)/\1/')
        [[ -z "$rca_trend_score" ]] && rca_trend_score=0
    fi
fi

# ── 2. Escalation velocity: how fast are escalations aging? ───────────────────

escalation_velocity=0
escalation_velocity_detail=""

if [[ -f "$ESCALATIONS_FILE" ]]; then
    ESC_JSON=$(python_json read "$ESCALATIONS_FILE")
    if [[ -n "$ESC_JSON" && "$ESC_JSON" != "{}" ]]; then
        escalation_velocity=$(echo "$ESC_JSON" | python3 - <<'PYEOF'
import json, sys
data = json.load(sys.stdin)
stale_count = 0
critical_count = 0
for k, v in (data or {}).items():
    if isinstance(v, dict):
        esc_status = v.get("escalation_status", "")
        if esc_status in ("overdue", "critical"):
            stale_count += 1
        if esc_status == "critical":
            critical_count += 1
# velocity = stale items / total (normalized 0-10)
total = len(data) if data else 1
velocity = min(10, int((stale_count / total) * 10 + critical_count * 2))
print(velocity)
PYEOF
)
        [[ -z "$escalation_velocity" ]] && escalation_velocity=0
    fi
fi

# ── 3. Lessons learned strength × recency ────────────────────────────────────

lesson_urgency=0
lesson_urgency_detail=""

if [[ -f "$LESSONS_FILE" ]]; then
    LESSONS_JSON=$(python_json read "$LESSONS_FILE")
    if [[ -n "$LESSONS_JSON" && "$LESSONS_JSON" != "{}" ]]; then
        lesson_urgency=$(echo "$LESSONS_JSON" | python3 - <<'PYEOF'
import json, sys
data = json.load(sys.stdin)
lessons = data.get("lessons", []) or data.get("entries", []) or []
total_strength = 0
unverified_count = 0
for l in lessons:
    if isinstance(l, dict):
        strength_map = {"very_high": 4, "high": 3, "medium": 2, "low": 1}
        s = strength_map.get(l.get("lesson_strength", "low"), 1)
        total_strength += s
        if l.get("fix_status") not in ("verified", "applied"):
            unverified_count += 1
# High unverified + high strength = active risk area
urgency = min(10, total_strength // 2 + unverified_count)
print(urgency)
PYEOF
)
        [[ -z "$lesson_urgency" ]] && lesson_urgency=0
    fi
fi

# ── 4. Critique accuracy trend ────────────────────────────────────────────────

critique_trend_score=0

if [[ -f "$CRITIQUE_FILE" ]]; then
    CRITIQUE_JSON=$(python_json read "$CRITIQUE_FILE")
    if [[ -n "$CRITIQUE_JSON" && "$CRITIQUE_JSON" != "{}" ]]; then
        critique_trend_score=$(echo "$CRITIQUE_JSON" | python3 - <<'PYEOF'
import json, sys
data = json.load(sys.stdin)
entries = data.get("entries", []) or []
pending = [e for e in entries if isinstance(e, dict) and e.get("outcome") in (None, "pending")]
overdue = [e for e in pending if e.get("verify_after", "") < sys.argv[1]]
# High pending + overdue = critique loop degradation
score = min(10, len(pending) + len(overdue) * 2)
print(score)
PYEOF
"$NOW"
)
        [[ -z "$critique_trend_score" ]] && critique_trend_score=0
    fi
fi

# ── 5. Capability gap severity from gap DB ──────────────────────────────────

gap_urgency=0
top_gap=""
top_gap_severity=0

if [[ -f "$GAP_DB" ]]; then
    GAP_JSON=$(python_json read "$GAP_DB")
    if [[ -n "$GAP_JSON" && "$GAP_JSON" != "{}" ]]; then
        GAP_ANALYSIS=$(echo "$GAP_JSON" | python3 - <<'PYEOF'
import json, sys
data = json.load(sys.stdin)
gaps = data.get("gaps", []) or data.get("work_mode_gaps", []) or []
if not gaps:
    print("gap_score=0 top_gap=none top_gap_severity=0")
else:
    top = sorted(gaps, key=lambda x: x.get("severity_score", 0), reverse=True)[0]
    score = min(10, sum(g.get("severity_score", 0) for g in gaps) // 10)
    print(f"gap_score={score} top_gap={top.get('work_mode','none')} top_gap_severity={top.get('severity_score',0)}")
PYEOF
)
        gap_urgency=$(echo "$GAP_ANALYSIS" | sed 's/gap_score=\([0-9]*\).*/\1/')
        top_gap=$(echo "$GAP_ANALYSIS" | sed 's/.*top_gap=\([^ ]*\).*/\1/')
        top_gap_severity=$(echo "$GAP_ANALYSIS" | sed 's/.*top_gap_severity=\([0-9]*\)/\1/')
        [[ -z "$gap_urgency" ]] && gap_urgency=0
        [[ -z "$top_gap" ]] && top_gap="none"
        [[ -z "$top_gap_severity" ]] && top_gap_severity=0
    fi
fi

# ── 6. Horizon scoring: merge all signals into ranked priorities ──────────────

# urgency: how bad is it NOW (0-10)
# horizon: how likely is it to matter in 24-48h (0-10)

declare -A horizon_scores
declare -A horizon_reasons

# RCA trend → short horizon (issues already present, likely to persist)
horizon_scores["rca-open-findings"]=$(( rca_trend_score > 5 ? 8 : (rca_trend_score > 2 ? 5 : 2) ))
horizon_reasons["rca-open-findings"]="Open RCA findings: ${rca_trend_detail:-no details}"

# Escalation velocity → medium horizon (aging escalations → critical soon)
horizon_scores["escalation-velocity"]=$(( escalation_velocity > 6 ? 9 : (escalation_velocity > 3 ? 6 : 3) ))
horizon_reasons["escalation-velocity"]="Escalation velocity=${escalation_velocity}"

# Lessons → medium horizon (unverified lessons = unvalidated risk patterns)
horizon_scores["lesson-unverified"]=$(( lesson_urgency > 5 ? 7 : (lesson_urgency > 2 ? 4 : 2) ))
horizon_reasons["lesson-unverified"]="Lesson urgency=${lesson_urgency}"

# Critique loop → short horizon (overdue verifications degrade accuracy signal)
horizon_scores["critique-pending"]=$(( critique_trend_score > 3 ? 8 : (critique_trend_score > 1 ? 5 : 2) ))
horizon_reasons["critique-pending"]="Pending critique verifications contributing to score=${critique_trend_score}"

# Capability gap → medium/long horizon (structural, less time-sensitive)
horizon_scores["capability-gap"]=$(( top_gap_severity > 8 ? 7 : (top_gap_severity > 4 ? 5 : 2) ))
horizon_reasons["capability-gap"]="Top capability gap: ${top_gap}"

# Compute overall urgency = weighted combination
# Short-horizon (reactive): rca × 0.35 + escalation × 0.30 + critique × 0.20
# Long-horizon (structural): lesson × 0.15 + cap-gap × 0.20
# But we keep them separate for the priorities list

# Build sorted priorities list
python3 - "${!horizon_scores[@]}" "${horizon_reasons[@]}" <<'PYEOF'
import json, sys
keys = sys.argv[1:]
reasons = {}
i = 1
while i < len(keys):
    reasons[keys[i]] = keys[i+1]
    i += 2

priorities = []
for k in keys:
    if k.startswith("horizon_"):  # skip horizon_ keys
        continue
    # Read scores via env would be complex; instead read from input
    pass

# Read from a simpler input format
scores_raw = sys.stdin.read().strip()
print(scores_raw)
PYEOF

# Actually, use a simpler approach — build JSON directly
PRIORITIES_JSON=$(python3 - <<PYEOF
import json, sys

signals = [
    {
        "id": "rca-open-findings",
        "name": "Open RCA Findings",
        "short_name": "RCA",
        "category": "reactive",
        "urgency": ${rca_trend_score},
        "horizon_score": ${horizon_scores[rca-open-findings]:-3},
        "reason": "${horizon_reasons[rca-open-findings]:-open findings}",
        "timeframe": "0-24h",
        "recommended_action": "Run RCA followup; escalate Roger-actionable items"
    },
    {
        "id": "escalation-velocity",
        "name": "Escalation Velocity",
        "short_name": "ESC",
        "category": "reactive",
        "urgency": ${escalation_velocity},
        "horizon_score": ${horizon_scores[escalation-velocity]:-3},
        "reason": "Escalation velocity=${escalation_velocity}",
        "timeframe": "0-24h",
        "recommended_action": "Review aging escalations; trigger Roger handoff for stale items"
    },
    {
        "id": "lesson-unverified",
        "name": "Unverified Lessons",
        "short_name": "LRN",
        "category": "structural",
        "urgency": ${lesson_urgency},
        "horizon_score": ${horizon_scores[lesson-unverified]:-3},
        "reason": "Unverified lessons = unvalidated risk patterns accumulating",
        "timeframe": "24-72h",
        "recommended_action": "Verify pending lessons; run RCA followup to close loop"
    },
    {
        "id": "critique-pending",
        "name": "Critique Verification Lag",
        "short_name": "CRT",
        "category": "structural",
        "urgency": ${critique_trend_score},
        "horizon_score": ${horizon_scores[critique-pending]:-3},
        "reason": "Overdue critique verifications degrade accuracy signal",
        "timeframe": "0-48h",
        "recommended_action": "Run critique verifier; log overdue outcomes"
    },
    {
        "id": "capability-gap",
        "name": "Capability Gap (Structural)",
        "short_name": "GAP",
        "category": "structural",
        "urgency": ${top_gap_severity},
        "horizon_score": ${horizon_scores[capability-gap]:-3},
        "reason": "Top gap: ${top_gap}",
        "timeframe": "48-168h",
        "recommended_action": "Run capability gap analyzer; prioritize top missing component"
    }
]

# Sort by horizon_score (descending) — what needs attention next
signals_sorted = sorted(signals, key=lambda x: x["horizon_score"], reverse=True)

# Overall horizon = weighted average of top signals
overall_horizon = int(sum(s["horizon_score"] for s in signals_sorted[:3]) / 3)

output = {
    "generated_at": "${NOW}",
    "overall_horizon_score": overall_horizon,
    "forecast_window": "24-48h",
    "signals": signals_sorted,
    "top_priority": signals_sorted[0]["id"] if signals_sorted else None,
    "top_priority_name": signals_sorted[0]["name"] if signals_sorted else None,
    "rally_point": signals_sorted[0]["recommended_action"] if signals_sorted else "No action needed"
}

print(json.dumps(output, indent=2))
PYEOF
)

# ── 7. Write priorities file ──────────────────────────────────────────────────

python_json write "$PRIORITIES_FILE" "$PRIORITIES_JSON"

# ── 8. Log scan ───────────────────────────────────────────────────────────────

log_event "INFO" "Horizon scan complete. Top priority: $(echo "$PRIORITIES_JSON" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(f\"{d[\"top_priority_name\"]} (score={d[\"overall_horizon_score\"]})\")' 2>/dev/null || echo 'unknown')" "$(( $(echo "$PRIORITIES_JSON" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d["overall_horizon_score"])' 2>/dev/null || echo 0) * 6 ))h" 5

# ── 9. Emit readable summary ──────────────────────────────────────────────────

echo "═══════════════════════════════════════════════"
echo "WALTER HORIZON SCAN — $NOW"
echo "═══════════════════════════════════════════════"
echo ""
echo "Forecast window: 24-48h"
echo "Overall horizon score: $(echo "$PRIORITIES_JSON" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d["overall_horizon_score"])' 2>/dev/null || echo '?')/10"
echo ""
echo "Ranked improvement priorities:"
echo "$PRIORITIES_JSON" | python3 -c '
import json, sys
d = json.load(sys.stdin)
for i, s in enumerate(d["signals"], 1):
    horizon_bar = "█" * s["horizon_score"] + "░" * (10 - s["horizon_score"])
    print(f"  {i}. [{s[\"short_name\"]}] {s[\"name\"]}")
    print(f"     Horizon: {horizon_bar} ({s[\"horizon_score\"]}/10) | {s[\"timeframe\"]}")
    print(f"     Reason: {s[\"reason\"]}")
    print(f"     Action: {s[\"recommended_action\"]}")
    print()
' 2>/dev/null || echo "  (priority parsing failed — check $PRIORITIES_FILE)"
echo "═══════════════════════════════════════════════"

echo ""
echo "Priorities written to: $PRIORITIES_FILE"
echo "Scan log: $LOG_FILE"
