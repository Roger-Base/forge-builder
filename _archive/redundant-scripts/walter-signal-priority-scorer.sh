#!/bin/bash
# walter-signal-priority-scorer.sh
# Walter Signal Priority Scorer — ranks degradation signals by severity × urgency × recency
# Returns ranked signal list and top priority signal for self-improvement targeting.
# All signal collection and scoring done in a single Python process to avoid shell field-splitting issues.
# Exits 0 if signals found, 1 if all clear.

STATE_DIR="${STATE_DIR:-/Users/roger/.openclaw/workspace/state}"
SIGNAL_CACHE="${STATE_DIR}/walter-signal-priority-cache.json"
LOG="${STATE_DIR}/walter-signal-priority-log.json"
WORK_FILE=$(mktemp)

now_iso() { date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ"; }

# ── collector helpers (pure Python — avoids shell splitting issues) ──────────

collect_all() {
  python3 - "$STATE_DIR" "$WORK_FILE" << 'PYEOF'
import json, os, sys, time, datetime

state_dir = sys.argv[1]
work_file = sys.argv[2]
now = time.time()
signals = []

def sev_score(s):
    mapping = {"critical": 10, "P1": 10, "high": 7, "P2": 7, "medium": 4, "P3": 4, "low": 1, "P4": 1}
    return mapping.get(s, 2)

def urg_score(age_hours, is_overdue):
    if is_overdue or age_hours > 48: return 3
    if age_hours > 24: return 2
    return 1

def recency_mult(age_hours):
    return 2 if age_hours > 48 else 1

def write(sig):
    signals.append(sig)

# ── Health ────────────────────────────────────────────────────────────────────
hm = os.path.join(state_dir, "walter-health-monitor.json")
if os.path.exists(hm):
    try:
        d = json.load(open(hm))
        s = d.get("current_state", "unknown")
        if s in ("critical", "degraded"):
            ss = sev_score(s)
            us = 3 if s == "critical" else 2
            write({"type":"HEALTH","severity":s,"score":ss*us,"signal":d.get("message",d.get("summary",s)),"status":"active"})
    except: pass

# ── Escalations ───────────────────────────────────────────────────────────────
et = os.path.join(state_dir, "walter-escalations.json")
if os.path.exists(et):
    try:
        d = json.load(open(et))
        items = d if isinstance(d, list) else d.get("escalations", list(d.values()) if isinstance(d, dict) else [])
        for e in items:
            sev  = e.get("severity", "medium")
            age  = int(e.get("age_hours", 0))
            st   = e.get("escalation_status", "fresh")
            ft   = e.get("failure_type", "UNKNOWN")
            fix  = e.get("fix", e.get("recommended_action", "—"))[:80]
            overdue = st in ("overdue", "critical") or age > 48
            ss = sev_score(sev)
            us = urg_score(age, overdue)
            rm = recency_mult(age)
            write({"type":"ESCALATION","severity":sev,"score":ss*us*rm,"signal":f"[{ft}] {fix}","status":st})
    except: pass

# ── RCA ───────────────────────────────────────────────────────────────────────
rca = os.path.join(state_dir, "walter-rca-findings.json")
if os.path.exists(rca):
    try:
        d = json.load(open(rca))
        items = d if isinstance(d, list) else list(d.values())
        for e in items:
            sev  = e.get("severity", "medium")
            age  = int(e.get("age_hours", 0))
            # Compute age from timestamp if missing
            if age == 0 and "timestamp" in e:
                try:
                    ts = time.mktime(time.strptime(e["timestamp"][:19], "%Y-%m-%dT%H:%M:%S"))
                    age = int((now - ts) / 3600)
                except: pass
            st   = e.get("status", "open")
            ft   = e.get("failureType", "UNKNOWN")
            rc   = str(e.get("root_cause", e.get("fixRecommendation", "—")))[:60]
            overdue = st == "open" and age > 48
            ss = sev_score(sev)
            us = urg_score(age, overdue)
            rm = recency_mult(age)
            write({"type":"RCA","severity":sev,"score":ss*us*rm,"signal":f"[{ft}] RCA: {rc}","status":st})
    except: pass

# ── Critiques (overdue) ────────────────────────────────────────────────────────
ca = os.path.join(state_dir, "walter-critique-accuracy.json")
if os.path.exists(ca):
    try:
        d = json.load(open(ca))
        entries = d if isinstance(d, list) else d.get("entries", [])
        for e in entries:
            if e.get("status") != "pending": continue
            va  = e.get("verify_after", "")
            ct  = e.get("critique", e.get("prediction", ""))[:80]
            conf = int(e.get("confidence", 3))
            overdue = False
            if va:
                try:
                    t = time.mktime(time.strptime(va[:10], "%Y-%m-%d"))
                    overdue = (now - t) / 86400.0 > 0
                except: pass
            us = urg_score(0, overdue)
            write({"type":"CRITIQUE","severity":"medium","score":conf*us,"signal":f"Overdue critique: {ct}","status":"pending"})
    except: pass

# ── Lessons (unverified fixes) ────────────────────────────────────────────────
ll = os.path.join(state_dir, "walter-lessons-learned.json")
if os.path.exists(ll):
    try:
        d = json.load(open(ll))
        entries = d if isinstance(d, list) else d.get("lessons", d.get("entries", []))
        for e in entries:
            fs  = e.get("fix_status", "unknown")
            if fs == "verified": continue
            lid = e.get("lesson_id", "")
            occ = int(e.get("occurrence_count", 1))
            lt  = e.get("lesson_text", "")[:80]
            if fs in ("open", "unverified", "pending_roger_action"): ss = 5
            elif fs == "applied": ss = 3
            else: ss = 2
            write({"type":"LESSON","severity":"low","score":ss*occ,"signal":f"[{lid}] Lesson {fs}: {lt}","status":fs,"lesson_id":lid,"fix_status":fs})
    except: pass

# Sort by score descending
signals.sort(key=lambda x: x["score"], reverse=True)
for i, s in enumerate(signals): s["rank"] = i + 1

# Write cache
with open(work_file, "w") as out:
    json.dump(signals, out, indent=2)

# Print summary
count = len(signals)
print(f"SIGNALS_FOUND|{count}")
if signals:
    top = signals[0]
    print(f"TOP|{top['type']}|{top['score']}|{top['severity']}|{top['signal'][:80]}")
PYEOF
}

# ── run ─────────────────────────────────────────────────────────────────────

output=$(collect_all 2>&1)
exit_code=$?

echo "$output"

if [[ $exit_code -ne 0 ]]; then
  echo "NO_SIGNALS"
  exit 1
fi

count_line=$(echo "$output" | grep "SIGNALS_FOUND" | head -1)
count=$(echo "$count_line" | cut -d'|' -f2)

if [[ -z "$count" || "$count" == "0" ]]; then
  echo "NO_SIGNALS"
  echo "[]" > "$SIGNAL_CACHE"
  python3 -c "
import json, os
ts='$(now_iso)'
d=json.load(open('$LOG')) if os.path.exists('$LOG') else []
d.insert(0,{'ts':ts,'event':'scan','result':'clear','count':0})
json.dump(d[:50],open('$LOG','w'),indent=2)
" 2>/dev/null || true
  rm -f "$WORK_FILE"
  exit 1
fi

# ranked already in WORK_FILE
cp "$WORK_FILE" "$SIGNAL_CACHE"
rm -f "$WORK_FILE"

# Log
python3 -c "
import json, os
ts='$(now_iso)'
d=json.load(open('$LOG')) if os.path.exists('$LOG') else []
try:
    sigs=json.load(open('$SIGNAL_CACHE'))
    top=sigs[0] if sigs else None
    d.insert(0,{'ts':ts,'event':'scan','count':len(sigs),'top':top,'signals':sigs})
except:
    d.insert(0,{'ts':ts,'event':'scan','result':'error'})
json.dump(d[:50],open('$LOG','w'),indent=2)
" 2>/dev/null || true

exit 0
