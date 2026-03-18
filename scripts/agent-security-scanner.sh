#!/usr/bin/env bash
# Roger agent-security-scanner V1

set -euo pipefail

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
OUT=""
MODE="sample"
TARGET=""
TS="$(date -u +%Y%m%d-%H%M%S)"
DEFAULT_TARGET="$WORKSPACE/skills/github-x-control/SKILL.md"
DEFAULT_OUT="$WORKSPACE/state/runtime/agent_security_scanner-report-$TS.md"
AUDITOR="$WORKSPACE/skills/skill-security-auditor/analyze-skill.sh"

usage() {
  cat <<USAGE
Usage:
  $0 --sample [--output <path>]
  $0 --target <file> [--output <path>]
  $0 --workspace [--output <path>]
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sample)
      MODE="sample"
      ;;
    --workspace)
      MODE="workspace"
      ;;
    --target)
      MODE="target"
      shift
      TARGET="${1:-}"
      ;;
    --output)
      shift
      OUT="${1:-}"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      usage
      exit 1
      ;;
  esac
  shift || true
done

if [[ -z "$OUT" ]]; then
  OUT="$DEFAULT_OUT"
fi
mkdir -p "$(dirname "$OUT")"

if [[ "$MODE" == "sample" ]]; then
  TARGET="$DEFAULT_TARGET"
fi

score=0
risk="SAFE"
recommendation="Proceed"
secret_hits=""
auditor_log=""
auditor_summary="auditor_not_run"
scan_target="$TARGET"

if [[ "$MODE" == "workspace" ]]; then
  scan_target="$WORKSPACE"
fi

secret_hits="$(rg -n --hidden -g '!**/.git/**' -g '!**/node_modules/**' -g '!**/backups/**' -e 'ghp_[A-Za-z0-9]{20,}' -e 'github_pat_[A-Za-z0-9_]{20,}' -e 'sk-[A-Za-z0-9]{20,}' -e 'xox[baprs]-[A-Za-z0-9-]+' "$scan_target" 2>/dev/null || true)"
if [[ -n "$secret_hits" ]]; then
  score=$((score + 40))
fi

if [[ "$MODE" != "workspace" && -f "$TARGET" && -x "$AUDITOR" ]]; then
  TMP_AUDIT="$(mktemp)"
  if "$AUDITOR" --file "$TARGET" > "$TMP_AUDIT" 2>&1; then
    auditor_log="$TMP_AUDIT"
  else
    auditor_log="$TMP_AUDIT"
  fi
  auditor_summary="$(rg -n 'Risk Score:|RECOMMENDATION:|Critical Findings|HIGH RISK|CRITICAL' "$TMP_AUDIT" || true)"
  if rg -q 'CRITICAL|HIGH RISK|Risk Score: ([6-9][0-9]|100)/100' "$TMP_AUDIT"; then
    score=$((score + 35))
  elif rg -q 'MEDIUM RISK|Risk Score: ([4-5][0-9])/100' "$TMP_AUDIT"; then
    score=$((score + 20))
  elif rg -q 'LOW RISK|Risk Score: ([2-3][0-9])/100' "$TMP_AUDIT"; then
    score=$((score + 10))
  fi
fi

# V2.1: Additional checks
workspace_findings="$(rg -n 'password reuse|raw password|plaintext|human_required|vendor_blocked|post-gate|decision_card|critic' "$WORKSPACE"/{AGENTS.md,HEARTBEAT.md,TOOLS.md,SECURITY.md,docs/agent-security.md} 2>/dev/null || true)"
if [[ -n "$workspace_findings" ]]; then
  score=$((score + 5))
fi

# Check for uncommitted secrets (staged or unstaged)
uncommitted_secrets="$(git status --porcelain 2>/dev/null | rg -i 'ghp_|github_pat_|sk-|xoxb-' || true)"
if [[ -n "$uncommitted_secrets" ]]; then
  score=$((score + 15))
fi

# Check for recent memory with potential leaks
recent_memory_leaks="$(rg -n 'password.*=|token.*=|secret.*=' "$WORKSPACE"/memory/2026-03-*.md 2>/dev/null | rg -v 'REDACTED|\[\]' || true)"
if [[ -n "$recent_memory_leaks" ]]; then
  score=$((score + 10))
fi

# Check for hardcoded wallet addresses in code
wallet_patterns="$(rg -n '0x[a-fA-F0-9]{40}' "$WORKSPACE"/code/*.sol "$WORKSPACE"/code/**/*.sol 2>/dev/null | rg -v '//.*0x|/\*.*0x' | head -5 || true)"
if [[ -n "$wallet_patterns" ]]; then
  score=$((score + 5))
fi

if (( score >= 75 )); then
  risk="CRITICAL"
  recommendation="Do not treat this target as trusted without remediation."
elif (( score >= 50 )); then
  risk="HIGH"
  recommendation="Review findings before using or installing."
elif (( score >= 25 )); then
  risk="MEDIUM"
  recommendation="Use with caution and address the highlighted issues."
elif (( score >= 10 )); then
  risk="LOW"
  recommendation="Minor concerns only."
fi

{
  echo "# Agent Security Scanner Report"
  echo
  echo "- timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "- mode: $MODE"
  echo "- target: $scan_target"
  echo "- canonical_tool: scripts/agent-security-scanner.sh"
  echo
  echo "## Result"
  echo "- risk_score: $score"
  echo "- risk_level: $risk"
  echo "- recommendation: $recommendation"
  echo
  echo "## Findings"
  if [[ -n "$secret_hits" ]]; then
    echo "### Secret-pattern scan"
    echo '```text'
    echo "$secret_hits"
    echo '```'
  else
    echo "- No obvious secret patterns found in the selected scan target."
  fi
  echo
  echo "### Auditor summary"
  if [[ -n "$auditor_log" ]]; then
    echo "- analyzer: $AUDITOR"
    echo "- raw_log: $auditor_log"
    if [[ -n "$auditor_summary" ]]; then
      echo '```text'
      echo "$auditor_summary"
      echo '```'
    else
      echo "- analyzer ran without concise findings output"
    fi
  else
    echo "- analyzer not run (workspace scan or missing executable target)"
  fi
  echo
  echo "### Workspace policy hits"
  if [[ -n "$workspace_findings" ]]; then
    echo '```text'
    echo "$workspace_findings"
    echo '```'
  else
    echo "- No additional policy hits captured."
  fi
  echo
  echo "## Actionable categories"
  echo "- secret_hygiene"
  echo "- runtime_guardrails"
  echo "- publish_governance"
  echo "- skill_installation_risk"
  echo
  echo "## Next steps"
  echo "1. Review the findings and remove or downgrade risky trust assumptions."
  echo "2. Keep using this script as the canonical V1 security-scan lane."
  echo "3. Publish a proof-backed explainer only after a clean sample audit is available."
} > "$OUT"

# Update session-state.json timestamp after successful artifact generation
STATE="$WORKSPACE/state/session-state.json"
if [[ -f "$STATE" ]]; then
  TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  tmp="$(mktemp)"
  jq ".last_artifact_change_at = \"$TS\" | .lastArtifactChangeAt = \"$TS\" | .updated_at = \"$TS\"" "$STATE" > "$tmp"
  mv "$tmp" "$STATE"
fi

echo "AGENT_SECURITY_SCANNER_OK $OUT"
