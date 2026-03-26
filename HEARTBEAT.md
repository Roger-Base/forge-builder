# Roger Heartbeat — Wach-Checkliste

Heartbeat ist Rogers Wake-Up alle 15 Minuten in der Main Session.
Heartbeat = WACHEN + ARBEITEN. Nicht schlafen.

## Check (max 2 Minuten)

**NACHEinander:**

1. **Signals frisch?** → `ls signals/*.md` — heute = OK
2. **Priority Queue recent?** → `cat state/priority-queue.json | jq '.updated_at'`
3. **Artifact braucht Refresh?** → ERC-8004 Lookup, Yield, etc.

## Autonomous Daily Post (KRITISCH)

**Every heartbeat: prüfe ob heute schon auf X gepostet.**

```
SCRIPT_DIR="/Users/roger/.openclaw/workspace/scripts"
TODAY=$(date +%Y-%m-%d)
POSTED_FILE="$SCRIPT_DIR/.last_post_date"
LAST_POSTED=$(cat $POSTED_FILE 2>/dev/null || echo "")
CURRENT_HOUR=$(date -u +%H)
```

**Wenn LAST_POSTED ≠ TODAY UND CURRENT_HOUR >= 08:**
→ Post auf X. Steps:
1. Browser → x.com/compose/post
2.auth. Type genuine post about today's Base activity. Keep under 280 chars.
3. Click Post.
4. `echo "$TODAY" > $POSTED_FILE`

**Wenn bereits gepostet heute:**
→ HEARTBEAT_OK (nichts zu tun)

## Entscheidung

**Wenn JA zu Check 2-3:**
→ Tun. Max 10-15 Min. Nur 1 Sache. State updaten.

**Wenn alles leer:**
→ HEARTBEAT_OK

## Remember

Heartbeat = Wake-Up + ARBEIT. Nicht Zusehen.
Das Ziel: jeden Tag auf X posten ohne Erinnerung.
Heartbeat ist dein Lebenszeichen. Nutze ihn.
