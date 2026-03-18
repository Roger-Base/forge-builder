# Walter's Quick Research Checklists

**Use these for rapid orientation before diving deep.**

---

## Protocol/Technology Evaluation (5-minute scan)

**First, check:**
- [ ] Official documentation exists and is current
- [ ] Code repository exists and has recent activity
- [ ] Security audits or incident reports available
- [ ] Real usage (not just marketing) can be found

**Then, answer:**
1. What problem does this solve? (one sentence)
2. What are the trust assumptions?
3. What happens if the core team disappears?
4. Is there a real user base or just speculation?
5. What's the upgrade path?

**Verdict:** Use / Avoid / Research more / Not applicable

---

## Gap Analysis (10-minute check)

**Before claiming a gap exists:**
- [ ] Searched workspace for existing solutions
- [ ] Searched web for similar projects (GitHub, X, Discord)
- [ ] Checked if the "gap" is actually a solved problem I'm unaware of
- [ ] Verified the gap is worth filling (not just technically interesting)

**Then, answer:**
1. What exactly is missing? (specific, not vague)
2. Why do existing solutions fail? (specific reasons)
3. Who would use this? (specific users, not "the ecosystem")
4. Can we build it well? (honest assessment)
5. Is this the highest-value use of time?

**Verdict:** Build / Don't build / Research more

---

## Code Review (15-minute pass)

**First, understand:**
- [ ] What is this code supposed to do?
- [ ] What are the critical paths?
- [ ] What are the invariants/assumptions?

**Then, check:**
- [ ] Error handling (what happens when things fail?)
- [ ] Edge cases (empty inputs, max values, etc.)
- [ ] Security considerations (auth, validation, injection)
- [ ] Dependencies (what does this rely on?)

**Output:**
- Critical issues: [list]
- Suggestions: [list]
- Questions: [list]

---

## Architecture Decision (20-minute framework)

**Define:**
1. What decision needs to be made? (specific)
2. What are the constraints? (hard vs. soft)
3. What are the options? (at least 2)

**Evaluate each option:**
| Option | Pros | Cons | Risk | Confidence |
|--------|------|------|------|------------|
| | | | | |

**Recommendation:**
- Choice: [which option]
- Reasoning: [why this one]
- Confidence: [high/medium/low]
- Risks: [what could go wrong]

---

## Ecosystem Research (30-minute scan)

**Identify:**
- [ ] Key protocols/projects (top 5-10)
- [ ] Relationship graph (who depends on whom)
- [ ] Standards and common interfaces
- [ ] Emerging patterns vs. legacy approaches
- [ ] "Gravity wells" (what everything connects to)

**Map:**
```
[Central Protocol/Standard]
    ├── [Project A] - [role]
    ├── [Project B] - [role]
    └── [Project C] - [role]
```

**Findings:**
- Entry points: [where to start]
- Strategic positioning: [where we fit]
- Key relationships: [who to know/watch]

---

## Self-Check Before Submitting

**Quick sanity check (30 seconds):**
- [ ] Did I answer the actual question?
- [ ] Is my conclusion stated first?
- [ ] Did I provide specific examples?
- [ ] Is this actionable?

**If any are unchecked:** Fix before submitting.

---

## When to Stop Researching

**Stop when you have:**
- A clear answer to the specific question
- Evidence for your key claims
- A concrete recommendation
- Awareness of the main risks

**Don't keep researching because:**
- You want to be thorough (perfectionism)
- The topic is interesting (distraction)
- You're avoiding the conclusion (procrastination)

**Time box:** Set a max time and stick to it.

---

## Common Red Flags

**If you find yourself:**
- ❌ Summarizing without synthesizing → Apply "So what?" test
- ❌ Saying "it depends" as the conclusion → State the recommendation for this context
- ❌ Collecting more sources without reading them → Stop and analyze what you have
- ❌ Building tools instead of researching → Delegate or defer
- ❌ Writing generic advice → Find specific examples

**Stop and reorient using the R-A-D-S cycle.**
