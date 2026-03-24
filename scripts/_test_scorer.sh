#!/bin/bash
set -e
STATE_DIR="/Users/roger/.openclaw/workspace/state"

echo "=== Test 1: Escalation collector ==="
python3 -c "
import json
d = json.load(open('$STATE_DIR/walter-escalations.json'))
items = d if isinstance(d, list) else d.get('escalations', list(d.values()))
for e in items:
    print('LINE:', 'ESCALATION', e.get('severity','medium'), int(e.get('age_hours',0)), e.get('escalation_status','fresh'), e.get('failure_type','UNKNOWN'))
    print('ESCALATION|%s|%d|%s|%s|-' % (e.get('severity','medium'), int(e.get('age_hours',0)), e.get('escalation_status','fresh'), e.get('failure_type','UNKNOWN')))
"

echo ""
echo "=== Test 2: RCA collector ==="
python3 -c "
import json, time
d = json.load(open('$STATE_DIR/walter-rca-findings.json'))
items = d if isinstance(d, list) else list(d.values())
now = time.time()
for e in items:
    age = int(e.get('age_hours', 0))
    if age == 0 and 'timestamp' in e:
        try:
            ts = time.mktime(time.strptime(e['timestamp'][:19], '%Y-%m-%dT%H:%M:%S'))
            age = int((now - ts) / 3600)
        except: pass
    print('RCA|%s|%d|%s|%s|-' % (e.get('severity','medium'), age, e.get('status','open'), e.get('failureType','UNKNOWN')))
"

echo ""
echo "=== Test 3: Signals JSON accumulation ==="
signals_json="[]"
rank=0

while IFS='|' read -r type severity age status failure_type fix; do
  [[ -z "$type" ]] && continue
  echo "READ: type=$type severity=$severity age=$age status=$status"
  rank=$((rank + 1))
  sev_s=7  # high
  is_overdue="false"; [[ "$status" == "overdue" || "$status" == "critical" ]] && is_overdue="true"
  [[ "$age" -gt 48 ]] && is_overdue="true"
  if [[ "$is_overdue" == "true" ]]; then urg_s=3; else urg_s=1; fi
  recency_mult=1; [[ "$age" -gt 48 ]] && recency_mult=2
  score=$((sev_s * urg_s * recency_mult))
  echo "  score=$score"
  signals_json=$(python3 -c "
import json, sys
s = json.loads('$signals_json')
s.append({'rank':$rank,'type':'$type','severity':'$severity','score':$score,'signal':'[$failure_type] $fix','status':'$status'})
print(json.dumps(s))
")
  echo "  signals_json after: $signals_json"
done < <(python3 -c "
import json
d = json.load(open('$STATE_DIR/walter-escalations.json'))
items = d if isinstance(d, list) else d.get('escalations', list(d.values()))
for e in items:
    print('ESCALATION|%s|%d|%s|%s|%s' % (e.get('severity','medium'), int(e.get('age_hours',0)), e.get('escalation_status','fresh'), e.get('failure_type','UNKNOWN'), 'fix'))
")

echo ""
echo "Final rank: $rank"
echo "Final signals_json: $signals_json"
count=$(python3 -c "import json; print(len(json.loads('$signals_json')))")
echo "Count: $count"
