#!/bin/bash
# walter-critique-logger.sh
# Logs Walter critiques and predictions for accuracy tracking
# Builds the feedback loop: log → verify → score
#
# Usage:
#   ./walter-critique-logger.sh --critique "Text of the critique/prediction" \
#     --context "what was being critiqued" \
#     [--verify-days 7] \
#     [--confidence 3] \
#     [--type prediction|critique|gap-assessment|architecture-review]
#
#   Or pipe JSON to stdin:
#   echo '{"critique":"...","context":"...","confidence":3}' | ./walter-critique-logger.sh
#
# Output: UUID of logged entry, written to critique-accuracy.json

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/../state/walter-critique-accuracy.json"
MAX_VERIFY_DAYS=90

LESSONS_FILE="${SCRIPT_DIR}/../state/walter-lessons-learned.json"
CHECK_LESSONS=false

# Defaults
CRITIQUE=""
CONTEXT=""
VERIFY_DAYS=7
CONFIDENCE=3
ENTRY_TYPE="critique"
MODE="add"

usage() {
    cat <<EOF
walter-critique-logger.sh — Log Walter critiques and predictions for accuracy tracking

USAGE:
    ./walter-critique-logger.sh [options]
    echo '{"critique":"...", "context":"...", "verify_days":7}' | ./walter-critique-logger.sh

OPTIONS:
    --critique <text>     The critique or prediction (required in add mode)
    --context <text>     What was being analyzed/critiqued (required in add mode)
    --verify-days <N>    Days until verification (default: 7, max: 90)
    --confidence <1-5>   Confidence level 1=low 5=high (default: 3)
    --type <type>        critique|prediction|gap-assessment|architecture-review (default: critique)
    --check-lessons      Search lessons-learned for relevant past lessons before logging
    --verify <id>        Verify an existing entry: --verify <id> --outcome correct|incorrect|partial
    --outcome <val>      Outcome for verification: correct|incorrect|partial
    --list               List all entries without modification
    --pending            List pending verifications
    --stats              Show accuracy statistics
    --help               Show this help

EXAMPLES:
    # Log a critique about a proposed build
    ./walter-critique-logger.sh \
      --critique "This duplicates existing X protocol — not a real gap" \
      --context "proposal: yield-aggregator-v2" \
      --type gap-assessment \
      --confidence 4

    # Log a prediction
    ./walter-critique-logger.sh \
      --critique "Stage mismatch between Walter and Roger will cause duplicate work" \
      --context "base_account_miniapp_probe workflow" \
      --type prediction \
      --verify-days 3

    # Verify an entry
    ./walter-critique-logger.sh --verify abc123 --outcome correct

    # Show pending verifications
    ./walter-critique-logger.sh --pending

    # Pipe JSON from another script
    echo '{"critique":"Text","context":"ctx","confidence":4}' | ./walter-critique-logger.sh
EOF
}

init_log() {
    if [ ! -f "$LOG_FILE" ]; then
        cat > "$LOG_FILE" <<'EOF'
{
  "version": "1.1",
  "created_at": "2026-03-19T11:25:00Z",
  "description": "Walter critique and prediction accuracy tracker",
  "critiques": [],
  "schema": {
    "id": "uuid",
    "type": "critique|prediction|gap-assessment|architecture-review",
    "logged_at": "ISO timestamp",
    "critique": "text of the critique or prediction",
    "context": "what was being analyzed",
    "confidence": "1-5 confidence at time of logging",
    "verify_after": "ISO timestamp — when to verify",
    "status": "pending|verified",
    "outcome": "correct|incorrect|partial|null",
    "verified_at": "ISO timestamp",
    "verified_by": "manual|cron|script",
    "notes": "optional post-verify notes"
  }
}
EOF
    fi
}

uuidgen() {
    if command -v uuidgen &>/dev/null; then
        uuidgen | tr '[:upper:]' '[:lower:]'
    else
        # Fallback: timestamp + random
        echo "$(date +%s)-$((RANDOM * RANDOM))"
    fi
}

json_escape() {
    printf '%s' "$1" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))' 2>/dev/null || \
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\n/\\n/g'
}

check_lessons_before_log() {
    # Searches lessons-learned for relevant entries based on critique/context keywords
    # Surfaces matches inline — critique still logs regardless
    local critique="$1"
    local context="$2"

    if [[ ! -f "$LESSONS_FILE" ]]; then
        return 1
    fi

    python3 "${SCRIPT_DIR}/walter-lessons-check.py" "$critique" "$context" "$LESSONS_FILE" 2>/dev/null && return 0
    return 1
}

log_entry() {
    local id="$1"
    local critique="$2"
    local context="$3"
    local verify_days="$4"
    local confidence="$5"
    local entry_type="$6"

    local logged_at now verify_after
    logged_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    verify_after=$(date -u -d "+${verify_days} days" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || \
                   date -u -v+${verify_days}d +%Y-%m-%dT%H:%M:%SZ)

    local escaped_critique escaped_context
    escaped_critique=$(json_escape "$critique")
    escaped_context=$(json_escape "$context")

    python3 <<EOF
import json

log_file = "$LOG_FILE"
with open(log_file, 'r') as f:
    data = json.load(f)

new_entry = {
    "id": "$id",
    "type": "$entry_type",
    "logged_at": "$logged_at",
    "critique": $escaped_critique,
    "context": $escaped_context,
    "confidence": $confidence,
    "verify_after": "$verify_after",
    "status": "pending",
    "outcome": None,
    "verified_at": None,
    "verified_by": None,
    "notes": None
}

data["critiques"].append(new_entry)
data["last_updated"] = "$logged_at"

with open(log_file, 'w') as f:
    json.dump(data, f, indent=2)

print(f"Logged: {new_entry['id']} (verify_after: $verify_after)")
EOF
}

verify_entry() {
    local id="$1"
    local outcome="$2"

    local verified_at
    verified_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    # Extract entry info before verification for vault capture
    local entry_critique entry_context entry_type entry_conf
    entry_critique=$(python3 -c "
import json
with open('$LOG_FILE') as f:
    data = json.load(f)
for e in data['critiques']:
    if e['id'] == '$id':
        print(e.get('critique','')[:200])
        break
" 2>/dev/null || echo "")
    entry_context=$(python3 -c "
import json
with open('$LOG_FILE') as f:
    data = json.load(f)
for e in data['critiques']:
    if e['id'] == '$id':
        print(e.get('context','')[:200])
        break
" 2>/dev/null || echo "")
    entry_type=$(python3 -c "
import json
with open('$LOG_FILE') as f:
    data = json.load(f)
for e in data['critiques']:
    if e['id'] == '$id':
        print(e.get('type','critique'))
        break
" 2>/dev/null || echo "critique")

    python3 <<EOF
import json

log_file = "$LOG_FILE"
with open(log_file, 'r') as f:
    data = json.load(f)

entry = None
for e in data["critiques"]:
    if e["id"] == "$id":
        entry = e
        break

if entry is None:
    print(f"ERROR: Entry '$id' not found")
    exit(1)

entry["status"] = "verified"
entry["outcome"] = "$outcome"
entry["verified_at"] = "$verified_at"
entry["verified_by"] = "manual"

# Recalculate stats
total = len(data["critiques"])
correct = sum(1 for e in data["critiques"] if e["outcome"] == "correct")
incorrect = sum(1 for e in data["critiques"] if e["outcome"] == "incorrect")
partial = sum(1 for e in data["critiques"] if e["outcome"] == "partial")
pending = sum(1 for e in data["critiques"] if e["status"] == "pending")

data["stats"] = {
    "total_predictions": total,
    "verified_correct": correct,
    "verified_incorrect": incorrect,
    "verified_partial": partial,
    "pending": pending,
    "accuracy_pct": round(correct / max(correct + incorrect, 1) * 100, 1) if (correct + incorrect) > 0 else None
}

with open(log_file, 'w') as f:
    json.dump(data, f, indent=2)

print(f"Verified '$id' as $outcome (accuracy: {data['stats']['accuracy_pct']}%)")
EOF

    # Capture verified outcome to ClawVault
    if [[ -n "$entry_critique" ]]; then
        local vault_category="critiques"
        local vault_note="[critique-verify] outcome=$outcome type=$entry_type | critique: ${entry_critique:0:150} | context: ${entry_context:0:150}"
        clawvault capture "$vault_note" --category "$vault_category" 2>/dev/null || true
    fi
}

list_entries() {
    python3 <<EOF
import json
import sys
from datetime import datetime, timezone

log_file = "$LOG_FILE"
with open(log_file, 'r') as f:
    data = json.load(f)

print(f"=== Walter Critique Accuracy Log ===")
print(f"Total entries: {len(data['critiques'])}")
print()

now = datetime.now(timezone.utc)

for e in sorted(data["critiques"], key=lambda x: x.get("logged_at",""), reverse=True):
    ts_str = e.get("logged_at","")
    ts = datetime.fromisoformat(ts_str.replace("Z","+00:00")) if ts_str else now
    age = (now - ts).days

    status_icon = {"pending": "⏳", "verified": "✓"}.get(e.get("status",""), "?")
    outcome_icon = {"correct": "✅", "incorrect": "❌", "partial": "⚠️"}.get(e.get("outcome","") or "", "")

    verify_info = f"-> verify after {e.get('verify_after','')[:10]}"
    if e["status"] == "verified":
        verify_info = f"-> verified {str(e.get('verified_at',''))[:10]} as {e.get('outcome','')}"

    conf = e.get("confidence", e.get("conf", 3))
    confidence_bar = "★" * conf + "☆" * (5 - conf)

    entry_type = e.get("type", e.get("prediction","critique")[:4])
    crit_text = e.get("critique", e.get("prediction",""))
    ctx_text = e.get("context","")

    print(f"{status_icon} [{entry_type[:4]}] {e['id'][:8]} | conf:{confidence_bar} | {age}d ago | {verify_info}")
    print(f"   critique: {crit_text[:80]}{'...' if len(crit_text) > 80 else ''}")
    print(f"   context:  {ctx_text[:80]}{'...' if len(ctx_text) > 80 else ''}")
    if outcome_icon:
        print(f"   {outcome_icon}")
    print()
EOF
}

show_pending() {
    python3 <<EOF
import json
from datetime import datetime, timezone

log_file = "$LOG_FILE"
with open(log_file, 'r') as f:
    data = json.load(f)

now = datetime.now(timezone.utc)
pending = [e for e in data["critiques"] if e.get("status") == "pending"]

if not pending:
    print("No pending verifications.")
    exit(0)

print(f"=== {len(pending)} Pending Verifications ===\n")
for e in sorted(pending, key=lambda x: x.get("verify_after","")):
    verify_str = e.get("verify_after","")
    if not verify_str:
        continue
    verify_date = datetime.fromisoformat(verify_str.replace("Z", "+00:00"))
    days_until = (verify_date - now).days
    overdue = days_until < 0

    marker = "🔴 OVERDUE" if overdue else f"due in {days_until}d"
    crit_text = e.get("critique", e.get("prediction",""))
    ctx_text = e.get("context","")
    print(f"[{marker}] {e['id'][:8]} -- {ctx_text}")
    print(f"   {crit_text[:90]}")
    print()
EOF
}

show_stats() {
    python3 <<EOF
import json

log_file = "$LOG_FILE"
with open(log_file, 'r') as f:
    data = json.load(f)

critiques = data.get("critiques", [])
total = len(critiques)
pending = sum(1 for e in critiques if e.get("status") == "pending")
verified = [e for e in critiques if e.get("status") == "verified"]

print(f"=== Walter Accuracy Stats ===")
print(f"Total entries:  {total}")
print(f"Pending:        {pending}")
print(f"Verified:       {len(verified)}")
print()

if verified:
    correct = sum(1 for e in verified if e.get("outcome") == "correct")
    incorrect = sum(1 for e in verified if e.get("outcome") == "incorrect")
    partial = sum(1 for e in verified if e.get("outcome") == "partial")
    total_verified = correct + incorrect

    print(f"  ✅ Correct:   {correct}")
    print(f"  ❌ Incorrect: {incorrect}")
    print(f"  ⚠️  Partial:  {partial}")
    print()

    if total_verified > 0:
        accuracy = correct / total_verified * 100
        print(f"  Accuracy:     {accuracy:.1f}% ({correct}/{total_verified} verified)")
        print()

    # By type
    print("  By type:")
    for t in ["critique", "prediction", "gap-assessment", "architecture-review"]:
        entries = [e for e in verified if e.get("type") == t]
        if entries:
            c = sum(1 for e in entries if e.get("outcome") == "correct")
            acc = c / len(entries) * 100 if len(entries) > 0 else 0
            print(f"    {t}: {acc:.0f}% accuracy ({c}/{len(entries)})")

    print()
    # By confidence level
    print("  Accuracy by confidence level:")
    for conf in [1, 2, 3, 4, 5]:
        entries = [e for e in verified if e.get("confidence", e.get("conf", 3)) == conf]
        if entries:
            c = sum(1 for e in entries if e.get("outcome") == "correct")
            acc = c / len(entries) * 100
            bar = "█" * int(acc / 10) + "░" * (10 - int(acc / 10))
            print(f"    conf {conf}: {acc:5.1f}% {bar} ({c}/{len(entries)})")
else:
    print("  No verified entries yet -- start logging critiques!")
    print(f"  Run: walter-critique-logger.sh --critique '...' --context '...'")
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --critique) CRITIQUE="$2"; shift 2 ;;
        --context) CONTEXT="$2"; shift 2 ;;
        --verify-days) VERIFY_DAYS="$2"; shift 2 ;;
        --confidence) CONFIDENCE="$2"; shift 2 ;;
        --type) ENTRY_TYPE="$2"; shift 2 ;;
        --verify) MODE="verify"; VERIFY_ID="$2"; shift 2 ;;
        --outcome) OUTCOME="$2"; shift 2 ;;
        --list) MODE="list"; shift ;;
        --pending) MODE="pending"; shift ;;
        --stats) MODE="stats"; shift ;;
        --check-lessons) CHECK_LESSONS=true; shift ;;
        --help) usage; exit 0 ;;
        *) echo "Unknown: $1"; usage; exit 1 ;;
    esac
done

# Validate
case "$MODE" in
    add)
        if [ -z "$CRITIQUE" ] || [ -z "$CONTEXT" ]; then
            echo "ERROR: --critique and --context required in add mode"
            usage
            exit 1
        fi
        if [ "$CONFIDENCE" -lt 1 ] || [ "$CONFIDENCE" -gt 5 ]; then
            echo "ERROR: --confidence must be 1-5"
            exit 1
        fi
        if [ "$VERIFY_DAYS" -lt 1 ] || [ "$VERIFY_DAYS" -gt "$MAX_VERIFY_DAYS" ]; then
            echo "ERROR: --verify-days must be 1-$MAX_VERIFY_DAYS"
            exit 1
        fi
        if [[ ! "$ENTRY_TYPE" =~ ^(critique|prediction|gap-assessment|architecture-review)$ ]]; then
            echo "ERROR: --type must be critique|prediction|gap-assessment|architecture-review"
            exit 1
        fi
        ;;
    verify)
        if [ -z "${VERIFY_ID:-}" ] || [ -z "${OUTCOME:-}" ]; then
            echo "ERROR: --verify <id> --outcome <correct|incorrect|partial> required"
            exit 1
        fi
        if [[ ! "$OUTCOME" =~ ^(correct|incorrect|partial)$ ]]; then
            echo "ERROR: --outcome must be correct|incorrect|partial"
            exit 1
        fi
        ;;
esac

# Execute
init_log

case "$MODE" in
    add)
        # Pre-log lesson check: surface relevant past lessons before logging new critique
        if [[ "$CHECK_LESSONS" == "true" ]] || [[ -f "$LESSONS_FILE" ]]; then
            check_lessons_before_log "$CRITIQUE" "$CONTEXT" || true
        fi
        id=$(uuidgen)
        log_entry "$id" "$CRITIQUE" "$CONTEXT" "$VERIFY_DAYS" "$CONFIDENCE" "$ENTRY_TYPE"
        ;;
    verify)
        verify_entry "$VERIFY_ID" "$OUTCOME"
        ;;
    list)
        list_entries
        ;;
    pending)
        show_pending
        ;;
    stats)
        show_stats
        ;;
esac
