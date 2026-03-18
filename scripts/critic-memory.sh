#!/bin/bash
# critic-memory.sh - Track Walter's critiques and their outcomes
# Usage: 
#   ./critic-memory.sh log "<critique>" "<response>" "<notes>"
#   ./critic-memory.sh patterns
#   ./critic-memory.sh recent [n]

MEMORY_FILE="$HOME/.critic_memory.json"

init() {
    if [[ ! -f "$MEMORY_FILE" ]]; then
        echo '{"critiques":[]}' > "$MEMORY_FILE"
    fi
}

log_critique() {
    local critique="$1"
    local response="$2"
    local outcome="$3"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    init
    local new_entry=$(jq -n \
        --arg t "$timestamp" \
        --arg c "$critique" \
        --arg r "$response" \
        --arg o "$outcome" \
        '{timestamp: $t, critique: $c, response: $r, outcome: $o}')
    
    local updated=$(jq --argjson entry "$new_entry" '.critiques += [$entry]' "$MEMORY_FILE")
    echo "$updated" > "$MEMORY_FILE"
    echo "Logged critique: ${critique:0:50}..."
}

show_patterns() {
    init
    echo "=== Critique Patterns (response breakdown) ==="
    jq -r '.critiques | group_by(.response) | .[] | 
        "\n[\(.[0].response)] \(. | length) times" +
        "\n  Sample: \(.[0].critique | .[0:60])..."' "$MEMORY_FILE"
}

show_recent() {
    local n="${1:-5}"
    init
    echo "=== Recent $n Critiques ==="
    jq -r ".critiques | reverse | limit($n; .[]) | 
        \"[\(.timestamp)] \(.response): \(.critique | .[0:70])...\"" "$MEMORY_FILE"
}

case "$1" in
    log)
        log_critique "$2" "$3" "$4"
        ;;
    patterns)
        show_patterns
        ;;
    recent)
        show_recent "$2"
        ;;
    *)
        echo "Usage: $0 {log|patterns|recent}"
        exit 1
        ;;
esac
