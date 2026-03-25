#!/bin/bash
# walter-rca-followup.sh
# Verifies fixes for open RCA findings.
# Uses Python for robust JSON handling (avoids macOS date/jq compatibility issues).
#
# SLA: HIGH = 4h, MEDIUM = 24h, LOW = 72h
# Escalation: if open past SLA → writes to walter-rca-escalations.log
# Resolution: if fix confirmed (job healthy + last run success) → marks resolved

WORKSPACE="${WORKSPACE:-/Users/roger/.openclaw/workspace}"
RCA_FINDINGS="$WORKSPACE/state/walter-rca-findings.json"
LOG_FILE="$WORKSPACE/state/walter-rca-followup.log"
ESCALATION_LOG="$WORKSPACE/state/walter-rca-escalations.log"

python3 - <<'PYEOF'
import sys, json, subprocess, os, re
from datetime import datetime, timezone

WORKSPACE = os.environ.get("WORKSPACE", "/Users/roger/.openclaw/workspace")
RCA_FINDINGS = f"{WORKSPACE}/state/walter-rca-findings.json"
LOG_FILE = f"{WORKSPACE}/state/walter-rca-followup.log"
ESCALATION_LOG = f"{WORKSPACE}/state/walter-rca-escalations.log"

def log(msg):
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    with open(LOG_FILE, "a") as f:
        f.write(f"[{ts}] {msg}\n")

def hours_since(ts_str):
    """Return hours since ISO-8601 UTC timestamp. Returns 999 on parse failure."""
    if not ts_str:
        return 999
    try:
        # Handle ISO-8601 with Z suffix
        ts_str = ts_str.replace("Z", "+00:00")
        # Strip microseconds if present
        ts_str = re.sub(r'\.\d+', '', ts_str)
        dt = datetime.fromisoformat(ts_str)
        delta = datetime.now(timezone.utc) - dt
        return max(0, int(delta.total_seconds() / 3600))
    except Exception:
        return 999

def sla_hours(severity):
    return {"HIGH": 4, "MEDIUM": 24, "LOW": 72}.get(severity.upper(), 24)

def check_cron_state(job_id):
    """Check if a cron job is enabled and its last run status.
    Returns (enabled: bool|None, last_status: str)."""
    try:
        # Get job list as JSON (filter plugin noise lines starting with '[')
        result = subprocess.run(
            ["openclaw", "cron", "list", "--all", "--json"],
            capture_output=True, text=True, timeout=15
        )
        json_lines = [l for l in result.stdout.splitlines()
                      if l.strip() and not l.strip().startswith('[')]
        if not json_lines:
            return (None, "ERROR")
        jobs = json.loads("\n".join(json_lines))
    except Exception as e:
        log(f"  cron list failed: {e}")
        return (None, "ERROR")

    job = None
    for j in jobs.get("jobs", []):
        if j.get("id") == job_id:
            job = j
            break

    if not job:
        return (None, "NOT_FOUND")

    enabled = job.get("enabled")

    # Get last run status
    try:
        runs_result = subprocess.run(
            ["openclaw", "cron", "runs", job_id, "--limit", "1"],
            capture_output=True, text=True, timeout=15
        )
        runs = json.loads(runs_result.stdout)
        last_status = runs[0].get("status", "unknown") if runs else "NO_RUNS"
    except Exception:
        last_status = "NO_RUNS"

    return (enabled, last_status)

def update_finding_status(job_id, new_status, resolution_note="", age_hours=None):
    """Update a finding's status in the RCA findings JSON."""
    with open(RCA_FINDINGS) as f:
        data = json.load(f)

    key = None
    for k, v in data.items():
        if v.get("jobId") == job_id or k == job_id:
            key = k
            break

    if key is None:
        log(f"  Could not locate finding for {job_id}")
        return False

    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    data[key]["status"] = new_status
    if new_status == "resolved":
        data[key]["resolvedAt"] = now
        data[key]["resolvedAfterHours"] = age_hours
        data[key]["resolution"] = resolution_note or "Fix verified via walter-rca-followup.sh"
    elif new_status == "superseded":
        data[key]["supersededAt"] = now

    with open(RCA_FINDINGS, "w") as f:
        json.dump(data, f, indent=2)
    return True

def write_escalation(job_id, job_name, severity, failure_type, fix_rec, age_h, sla_h):
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    lines = [
        f"{now} ESCALATION [{severity}] RCA finding still open after {age_h}h",
        f"  Job: {job_name} ({job_id})",
        f"  Type: {failure_type}",
        f"  Age: {age_h}h (SLA: {sla_h}h)",
        f"  Fix needed: {fix_rec}",
        f"  Action: Apply fix or update status in {RCA_FINDINGS}",
        ""
    ]
    with open(ESCALATION_LOG, "a") as f:
        f.write("\n".join(lines) + "\n")
    log(f"  Escalation written to {ESCALATION_LOG}")

# ─── main ───────────────────────────────────────────────────────────────────
log("=== RCA Followup started ===")

if not os.path.exists(RCA_FINDINGS):
    log("No RCA findings file — nothing to follow up")
    sys.exit(0)

with open(RCA_FINDINGS) as f:
    data = json.load(f)

open_findings = {k: v for k, v in data.items()
                 if v.get("status") in ("open", None)}

log(f"Open RCA findings: {len(open_findings)}")

if not open_findings:
    log("No open findings — followup complete")
    sys.exit(0)

resolved_count = 0
escalated_count = 0

for job_id, finding in open_findings.items():
    timestamp     = finding.get("timestamp", "")
    severity      = finding.get("severity", "MEDIUM")
    failure_type  = finding.get("failureType", "unknown")
    job_name      = finding.get("jobName", "unknown")
    auto_fixable  = finding.get("autoFixable", False)
    fix_rec       = finding.get("fixRecommendation", "see RCA findings")

    age_hours = hours_since(timestamp)
    sla_h     = sla_hours(severity)

    log(f"Checking {job_id}: {job_name} | {age_hours}h old | severity={severity}")

    fix_applied = False

    if auto_fixable:
        fix_status = finding.get("fixStatus", "unknown")
        if fix_status in ("applied", "verified"):
            fix_applied = True
            log(f"  Auto-fix reported as: {fix_status}")

    elif failure_type in ("DELIVERY_ERROR", "EXECUTION_ERROR", "TIMEOUT_ERROR"):
        enabled, last_run = check_cron_state(job_id)
        log(f"  Cron state: enabled={enabled}, last_run={last_run}")

        if enabled is None and last_run == "NOT_FOUND":
            log(f"  → Job not found — marking superseded")
            update_finding_status(job_id, "superseded")
            resolved_count += 1
            continue

        if enabled is True and last_run == "success":
            fix_applied = True
            log(f"  → Fix confirmed: job enabled and last run succeeded")

    if fix_applied:
        log(f"  → Marking {job_id} as RESOLVED")
        update_finding_status(job_id, "resolved",
                              resolution_note="Fix verified via walter-rca-followup.sh",
                              age_hours=age_hours)
        resolved_count += 1

    elif age_hours >= sla_h:
        log(f"  → Escalating {job_id} ({age_hours}h >= {sla_h}h SLA)")
        write_escalation(job_id, job_name, severity, failure_type,
                         fix_rec, age_hours, sla_h)
        escalated_count += 1

    else:
        log(f"  → Within SLA ({age_hours}h / {sla_h}h) — no action")

log(f"=== RCA Followup done — resolved: {resolved_count}, escalated: {escalated_count} ===")
print(f"resolved={resolved_count} escalated={escalated_count}")
PYEOF
