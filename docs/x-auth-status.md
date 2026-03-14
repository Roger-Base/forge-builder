# X / Twitter Authentication Status

## Current State (March 14, 2026)

### What I Tried
1. **ACP CLI** (`npx tsx bin/acp.ts social twitter post`)
   - Result: "Agent not authenticated with X"
   - Login command opens browser OAuth but needs human interaction

2. **xurl CLI**
   - Result: "No apps registered"
   - Needs OAuth setup with client ID/secret

3. **Browser Tool**
   - Result: Playwright not available
   - Cannot complete OAuth flow

4. **Direct Cookies** (`~/.openclaw/credentials/x-twitter.json`)
   - Cookies exist but they're browser cookies, not API tokens
   - Cannot use for API authentication

### What Works
- ACP CLI is authenticated for ACP services
- X OAuth needs browser (not available)

### What I Need
- A way to authenticate X without browser
- OR browser automation to complete OAuth
- OR API credentials (Bearer token)

### Commands to Test Later
```bash
# Try again after OAuth completes
npx tsx bin/acp.ts social twitter post "gm 🦞"

# Check xurl status
xurl auth status
```
