# Feedback Loop Systems for AI Agents - Research

*Research conducted: March 13, 2026*

## Executive Summary

Roger lacks external feedback signals to evaluate his work. This document researches what's available and proposes a feedback loop system.

---

## What I Found

### 1. Agent Evaluation Frameworks (External)

| Framework | What It Does | Relevance |
|-----------|--------------|-----------|
| **DeepEval (Confident AI)** | LLM evaluation framework with PlanQualityMetric, PlanAdherenceMetric | Could integrate |
| **LangSmith** | Continuous agent evaluation, human feedback loops | Could integrate |
| **AgentOps** | Tool selection quality, context adherence metrics | Could track |
| **LLM-as-Judge** | Secondary LLM evaluates agent output quality | Could use |

**Key Insight**: "They typically consist of four components — a performance element (makes initial decisions), a learning element (improves the agent based on feedback), a critic (evaluates performance against some ideal), and a problem generator (proposes exploratory actions)." - Dave Davies, Medium

### 2. Self-Evaluation Methods

From Anthropic's Constitutional AI:
- Models trained with feedback loops that critique their own outputs show improvements in alignment and safety
- **Reflection Quality**: How accurately the model identifies errors
- **Correction Accuracy**: Percentage of identified errors resolved
- **Improvement Consistency**: Stability of gains across task types

### 3. Human-in-the-Loop Feedback

From Google Cloud:
- "For complex tasks, a human expert evaluates the agent's final output for quality, nuance, and correctness"
- Creates "human-in-the-loop" feedback system

### 4. GitHub Pages Analytics Options

| Option | Pros | Cons |
|--------|------|------|
| **Cloudflare Pages** | Built-in analytics | Need to switch from GitHub Pages |
| **Google Analytics** | Full features | Blocked by AdBlock |
| **Plausible** | Privacy-friendly | Paid |
| **umami** | Self-hosted, free | Need hosting |

**Key Finding**: GitHub Pages has NO built-in analytics. Must add third-party.

### 5. Virtuals/ACP Feedback Mechanisms

From Virtuals Whitepaper:
- "Feedback from users based on completed jobs" - displayed on agent page
- "At the end of each job, users would be prompted to provide their rating and/or review via DM from Butler Agent"
- **Current Status**: Roger has 0 jobs = 0 feedback

---

## What's Missing for Roger

### Current State

| Feedback Channel | Status | Problem |
|-----------------|--------|---------|
| ACP Jobs | 0 | No revenue = no signal |
| GitHub Pages Analytics | None | Can't measure usage |
| X Engagement | Low | No followers/engagement |
| Tomas Feedback | Rare | Only when he asks |

### Root Problem

**Roger cannot evaluate quality because:**
1. No usage data (who visits demos?)
2. No revenue feedback (who pays?)
3. No engagement metrics (who cares?)
4. No self-evaluation framework (how would I judge?)

---

## Proposed Solution: Roger Feedback Loop System

### Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   External      │────▶│   Feedback       │────▶│   Decision      │
│   Signals       │     │   Aggregator    │     │   Engine        │
└─────────────────┘     └──────────────────┘     └─────────────────┘
        │                       │                        │
        ▼                       ▼                        ▼
   - ACP Jobs            - Score Calculator       - Build/Stop
   - GitHub Views        - Trend Analysis         - Improve
   - X Mentions         - Quality Metrics        - Research
   - Tomas Direct        - Anomaly Detection
```

### Components to Build

#### 1. Usage Tracker (GitHub Pages)
**Options:**
- Add Plausible or umami to demos
- OR switch to Cloudflare Pages (has analytics built-in)
- Simple solution: Add hit counter badge

#### 2. ACP Job Monitor
- Already running: `acp job active`
- Need: Track over time, not just current state
- Alert when jobs increase/decrease

#### 3. Self-Evaluation Checkpoint
Before every "build" action:
- Have I received external signal this is needed?
- When was the last external signal?
- Is signal stale (>30 days)?

#### 4. Tomas Feedback Queue
- Create system for Tomas to rate work
- Simple: Quick rating after each demo update

---

## Implementation Priority

### Immediate (This Week)
1. **Add hit counter to demos** - Simple GitHub profile views counter
2. **Create "last signal" tracking** - When did I last receive feedback?
3. **Ask Tomas directly** - "Is this useful?" for each project

### Short-term (This Month)
1. **Set up umami analytics** - Self-hosted, free
2. **Build feedback aggregator** - Central dashboard
3. **Define quality metrics** - What counts as "good"?

### Long-term
1. **Integrate LLM-as-Judge** - Evaluate own outputs
2. **Build trend analysis** - Improvement over time
3. **Auto-adjust priorities** - Based on feedback signals

---

## What Already Exists That I Can Use

| Tool | Use |
|------|-----|
| `acp job active` | Revenue feedback |
| GitHub traffic (private) | Repo views |
| Virtuals agent page | Job completion ratings |
| session-logs skill | Analyze past sessions |

---

## Questions for Tomas

1. Should I switch from GitHub Pages to Cloudflare Pages (has analytics)?
2. How should I measure "success" for my projects?
3. Can you give me direct feedback after each build?

---

## Research Sources

- https://deepeval.com/guides/guides-ai-agent-evaluation
- https://aws.amazon.com/blogs/machine-learning/evaluating-ai-agents-real-world-lessons-from-building-agentic-systems-at-amazon/
- https://medium.com/online-inference/ai-agent-evaluation-frameworks-strategies-and-best-practices-9dc3cfdf9890
- https://www.langchain.com/langsmith/evaluation
- https://galileo.ai/blog/self-evaluation-ai-agents-performance-reasoning-reflection
- https://github.com/orgs/community/discussions/31474
- https://whitepaper.virtuals.io/about-virtuals/agent-commerce-protocol/acp-current-status

---

*Research done by Roger - March 13, 2026*
