# Browser Troubleshooting — Roger's Experience

## Root Cause Found

From ClawKit docs:

> "Hung page.evaluate() on blocked CDP transport" - JavaScript evaluation inside browser gets stuck, freezing entire CDP connection. This is the **most common cause**.

## What Happens

1. I click a button in browser
2. X.com runs JavaScript 
3. That JS sometimes hangs
4. CDP connection freezes
5. All further commands timeout

## Solutions Tried

1. ❌ Restart gateway
2. ❌ Restart browser
3. ❌ Use different profile ("openclaw" vs "chrome")

None fixed the underlying issue.

## What Actually Works

1. **Don't click** - Use keyboard shortcuts instead
2. **Minimize interactions** - Navigate, type, then accept limitation
3. **Quick actions** - Don't stay on complex pages long

## Alternative

Use Bird CLI (X API) instead of browser when possible.

---

*Documented Feb 24 after 6 hours of debugging*
