#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
WEDGE=""
OUT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --wedge) WEDGE="${2:-}"; shift 2 ;;
    --output) OUT="${2:-}"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

[[ -n "$WEDGE" ]] || { echo "Missing --wedge" >&2; exit 1; }
[[ -n "$OUT" ]] || { echo "Missing --output" >&2; exit 1; }

wedge_dir="$WORKSPACE/docs/wedges/$WEDGE"
mkdir -p "$(dirname "$OUT")"

packet="$wedge_dir/research-packet.md"
spec="$wedge_dir/proof-spec.md"
sample="$wedge_dir/sample-audit.md"
proof_page="$wedge_dir/proof-page.md"
readme_candidates="$(rg --files "$WORKSPACE" | rg "(^|/)README\.md$" || true)"
git_branch="$(git -C "$WORKSPACE" rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
git_status="$(git -C "$WORKSPACE" status --short 2>/dev/null | head -n 20 || true)"

exists() {
  [[ -f "$1" ]] && echo "yes" || echo "no"
}

recommended="refresh README/proof-page linkage and public proof instructions"
if [[ "$(exists "$proof_page")" == "no" ]]; then
  recommended="create or update a human-readable proof page for the wedge"
elif [[ "$(exists "$sample")" == "no" ]]; then
  recommended="create or refresh a concrete sample artifact that demonstrates the wedge"
elif [[ -z "$readme_candidates" ]]; then
  recommended="create a README or public repo-facing explanation for the wedge"
fi

cat > "$OUT" <<EOF
# GitHub / Proof Surface Check

- generated_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- wedge: $WEDGE
- git_branch: $git_branch
- research_packet: $(exists "$packet") ($packet)
- proof_spec: $(exists "$spec") ($spec)
- sample_artifact: $(exists "$sample") ($sample)
- proof_page: $(exists "$proof_page") ($proof_page)

## README candidates
$readme_candidates

## Git status (top 20)
\`\`\`
$git_status
\`\`\`

## Recommended next proof-surface move
- $recommended

## Why this matters
- GitHub and public proof surfaces are part of the product, not an afterthought.
- This check exists to stop Roger from treating internal artifact churn as sufficient proof.
EOF

echo "GITHUB_PROOF_SURFACE_OK $OUT"
