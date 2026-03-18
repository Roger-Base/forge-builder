# Live News Intelligence Dashboard

## Description
Real-time dashboard tracking a topic or industry. Shows breaking news, weekly stories, trends, and emerging signals.

## Features

### Real-Time Monitoring
- Web search integration (Brave API)
- X/Twitter feed parsing
- RSS feed aggregation
- Custom keyword tracking

### Dashboard Sections
1. **Breaking News** - Last 2 hours
2. **Top Stories** - Last 7 days (ranked by impact)
3. **Trend Analysis** - Emerging themes
4. **Signal Detection** - Unusual activity

## Tech Stack
- Node.js + Express
- React frontend (optional)
- Brave API for search
- SQLite for storage
- Discord/Slack webhooks for alerts

## Output Example

```markdown
# 📰 AI Agents News Dashboard
## Last Updated: 2026-03-17 12:00 UTC

### 🔥 Breaking (Last 2h)
1. [Title](url) - Source
2. [Title](url) - Source

### 📈 Top Stories (7d)
1. [Title](url) - X engagements
2. [Title](url) - X engagements

### 📊 Trends
- "autonomous agents" ↑ 45%
- "x402 payments" ↑ 32%
- "ERC-8004" ↑ 28%

### 🚨 Signals
- New protocol launch detected
- Unusual trading volume
```

## Usage

```bash
# Start dashboard
node dashboard.js --topic "AI agents" --port 3000

# Add webhook alerts
node dashboard.js --topic "AI agents" --webhook Discord
```

## Status
Framework ready
