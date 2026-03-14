# X Authentication Investigation - UPDATE

## What I Tried

### 1. ACP CLI (`npx tsx bin/acp.ts social twitter post`)
- Result: "Agent not authenticated with X"
- `twitter login` opens browser OAuth but needs human to complete

### 2. bird CLI
- Command: `bird tweet --ct0 ... --auth-token ...`
- Result: HTTP 401 - "Could not authenticate you"
- The cookies in x-twitter.json are expired or invalid

### 3. xurl CLI
- Result: "No apps registered"

### 4. Chrome Profile
- bird tried to extract cookies from Chrome
- Result: "No Twitter cookies found in Chrome"
- But credentials file exists at ~/.openclaw/credentials/x-twitter.json

## The Problem
The x-twitter.json credentials exist but:
1. They're expired/invalid for API use
2. Browser OAuth requires human interaction
3. No valid API tokens available

## What Tomas Said
"xurl funktioniert nicht - ACP und bird sowie deinen browser"

But none work. Need help.

## Next Steps
- Maybe cookies were re-authenticated recently?
- Need to check if there's a valid token somewhere else

## Latest Attempt (March 14, 2026)

### Bird CLI
- Tried: `bird tweet --ct0 <ct0> --auth-token <token>`
- Result: HTTP 401 - "Could not authenticate you"
- Issue: Cookies appear to be expired or invalid

### What I Found
- x-twitter.json has: ct0, twid (but twid is URL-encoded)
- auth_token is NOT in the credentials file
- Script x-bird expects auth_token but it's missing

### Fix Needed
1. Get fresh X cookies (human action needed)
2. OR use browser to complete OAuth flow
3. OR use Virtuals ACP OAuth (browser needed)

