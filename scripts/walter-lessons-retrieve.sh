#!/bin/bash
# walter-lessons-retrieve.sh - Retrieve lessons by failure type or context
# Usage: ./walter-lessons-retrieve.sh [failure_type] [context]
#   or:  ./walter-lessons-retrieve.sh --all
#   or:  ./walter-lessons-retrieve.sh --recent 5
#   or:  ./walter-lessons-retrieve.sh --tag cron

LESSONS_FILE="$HOME/.openclaw/workspace/state/walter-lessons-learned.json"

if [[ ! -f "$LESSONS_FILE" ]]; then
    echo "No lessons file found at $LESSONS_FILE"
    exit 1
fi

MODE="${1:-}"
ARG="${2:-}"

echo "=============================================="
echo "    WALTER LESSONS RETRIEVE — $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "=============================================="
echo ""

case "$MODE" in
  --all)
    echo "--- All Lessons ---"
    total=$(jq '.total_lessons' "$LESSONS_FILE")
    echo "Total: $total lessons"
    echo ""
    jq -r '.lessons[] | "[\(.lesson_id)] \(.failure_type) / \(.failure_context)\n  Strength: \(.lesson_strength)\n  Fix: \(.fix_status)\n  Occurrences: \(.occurrence_count)\n  Summary: \(.outcome_summary[0:120])…\n"' "$LESSONS_FILE"
    ;;

  --recent)
    count="${ARG:-5}"
    echo "--- Recent $count Lessons ---"
    jq -r ".lessons | reverse |.[0:$count][] | \"[\(.lesson_id)] \(.failure_type) / \(.failure_context)\n  Strength: \(.lesson_strength)\n  Last: \(.last_occurred)\n  Fix: \(.fix_status)\n  Lesson: \(.lesson_text[0:150])…\n\"" "$LESSONS_FILE"
    ;;

  --tag)
    tag="${ARG:-}"
    if [[ -z "$tag" ]]; then
      echo "Usage: --tag <tag_name>"
      exit 1
    fi
    echo "--- Lessons tagged: $tag ---"
    ids=$(jq -r ".tag_index.\"$tag\" // [] | .[]" "$LESSONS_FILE" 2>/dev/null)
    if [[ -z "$ids" ]]; then
      echo "No lessons found with tag: $tag"
    else
      for id in $ids; do
        jq -r ".lessons[] | select(.lesson_id == \"$id\") | \"[\(.lesson_id)] \(.failure_type) / \(.failure_context)\n  Strength: \(.lesson_strength)\n  Fix: \(.fix_status)\n  Lesson: \(.lesson_text)\n\"" "$LESSONS_FILE"
      done
    fi
    ;;

  *)
    # Default: retrieve by failure_type (positional arg 1)
    if [[ -n "$MODE" && "$MODE" != "--"* ]]; then
      failure_type="$MODE"
      context="${ARG:-}"
      echo "--- Lessons for failure_type: $failure_type ---"
      if [[ -n "$context" ]]; then
        echo "  + context filter: $context"
        jq -r ".lessons[] | select(.failure_type == \"$failure_type\" and .failure_context == \"$context\") | \"[\(.lesson_id)] \(.failure_type) / \(.failure_context)\n  Strength: \(.lesson_strength)\n  Occurrences: \(.occurrence_count)\n  Lesson: \(.lesson_text)\n\"" "$LESSONS_FILE"
      else
        jq -r ".lessons[] | select(.failure_type == \"$failure_type\") | \"[\(.lesson_id)] \(.failure_type) / \(.failure_context)\n  Strength: \(.lesson_strength)\n  Occurrences: \(.occurrence_count)\n  Lesson: \(.lesson_text)\n\"" "$LESSONS_FILE"
      fi
    else
      echo "Usage:"
      echo "  $0 --all                    Show all lessons"
      echo "  $0 --recent [N]             Show N most recent lessons (default 5)"
      echo "  $0 --tag <tag>              Show lessons by tag"
      echo "  $0 <failure_type> [context] Show lessons by failure type"
      echo ""
      echo "Available tags:"
      jq -r '.tag_index | keys[]' "$LESSONS_FILE" | sed 's/^/  /'
    fi
    ;;
esac

echo ""
echo "=============================================="
