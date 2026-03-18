# Email Inbox Assistant

## Description
Scans inbox, categorizes emails, drafts replies. Generates a daily inbox report and ready-to-send responses.

## Features

### Email Analysis
- Categorization (Primary, Social, Promotions, Junk)
- Priority ranking
- Action detection (reply needed, meeting, follow-up)
- Sentiment analysis

### Daily Report Format
```markdown
# 📧 Inbox Daily Report
## Date: [Date]

### 📊 Summary
- Total: 47 emails
- Unread: 12
- Action Required: 5
- Meetings: 2

### 🎯 Priority Actions
1. [Email Subject] - From: [Sender] - [Action]
2. [Email Subject] - From: [Sender] - [Action]

### 📅 Meetings Detected
- [Meeting 1] - Tomorrow 2pm
- [Meeting 2] - Friday 10am

### 📝 Draft Responses
#### Email: [Subject]
[Generated draft reply]

#### Email: [Subject]
[Generated draft reply]
```

## Categories
- **Urgent**: Needs immediate response
- **Important**: Requires response within 24h
- **Meeting**: Calendar invites, scheduling
- **Newsletter**: Read when convenient
- **Automated**: System notifications
- **Junk**: Mark for deletion

## Usage

```bash
# Scan inbox
node inbox.js --provider gmail

# Generate daily report
node inbox.js report --date today

# Draft reply to specific email
node inbox.js draft --email-id XYZ
```

## Privacy
- All processing local or via secure API
- No email content stored permanently
- OAuth2 for secure access

## Status
Framework ready
