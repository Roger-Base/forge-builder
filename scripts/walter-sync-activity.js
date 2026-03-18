#!/usr/bin/env node
// Walter Activity Sync - Node script to query OpenClaw sessions and update cache
// Usage: node walter-sync-activity.js
// This script uses OpenClaw's sessions_list capability via the CLI

const fs = require('fs');
const path = require('path');

const STATE_DIR = '/Users/roger/.openclaw/workspace/state';
const ACTIVITY_FILE = path.join(STATE_DIR, 'roger-activity-cache.json');
const LOG_FILE = path.join(STATE_DIR, 'walter-coordination-log.json');

function getTimestamp() {
    return new Date().toISOString();
}

function getEpoch() {
    return Math.floor(Date.now() / 1000);
}

function loadJson(file) {
    try {
        return JSON.parse(fs.readFileSync(file, 'utf8'));
    } catch (e) {
        return null;
    }
}

function saveJson(file, data) {
    fs.writeFileSync(file, JSON.stringify(data, null, 2));
}

// Main sync function - to be called with session data from OpenClaw
function syncActivity(sessionData) {
    const timestamp = getTimestamp();
    const nowEpoch = getEpoch();
    
    // Handle both { sessions: [...] } and [...] formats
    const sessions = sessionData.sessions || sessionData;
    if (!Array.isArray(sessions)) {
        console.error('Invalid session data: expected array or {sessions: [...]}');
        return false;
    }
    
    // Find Roger's session (main agent)
    const rogerSession = sessions.find(s => s.agentId === 'main' || s.key?.startsWith('agent:main:') || s.label === 'roger');
    
    if (!rogerSession) {
        console.log('No Roger session found');
        
        // Update log with unknown status but preserve last known
        const log = loadJson(LOG_FILE) || {};
        if (log.rogerActivity) {
            log.rogerActivity.status = 'unknown';
            log.rogerActivity.lastSyncAttempt = timestamp;
            saveJson(LOG_FILE, log);
        }
        return false;
    }
    
    // Parse last activity time (handle both ISO strings and epoch milliseconds)
    let lastActivityAt = rogerSession.lastActivityAt || rogerSession.lastMessageAt || rogerSession.updatedAt;
    let lastEpoch;
    
    if (typeof lastActivityAt === 'number') {
        // Epoch milliseconds
        lastEpoch = lastActivityAt / 1000;
        lastActivityAt = new Date(lastActivityAt).toISOString();
    } else {
        // ISO string
        lastActivityAt = lastActivityAt || timestamp;
        lastEpoch = new Date(lastActivityAt).getTime() / 1000;
    }
    
    const minutesIdle = Math.floor((nowEpoch - lastEpoch) / 60);
    const status = minutesIdle >= 30 ? 'idle' : 'active';
    
    // Update activity cache
    const activityCache = {
        lastActivity: lastActivityAt,
        sessionKey: rogerSession.sessionKey,
        channel: rogerSession.channel || 'unknown',
        minutesIdle: minutesIdle,
        status: status,
        cachedAt: timestamp,
        syncedFrom: 'openclaw_sessions_list'
    };
    saveJson(ACTIVITY_FILE, activityCache);
    
    // Update coordination log
    const log = loadJson(LOG_FILE) || {};
    log.rogerActivity = log.rogerActivity || {};
    log.rogerActivity.lastSeen = lastActivityAt;
    log.rogerActivity.status = status;
    log.rogerActivity.minutesIdle = minutesIdle;
    log.rogerActivity.lastSyncAttempt = timestamp;
    log.lastUpdated = timestamp;
    saveJson(LOG_FILE, log);
    
    console.log(`Synced: Roger is ${status} (${minutesIdle}m idle)`);
    return true;
}

// If called directly with stdin JSON
if (require.main === module) {
    let input = '';
    process.stdin.setEncoding('utf8');
    process.stdin.on('data', chunk => input += chunk);
    process.stdin.on('end', () => {
        try {
            const sessions = JSON.parse(input);
            const success = syncActivity(sessions);
            process.exit(success ? 0 : 1);
        } catch (e) {
            console.error('Error parsing input:', e.message);
            process.exit(1);
        }
    });
}

module.exports = { syncActivity };
