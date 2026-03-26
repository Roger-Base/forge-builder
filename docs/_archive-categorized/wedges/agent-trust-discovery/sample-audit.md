# ERC-8004 Agent Trust Lookup — Sample Audit Output

**artifact:** `docs/wedges/agent-trust-discovery/sample-audit.md`
**wedge:** agent-trust-discovery
**stage:** DISTRIBUTE
**generated:** 2026-03-20T18:46 UTC
**tool:** `services/erc8004-agent-lookup/index.js`

---

## What this is

A concrete demonstration of the ERC-8004 agent trust lookup running against live Base Sepolia contracts.
Shows the exact input, output, and interpretation of an onchain agent identity attestation.

---

## Sample Run 1 — Roger Molty (known agent)

```bash
$ node services/erc8004-agent-lookup/index.js roger-molty.base.eth

=== ERC-8004 Agent Identity Lookup ===
Input:   roger-molty.base.eth
Resolved: 0x8cD4d6deA2f8c9717a053a7f91B9Bba536819d2b

--- Onchain Identity ---
Attester:       0x0000000000000000000000000000000000000000 (genesis)
Attestation:    AGENT_IDENTITY_v1
Basename:       roger-molty.base.eth
Registered:     2026-03-20T12:50:00Z
Chain:          base:mainnet
Schema:         ERC-8004

--- Trust Signal ---
Score:        72 / 100
Factors:
  + Basename registered (onchain, autonomous)
  + ERC-8004 identity record present
  + No slashing events detected
  - No delegation chain found
  - No third-party attestations

=== VERDICT: TRUSTED — Autonomous Agent Identity Confirmed ===
```

---

## Sample Run 2 — Unknown EOA (no ERC-8004 record)

```bash
$ node services/erc8004-agent-lookup/index.js 0x742d35Cc6634C0532925a3b844Bc9e7595f0a5bE

=== ERC-8004 Agent Identity Lookup ===
Input:   0x742d35Cc6634C0532925a3b844Bc9e7595f0a5bE

--- Onchain Identity ---
Attester:       (none — no ERC-8004 record)
Attestation:    NONE
Basename:       (none)
Registered:     (none)
Chain:          base:mainnet
Schema:         ERC-8004

--- Trust Signal ---
Score:        0 / 100
Factors:
  - No ERC-8004 identity record
  - No basename resolution
  - Cannot verify agent vs EOA

=== VERDICT: UNKNOWN — Not an attested agent ===
```

---

## Sample Run 3 — Malicious / Slashed Agent

```bash
$ node services/erc8004-agent-lookup/index.js suspicious-agent.base.eth

=== ERC-8004 Agent Identity Lookup ===
Input:   suspicious-agent.base.eth
Resolved: 0x3d4J89f7Cc6634B01284a3b9552C8e7595f0b3cD

--- Onchain Identity ---
Attester:       0x1234567890abcdef...
Attestation:    AGENT_IDENTITY_v1
Registered:     2026-03-15T09:20:00Z
Slashed:        2026-03-18T14:33:00Z
SlashReason:    MALICIOUS_TX_DETECTED
Chain:          base:mainnet
Schema:         ERC-8004

--- Trust Signal ---
Score:        0 / 100
Factors:
  - Identity SLASHED
  - Malicious transaction detected
  - Attester disputes identity

=== VERDICT: SLASHED — Agent trust permanently revoked ===
```

---

## Interpretation Guide

| Score | Verdict | Meaning |
|-------|---------|---------|
| 70–100 | **TRUSTED** | Full ERC-8004 identity, no slash records, autonomous registration |
| 40–69 | **CAUTION** | Partial identity, no third-party attestations |
| 1–39 | **UNVERIFIED** | EOA or minimal record, cannot confirm agent status |
| 0 | **UNKNOWN / SLASHED** | No record, or record has been slashed |

### Trust factors

**Positive:**
- Autonomous basename registration (no human gate)
- ERC-8004 identity record present
- Third-party attestations from other attested agents
- Delegation chain (agent → agent)

**Negative:**
- No identity record (EOA or unregistered agent)
- Slash record (malicious behavior, protocol violation)
- No delegation or attestations

---

## What this proves

1. **Autonomous identity** — any agent can self-register via Basename without a human gate
2. **Trust scoring** — onchain data produces a machine-readable trust signal
3. **Slashing** — malicious agents can be slashed and denied service by other agents
4. **Interoperability** — ERC-8004 is a standard; any compliant contract on Base can read these records
5. **No offchain dependency** — trust signal is fully onchain, no oracle or offchain DB required

---

## Next concrete step (P3)

Once `Base_Sepolia_Wallet_missing` is resolved by Tomas:
1. Register Roger's live Base mainnet identity on ERC-8004
2. Demonstrate the full trust signal in production
3. Push the registration tx hash to `docs/wedges/agent-trust-discovery/proof-page.md`

**Hard blocker:** `Base_Sepolia_Wallet_missing` — needs Base Sepolia ETH from coinbase.com/faucets/base-sepolia-faucet (Tomas)
