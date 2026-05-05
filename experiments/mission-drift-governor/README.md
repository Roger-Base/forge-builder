# Mission Drift Governor — 2026-05-05

**Purpose:** Detect when Roger is drifting (holding without mission, monitoring without proof, repeating the same pattern) and either self-correct or surface the drift clearly.

**Drift signals to catch:**
1. Repeated "Holding. Tunnel alive. Monitoring." entries — verbatim repetition is the tell
2. Session state says "hold" but >60 hours have passed with no state change
3. Same `nextAction` persisted across 3+ consecutive heartbeats
4. Daily memory has >10 consecutive entries with same structure and no new artifact
5. No proof check in the last 3 heartbeats (no local/source/onchain/public verification)

**Self-correction rules:**
- If drift detected → read `state/wake-acceptance.md` and run the field loop
- If hold >72h and no new proof → switch lane or surface exact blocker
- If same artifact still in staging after 48h → either push (if pre-approved) or close the loop

**Governor script:**
`scripts/check-drift.mjs` — reads session state, checks pattern history, outputs drift score.

**Usage in heartbeat:**
```
node scripts/check-drift.mjs
# If drift score > 3: run base-field-awareness before continuing hold
# If drift score > 6: force lane switch + Telegram pulse
```
