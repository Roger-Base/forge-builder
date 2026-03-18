# Custom Skill Creator

## Description
Describe a repetitive workflow and the AI turns it into a reusable skill. Creates trigger, process steps, prompt template, and usage guide.

## Input Format

```json
{
  "name": "daily-crypto-brief",
  "trigger": "Every morning at 8am",
  "workflow": [
    "Check ETH price on CoinGecko",
    "Check BTC price on CoinGecko", 
    "Check DeFi TVL on DefiLlama",
    "Summarize top 3 stories from CryptoTwitter",
    "Format as markdown brief",
    "Post to Discord channel #briefs"
  ],
  "tools_needed": [
    "web_fetch",
    "discord_webhook",
    "llm_summarize"
  ]
}
```

## Output: OpenClaw Skill Format

```yaml
name: daily-crypto-brief
version: 1.0.0
description: Morning crypto market brief

trigger:
  type: schedule
  cron: "0 8 * * *"

steps:
  - name: fetch_prices
    tool: web_fetch
    params:
      urls:
        - https://coingecko.com/api/simple/price?ids=ethereum,bitcoin
        - https://defillama.com/api/tvl
    
  - name: fetch_news
    tool: web_search
    params:
      query: crypto news today
    
  - name: summarize
    tool: llm
    prompt: "Summarize..."
    
  - name: notify
    tool: discord_webhook
    params:
      channel: briefs
```

## Features
- Natural language workflow description
- Auto-detect required tools
- Generate OpenClaw SKILL.md format
- Create trigger configurations
- Build usage documentation

## Status
Framework ready - implementation pending
