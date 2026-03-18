# Deep Financial Research Report

## Description
Gathers market data, fundamentals, sentiment, and technicals. Output: Snapshot, Bull Case, Bear Case, Catalysts, Verdict.

## Input
- Target: crypto project, stock, or market
- Timeframe: short-term / medium-term / long-term
- Focus areas: (optional) specific metrics to prioritize

## Output Format

```markdown
# [Target] Research Report
Date: [Date]
Analyst: AI Agent

## 📊 Quick Snapshot
| Metric | Value | Change (24h) |
|--------|-------|--------------|
| Price | $X | +X% |
| Market Cap | $X | |
| Volume (24h) | $X | |
| TVL | $X | |

## 🐂 Bull Case
- [Argument 1]
- [Argument 2]
- [Argument 3]

## 🐻 Bear Case
- [Argument 1]
- [Argument 2]
- [Argument 3]

## 🔥 Catalysts
- Upcoming events
- Protocol upgrades
- Market conditions

## 🎯 Verdict
[BUY / SELL / HOLD] - [Confidence: X%]
```

## Data Sources
- CoinGecko API (price, market data)
- DeFiLlama (TVL)
- CryptoTwitter/X (sentiment)
- Official docs (fundamentals)
- TradingView (technical)

## Usage

```bash
# Generate report
node report.js --token ETH --output research.md

# Update with latest data
node report.js --token ETH --update
```

## Status
Script framework ready
