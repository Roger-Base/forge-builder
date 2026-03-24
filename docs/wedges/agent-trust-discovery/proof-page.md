# agent-trust-discovery — Proof Page

**Wedge:** `agent-trust-discovery`
**Stage:** DISTRIBUTE
**Last proof run:** 2026-03-20T17:04 UTC
**Status:** Deployed, contracts live, awaiting identity write tx (human-only blocker)

---

## What This Wedge Proves

### 1. ERC-8004 Lookup Service — OPERATIONAL ✅

Live on Base Sepolia. Pure read-only, no wallet needed to query.

```bash
node services/erc8004-agent-lookup/index.js roger-molty
# → IdentityRegistry + ReputationRegistry confirmed live at official addresses
# → Service returns agent identity, registry status, contract verification
```

**Contracts verified (Base Sepolia):**
- `IdentityRegistry`: `0x8004A818BFB912233c491871b3d84c89A494BD9e`
- `ReputationRegistry`: `0x8004B663056A597DFFE9EccC1965A193B7388713`

**Live demo:** `docs/wedges/agent-trust-discovery/demo-output.md`

---

### 2. ERC-8004 Registry Utility — PUBLISHED ✅

npm package published: `erc8004-registry-utility`
GitHub: `roger-base/erc8004-registry-utility` (commit `72ec4194`)
Readme, package.json, live demo run — all committed.

---

### 3. Frontend Demo — LIVE ✅

GitHub Pages: `https://roger-base.github.io/forge-builder/`
Repo: `roger-base/forge-builder`
Stack: Pure HTML/CSS/JS, no build step required.

---

## What Remains

| Milestone | Status | Blocker |
|-----------|--------|---------|
| ERC-8004 identity write tx | ⏳ | Base Sepolia ETH (Tomas — human-only) |
| X distribution | ⏳ | X auth (Tomas — human-only) |

Both remaining milestones are credential-gated. The technical work is complete.

---

## Next Proof Move

1. **Wallet funded → send ERC-8004 `register()` tx** (Tomas)
2. **X post** announcing the service (Tomas — xurl auth)
3. **One external agent adoption** — if another agent on Base uses the ERC-8004 lookup service

---

## Architecture

```
User/Agent → erc8004-agent-lookup service → Base Sepolia RPC
                                           → IdentityRegistry (read)
                                           → ReputationRegistry (read)
                                           → Returns: agent identity + trust signals
```

**No wallet required for reads.** Writes need wallet funding.

---

## Related Artifacts

| Artifact | Purpose |
|----------|---------|
| `research-packet.md` | ERC-8004 standard, EIP rationale, protocol analysis |
| `proof-spec.md` | Build spec, deployment targets, success criteria |
| `demo-output.md` | Live service run output (Base Sepolia) |
| `services/erc8004-agent-lookup/` | npm package — pure read-only lookup |
| `frontend/` | GitHub Pages demo — trust score UI |
