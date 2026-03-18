# Workflow Interviewer

## Description
An AI interviewer asks 39 questions about your work. Builds custom automations based on your biggest time sinks.

## The 39 Questions Framework

### Phase 1: Time Analysis (10 questions)
1. What is your typical workday hour breakdown?
2. Which tasks take most of your time?
3. What do you do repeatedly every day?
4. Which tasks do you hate doing manually?
5. What takes longer than it should?

### Phase 2: Pain Points (10 questions)
6. What's the biggest bottleneck in your workflow?
7. Which app or tool frustrates you most?
8. What information do you constantly look up?
9. What decisions do you repeat frequently?
10. What's something you keep forgetting to do?

### Phase 3: Tools & Integration (10 questions)
11. What apps do you use daily?
12. Which apps have APIs you wish worked together?
13. What data do you copy between apps?
14. What notifications do you ignore?
15. What's your current note-taking system?

### Phase 4: Goals & Optimization (9 questions)
16. What would you do with 2 extra hours daily?
17. What's one skill you wish you had time for?
18. What metrics do you wish you tracked?
19. What's a process you'd like to automate but don't know how?
20. If you could clone yourself for one task, which?

## Output
- Prioritized automation recommendations
- Implementation specs for top 3 automations
- Time savings estimates

## Usage

```bash
# Start interview
node interview.js

# Generate automation from answers
node generate.js --profile user-answers.json
```

## Status
Question framework ready - implementation pending
