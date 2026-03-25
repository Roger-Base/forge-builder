#!/usr/bin/env python3
"""
walter-horizon-scanner.py
Walter's forecasting layer: predicts which capability gaps are most likely
to matter in the next 24-48h based on trend analysis.
Stage 5 gap: reactive-only self-improvement → anticipatory self-improvement.

Reads: rca-findings, escalations, lessons-learned, critique-accuracy, capability-gaps
Writes: walter-improvement-priorities.json, walter-horizon-log.jsonl
"""

import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

# ── Paths ──────────────────────────────────────────────────────────────────────

STATE_DIR = Path(os.environ.get("STATE_DIR", str(Path(__file__).parent.parent / "state")))
SCRIPT_DIR = Path(os.environ.get("SCRIPT_DIR", str(Path(__file__).parent)))

RCA_FILE       = STATE_DIR / "walter-rca-findings.json"
ESCALATIONS    = STATE_DIR / "walter-escalations.json"
LESSONS_FILE   = STATE_DIR / "walter-lessons-learned.json"
CRITIQUE_FILE  = STATE_DIR / "walter-critique-accuracy.json"
GAP_DB         = STATE_DIR / "walter-capability-gaps.json"
PRIORITIES     = STATE_DIR / "walter-improvement-priorities.json"
LOG_FILE       = STATE_DIR / "walter-horizon-log.jsonl"

NOW = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
NOW_TS = datetime.now(timezone.utc).timestamp()


def load_json(path, default=None):
    try:
        with open(path) as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return default if default is not None else {}


def log_event(level, message, horizon_hours=0, urgency=0):
    entry = {
        "ts": NOW,
        "level": level,
        "message": message,
        "horizon_hours": horizon_hours,
        "urgency": urgency
    }
    with open(LOG_FILE, "a") as f:
        f.write(json.dumps(entry) + "\n")


# ── 1. RCA trend: open severity × recency ─────────────────────────────────────

def rca_trend():
    data = load_json(RCA_FILE)
    if not data:
        return 0, "no RCA data"
    findings = data.get("findings", {}) or data.get("rca_findings", {}) or {}
    score = 0
    details = []
    for fid, v in findings.items():
        if isinstance(v, dict) and v.get("status") == "open":
            sev = v.get("severity", "LOW")
            weight = {"CRITICAL": 10, "HIGH": 7, "MEDIUM": 4, "LOW": 1}.get(sev, 1)
            age_h = v.get("age_hours", 0)
            score += weight * 2
            if age_h < 2:
                score += weight  # fresh bonus
            details.append(f"{fid[:8]}:{sev}")
    return min(score, 20), ",".join(details) if details else "no open findings"


# ── 2. Escalation velocity: stale/critical ratio ───────────────────────────────

def escalation_velocity():
    data = load_json(ESCALATIONS)
    if not data:
        return 0
    stale = sum(1 for v in data.values() if isinstance(v, dict)
                and v.get("escalation_status") in ("overdue", "critical"))
    critical = sum(1 for v in data.values() if isinstance(v, dict)
                   and v.get("escalation_status") == "critical")
    total = len(data) or 1
    return min(10, int((stale / total) * 10 + critical * 2))


# ── 3. Lesson urgency: unverified × strength ───────────────────────────────────

def lesson_urgency():
    data = load_json(LESSONS_FILE)
    if not data:
        return 0
    lessons = data.get("lessons", []) or data.get("entries", []) or []
    strength_map = {"very_high": 4, "high": 3, "medium": 2, "low": 1}
    total = sum(strength_map.get(l.get("lesson_strength", "low"), 1)
                for l in lessons if isinstance(l, dict))
    unverified = sum(1 for l in lessons if isinstance(l, dict)
                      and l.get("fix_status") not in ("verified", "applied"))
    return min(10, total // 2 + unverified)


# ── 4. Critique trend: overdue verification ─────────────────────────────────────

def critique_trend():
    data = load_json(CRITIQUE_FILE)
    if not data:
        return 0
    entries = data.get("entries", []) or []
    pending = [e for e in entries if isinstance(e, dict)
               and e.get("outcome") in (None, "pending")]
    try:
        now = datetime.fromisoformat(NOW.replace("Z", "+00:00"))
        overdue = [
            e for e in pending
            if e.get("verify_after") and
            datetime.fromisoformat(e["verify_after"].replace("Z", "+00:00")) < now
        ]
    except Exception:
        overdue = []
    return min(10, len(pending) + len(overdue) * 2)


# ── 5. Capability gap severity ─────────────────────────────────────────────────

def gap_severity():
    data = load_json(GAP_DB)
    if not data:
        return 0, "none", 0
    gaps = data.get("gaps", []) or data.get("work_mode_gaps", []) or []
    if not gaps:
        return 0, "none", 0
    top = max(gaps, key=lambda g: g.get("severity_score", 0))
    total_score = sum(g.get("severity_score", 0) for g in gaps)
    return min(10, total_score // 10), top.get("work_mode", "unknown"), top.get("severity_score", 0)


# ── 6. Build horizon-ranked priorities ──────────────────────────────────────────

def score_signal(name, raw_score, horizon_ceiling=8):
    """Map raw signal score to horizon score (0-10)."""
    if raw_score >= 6:
        return horizon_ceiling
    elif raw_score >= 3:
        return max(3, horizon_ceiling - 2)
    else:
        return max(2, horizon_ceiling - 4)

signals_raw = {}

rca_score, rca_detail   = rca_trend()
esc_vel                  = escalation_velocity()
lesn_score               = lesson_urgency()
crit_score               = critique_trend()
gap_score, gap_name, gap_sev = gap_severity()

signals_raw["rca"]            = rca_score
signals_raw["escalation"]      = esc_vel
signals_raw["lesson"]         = lesn_score
signals_raw["critique"]       = crit_score
signals_raw["gap"]            = gap_score

signals = [
    {
        "id": "rca-open-findings",
        "name": "Open RCA Findings",
        "short_name": "RCA",
        "category": "reactive",
        "raw_score": rca_score,
        "horizon_score": score_signal("rca", rca_score, 8),
        "reason": f"Open RCA: {rca_detail}" if rca_detail else "Open RCA findings present",
        "timeframe": "0-24h",
        "recommended_action": "Run RCA followup; escalate Roger-actionable items"
    },
    {
        "id": "escalation-velocity",
        "name": "Escalation Velocity",
        "short_name": "ESC",
        "category": "reactive",
        "raw_score": esc_vel,
        "horizon_score": score_signal("escalation", esc_vel, 9),
        "reason": f"Escalation velocity={esc_vel} — aging escalations approaching critical",
        "timeframe": "0-24h",
        "recommended_action": "Review aging escalations; trigger Roger handoff for stale items"
    },
    {
        "id": "lesson-unverified",
        "name": "Unverified Lessons",
        "short_name": "LRN",
        "category": "structural",
        "raw_score": lesn_score,
        "horizon_score": score_signal("lesson", lesn_score, 7),
        "reason": "Unverified lessons = risk patterns accumulating without validation",
        "timeframe": "24-72h",
        "recommended_action": "Verify pending lessons; run RCA followup to close the loop"
    },
    {
        "id": "critique-pending",
        "name": "Critique Verification Lag",
        "short_name": "CRT",
        "category": "structural",
        "raw_score": crit_score,
        "horizon_score": score_signal("critique", crit_score, 8),
        "reason": "Overdue critique verifications degrade accuracy signal integrity",
        "timeframe": "0-48h",
        "recommended_action": "Run critique verifier; log overdue outcomes"
    },
    {
        "id": "capability-gap",
        "name": "Structural Capability Gap",
        "short_name": "GAP",
        "category": "structural",
        "raw_score": gap_sev,
        "horizon_score": score_signal("gap", gap_sev, 7),
        "reason": f"Top gap: {gap_name} (severity={gap_sev})",
        "timeframe": "48-168h",
        "recommended_action": "Run capability gap analyzer; prioritize top missing component"
    }
]

signals_sorted = sorted(signals, key=lambda x: x["horizon_score"], reverse=True)

overall_horizon = int(sum(s["horizon_score"] for s in signals_sorted[:3]) / 3)

output = {
    "generated_at": NOW,
    "overall_horizon_score": overall_horizon,
    "forecast_window": "24-48h",
    "raw_signals": signals_raw,
    "signals": signals_sorted,
    "top_priority": signals_sorted[0]["id"] if signals_sorted else None,
    "top_priority_name": signals_sorted[0]["name"] if signals_sorted else None,
    "rally_point": signals_sorted[0]["recommended_action"] if signals_sorted else "No action needed"
}

# ── Write outputs ──────────────────────────────────────────────────────────────

PRIORITIES.parent.mkdir(parents=True, exist_ok=True)
with open(PRIORITIES, "w") as f:
    json.dump(output, f, indent=2)

log_event("INFO",
          f"Horizon scan complete. Top: {output['top_priority_name']} (score={overall_horizon})",
          horizon_hours=overall_horizon * 6,
          urgency=5)

# ── Human-readable output ──────────────────────────────────────────────────────

print("═" * 52)
print(f"WALTER HORIZON SCAN — {NOW}")
print("═" * 52)
print()
print(f"Forecast window: 24-48h")
print(f"Overall horizon score: {overall_horizon}/10")
print()
print("Ranked improvement priorities:")
for i, s in enumerate(signals_sorted, 1):
    bar = "█" * s["horizon_score"] + "░" * (10 - s["horizon_score"])
    print(f"  {i}. [{s['short_name']}] {s['name']}")
    print(f"     Horizon: {bar} ({s['horizon_score']}/10) | {s['timeframe']}")
    print(f"     Reason:  {s['reason']}")
    print(f"     Action:  {s['recommended_action']}")
    print()
print("═" * 52)
print()
print(f"Priorities → {PRIORITIES}")
print(f"Scan log   → {LOG_FILE}")

print()
print("Raw signals:", signals_raw)
