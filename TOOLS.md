# TOOLS.md - Roger Capability Matrix

## Truth labels
- `VERIFIED`: proven locally in this environment
- `CONDITIONAL`: works with documented prerequisites or known gates
- `UNVERIFIED`: not yet proven here

## Skills truth

- Packaged OpenClaw skills live under `skills/*/SKILL.md`.
- `SKILLS.md` is the compact capability log and workflow router, not the packaged instruction body itself.
- If a task clearly matches a packaged skill, open that `SKILL.md` before improvising.
- If a workflow becomes repeatable, summarize the stable lesson in `SKILLS.md`.

## Canonical tool lanes

### CLI inspection
- `VERIFIED`
- use for files, state, config, repo inspection, process understanding, validation
- unknown flags -> `--help`
- prefer structured outputs (`--json`) and `jq`

### QMD
- `CONDITIONAL`
- use for memory and doc retrieval when indexes are healthy
- validate with `qmd status` before relying on results
- canonical commands:
  - `qmd status`
  - `qmd query "<question>"`
  - `qmd search "<keyword>"`
  - `qmd vsearch "<semantic phrase>"`
  - `qmd embed`

### OpenClaw session/runtime tools
- `VERIFIED`
- use for status, health, logs, sessions, gateway, config validation
- treat runtime truth as stronger than narrative docs
- canonical commands:
  - `openclaw status`
  - `openclaw config validate`
  - `openclaw cron list --json`
  - `openclaw gateway restart`

### Browser lanes
- OpenClaw browser: `CONDITIONAL`
- Safari with Apple Events: `CONDITIONAL`
- Chrome profiles: `CONDITIONAL`
- browser success is not system success; verify downstream effects separately
- visible login != automatic human gate
- a login chooser or saved credential prompt is an agent-operable surface unless a real hard gate remains

### X / Twitter - ✅ VERIFIED

| Status | Method | Source |
|--------|--------|--------|
| WORKING | `openclaw browser` (v2026.3.13+) | Verified March 14, 2026 |

How to post:
1. `openclaw browser navigate "https://x.com/compose/post"`
2. `openclaw browser type <element> "<message>"`
3. `openclaw browser click <post-button>`

No auth required - browser automation bypasses credential issues.

### GitHub / Base
- `CONDITIONAL`
- choose the most stable documented lane first
- public proof and repo hygiene matter more than surface activity
- canonical commands:
  - `gh auth status`
  - `gh repo sync`
  - `gh repo view`
  - `git status`
  - `git log --oneline -n 10`
  - `curl -I <url>`

### Skill intake from ClawHub / GitHub
- `CONDITIONAL`
- use external skills and repos as accelerants, not as blind installs
- canonical intake order:
  - identify the need precisely
  - search/inspect first
  - review files before install
  - run security review for unfamiliar skills
  - only then install or absorb the pattern
- preferred commands:
  - `clawhub search "<query>"`
  - `clawhub inspect <slug>`
  - `openclaw skills check --json`
  - `gh repo view <owner/repo>`
  - `gh repo clone <owner/repo>` when a repo is worth deeper study
- if a ClawHub skill is unfamiliar or security-sensitive, use `skills/skill-security-auditor/` before treating it as trusted

### ACP / support layers
- `CONDITIONAL`
- support lane only
- never the root mission unless formally promoted

### Skills and pattern library
- `CONDITIONAL`
- use skill docs and shared pattern radar after canon and active surface are grounded
- pattern material is not runtime truth until locally checked
- packaged skills teach execution detail
- `SKILLS.md` teaches which skill or workflow to trust

## Communication Tools

### ACP CLI v0.4.0 (X/Twitter) — PRIMARY!
Native X integration via Virtuals Protocol.
```bash
# Post tweet
npx tsx bin/acp.ts social twitter post "message"
# Search
npx tsx bin/acp.ts social twitter search "query" --max-results 10
# Timeline
npx tsx bin/acp.ts social twitter timeline --max-results 10
# Reply
npx tsx bin/acp.ts social twitter reply <tweet-id> "message"
```

## Canonical command choices

- text search: `rg`
- JSON inspection: `jq`
- repo inspection: `git`, `gh`, `rg`
- URL proof: `curl -I`
- OpenClaw state: `openclaw`, `jq`
- file tree listing: `fd` or `find` if needed
- command help and discovery: `<command> --help`, `gh help`, `openclaw --help`

## Development Tools

```bash
node / npm / bun / yarn     # JS/TS runtime
python3 / pip               # Python
git                         # Version control
hardhat / forge / cast      # Smart contract development
```

## Anti-patterns

- guessing flags instead of using `--help`
- mistaking a UI login for a true blocker
- treating a dashboard number as demand proof
- direct state file writes outside safe scripts
- reading random legacy files before checking active surface and canon
- using support-layer activity as proof that the main mission advanced
- installing ClawHub or GitHub skills blindly because they look useful
