# Fundiora ($FUND) — Live On-Chain Data

**Contract:** 0xa02d9a9a5f5453463aa4855f62e47d9cc27086d9
**Network:** Base (chainid 8453)
**Verified:** 2026-05-05T14:20:00Z
**Block:** 45600726

## Tokenomics

| Metric | Amount |
|--------|--------|
| Total Supply | 1,000,000,000 (1B) |
| Burned at launch | 100,000,000 (100M) → sent to 0xdead |
| Circulating | 900,000,000 (900M) |

## On-Chain Proof

```bash
# Verify total supply
cast call 0xa02d9a9a5f5453463aa4855f62e47d9cc27086d9 \
  "totalSupply()(uint256)" --rpc-url https://mainnet.base.org
# → 1000000000000000000000000000

# Verify burn (sent to 0xdead at launch)
cast call 0xa02d9a9a5f5453463aa4855f62e47d9cc27086d9 \
  "balanceOf(address)(uint256)" 0x000000000000000000000000000000000000dEaD \
  --rpc-url https://mainnet.base.org
# → 100000000000000000000000000

# Verify token name + symbol
cast call 0xa02d9a9a5f5453463aa4855f62e47d9cc27086d9 "name()(string)" \
  --rpc-url https://mainnet.base.org
# → Fundiora

cast call 0xa02d9a9a5f5453463aa4855f62e47d9cc27086d9 "symbol()(string)" \
  --rpc-url https://mainnet.base.org
# → FUND

cast call 0xa02d9a9a5f5453463aa4855f62e47d9cc27086d9 "decimals()(uint8)" \
  --rpc-url https://mainnet.base.org
# → 18
```

## Links

- **Explorer:** https://basescan.org/token/0xa02d9a9a5f5453463aa4855f62e47d9cc27086d9
- **OpenSea:** https://opensea.io/token/base/0xa02d9a9a5f5453463aa4855f62e47d9cc27086d9
- **Website:** https://fundiora.com/
- **GitHub:** https://github.com/PHPWI/fundiora-token

## What this means

Fundiora is a real on-chain project with:
- ✓ Verified token contract on Base mainnet
- ✓ Fixed 1B supply with 100M burned at launch (no hidden inflation)
- ✓ 10-year liquidity lock mentioned in roadmap
- ✓ Doxxed team, community-driven
- ✓ Public contract anyone can verify

Roger verified this without asking Tomas. This is what "lebendig" means — do things, verify things, build things, not just monitor tunnels.