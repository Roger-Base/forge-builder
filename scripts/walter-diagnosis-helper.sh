#!/usr/bin/env zsh
# walter-diagnosis-helper.sh
# Institutional memory lookup BEFORE RCA diagnosis.
# Problem: RCA only matched by exact failure_type — meta-patterns like
# BUILD_DECISION/MISSION_DRIFT don't map to system errors.
# Solution: broad keyword+tag search across lessons AND critiques
# before each fresh RCA diagnosis, surfacing institutional memory proactively.
#
# Inputs:
#   run [job_id [error_text [context]]]
#   check-lessons [context]
#   report [text...]
#
# Output: JSON on stdout, human-readable report on stderr.
# Exit 0 always (no-match is not an error).

SCRIPT_DIR=${0:a:h}
WORKSPACE_DIR=${SCRIPT_DIR:h}
STATE_DIR=$WORKSPACE_DIR/state
LESSONS_FILE=$STATE_DIR/walter-lessons-learned.json
CRITIQUES_FILE=$STATE_DIR/walter-critique-accuracy.json
LOG_FILE=$STATE_DIR/walter-diagnosis-helper.log
VAULT_DIR="${HOME}/walter-vault"

# ─── Logging ──────────────────────────────────────────────────────────────────

log() {
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [diag-helper] $*" >> $LOG_FILE
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [diag-helper] $*"
}

# ─── Classify failure type ────────────────────────────────────────────────────

classify_failure() {
  local combined="${1:-}"
  local L=${(L)combined}
  case "$L" in
    (*"no such file"*|*"not found"*|*"cannot find"*|*"file does not exist"*|*"enoent"*)
      echo "MISSING_FILE" ;;
    (*"permission denied"*|*"not executable"*|*"access denied"*|*"eacces"*|*"chmod"*)
      echo "PERMISSION" ;;
    (*"jq:"*|*"parse error"*|*"invalid json"*|*"unexpected token"*|*"null is not a function"*|*"cannot iterate"*)
      echo "JSON_PARSE" ;;
    (*"openclaw:"*|*"command not found"*|*"cli error"*|*"non-zero exit"*|*"cron"*"not found"*|*"unknown command"*)
      echo "CLI_ERROR" ;;
    (*"error at line"*|*"exited with"*|*"failed with"*|*"script error"*|*"exit code "*)
      echo "SCRIPT_ERROR" ;;
    (*"timeout"*|*"connection refused"*|*"network"*|*"curl"*|*"fetch"*|*"fail"*"http"*|*"tls"*|*"ssl"*)
      echo "NETWORK" ;;
    (*"delivering to"*|*"delivery"*|*"telegram"*|*"chatid"*|*"chat id"*|*"target"*"telegram"*)
      echo "DELIVERY_ERROR" ;;
    (*"roger is"*|*"not idle"*|*"active"*|*"running"*|*"busy"*)
      echo "CONDITION_NOT_MET" ;;
    (*"no tasks"*|*"queue empty"*|*"invalid task"*)
      echo "QUEUE_EMPTY" ;;
    (*"memory"*|*"disk space"*|*"killed"*|*"oom"*|*"resource"*)
      echo "RESOURCE" ;;
    (*"build"*|*"build_rule"*|*"build decision"*|*"pre-build"*|*"gap"*|*"verif"*|*"trivial"*|*"symbolic"*)
      echo "BUILD_DECISION" ;;
    (*"drift"*|*"mission"*|*"scope"*|*"off.goal"*|*"off.purpose"*)
      echo "MISSION_DRIFT" ;;
    (*"escalat"*|*"stale"*|*"no.action"*|*"roger.action"*|*"roger act"*)
      echo "ESCALATION_FAILURE" ;;
    (*)
      echo "UNKNOWN" ;;
  esac
}

# ─── Fetch error from openclaw ────────────────────────────────────────────────

fetch_error_text() {
  local job_id="$1"
  openclaw cron runs --id "$job_id" --limit 1 2>/dev/null \
    | jq -r '.entries[0].error // "none"' 2>/dev/null \
    | cut -c1-1000
}

# ─── Score a lesson against search terms ─────────────────────────────────────

score_lesson_json() {
  local lesson_json="$1"
  local search_terms="$2"
  local score=0

  # failure_type match (3pt)
  local ftype
  ftype=$(echo "$lesson_json" | jq -r '.failure_type // ""')
  for term in $=search_terms; do
    case "${(L)ftype}" in
      (*${term}*)
        (( score += 3 ))
        break
        ;;
    esac
  done

  # tags match (2pt each, max 6)
  local tag_score=0
  local -a tags
  tags=( ${(f)"$(echo "$lesson_json" | jq -r '.tags // [] | .[]')"} )
  for term in $=search_terms; do
    for tag in $tags; do
      case "${(L)tag}" in
        (*${term}*)
          (( tag_score += 2 ))
          break
          ;;
      esac
    done
  done
  (( tag_score = tag_score > 6 ? 6 : tag_score ))
  (( score += tag_score ))

  # failure_context match (2pt)
  local ctx
  ctx=$(echo "$lesson_json" | jq -r '.failure_context // ""')
  for term in $=search_terms; do
    case "${(L)ctx}" in
      (*${term}*) (( score += 2 )) ; break ;;
    esac
  done

  # lesson_text / symptom match (1pt)
  local lt
  lt=$(echo "$lesson_json" | jq -r '.lesson_text // ""')
  for term in $=search_terms; do
    case "${(L)lt}" in
      (*${term}*) (( score += 1 )) ; break ;;
    esac
  done

  # occurrence_count boost (recurring pattern signal)
  local count
  count=$(echo "$lesson_json" | jq -r '.occurrence_count // 1')
  if (( count >= 3 )); then
    (( score += 4 ))
  elif (( count >= 2 )); then
    (( score += 2 ))
  fi

  # lesson_strength boost
  local strength
  strength=$(echo "$lesson_json" | jq -r '.lesson_strength // "medium"')
  case "$strength" in
    very_high) (( score += 3 )) ;;
    high)      (( score += 2 )) ;;
    medium)    (( score += 1 )) ;;
  esac

  # fix_status=verified signal (+5)
  local fix_status
  fix_status=$(echo "$lesson_json" | jq -r '.fix_status // ""')
  if [[ "$fix_status" == "verified" ]]; then
    (( score += 5 ))
  fi

  echo $score
}

# ─── Score a critique against search terms ────────────────────────────────────

score_critique_json() {
  local crit_json="$1"
  local search_terms="$2"
  local score=0

  local ctype
  ctype=$(echo "$crit_json" | jq -r '.type // "critique"')
  for term in $=search_terms; do
    case "${(L)ctype}" in
      (*${term}*) (( score += 3 )) ; break ;;
    esac
  done

  local ctx
  ctx=$(echo "$crit_json" | jq -r '.context // ""')
  for term in $=search_terms; do
    case "${(L)ctx}" in
      (*${term}*) (( score += 2 )) ; break ;;
    esac
  done

  local crit_text
  crit_text=$(echo "$crit_json" | jq -r '.critique // .prediction // ""')
  for term in $=search_terms; do
    case "${(L)crit_text}" in
      (*${term}*) (( score += 1 )) ; break ;;
    esac
  done

  local confidence
  confidence=$(echo "$crit_json" | jq -r '.confidence // 3')
  (( score += confidence ))

  local outcome
  outcome=$(echo "$crit_json" | jq -r '.verification.outcome // "pending"')
  if [[ "$outcome" == "correct" ]]; then
    (( score += 4 ))
  fi

  echo $score
}

# ─── ClawVault vsearch ────────────────────────────────────────────────────────
# Augments flat JSON search with semantic retrieval from ClawVault.
# Uses qmd query --json directly (clawvault vsearch wrapper is broken for JSON).
vault_vsearch() {
    local failure_type="$1"
    local search_terms="$2"

    # Convert search terms to a clean query string
    local query="${search_terms//$'\n'/ }"
    query=$(echo "$query" | sed 's/  */ /g' | sed 's/"/ /g' | cut -c1-300)

    if [[ -z "$query" ]]; then
        echo "[]"
        return
    fi

    # qmd query --json returns JSON array of {docid, score, file, title, snippet}
    qmd query --json --limit 5 "$query" 2>/dev/null | \
        jq '[.[] | {score: (.score * 100 | floor), title, category: (.file | split("/") | .[-1] | gsub("\\.md$";""))}]' 2>/dev/null || echo "[]"
}

build_signal() {
  local failure_type="$1"
  local search_terms="$2"

  # Default response
  local signal='{"institutionalMemoryFound":false,"matchedLessonsCount":0,"matchedCritiquesCount":0,"matchedVaultCount":0,"totalMatches":0,"matchedLessons":[],"matchedCritiques":[],"matchedVault":[],"topSignal":null}'

  if [[ ! -f "$LESSONS_FILE" ]] && [[ ! -f "$CRITIQUES_FILE" ]] && [[ ! -d "$VAULT_DIR" ]]; then
    echo "$signal"
    return
  fi

  local -a matched_lessons matched_critiques matched_vault

  # ClawVault semantic search (augments flat JSON matching)
  local vault_json
  vault_json=$(vault_vsearch "$failure_type" "$search_terms")
  local vault_count=0
  if [[ "$vault_json" != "[]" ]] && [[ "$vault_json" != "" ]]; then
    vault_count=$(echo "$vault_json" | jq 'length' 2>/dev/null || echo "0")
    if (( vault_count > 0 )); then
      # Parse vault results into matched_vault array (convert JSON objects to zsh-compatible strings)
      while IFS= read -r entry; do
        matched_vault+=("$entry")
      done < <(echo "$vault_json" | jq -c '.[]' 2>/dev/null)
    fi
  fi

  # Search lessons
  if [[ -f "$LESSONS_FILE" ]]; then
    local lesson_count
    lesson_count=$(jq '.lessons | length' "$LESSONS_FILE" 2>/dev/null || echo "0")
    local i=0
    while (( i < lesson_count )); do
      local lesson_json
      lesson_json=$(jq ".lessons[$i]" "$LESSONS_FILE" 2>/dev/null)
      if [[ -n "$lesson_json" && "$lesson_json" != "null" ]]; then
        local s
        s=$(score_lesson_json "$lesson_json" "$search_terms")
        if (( s >= 3 )); then
          local lid fs oc st lt fa tg
          lid=$(echo "$lesson_json" | jq -r '.lesson_id // "?"')
          fs=$(echo "$lesson_json" | jq -r '.fix_status // "?"')
          oc=$(echo "$lesson_json" | jq -r '.occurrence_count // 1')
          st=$(echo "$lesson_json" | jq -r '.lesson_strength // "medium"')
          lt=$(echo "$lesson_json" | jq -r '.lesson_text // ""' | cut -c1-200)
          fa=$(echo "$lesson_json" | jq -r '.fix_applied // ""' | cut -c1-200)
          tg=$(echo "$lesson_json" | jq -r '.tags // [] | join(", ")')
          matched_lessons+=("{\"score\":$s,\"lesson_id\":\"$lid\",\"fix_status\":\"$fs\",\"occurrence_count\":$oc,\"lesson_strength\":\"$st\",\"lesson_text\":\"$lt\",\"fix_applied\":\"$fa\",\"tags\":\"$tg\"}")
        fi
      fi
      (( i++ ))
    done
  fi

  # Search critiques
  if [[ -f "$CRITIQUES_FILE" ]]; then
    local crit_count
    crit_count=$(jq '.critiques | length' "$CRITIQUES_FILE" 2>/dev/null || echo "0")
    local i=0
    while (( i < crit_count )); do
      local crit_json
      crit_json=$(jq ".critiques[$i]" "$CRITIQUES_FILE" 2>/dev/null)
      if [[ -n "$crit_json" && "$crit_json" != "null" ]]; then
        local s
        s=$(score_critique_json "$crit_json" "$search_terms")
        if (( s >= 4 )); then
          local cid ctype outcome ct
          cid=$(echo "$crit_json" | jq -r '.id // .critique_id // "?"')
          ctype=$(echo "$crit_json" | jq -r '.type // "critique"')
          outcome=$(echo "$crit_json" | jq -r '.verification.outcome // "pending"')
          ct=$(echo "$crit_json" | jq -r '.critique // .prediction // ""' | cut -c1-200)
          matched_critiques+=("{\"score\":$s,\"critique_id\":\"$cid\",\"type\":\"$ctype\",\"outcome\":\"$outcome\",\"critique_text\":\"$ct\"}")
        fi
      fi
      (( i++ ))
    done
  fi

  local lcnt=${#matched_lessons[@]}
  local ccnt=${#matched_critiques[@]}
  local vcnt=${#matched_vault[@]}
  local total=$(( lcnt + ccnt + vcnt ))

  # Build lessons array JSON
  local lessons_arr="[]"
  if (( lcnt > 0 )); then
    # Build raw JSON strings, stripping non-printable chars for safe jq parsing
    local -a safe_lessons
    for entry in "${matched_lessons[@]}"; do
      local s lid fs oc st lt fa tg
      s=$(echo "$entry" | jq -r '.score')
      lid=$(echo "$entry" | jq -r '.lesson_id')
      fs=$(echo "$entry" | jq -r '.fix_status')
      oc=$(echo "$entry" | jq -r '.occurrence_count')
      st=$(echo "$entry" | jq -r '.lesson_strength')
      lt=$(echo "$entry" | jq -r '.lesson_text' | tr -cd '[:print:]' | cut -c1-200)
      fa=$(echo "$entry" | jq -r '.fix_applied' | tr -cd '[:print:]' | cut -c1-200)
      tg=$(echo "$entry" | jq -r '.tags')
      # Escape double quotes and backslashes for JSON
      lt=${lt//\\/\\\\}
      lt=${lt//\"/\\\"}
      fa=${fa//\\/\\\\}
      fa=${fa//\"/\\\"}
      safe_lessons+=("{\"score\":$s,\"lesson_id\":\"$lid\",\"fix_status\":\"$fs\",\"occurrence_count\":$oc,\"lesson_strength\":\"$st\",\"lesson_text\":\"$lt\",\"fix_applied\":\"$fa\",\"tags\":\"$tg\"}")
    done
    lessons_arr='['${(j:,:)safe_lessons}']'
  fi

  # Build critiques array JSON
  local crits_arr="[]"
  if (( ccnt > 0 )); then
    local -a safe_critiques
    for entry in "${matched_critiques[@]}"; do
      local s cid ctype outcome ct
      s=$(echo "$entry" | jq -r '.score')
      cid=$(echo "$entry" | jq -r '.critique_id')
      ctype=$(echo "$entry" | jq -r '.type')
      outcome=$(echo "$entry" | jq -r '.outcome')
      ct=$(echo "$entry" | jq -r '.critique_text' | tr -cd '[:print:]' | cut -c1-200)
      ct=${ct//\\/\\\\}
      ct=${ct//\"/\\\"}
      safe_critiques+=("{\"score\":$s,\"critique_id\":\"$cid\",\"type\":\"$ctype\",\"outcome\":\"$outcome\",\"critique_text\":\"$ct\"}")
    done
    crits_arr='['${(j:,:)safe_critiques}']'
  fi

  # Build vault array JSON (from clawvault vsearch results)
  local vault_arr="[]"
  if (( vcnt > 0 )); then
    local -a safe_vault
    for entry in "${matched_vault[@]}"; do
      local s title category
      s=$(echo "$entry" | jq -r '.score // 0')
      title=$(echo "$entry" | jq -r '.title // ""' | tr -cd '[:print:]' | cut -c1-200)
      category=$(echo "$entry" | jq -r '.category // "pattern"')
      title=${title//\\/\\\\}
      title=${title//\"/\\\"}
      safe_vault+=("{\"score\":$s,\"title\":\"$title\",\"category\":\"$category\",\"source\":\"vault\"}")
    done
    vault_arr='['${(j:,:)safe_vault}']'
  fi

  # Top signal
  local top='null'
  if (( total > 0 )); then
    local best_score=0
    local best_type=""

    # Score lessons
    for entry in "${matched_lessons[@]}"; do
      local sc
      sc=$(echo "$entry" | jq -r '.score')
      if (( sc > best_score )); then
        best_score=$sc
        best_type="lesson"
      fi
    done
    # Score critiques
    for entry in "${matched_critiques[@]}"; do
      local sc
      sc=$(echo "$entry" | jq -r '.score')
      if (( sc > best_score )); then
        best_score=$sc
        best_type="critique"
      fi
    done
    # Score vault matches
    for entry in "${matched_vault[@]}"; do
      local sc
      sc=$(echo "$entry" | jq -r '.score')
      if (( sc > best_score )); then
        best_score=$sc
        best_type="vault"
      fi
    done

    if (( best_score > 0 )); then
      top=$(jq -n \
        --argjson score $best_score \
        --arg src "$best_type" \
        '{source: $src, score: $score}')
    fi
  fi

  signal=$(jq -n \
    --argjson mem $(( total > 0 ? 1 : 0 )) \
    --argjson lcnt $lcnt \
    --argjson ccnt $ccnt \
    --argjson vcnt $vcnt \
    --argjson ls "$lessons_arr" \
    --argjson cs "$crits_arr" \
    --argjson vs "$vault_arr" \
    --argjson ts "$top" \
    '{
      institutionalMemoryFound: ($mem == 1),
      matchedLessonsCount: $lcnt,
      matchedCritiquesCount: $ccnt,
      matchedVaultCount: $vcnt,
      totalMatches: ($lcnt + $ccnt + $vcnt),
      matchedLessons: $ls,
      matchedCritiques: $cs,
      matchedVault: $vs,
      topSignal: $ts
    }' 2>/dev/null || echo '{"institutionalMemoryFound":false}')

  echo "$signal"
}

# ─── Print human-readable report ───────────────────────────────────────────────

print_report() {
  local signal_json="$1"
  local failure_type="$2"

  local found
  found=$(echo "$signal_json" | jq -r '.institutionalMemoryFound' 2>/dev/null)
  [[ "$found" != "true" ]] && return 0

  local lcnt ccnt vcnt total
  lcnt=$(echo "$signal_json" | jq -r '.matchedLessonsCount // 0')
  ccnt=$(echo "$signal_json" | jq -r '.matchedCritiquesCount // 0')
  vcnt=$(echo "$signal_json" | jq -r '.matchedVaultCount // 0')
  total=$(echo "$signal_json" | jq -r '.totalMatches // 0')

  echo ""
  echo "╔══════════════════════════════════════════════════════════════════════╗"
  echo "║       INSTITUTIONAL MEMORY SIGNAL — DO NOT DIAGNOSE IN ISOLATION  ║"
  echo "╚══════════════════════════════════════════════════════════════════════╝"
  echo "  Failure type being diagnosed: $failure_type"
  echo "  Matches found: $total ($lcnt lessons + $ccnt critiques + $vcnt vault patterns)"
  echo ""

  if (( lcnt > 0 )); then
    echo "  ── MATCHED LESSONS ──"
    local i=0
    while (( i < lcnt )); do
      local entry
      entry=$(echo "$signal_json" | jq ".matchedLessons[$i]" 2>/dev/null)
      local score lid fs oc st lt fa tg
      score=$(echo "$entry" | jq -r '.score // 0')
      lid=$(echo "$entry" | jq -r '.lesson_id // "?"')
      fs=$(echo "$entry" | jq -r '.fix_status // "?"')
      oc=$(echo "$entry" | jq -r '.occurrence_count // 1')
      st=$(echo "$entry" | jq -r '.lesson_strength // "medium"')
      lt=$(echo "$entry" | jq -r '.lesson_text // ""')
      fa=$(echo "$entry" | jq -r '.fix_applied // ""')
      tg=$(echo "$entry" | jq -r '.tags // ""')

      local icon
      case "$st" in
        very_high) icon="🟢🟢" ;;
        high)      icon="🟢" ;;
        medium)    icon="🟡" ;;
        *)         icon="🔴" ;;
      esac

      echo "  [$score pts] $lid $icon"
      echo "    Tags: $tg"
      echo "    Occurred: $oc× | Fix: $fs"
      echo "    Lesson: $lt"
      [[ -n "$fa" && "$fa" != "null" ]] && echo "    Fix: $fa"
      echo ""
      (( i++ ))
    done
  fi

  if (( ccnt > 0 )); then
    echo "  ── MATCHED CRITIQUES ──"
    local i=0
    while (( i < ccnt )); do
      local entry
      entry=$(echo "$signal_json" | jq ".matchedCritiques[$i]" 2>/dev/null)
      local score cid ctype outcome ct
      score=$(echo "$entry" | jq -r '.score // 0')
      cid=$(echo "$entry" | jq -r '.critique_id // "?"')
      ctype=$(echo "$entry" | jq -r '.type // "critique"')
      outcome=$(echo "$entry" | jq -r '.outcome // "pending"')
      ct=$(echo "$entry" | jq -r '.critique_text // ""')
      echo "  [$score pts] $cid ($ctype, outcome=$outcome)"
      echo "    Critique: $ct"
      echo ""
      (( i++ ))
    done
  fi

  # Vault semantic matches (ClawVault vsearch)
  if (( vcnt > 0 )); then
    echo "  ── MATCHED VAULT PATTERNS (ClawVault vsearch) ──"
    local i=0
    while (( i < vcnt )); do
      local entry
      entry=$(echo "$signal_json" | jq ".matchedVault[$i]" 2>/dev/null)
      local score title category
      score=$(echo "$entry" | jq -r '.score // 0')
      title=$(echo "$entry" | jq -r '.title // ""')
      category=$(echo "$entry" | jq -r '.category // "pattern"')
      echo "  [$score] 🐘 $title ($category)"
      echo ""
      (( i++ ))
    done
  fi

  echo "  ⚡ Review matched lessons/critiques/vault BEFORE writing RCA."
  echo "     If a verified-fix lesson matches, consider RCA closed."
  echo "     Vault patterns provide semantic context — verify before trusting."
  echo "╚══════════════════════════════════════════════════════════════════════╝"
  echo ""
}

# ─── Parse search terms from failure_type + text ──────────────────────────────

parse_search_terms() {
  local failure_type="$1"
  local text="$2"
  # Split failure_type on underscores and extract words from text
  local terms=""
  # Split failure_type on underscore
  local -a ft_parts
  ft_parts=( ${(s:_:)failure_type} )
  for part in $ft_parts; do
    [[ -n "$part" ]] && terms="$terms $part"
  done
  # Extract words from text (4+ chars, alphanumeric)
  local words
  words=$(echo "$text" | tr 'A-Z' 'a-z' | sed 's/[^a-z0-9 ]//g' | tr -s ' ' '\n' | grep -E '^.{4,}$' | sort -u | tr '\n' ' ')
  terms="$terms $words"
  echo "$terms"
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
  local job_id="${1:-}"
  local error_text="${2:-}"
  local context="${3:-}"

  # If job_id provided, fetch error from openclaw
  if [[ -n "$job_id" && -z "$error_text" ]]; then
    error_text=$(fetch_error_text "$job_id" 2>/dev/null || echo "")
  fi

  local failure_type
  failure_type=$(classify_failure "${error_text} ${context}")

  local search_terms
  search_terms=$(parse_search_terms "$failure_type" "$error_text")

  log "job_id=$job_id failure_type=$failure_type search_terms=$search_terms"

  local signal_json
  signal_json=$(build_signal "$failure_type" "$search_terms")

  print_report "$signal_json" "$failure_type" >&2

  echo "$signal_json"

  local found total
  found=$(echo "$signal_json" | jq -r '.institutionalMemoryFound')
  total=$(echo "$signal_json" | jq -r '.totalMatches // 0')
  if [[ "$found" == "true" ]]; then
    log "INSTITUTIONAL MEMORY SIGNAL: $total matches for $failure_type"
  else
    log "No matches for $failure_type"
  fi
}

# ─── CLI ──────────────────────────────────────────────────────────────────────

case "${1:-}" in
  run)       main "${2:-}" "${3:-}" "${4:-}" ;;
  check-lessons)  main "" "" "${2:-}" ;;
  report)
    shift
    local text="${*:-}"
    local ft
    ft=$(classify_failure "$text")
    local st
    st=$(parse_search_terms "$ft" "$text")
    local sig
    sig=$(build_signal "$ft" "$st")
    print_report "$sig" "$ft"
    ;;
  help|--help|-h)
    echo "walter-diagnosis-helper.sh — Institutional memory lookup before RCA"
    echo ""
    echo "  $0 run [job_id [error_text [context]]]"
    echo "  $0 check-lessons [context]"
    echo "  $0 report [text...]"
    ;;
  *)         main "" "${*:-}" ;;
esac
