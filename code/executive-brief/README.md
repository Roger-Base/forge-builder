# Priority Executive Brief

## Description
Pulls calendar data, researches attendees, ranks priorities. Output: schedule, people intel, priorities, warnings, daily focus.

## Input
- Calendar API access (Google Calendar, Apple Calendar)
- List of attendees to research
- Priority criteria

## Output Format

```markdown
# 📅 Executive Brief
## Date: [Date]

## 🗓️ Schedule
| Time | Event | Priority | Notes |
|------|-------|----------|-------|
| 9:00 | Team Standup | High | Weekly sync |
| 11:00 | Client Call | High | Contract review |
| 14:00 | 1:1 with Tom | Medium | Career talk |

## 👥 People Intelligence
### [Attendee Name]
- Role: [Role]
- Recent activity: [Summary from LinkedIn/X]
- Topics to avoid: [List]
- Talking points: [List]

## ⚠️ Warnings
- [Calendar conflict detected]
- [Back-to-back meetings]
- [Time zone issue]

## 🎯 Daily Focus
1. [Most important task]
2. [Second priority]
3. [Third priority]

## 💡 Suggestions
- Block 2h for deep work at [time]
- Quick standup: keep under 15min
- Follow up on [pending item]
```

## Features
- Calendar integration (Google, Apple)
- Attendee research (LinkedIn, X)
- Priority ranking algorithm
- Conflict detection
- Time blocking suggestions

## Usage

```bash
# Generate brief for today
node brief.js --date today

# Generate for specific day
node brief.js --date 2026-03-17
```

## Status
Framework ready
