#!/bin/bash
# walter-escalation-tracker.sh
# Tracks RCA findings that require Roger action, ages them, and escalates stale ones.
# Walter owns this file. Roger consumes it. No symbolic output.

set -euo pipefail

STATE_DIR="/Users/roger/.openclaw/workspace/state"
ESCALATION_FILE="$STATE_DIR/walter-escalations.json"
RCA_FILE="$STATE_DIR/walter-rca-findings.json"
LOG_FILE="$STATE_DIR/walter-escalation-log.json"

# ── SLA thresholds in hours ─────────────────────────────────────────────────
SLA_P1_HOURS=4
SLA_P2_HOURS=24
SLA_P3_HOURS=72

# ── Load jq if available ────────────────────────────────────────────────────
JQ=$(command -v jq 2>/dev/null || echo "missing")
if [[ "$JQ" == "missing" ]]; then
  echo "ERROR: jq not found. Cannot run escalation tracker."
  exit 1
fi

# ── Helpers ─────────────────────────────────────────────────────────────────
now_iso() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
now_hours() { python3 -c "import time; print(int(time.time() / 3600))"; }

current_hours=$(now_hours)

get_age_hours() {
    local timestamp="$1"
    python3 -c "
import time, sys
ts = '$timestamp'
try:
    # Try ISO format
    t = time.mktime(time.strptime(ts, '%Y-%m-%dT%H:%M:%SZ'))
except:
    try:
        t = time.mktime(time.strptime(ts, '%Y-%m-%dT%H:%M:%S.%fZ'))
    except:
        t = time.mktime(time.strptime(ts[:19], '%Y-%m-%dT%H:%M:%S'))
print(int((time.time() - t) / 3600))
"
}

sla_for_priority() {
    local p="$1"
    case "$p" in
        P1|HIGH) echo "$SLA_P1_HOURS" ;;
        P2|MEDIUM) echo "$SLA_P2_HOURS" ;;
        P3|LOW) echo "$SLA_P3_HOURS" ;;
        *) echo "$SLA_P3_HOURS" ;;
    esac
}

status_for_age() {
    local age="$1"; local sla="$2"
    if [[ "$age" -ge $((sla * 2)) ]]; then echo "critical"
    elif [[ "$age" -ge "$sla" ]]; then echo "overdue"
    elif [[ "$age" -ge $((sla / 2)) ]]; then echo "warning"
    else echo "fresh"
    fi
}

# ── Load existing escalations ────────────────────────────────────────────────
load_escalations() {
    if [[ -f "$ESCALATION_FILE" ]]; then
        python3 -c "
import json, sys
with open('$ESCALATION_FILE') as f:
    d = json.load(f)
print(json.dumps(d))
" 2>/dev/null || echo '{"escalations":[]}'
    else
        echo '{"escalations":[]}'
    fi
}

# ── Sync RCA findings into escalations ─────────────────────────────────────
sync_from_rca() {
    local rca_json="$1"
    local esc_json="$2"

    # For each open RCA finding, check if it needs Roger action
    echo "$rca_json" | python3 -c "
import json, sys, copy

rca = json.load(sys.stdin)
esc_raw = '''$esc_json'''
esc = json.loads(esc_raw) if esc_raw.strip() else {'escalations': []}

esc_by_rca = {e['rca_id']: e for e in esc['escalations']}

# Roger-requires RCA conditions:
# - finding.status == 'open' AND
# - (fix requires config change OR external tool OR manual review OR human decision)
# - specifically: Telegram misconfigs, missing API keys, permission issues,
#   cron job external failures, anything requiring openclaw config or human action

ROGER_REQUIRED_TYPES = [
    'DELIVERY_ERROR',      # needs config change
    'AUTH_ERROR',          # needs credentials
    'PERMISSION_ERROR',     # needs permission grant
    'CONFIG_MISSING',      # needs config
    'MANUAL_REVIEW',       # needs human
    'EXTERNAL_DEPENDENCY', # waiting on external system
]

# Also flag autoFixable: false as Roger-needed (Walter can't fix it)
for finding in rca.get('findings', []):
    fid = finding.get('id', finding.get('jobId', ''))
    # Support both flat dict (keyed by finding_id) and list format
    finding_id = finding.get('id', finding.get('jobId', ''))

    if finding.get('status') not in ('open', None, ''):
        # Remove from escalations if no longer open
        if fid in esc_by_rca:
            esc['escalations'] = [e for e in esc['escalations'] if e.get('rca_id') != fid]
        continue

    ftype = finding.get('failureType', '')
    fix_text = finding.get('fixRecommendation', finding.get('fix', ''))
    auto_fixable = finding.get('autoFixable', True)

    needs_roger = (
        ftype in ROGER_REQUIRED_TYPES or
        not auto_fixable or
        finding.get('requires_roger', False) or
        'configure' in fix_text.lower() or
        'openclaw config' in fix_text.lower() or
        'chatid' in fix_text.lower() or
        'chatid' in str(finding.get('lastError', '')).lower()
    )

    if not needs_roger:
        continue

    rid = fid
    age = float(finding.get('age_hours', 0))
    priority = finding.get('severity', 'P3')
    if priority == 'HIGH': priority = 'P1'
    elif priority == 'MEDIUM': priority = 'P2'
    elif priority == 'LOW': priority = 'P3'

    # Support both RCA formats: flat dict keyed by id, and list
    timestamp = finding.get('timestamp', finding.get('created_at', ''))

    if rid in esc_by_rca:
        # Update existing
        for e in esc['escalations']:
            if e.get('rca_id') == rid:
                e['status'] = finding.get('status', 'open')
                e['age_hours'] = age
                e['last_seen'] = timestamp
                break
    else:
        # New escalation
        new_esc = {
            'rca_id': rid,
            'job_name': finding.get('jobName', finding.get('job_name', 'unknown')),
            'failure_type': ftype,
            'severity': priority,
            'created_at': timestamp,
            'last_seen': timestamp,
            'age_hours': age,
            'status': 'open',
            'fix': fix_text,
            'root_cause': finding.get('root_cause', finding.get('lastError', '')),
            'snoozed_until': None
        }
        esc['escalations'].append(new_esc)

print(json.dumps(esc))
"
}

# ── Age escalations and mark stale ones ─────────────────────────────────────
age_escalations() {
    local esc_json="$1"
    echo "$esc_json" | python3 -c "
import json, sys, copy

esc = json.load(sys.stdin)
now_h = $current_hours

for e in esc.get('escalations', []):
    if e.get('snoozed_until'):
        continue
    created = e.get('created_at', '')
    if not created:
        continue
    try:
        import time
        t = time.mktime(time.strptime(created[:19], '%Y-%m-%dT%H:%M:%S'))
        age = int((time.time() - t) / 3600)
    except:
        age = int(e.get('age_hours', 0)) + 1

    e['age_hours'] = age

    sla = ${SLA_P1_HOURS}
    p = e.get('severity', 'P3')
    if p == 'P1': sla = ${SLA_P1_HOURS}
    elif p == 'P2': sla = ${SLA_P2_HOURS}
    elif p == 'P3': sla = ${SLA_P3_HOURS}

    prev = e.get('escalation_status', 'fresh')
    new_status = 'fresh'
    if age >= sla * 2: new_status = 'critical'
    elif age >= sla:   new_status = 'overdue'
    elif age >= sla / 2: new_status = 'warning'

    e['escalation_status'] = new_status

    # Auto-escalate if critical and not already escalated
    if new_status == 'critical' and e.get('escalation_count', 0) == 0:
        e['escalation_count'] = 1
        e['last_escalated_at'] = '${current_hours}h_unix'
        e['escalation_note'] = f'AUTO: past {sla*2}h SLA (2x threshold) — escalated to Roger'

print(json.dumps(esc))
"
}

# ── Generate readable summary ────────────────────────────────────────────────
generate_summary() {
    local esc_json="$1"
    echo "$esc_json" | python3 -c "
import json, sys

esc = json.load(sys.stdin)
items = esc.get('escalations', [])
open_items = [e for e in items if e.get('status') == 'open' and not e.get('snoozed_until')]
critical = [e for e in open_items if e.get('escalation_status') == 'critical']
overdue  = [e for e in open_items if e.get('escalation_status') == 'overdue']
warning  = [e for e in open_items if e.get('escalation_status') == 'warning']
fresh    = [e for e in open_items if e.get('escalation_status') == 'fresh']

lines = []
lines.append(f'Total open escalations: {len(open_items)}')
if critical: lines.append(f'  !! CRITICAL ({len(critical)}): {[e[\"rca_id\"][:8] for e in critical]}')
if overdue:  lines.append(f'  !! OVERDUE ({len(overdue)}): {[e[\"rca_id\"][:8] for e in overdue]}')
if warning:  lines.append(f'  - WARNING ({len(warning)}): {[e[\"rca_id\"][:8] for e in warning]}')
if fresh:    lines.append(f'  o FRESH ({len(fresh)})')
if not open_items:
    lines.append('  (none — all clear)')

for e in open_items:
    lines.append('')
    lines.append(f'  [{e[\"severity\"]}] {e[\"job_name\"]}')
    lines.append(f'    RCA: {e[\"rca_id\"][:20]}...')
    lines.append(f'    Age: {e[\"age_hours\"]}h | Status: {e[\"escalation_status\"]}')
    lines.append(f'    Fix: {e[\"fix\"][:80]}')

print('\n'.join(lines))
"
}

# ── Write output files ───────────────────────────────────────────────────────
write_escalation_state() {
    local esc_json="$1"
    echo "$esc_json" | python3 -c "
import json, sys
with open('$ESCALATION_FILE', 'w') as f:
    json.dump(json.load(sys.stdin), f, indent=2)
"
}

log_event() {
    local esc_json="$1"
    local event_type="$2"
    echo "$esc_json" | python3 -c "
import json, sys, copy
esc = json.load(sys.stdin)
event = {
    'timestamp': '${current_hours}h_unix',
    'type': '$event_type',
    'open_count': len([e for e in esc.get('escalations',[]) if e.get('status')=='open']),
    'critical_count': len([e for e in esc.get('escalations',[]) if e.get('escalation_status')=='critical'])
}
try:
    with open('$LOG_FILE') as f:
        log = json.load(f)
except:
    log = {'events': []}
log['events'].append(event)
log['events'] = log['events'][-100:]  # keep last 100
with open('$LOG_FILE', 'w') as f:
    json.dump(log, f, indent=2)
"
}

# ── Main ─────────────────────────────────────────────────────────────────────
main() {
    echo "[escalation-tracker] Running at $(now_iso)"

    # 1. Load current escalations
    esc_json=$(load_escalations)

    # 2. Sync from RCA findings
    if [[ -f "$RCA_FILE" ]]; then
        # RCA uses flat dict keyed by finding_id; convert to list format
        rca_json=$(python3 -c "
import json
with open('$RCA_FILE') as f:
    raw = json.load(f)
# Flat dict format: {'finding-id': {...}} → {'findings': [{id, ...fields},]}
if isinstance(raw, dict) and 'findings' not in raw:
    findings = []
    for fid, fdata in raw.items():
        if isinstance(fdata, dict):
            fdata['id'] = fid
            findings.append(fdata)
    print(json.dumps({'findings': findings}))
else:
    print(json.dumps(raw))
" 2>/dev/null || echo '{"findings":[]}')
        esc_json=$(sync_from_rca "$rca_json" "$esc_json")
        echo "[escalation-tracker] Synced from RCA findings"
    fi

    # 3. Age and status update
    esc_json=$(age_escalations "$esc_json")
    echo "[escalation-tracker] Aged escalations"

    # 4. Write state
    write_escalation_state "$esc_json"
    echo "[escalation-tracker] Written to $ESCALATION_FILE"

    # 5. Log event
    log_event "$esc_json" "escalation_check"

    # 6. Print summary for human consumption
    echo ""
    echo "═══ ESCALATION SUMMARY ═══"
    generate_summary "$esc_json"

    # 7. Print Roger action items (if any critical)
    critical=$(echo "$esc_json" | python3 -c "
import json, sys
esc = json.load(sys.stdin)
for e in esc.get('escalations', []):
    if e.get('escalation_status') == 'critical' and e.get('status') == 'open':
        print(f'RogerAction|{e[\"rca_id\"]}|{e[\"job_name\"]}|{e[\"fix\"]}')
" 2>/dev/null)

    if [[ -n "$critical" ]]; then
        echo ""
        echo "═══ CRITICAL — ROGER ACTION REQUIRED ═══"
        echo "$critical"
    fi
}

main
