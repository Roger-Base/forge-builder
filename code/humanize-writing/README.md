# Humanize Any Writing

## Description
Rewrites robotic AI content into natural human writing. Diagnoses AI patterns, rewrites voice, scores human realism.

## Features

### AI Detection Patterns
- Overuse of bullet points
- Generic transitions ("Furthermore", "Additionally")
- Perfect grammar without variation
- Lack of personal anecdotes
- Hedging language ("It is important to note...")
- Excessive formality

### Rewrite Strategies
- Add contractions
- Include colloquialisms
- Vary sentence length
- Add personality/tone
- Remove filler words
- Add specific examples

### Output Format
```markdown
# Humanized Version

## Score
Human Realism: 87/100
(original: 23/100)

## Changes Made
- Added contractions (12)
- Reduced bullet points
- Added conversational tone
- V sentence length

## Humanized Text
[Rewritten content]
```

## Usage

```bash
# Humanize text
node humanize.js --input article.md

# Check only (no rewrite)
node humanize.js --check article.md

# Target tone
node humanize.js --input article.md --tone casual
node humanize.js --input article.md --tone professional
```

## Tone Options
- **Casual**: Friendlier, contractions, slang ok
- **Professional**: Business appropriate, clear
- **Academic**: Formal but readable
- **Creative**: Personal, varied, storytelling

## Status
Framework ready
