#!/bin/bash
# walter-mismatch-detector.sh
# Walter Specialist — runs inside heartbeat cycle
# Enforces the OUTPUT QUALITY GATE that currently exists only in HEARTBEAT.md documentation
# Detects: P1-L avoidance, same-priority-lock, role-mismatch, stale-ready
#
# Produces: structured findings written to state/walter-mismatch-log.jsonl
# Sets: EXIT_CODE 0=clean 1=mismatch-found 2=critical
#
# Usage: bash walter-mismatch-detector.sh [--verbose]
# Runs automatically as part of heartbeat if not called standalone

WORKSPACE="/Users/roger/.openclaw/workspace"
QUEUE_FILE="$WORKSPACE/walter/tasks/QUEUE.md"
HEARTBEAT_OUT="$WORKSPACE/state/walter-heartbeat-output.json"
MISMATCH_LOG="$WORKSPACE/state/walter-mismatch-log.jsonl"
LEARNINGS_FILE="$WORKSPACE/.learnings/LEARNINGS.md"
VERBOSE=false

[[ "${1:-}" == "--verbose" ]] && VERBOSE=true

log_verbose() {
    [[ "$VERBOSE" == "true" ]] && echo "[MISMATCH-DETECTOR] $*"
}

timestamp() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

# ──────────────────────────────────────────────────────────────
# CHECK 1: P1-L Avoidance — P1-L tasks in Ready too long
# Rule: If any P1-L has been Ready > 60 minutes → mismatch
# ───────────────────────────────────────────────────────────────
check_p1l_avoidance() {
    local in_ready=0
    local in_p1=0
    local p1l_found=false
    local p1l_stale=false
    local p1l_title=""
    local p1l_ready_age="" # in minutes if available

    if [[ ! -f "$QUEUE_FILE" ]]; then
        log_verbose "QUEUE_FILE not found: $QUEUE_FILE"
        return 0
    fi

    while IFS= read -r line; do
        # Enter Ready section
        [[ "$line" =~ ^##\ Ready ]] && in_ready=1 && continue
        # Exit Ready section
        [[ "$in_ready" -eq 1 && "$line" =~ ^##\  ]] && in_ready=0 && continue

        # Track P1 subsection
        [[ "$in_ready" -eq 1 && "$line" =~ ^###\ P1 ]] && in_p1=1 && continue
        [[ "$in_ready" -eq 1 && "$line" =~ ^###\ P[02] ]] && in_p1=0 && continue

        # P1-L task detection
        if [[ "$in_ready" -eq 1 && "$in_p1" -eq 1 && "$line" =~ ^###\ P1.*L ]]; then
            p1l_found=true
            continue
        fi

        # P1-L task items
        if [[ "$p1l_found" == "true" && "$line" =~ ^-\ \[\ \] ]]; then
            p1l_title="${line//-[ ] /**}"
            p1l_title="${p1l_title//\*\*/}"
            p1l_title="${p1l_title//\*\*/}"

            # Try to extract age from task metadata
            # Pattern: "Ready: YYYY-MM-DD HH:MM" or "age: Xm" in task body
            local age_minutes=""
            if [[ "$line" =~ age:\ ([0-9]+)m ]]; then
                age_minutes="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ Ready:\ ([0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}) ]]; then
                local ready_time="${BASH_REMATCH[1]}"
                # rough minutes since ready time
                local ready_ts
                ready_ts=$(date -j -f "%Y-%m-%d %H:%M" "$ready_time" +%s 2>/dev/null) || ready_ts=0
                local now_ts
                now_ts=$(date +%s)
                age_minutes=$(( (now_ts - ready_ts) / 60 ))
            fi

            if [[ -n "$age_minutes" && "$age_minutes" -gt 60 ]]; then
                p1l_stale=true
            elif [[ -n "$age_minutes" ]]; then
                log_verbose "P1-L '$p1l_title' Ready for ${age_minutes}m (threshold: 60m)"
            else
                # No timestamp available — flag for manual review
                p1l_stale=true
                p1l_ready_age="unknown (no timestamp)"
            fi

            # Reset for next task
            p1l_found=false
        fi
    done < "$QUEUE_FILE"

    if [[ "$p1l_stale" == "true" ]]; then
        echo "MISMATCH|P1-L-AVOIDANCE|P1-L task stale/aged without being selected: '$p1l_title' (${p1l_ready_age:-age unknown})"
        return 1
    fi

    log_verbose "CHECK 1 PASS: No P1-L avoidance detected"
    return 0
}

# ──────────────────────────────────────────────────────────────
# CHECK 2: Same-Priority Lock — same P1 tier selected 3+ cycles
# Rule: If last 3 heartbeat selections were all P1-S or all P1-M → lock pattern
# ───────────────────────────────────────────────────────────────
check_same_priority_lock() {
    local last_selections=()
    local i=0

    # Read last heartbeat outputs (up to 5 most recent)
    for logfile in $(ls -t "$WORKSPACE/state"/walter-heartbeat-output.json 2>/dev/null | head -5); do
        local sel
        sel=$(grep -o '"priority"[[:space:]]*:[[:space:]]*"[^"]*"' "$logfile" 2>/dev/null | head -1 | grep -o '"[^"]*"$' | tr -d '"')
        [[ -n "$sel" ]] && last_selections+=("$sel")
    done

    # If fewer than 3 selections, no lock possible
    if [[ ${#last_selections[@]} -lt 3 ]]; then
        log_verbose "CHECK 2 PASS: Only ${#last_selections[@]} selections in history"
        return 0
    fi

    local first="${last_selections[0]}"
    local all_same=true
    for sel in "${last_selections[@]}"; do
        [[ "$sel" == "$first" ]] || { all_same=false; break; }
    done

    if [[ "$all_same" == "true" && "$first" =~ ^P1- ]]; then
        echo "MISMATCH|SAME-PRIORITY-LOCK|Selected $first 3+ consecutive cycles: ${last_selections[*]}"
        return 1
    fi

    log_verbose "CHECK 2 PASS: Priority rotation healthy (${last_selections[*]})"
    return 0
}

# ──────────────────────────────────────────────────────────────
# CHECK 3: Role Alignment — was the selected task Walter-appropriate?
# Walter's role: architecture distillation, gap analysis, research synthesis
# NOT: routine task completion, operational monitoring, Roger-support busywork
# ───────────────────────────────────────────────────────────────
check_role_alignment() {
    if [[ ! -f "$HEARTBEAT_OUT" ]]; then
        log_verbose "CHECK 3 SKIP: No heartbeat output found"
        return 0
    fi

    local selected_task
    selected_task=$(grep -o '"directive"[[:space:]]*:[[:space:]]*"[^"]*"' "$HEARTBEAT_OUT" 2>/dev/null | head -1 | sed 's/.*directive"[[:space:]]*:[[:space:]]*"//' | tr -d '"')

    if [[ -z "$selected_task" || "$selected_task" == "No Ready tasks available" ]]; then
        return 0
    fi

    # Task keywords that suggest MISALIGNMENT with Walter's distillation role
    local misalignment_patterns=(
        "deploy" "monitor" "check" "update status" "routine" "operational"
        "send to" "notify" "remind" "bookkeeping" "log only"
    )

    # Task keywords that suggest ALIGNMENT with Walter's role
    local alignment_patterns=(
        "analyze" "research" "architect" "distill" "synthesize" "evaluate"
        "assess" "map" "protocol" "gap" "strategy" "framework" "pattern"
    )

    local is_misaligned=false
    local is_aligned=false

    for pattern in "${misalignment_patterns[@]}"; do
        if [[ "$selected_task" =~ ${pattern} ]]; then
            is_misaligned=true
            break
        fi
    done

    for pattern in "${alignment_patterns[@]}"; do
        if [[ "$selected_task" =~ ${pattern} ]]; then
            is_aligned=true
            break
        fi
    done

    if [[ "$is_misaligned" == "true" && "$is_aligned" == "false" ]]; then
        echo "MISMATCH|ROLE-MISALIGN|Walter selected task outside distillation role: '$selected_task'"
        return 1
    fi

    log_verbose "CHECK 3 PASS: Task '$selected_task' aligned with distillation role"
    return 0
}

# ──────────────────────────────────────────────────────────────
# CHECK 4: Stale Ready — any task Ready > 2 hours without being touched
# ───────────────────────────────────────────────────────────────
check_stale_ready() {
    if [[ ! -f "$QUEUE_FILE" ]]; then
        return 0
    fi

    # Simple heuristic: count tasks in Ready section
    local ready_count
    ready_count=$(grep -c '^\- \[ \]' "$QUEUE_FILE" 2>/dev/null || echo 0)

    # If 8+ tasks have been Ready for a while (we can't easily get timestamps without them)
    # flag for manual review - this is a rough heuristic
    if [[ "$ready_count" -ge 8 ]]; then
        echo "MISMATCH|STALE-READY|Queue has $ready_count Ready items — possible backlog accumulation"
        return 1
    fi

    return 0
}

# ──────────────────────────────────────────────────────────────
# LOGGING: Write mismatch to jsonl + promote to LEARNINGS.md if needed
# ───────────────────────────────────────────────────────────────
log_mismatch() {
    local severity="$1"
    local category="$2"
    local detail="$3"
    local ts
    ts=$(timestamp)

    # Write to mismatch log
    cat >> "$MISMATCH_LOG" << EOF
{"timestamp":"$ts","severity":"$severity","category":"$category","detail":"$detail","beat":"$(hostname -s)"}
EOF

    log_verbose "LOGGED: [$severity] $category — $detail"

    # If SEVERITY=CRITICAL → write to LEARNINGS.md
    if [[ "$severity" == "CRITICAL" ]]; then
        local lrn_id
        lrn_id="LRN-$(date +%Y%m%d)-$(date +%H%M%S)"
        cat >> "$LEARNINGS_FILE" << EOF

## $lrn_id $(timestamp)

**Type:** weakness
**Category:** output-quality
**Severity:** critical
**Pattern-Key:** P1-L-avoidance-pattern
**Recurrence-Count:** 1
**Status:** active

### Observation
$detail

### Root Cause
Heartbeat executor selects purely by priority/effort order without avoidance detection.
Quality gate in HEARTBEAT.md exists in documentation but not in the execution script.

### Concrete Change Required
walter-mismatch-detector.sh must be integrated as Step 2.5 in heartbeat-executor.sh
before task selection occurs. P1-L age must be tracked with timestamps in QUEUE.md.

### Follow-up
- [ ] Integrate mismatch-detector into heartbeat-executor.sh
- [ ] Add Ready timestamp tracking to QUEUE.md task format
- [ ] Verify quality gate fires before next P1-M task is selected
EOF
        log_verbose "PROMOTED to LEARNINGS.md as $lrn_id"
    fi
}

# ──────────────────────────────────────────────────────────────
# MAIN — run all checks
# ───────────────────────────────────────────────────────────────
main() {
    log_verbose "=== Walter Mismatch Detector ==="

    local exit_code=0
    local mismatch_found=false

    # CHECK 1: P1-L Avoidance
    local result1
    if ! result1=$(check_p1l_avoidance); then
        mismatch_found=true
        log_mismatch "WARNING" "P1-L-AVOIDANCE" "$result1"
        exit_code=1
    fi

    # CHECK 2: Same-Priority Lock
    local result2
    if ! result2=$(check_same_priority_lock); then
        mismatch_found=true
        log_mismatch "WARNING" "SAME-PRIORITY-LOCK" "$result2"
        exit_code=1
    fi

    # CHECK 3: Role Alignment
    local result3
    if ! result3=$(check_role_alignment); then
        mismatch_found=true
        log_mismatch "WARNING" "ROLE-MISALIGN" "$result3"
        exit_code=1
    fi

    # CHECK 4: Stale Ready
    local result4
    if ! result4=$(check_stale_ready); then
        mismatch_found=true
        log_mismatch "INFO" "STALE-READY" "$result4"
        exit_code=1
    fi

    if [[ "$mismatch_found" == "false" ]]; then
        log_verbose "=== All checks PASSED — heartbeat cycle clean ==="
    else
        log_verbose "=== MIS_MATCH DETECTED — quality gate triggered ==="
    fi

    # Output structured summary for piping to heartbeat
    local summary
    summary=$(cat << EOF
{"timestamp":"$(timestamp)","status":"$([ "$mismatch_found" == "false" ] && echo "clean" || echo "mismatch")","exit_code":$exit_code}
EOF
)
    echo "$summary"
    return $exit_code
}

main "$@"
