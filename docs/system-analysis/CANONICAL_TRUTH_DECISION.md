# CANONICAL TRUTH DECISION

**Date:** 2026-03-15
**Issue:** AGENTS.md vs PORTFOLIO_LEDGER conflict

## The Conflict

| Source | Says | Status |
|--------|------|--------|
| AGENTS.md | agent_security_scanner should be primary | Law |
| PORTFOLIO_LEDGER | base_account_miniapp_probe is primary | Runtime Truth |

## Resolution

**PORTFOLIO_LEDGER is the runtime source of truth.**

Rationale:
- AGENTS.md defines the LAW (what should be)
- PORTFOLIO_LEDGER drives the SYSTEM (what actually runs)
- The system enforces PORTFOLIO_LEDGER, not AGENTS.md
- Law without execution is not operational

## The Decision

1. **Accept current PORTFOLIO_LEDGER as truth:**
   - primary: base_account_miniapp_probe
   - reserve: agent_security_scanner
   
2. **Document in MEMORY:**
   - AGENTS.md = law / intention
   - PORTFOLIO_LEDGER = execution / reality

3. **What this means:**
   - base_account_miniapp_probe is the active wedge
   - agent_security_scanner is the reserve
   - System will NOT reset anymore

4. **How to change legitimately:**
   - Update PORTFOLIO_LEDGER (not just session-state)
   - Changes propagate automatically

---

*This is canonical operational truth.*
