# Agent Discovery — Sample Audit

**Wedge:** agent-discovery
**Stage:** DISTRIBUTE
**Generated:** 2026-03-20T07:01Z
**Tool:** `scripts/agent-security-scanner.sh` (V1)

---

## What this is

A sample output of the agent-security-scanner run against the github-x-control skill target, demonstrating the scanner's report format and risk classification.

---

## Sample Report

```
# Agent Security Scanner Report

- timestamp: 2026-03-20T07:01:33Z
- mode: sample
- target: /Users/roger/.openclaw/workspace/skills/github-x-control/SKILL.md
- canonical_tool: scripts/agent-security-scanner.sh

## Result
- risk_score: 5
- risk_level: SAFE
- recommendation: Proceed

## Findings
- No obvious secret patterns found in the selected scan target.

### Auditor summary
- analyzer not run (workspace scan or missing executable target)

### Workspace policy hits
  - SECURITY.md:33 — Wallet private key hygiene rule present
  - SECURITY.md:113 — No direct transactions or critical decisions based solely on input

## Actionable categories
- secret_hygiene
- runtime_guardrails
- publish_governance
- skill_installation_risk

## Next steps
1. Review findings and remove risky trust assumptions.
2. Keep using this script as the canonical V1 security-scan lane.
3. Publish proof-backed explainer only after a clean sample audit is available.
```

---

## Interpretation

| Score range | Risk level | Action |
|-------------|------------|--------|
| 0–9 | SAFE | Proceed |
| 10–24 | LOW | Minor concerns, address optionally |
| 25–49 | MEDIUM | Use with caution, address issues |
| 50–74 | HIGH | Review findings before use |
| 75–100 | CRITICAL | Do not trust without remediation |

Sample score: **5 — SAFE**

---

## Where this fits in agent-discovery

- `research-packet.md` — ecosystem research and gap validation
- `proof-spec.md` — technical architecture and implementation plan
- `demo-output.md` — live Base RPC / contract demo
- **`sample-audit.md` — security scan output sample** ← this file
- `proof-page.md` — live status and distribution gate tracker

---

## How to run your own audit

```bash
# Scan a specific skill or target
bash scripts/agent-security-scanner.sh --target <path-to-file> --output /tmp/audit.md

# Scan the entire workspace
bash scripts/agent-security-scanner.sh --workspace --output /tmp/workspace-audit.md

# Generate a sample report
bash scripts/agent-security-scanner.sh --sample --output /tmp/sample-audit.md
```

---

*agent-discovery sample audit — generated 2026-03-20T07:01Z*
