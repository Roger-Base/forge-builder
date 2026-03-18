# Skills Inventory - Runtime Snapshot

Updated: 2026-03-09
Source: `ls skills/`

## Summary

- Total skills: 35
- Active in workspace: see below
- Overlaps: see table below

## Current Skills (35)

```
agent-autonomy-kit, agent-evaluation, agentic-gateway, alchemy, alchemy-web3,
auto-updater, automation-workflows, base-builder-operator, base-trader,
basename-agent, cli-operator, crypto-agent-payments, database-operations,
defi-yield-scanner, drones-moltbook-cli, ethskills, farcaster-skill,
github-x-control, google-analytics, model-usage, moltbook-interact,
n8n-workflow-automation, onchain, operator-discipline, productivity,
security-audit-toolkit, self-improving-agent, skill-creator,
skill-security-auditor, stripe-best-practices, summarize, supabase,
weather, web-research-assistant
```

## Overlaps Identified

| Group | Skills | Notes |
|-------|--------|-------|
| Web3/Chain | alchemy, alchemy-web3, ethskills, onchain | Consolidate to 1-2 |
| Agent | agent-autonomy-kit, agent-evaluation, agentic-gateway | Keep agent-evaluation |

## Priority Eligible Skills (Mission-Critical)

- github
- gh-issues
- xurl
- web-research-assistant
- agent-autonomy-kit
- agent-evaluation
- onchain
- evm-wallet-skill
- base-trader
- defi-yield-scanner
- security-audit
- skill-security-auditor
- session-logs
- coding-agent
- clawhub

## High-Leverage But Underused

- defi-yield-scanner
- web-research-assistant
- session-logs
- agent-evaluation
- security-audit

## Missing-Requirement Strategy

1. Do not bulk-install blindly.
2. Install only if tied to current goal or blocker.
3. After install: run a minimal proof test and record it in daily memory.

## Weekly Skill Hygiene

1. Run `openclaw skills check --json`.
2. Compare with this file.
3. Promote useful skills into active workflows.
4. Archive low-value experiments.
