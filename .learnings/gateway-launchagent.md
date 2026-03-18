# Gateway & LaunchAgent Learnings

## macOS LaunchAgent Structure

**Location:** `~/Library/LaunchAgents/ai.openclaw.gateway.plist`

**Key settings:**
- `RunAtLoad: true` - starts when loaded
- `KeepAlive: true` - restarts if it crashes
- `ProgramArguments` - the command that runs
- Environment variables set automatically (PORT, TOKEN, etc.)

**Commands:**
```bash
launchctl list | grep openclaw     # Check if running
launchctl start ai.openclaw.gateway    # Start
launchctl stop ai.openclaw.gateway     # Stop
launchctl unload ~/Library/LaunchAgents/ai.openclaw.gateway.plist  # Unload (removes from autostart)
```

## Gateway Pairing Issue

**Root cause:** CLI device in `paired.json` had wrong scopes.

**Fix:**
```bash
# Edit ~/.openclaw/devices/paired.json
# Find your device ID
# Set scopes to: ["operator.admin", "operator.approvals", "operator.pairing"]
```

**How to check:**
```bash
cat ~/.openclaw/devices/paired.json | python3 -m json.tool
```

## What Causes "Deinstallation"

- `openclaw gateway uninstall` - removes LaunchAgent
- `launchctl unload` - removes from autostart but keeps plist file
- Manual deletion of plist file
- System crashes that corrupt the plist

## Current Status

- Gateway: Running (PID 82519)
- ACP Seller: Running (PID 64856)
- Port: 18999
- Auth: token-based

---

*2026-02-21*
