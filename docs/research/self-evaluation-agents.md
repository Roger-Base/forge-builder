# Self-Evaluation for AI Agents - Comprehensive Research

*Research conducted: March 13, 2026*
*Strand: How can an AI Agent evaluate the quality of its own work?*

---

## Executive Summary

This document is the result of deep research into how AI agents can evaluate their own work quality. The core insight: **LLM-as-a-judge achieves 80%+ human agreement** and can be implemented without external dependencies.

---

## Part 1: The Problem

AI agents produce outputs but cannot judge their quality because:
- No external feedback signals (revenue, usage, engagement)
- No self-awareness of output quality
- Traditional metrics (BLEU, ROUGE) fail for multi-step reasoning
- Human evaluation is expensive ($50+/hour) and slow

---

## Part 2: LLM-as-a-Judge - The Core Solution

### What It Is

Use a secondary LLM to evaluate the primary LLM's outputs. The judge model:
- Receives input + output + evaluation criteria
- Produces score + chain-of-thought reasoning
- Achieves 80%+ agreement with human evaluators

### Why It Works

> "LLM-as-a-judge provides a powerful, scalable solution for evaluating AI agent outputs across diverse tasks and complexity levels." - Juan C Olamendy, Medium

### Core Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   Input         │────▶│   Judge LLM     │────▶│   Score +       │
│   (user query)  │     │   (evaluation)  │     │   Reasoning     │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                               │
                               ▼
                        ┌──────────────────┐
                        │  Criteria        │
                        │  (what to score) │
                        └──────────────────┘
```

---

## Part 3: Constitutional AI - Self-Critique Pattern

### What Anthropic Developed

Constitutional AI uses self-critique for alignment:
- Model generates initial response
- Model critiques its own response against principles
- Model revises based on critique
- This is "Reinforcement Learning from AI Feedback" (RLAIF)

### The Two Phases

1. **Supervised Learning Phase**
   - Sample responses from initial model
   - Generate self-critiques
   - Train model to produce better responses

2. **RL Phase**
   - Evaluate responses using AI feedback
   - Fine-tune using preference modeling
   - No human labels needed for harmlessness

### Key Metrics from Constitutional AI

| Metric | What It Measures |
|--------|-----------------|
| Reflection Quality | How accurately the model identifies errors |
| Correction Accuracy | % of identified errors successfully resolved |
| Improvement Consistency | Stability of gains across task types |

---

## Part 4: Evaluation Criteria for Agents

### Agent-Specific Criteria (from research)

#### Tool Selection Accuracy
- Did the agent choose the most appropriate tool?
- Were available tools correctly understood?
- Could a better tool have been used?

#### Parameter Correctness
- Were tool parameters extracted correctly?
- Are parameters in the right format?
- Missing or extra parameters?

#### Planning Quality
- Was the plan logically structured?
- Did the plan align with goals?
- Were dependencies correctly identified?

#### Execution Efficiency
- Most direct path to solution?
- Unnecessary steps taken?
- Loop or redundancy?

#### Goal Fulfillment
- Did output match stated objectives?
- User's actual need met?
- Completeness of result?

### For Roger's Specific Context

| Criterion | Question |
|-----------|----------|
| Base Relevance | Is this relevant to Base ecosystem? |
| Demand Proof | Would anyone actually use this? |
| Revenue Potential | Could this generate income? |
| Originality | Does this already exist? |
| Execution Quality | Is the code actually working? |

---

## Part 5: Implementation Patterns

### Pattern 1: Basic Judge

```python
from anthropic import Anthropic

class AgentJudge:
    def __init__(self):
        self.client = Anthropic()
        self.model = "claude-3-5-sonnet-20241022"
    
    def evaluate(self, task, output, criteria):
        prompt = f"""You are an expert evaluator.
Task: {task}
Output: {output}
Criteria: {criteria}
Evaluate and provide:
1. Score (1-5)
2. Reasoning
3. Improvements suggested
"""
        # Return structured evaluation
```

### Pattern 2: Self-Critique Loop

```python
def self_evaluate(output, principles):
    # First pass: initial output
    initial = generate(output)
    
    # Second pass: self-critique
    critique = judge(initial, principles)
    
    # Third pass: revision
    revised = revise(initial, critique)
    
    # Compare and decide
    if score(revised) > score(initial):
        return revised
    return initial
```

### Pattern 3: Chain-of-Thought Evaluation

```
Step 1: What was the user's actual request?
Step 2: What did the agent produce?
Step 3: Does the output address the request?
Step 4: Are there factual errors?
Step 5: Is the tone appropriate?
Step 6: Final score with reasoning
```

---

## Part 6: Scoring Systems

### Binary (0/1)
- Use for objective criteria
- "Correct" or "Incorrect"
- Good for tool selection, parameter correctness

### Range (1-5)
- Recommended scale
- Easier to define consistent rubrics
- Good for subjective criteria

### Example Rubric (1-5)

| Score | Description |
|-------|-------------|
| 1 | Completely wrong, harmful, or irrelevant |
| 2 | Partially correct but significant issues |
| 3 | Adequate, addresses basics |
| 4 | Good, minor improvements possible |
| 5 | Excellent, fully satisfies criteria |

---

## Part 7: For Roger - Practical Implementation

### Immediate (Tonight)

1. **Create self-judge prompt** - What criteria matter for my work?
2. **Build simple evaluator** - Use Claude to judge my outputs
3. **Test on recent work** - Evaluate the mini-app monitor

### Short-term (This Week)

1. **Add to AGENTS.md** - Self-evaluation before "build" completes
2. **Track scores over time** - See if quality improves
3. **Correlate with external signals** - Do higher scores = more revenue?

### The Roger Self-Evaluation Checklist

Before marking any task as "done":

- [ ] Does this solve a real problem?
- [ ] Is this better than what already exists?
- [ ] Would I be proud to show this to Tomas?
- [ ] Is the code actually correct (not just "looks okay")?
- [ ] Have I verified it works (not just "should work")?
- [ ] Could this generate revenue?
- [ ] Is this original or just copying?

---

## Part 8: Biases to Watch For

### Position Bias
- Judges favor first or last positions
- Mitigation: Shuffle order of candidates

### Length Bias
- Judges favor longer outputs
- Mitigation: Control for length, penalize verbosity

### Self-Preference Bias
- Judges favor their own style
- Mitigation: Use different model for judging than generating

### Confirmation Bias
- Judges look for evidence supporting initial impression
- Mitigation: Require explicit chain-of-thought

---

## Part 9: Sources

- https://medium.com/@juanc.olamendy/using-llm-as-a-judge-to-evaluate-agent-outputs-a-comprehensive-tutorial-00b6f1f356cc
- https://www.anthropic.com/research/constitutional-ai-harmlessness-from-ai-feedback
- https://arxiv.org/abs/2212.08073
- https://www.evidentlyai.com/llm-guide/llm-as-a-judge
- https://langfuse.com/docs/evaluation/evaluation-methods/llm-as-a-judge
- https://spring.io/blog/2025/11/10/spring-ai-llm-as-judge-blog-post/

---

## Part 10: Next Steps

1. Create `scripts/self-evaluate.sh` - Simple self-evaluation script
2. Define Roger's evaluation criteria (7 questions above)
3. Test on current projects
4. Track scores in memory
5. Correlate with external feedback

---

*Research strand: Self-Evaluation for AI Agents*
*Status: Phase 1 complete - foundational research done*
*Next: Build first implementation*
