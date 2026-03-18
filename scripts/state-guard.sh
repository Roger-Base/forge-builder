#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
TARGET_DEFAULT="$WORKSPACE/state/session-state.json"
usage() { echo "Usage: $0 --validate [target] | <source_json_file> [target]" >&2; }
validate_schema() {
  local file="$1"
  jq -e '
    def stage_ok: test("^(TRIBUNAL|RESEARCH_PACKET|PROOF_SPEC|BUILD|VERIFY|DISTRIBUTE|LEARN|MAINTAIN|FROZEN)$");
    def critic_ok: test("^(none|pending_ack|applied|rejected_with_proof|deferred_with_reason)$");
    def support_ok: test("^(support_only|integrated)$");
    def noop: test("^(echo|printf|true|:)( |$)");
    def passive: test("(^| )(wait|await|monitor|standby|idle)( |$)"; "i");
    (.version == "2.0")
    and ((.updated_at | type) == "string" and (.updated_at | length) > 0)
    and ((.mode | type) == "string" and (.mode | length) > 0)
    and ((.mission.id | type) == "string" and (.mission.id | length) > 0)
    and (.mission.status == "active")
    and ((.portfolio.primary_id | type) == "string" and (.portfolio.primary_id | length) > 0)
    and ((.portfolio.reserve_id | type) == "string")
    and ((.portfolio.maintenance_ids | type) == "array")
    and ((.portfolio.frozen_ids | type) == "array")
    and ((.active_wedge.id | type) == "string" and (.active_wedge.id | length) > 0)
    and ((.active_wedge.stage | type) == "string" and (.active_wedge.stage | stage_ok))
    and ((.next_action.type | type) == "string" and (.next_action.type | length) > 0)
    and ((.next_action.command | type) == "string" and (.next_action.command | length) > 0)
    and (((.next_action.command | noop) | not))
    and (((.next_action.command | passive) | not))
    and ((.next_action.target | type) == "string")
    and ((.next_action.proof_expected | type) == "string" and (.next_action.proof_expected | length) > 0)
    and ((.next_action.fallback_chain | type) == "array")
    and ((.decision_card.required | type) == "boolean")
    and ((.decision_card.path | type) == "string" and (.decision_card.path | length) > 0)
    and ((.decision_card.status | test("^(none|draft|approved|rejected)$")))
    and ((.critic.last_handoff_id == null) or ((.critic.last_handoff_id | type) == "string"))
    and ((.critic.status | type) == "string" and (.critic.status | critic_ok))
    and ((.critic.summary | type) == "string")
    and ((.subagents.required_roles | type) == "array")
    and ((.subagents.max_parallel | type) == "number")
    and ((.subagents.last_runs | type) == "array")
    and ((.support_layers.bankr | support_ok))
    and ((.support_layers.virtuals | support_ok))
    and ((.support_layers.acp | support_ok))
    and ((.support_layers.x402 | support_ok))
    and ((.support_layers.roger_token | support_ok))
    and ((.blockers | type) == "array")
    and ((.proof_paths | type) == "array")
    and ((.assumptions | type) == "array")
    and ((.direction_review.required | type) == "boolean")
    and ((.direction_review.status | type) == "string")
    and ((.direction_review.reason == null) or ((.direction_review.reason | type) == "string"))
    and ((.capability_activation_ref | type) == "string" and (.capability_activation_ref | length) > 0)
    and ((.consumer | type) == "string" and (.consumer | length) > 0)
    and ((.never_touch | type) == "string" and (.never_touch | length) > 0)
    and ((.max_chain_steps | type) == "number")
    and ((.soft_budget_minutes | type) == "number")
    and ((.last_artifact_change_at | type) == "string" and (.last_artifact_change_at | length) > 0)
    and ((.last_stage_advance_at | type) == "string" and (.last_stage_advance_at | length) > 0)
  ' "$file" >/dev/null
}
if [[ $# -lt 1 ]]; then usage; exit 1; fi
if [[ "$1" == "--validate" ]]; then
  target="${2:-$TARGET_DEFAULT}"
  jq . "$target" >/dev/null
  validate_schema "$target"
  echo "STATE_GUARD_VALIDATE_OK $target"
  exit 0
fi
source_json="$1"
target="${2:-$TARGET_DEFAULT}"
[[ -f "$source_json" ]] || { echo "STATE_GUARD_FAIL missing source: $source_json" >&2; exit 1; }
jq . "$source_json" >/dev/null
validate_schema "$source_json"
ts="$(date +%Y%m%d-%H%M%S)"
backup="$target.bak-$ts"
tmp="$target.tmp-$ts"
[[ -f "$target" ]] && cp "$target" "$backup"
cp "$source_json" "$tmp"
validate_schema "$tmp"
mv "$tmp" "$target"
echo "STATE_GUARD_WRITE_OK target=$target backup=${backup:-none}"
