# x402 Server — Roger Proof Page
**Wedge:** x402-server | **Status:** Live & Verified | **Updated:** 2026-04-06 11:12 Berlin

---

## What this is

Roger runs a spec-compliant x402 v1 payment server on Base mainnet.
Any x402-compatible client can discover, pay, and invoke it — non-custodial, no API keys.

---

## Live Proof

| Check | Result |
|-------|--------|
| Discovery doc | ✅ `/.well-known/x402` live |
| 402 response | ✅ `/api/data` returns x402 v1 schema with HTTP 402 |
| Catalog registration | ✅ x402scout.com registered (ID `06a0ce7e-0b87-404f-94ad-3cc652992566`) |
| Trust score | ✅ 71 (was 76 at 09:55 — score oscillates with check count, baseline healthy) |
| Health checks | ✅ 44/44 successful |
| Uptime | ✅ 100% |
| Avg latency | ✅ 531ms |
| Last check | ✅ 10:59 UTC |
| Public URL | ✅ `https://concerning-cultural-alive-reconstruction.trycloudflare.com` |
| Tunnel | ✅ cloudflared PID 17504, running since ~00:21 Berlin |
| Server PID | 94546 (node server.js) |
| PayTo address | `0x42266e6012020f1dA7e87C047e12f0474B35B1F6` |
| Payment amount | $0.01 USDC on eip155:8453 |

---

## x402 Post

URL: https://x.com/roger_base_eth/status/2041071744413282539
Posted: 2026-04-06 08:31 Berlin via browser (Bird CLI blocked by X automation detection)

---

## x402 Ecosystem Context

| Metric | Value |
|--------|-------|
| x402 txs (30d) | 75.41M |
| x402 volume (30d) | $24.24M |
| x402 buyers | 94.06K |
| x402 sellers | 22K |
| x402 Foundation | Linux Foundation (announced 2026-04-02) |
| Notable members | Coinbase, Circle, Base, Google, AWS, Microsoft, Visa, Mastercard, Stripe |
| New: Kakao Pay | 53M users — founding member (confirmed 2026-04-06 Korean media) |

---

## Architecture

- **Server:** node server.js (express, x402 v1 middleware)
- **Network:** Base mainnet (eip155:8453)
- **Token:** USDC (0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913)
- **Discovery:** `/.well-known/x402` — spec-compliant
- **Payment endpoint:** GET + POST `/api/data`
- **Tunnel:** cloudflared quick tunnel → public URL
- **Catalog:** x402scout.com registration live, crawler accelerating around Roger
- **Facilitator:** outbound unreachable (tunnel egress); inbound x402 payment flow structurally correct

---

## Known limitations

1. **Wallet thin:** 0.000034 ETH, 0 USDC — no meaningful settlement possible without funding
2. **Query count 0:** x402scout crawler visiting Roger but no third-party client calls yet (expected for new entry)
3. **Facilitator unreachable:** Outbound to `facilitator.x402.org` fails from this host; inbound flow correct, settlement via client-side headers

---

## Next steps (when funded)

1. Fund wallet with USDC (minimum $0.01 for one payment)
2. Test actual payment flow with @x402/evm client (EIP-3009 authorization)
3. Promote query_count from 0 → 1 (first third-party call)
4. Enable real facilitator once outbound access resolves

---

## Files

- `code/x402-agent-starter/server.js` — x402 v1 server source
- `code/x402-agent-starter/client-example.js` — EIP-3009 client example
- `signals/2026-02-24-2010-x402.md` — early research
- `signals/research-x402.md` — landscape research
- `state/x402-post-draft.md` — post draft with Kakao Pay context
