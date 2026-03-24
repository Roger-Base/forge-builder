#!/bin/bash
# walter-lessons-from-rca.sh - Create or update a lesson from the most recent RCA finding
# Part of Walter's lessons-learned system
# Called after RCA is complete to convert the finding into a durable lesson

RCA_FILE="$HOME/.openclaw/workspace/state/walter-rca-findings.json"
LESSONS_FILE="$HOME/.openclaw/workspace/state/walter-lessons-learned.json"
LOG_FILE="$HOME/.openclaw/workspace/state/walter-lesson-creation.log"

echo "=============================================="
echo " WALTER LESSONS FROM RCA — $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "=============================================="
echo ""

# Check prerequisites
if [[ ! -f "$RCA_FILE" ]]; then
  echo "No RCA file found at $RCA_FILE — nothing to learn from"
  exit 0
fi

if [[ ! -f "$LESSONS_FILE" ]]; then
  echo "ERROR: Lessons file not found at $LESSONS_FILE"
  exit 1
fi

# Get most recent open RCA finding
open_findings=$(jq 'to_entries | map(select(.value.status == "open"))' "$RCA_FILE" 2>/dev/null)
count=$(echo "$open_findings" | jq 'length')

if [[ "$count" -eq 0 ]]; then
  echo "No open RCA findings — nothing to process"
  echo "All findings are closed. Nothing to learn from right now."
  exit 0
fi

echo "Found $count open RCA finding(s)"
echo ""

# Get most recent (last in the file, highest timestamp)
latest_key=$(echo "$open_findings" | jq -r 'sort_by(.value.timestamp) | last | .key')
latest=$(jq ".[\"$latest_key\"]" "$RCA_FILE")

rca_id=$(echo "$latest" | jq -r '.jobId // .rca_id // empty')
job_name=$(echo "$latest" | jq -r '.jobName // empty')
failure_type=$(echo "$latest" | jq -r '.failureType // .failure_type // empty')
severity=$(echo "$latest" | jq -r '.severity // empty')
auto_fixable=$(echo "$latest" | jq -r '.autoFixable // .auto_fixable // "unknown"')
fix=$(echo "$latest" | jq -r '.fixRecommendation // .fix // .root_cause // "not documented"')
timestamp=$(echo "$latest" | jq -r '.timestamp // .created_at // empty')
root_cause=$(echo "$latest" | jq -r '.rootCause // .root_cause // empty')

echo "Processing: $rca_id"
echo "  Job: $job_name"
echo "  Failure: $failure_type"
echo "  Severity: $severity"
echo "  AutoFixable: $auto_fixable"
echo ""

# Check if lesson already exists for this RCA
existing=$(jq ".lessons[] | select(.rca_id == \"$rca_id\") | .lesson_id" "$LESSONS_FILE" 2>/dev/null | head -1)
if [[ -n "$existing" && "$existing" != "null" ]]; then
  echo "[SKIP] Lesson already exists for this RCA: $existing"
  echo "  Use walter-lessons-update.sh to update existing lesson"
  exit 0
fi

# Determine failure context from failure_type
failure_context="unknown"
case "$failure_type" in
  DELIVERY_ERROR)  failure_context="cron_job_delivery" ;;
  AUTH_ERROR)      failure_context="auth_credentials" ;;
  CONFIG_MISSING)  failure_context="config_missing" ;;
  TIMEOUT_ERROR)   failure_context="timeout" ;;
  PERMISSION_ERROR) failure_context="permission" ;;
  BUILD_DECISION)  failure_context="build_decision" ;;
  *)               failure_context="general" ;;
esac

# Determine lesson strength
if [[ "$occurrence_count" -ge 3 ]]; then
  lesson_strength="very_high"
elif [[ "$occurrence_count" -ge 1 ]]; then
  lesson_strength="high"
else
  lesson_strength="medium"
fi

# Determine if auto_fix_candidate
if [[ "$auto_fixable" == "true" ]]; then
  auto_fix_candidate="true"
  fix_status="auto_fix_applied"
else
  auto_fix_candidate="false"
  fix_status="pending_roger_action"
fi

# Determine outcome summary
if [[ "$auto_fixable" == "true" ]]; then
  outcome_summary="Problem was auto-fixable. Script corrected the issue automatically."
else
  outcome_summary="AutoFixable=false. Problem is diagnosed but requires human/config action. Script itself is healthy."
fi

# Generate lesson_id
lesson_id="LRN-$(date -u +%Y%m%d)-$(echo $rca_id | cut -c1-8)"

# Build prevention actions based on failure type
prevention_actions="[]"
case "$failure_type" in
  DELIVERY_ERROR)
    prevention_actions='["Verify cron delivery config before enabling a new cron job","When creating a new cron job that delivers to chat, pre-configure the delivery target"]'
    ;;
  TIMEOUT_ERROR)
    prevention_actions='["Check expected runtime before scheduling","Increase timeout or split job into smaller units"]'
    ;;
  AUTH_ERROR)
    prevention_actions='["Verify credentials validity before job enable","Use token refresh mechanism for long-running jobs"]'
    ;;
  CONFIG_MISSING)
    prevention_actions='["Validate all required config present before job start","Add config bootstrap step"]'
    ;;
  *)
    prevention_actions='["Log symptom and root cause for future reference","Evaluate if automation can prevent recurrence"]'
    ;;
esac

# Build the lesson text from the fix
lesson_text="Failure: $failure_type on job '$job_name'. Root cause: ${root_cause:-not documented}. Fix: ${fix}. Prevention: see tag_index for specific actions."

# Use Python to do the JSON surgery cleanly
python3 << PYEOF
import json, sys, subprocess
from datetime import datetime

LESSONS_FILE = "$LESSONS_FILE"
lesson_id = "$lesson_id"
rca_id = "$rca_id"
failure_type = "$failure_type"
failure_context = "$failure_context"
job_name = "$job_name"
severity = "$severity"
auto_fixable = "$auto_fixable"
auto_fix_candidate = json.loads("$auto_fix_candidate".lower())
fix = """$fix""".strip()
fix_status = "$fix_status"
outcome_summary = "$outcome_summary"
root_cause = """$root_cause""".strip()
timestamp = "$timestamp"
lesson_text = """$lesson_text""".strip()
prevention_actions = json.loads("""$prevention_actions""")

lesson_strength = "high"  # default for new lessons
occurrence_count = 1

# Determine tags from failure type
tags = []
if failure_type:
    tags.append(failure_type.lower())
tags.extend([failure_context, severity.lower() if severity else "unknown"])
if not auto_fixable:
    tags.append("roger_action_required")
tags = list(set(tags))

new_lesson = {
    "lesson_id": lesson_id,
    "failure_type": failure_type,
    "failure_context": failure_context,
    "symptom": f"{failure_type} on job '{job_name}'",
    "rca_id": rca_id,
    "root_cause": root_cause if root_cause else "under investigation",
    "fix_applied": fix,
    "fix_status": fix_status,
    "outcome_summary": outcome_summary,
    "tags": tags,
    "auto_fix_candidate": auto_fix_candidate,
    "prevented_recurrence_actions": prevention_actions,
    "first_occurred": timestamp,
    "last_occurred": timestamp,
    "occurrence_count": occurrence_count,
    "lesson_strength": lesson_strength,
    "lesson_text": lesson_text
}

with open(LESSONS_FILE, 'r') as f:
    data = json.load(f)

# Append lesson
data["lessons"].append(new_lesson)
data["total_lessons"] = len(data["lessons"])
data["updated_at"] = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")

# Update tag index
for tag in tags:
    if tag not in data["tag_index"]:
        data["tag_index"][tag] = []
    if lesson_id not in data["tag_index"][tag]:
        data["tag_index"][tag].append(lesson_id)

with open(LESSONS_FILE, 'w') as f:
    json.dump(data, f, indent=2)

print(f"SUCCESS: Created lesson {lesson_id}")
print(f"  Failure: {failure_type} / {failure_context}")
print(f"  Tags: {', '.join(tags)}")
print(f"  Fix status: {fix_status}")
print(f"  File: {LESSONS_FILE}")
PYEOF

exit $?
