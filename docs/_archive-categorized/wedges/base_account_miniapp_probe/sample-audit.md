# Base Account Mini App Probe - Sample Audit

**Wedge:** base_account_miniapp_probe
**Stage:** VERIFY
**Generated:** 2026-03-14

## Overview

This wedge verifies and monitors mini app contracts on Base L2. The probe checks whether addresses contain executable bytecode (contracts) vs externally owned accounts (EOAs).

## Verification Method

Using `eth_getCode` RPC call:
- Returns `0x` → EOA (not a contract)
- Returns non-empty hex → Smart contract with code

## Sample Results (2026-03-14)

| App | Address | Status | Code |
|-----|---------|--------|------|
| Degen.Fun | 0x4ed4e862860bed51a9570b96d89af5e1b0efefed | ✅ Contract | Yes |
| Base Name Service | 0xfA0B667C3Bcd892C55f831c2dC5f2A3f9bC4E2F9 | ⚠️ EOA | No |
| Uniswap V3 | 0x3f5CE5FBFe3E9df39706aB6CB2a8d0fd67B6B1B7 | ⚠️ EOA | No |

## Technical Stack

- **RPC:** https://mainnet.base.org
- **Latest Block Tested:** 43350749
- **Method:** eth_getCode

## Deliverables

- [x] Research packet (`research-packet.md`)
- [x] Proof spec (`proof-spec.md`)
- [x] Demo output (`demo-output.md`)
- [x] Live demo (`mini-app-monitor.html`)
- [x] Proof page (`proof-page.md`)
- [x] **This sample audit**

## Status

**Stage: VERIFY** - Core verification capability demonstrated. Ready for distribution proof.

## Consumer
current wedge proof surface and GitHub artifact lane

## Never Touch
Walter specialist work, Fundiora, and support-layer drift

---

## Agent Security Scanner Result (2026-03-14)

- **Scan Target**: skills/github-x-control/SKILL.md
- **Risk Score**: 5
- **Risk Level**: SAFE
- **Recommendation**: Proceed

### Findings
No obvious secret patterns found in the selected scan target.

### Workspace Policy Hits
- SECURITY.md:33 - Wallet private keys policy
- SECURITY.md:113 - No direct transactions policy

### Actionable Categories
- secret_hygiene
- runtime_guardrails
- publish_governance
- skill_installation_risk
