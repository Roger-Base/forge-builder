#!/bin/bash
# Fast ownerOf scan using bash parallel curl
REGISTRY="${1:-0x8004A169FB4a3325136EB29fA0ceB6D2e539a432}"
RPC="${2:-https://mainnet.base.org}"
START=${3:-35100}
END=${4:-35400}
BATCH=${5:-10}
DELAY=${6:-0.05}

echo "Scanning $START-$END on $RPC..."
declare -A AGENTS
TOTAL=0

for ((i=START; i<=END; i++)); do
  ID=$i
  DATA="0x6352211e$(printf '%064x' $ID)"
  
  RESP=$(curl -s -X POST "$RPC" \
    -H "Content-Type: application/json" \
    -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\":\"$REGISTRY\",\"data\":\"$DATA\"},\"latest\"],\"id\":1}" 2>/dev/null)
  
  RAW=$(echo "$RESP" | python3 -c "import sys,json; r=json.load(sys.stdin).get('result',''); print('0x'+r[26:66] if r else '')" 2>/dev/null)
  
  if [[ -n "$RAW" && "$RAW" != "0x$([ $ID -eq 1 ] && echo '0000000000000000000000000000000000000000' || echo '0000000000000000000000000000000000000000')" ]]; then
    AGENTS[$ID]=$RAW
    echo "Agent $ID: $RAW" >&2
  else
    echo "." >&2
  fi
  
  sleep $DELAY
done

echo "Found: ${#AGENTS[@]}"
python3 -c "
import sys, json
agents = {k: v for k, v in ${AGENTS[@]+"{"}$(/bin/echo "${!AGENTS[@]}" | tr ' ' '\n' | sed 's/^/"\&": "${AGENTS[&]}", /g' | tr -d '\n' | sed 's/,$//')$/}
print(json.dumps(agents, indent=2))
"
