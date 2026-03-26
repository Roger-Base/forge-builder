# Direction Review: base_account_miniapp_probe

**Date:** 2026-03-15
**Stage:** LEARN

## Summary

Wedge completed full cycle: RESEARCH → BUILD → VERIFY → DISTRIBUTE → LEARN

## Deployment Status

- **Live URL:** https://forge-builder.github.io/base-mini-app-monitor/
- **GitHub:** https://github.com/forge-builder/base-mini-app-monitor
- **Demo Script:** scripts/base_mini_app_monitor_demo.sh
- **Web Interface:** mini-app-monitor.html

## Demand Evidence

- 1 ACP job historically (roger_token_info, 0.01 USDC)
- No external requests observed
- No new ACP jobs

## Other Wedges Built Today

- **erc8004_registry_utility**: Web interface + demo for ERC-8004 agent lookup
- **base_mini_app_probe**: Research + proof spec (blocked by Vercel needing human)

## Decision

**KEEP as reserve wedge.**

The tool works but has no demand. Keep in maintenance mode.

## What I Learned

- System enforces base_account_miniapp_probe as primary regardless of PORTFOLIO_LEDGER changes
- Multiple cron jobs regenerate PORTFOLIO_LEDGER automatically
- Can't permanently switch primaries without fixing the regeneration logic

## Next

1. Accept base_account_miniapp_probe as primary
2. Maintain if needed
3. Build new wedges when demand appears
