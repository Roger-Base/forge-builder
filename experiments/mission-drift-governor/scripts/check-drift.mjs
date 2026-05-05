#!/usr/bin/env node
/**
 * Mission Drift Governor v3
 * Detects when Roger is drifting: holding without mission, monitoring without proof, repeating patterns.
 * 
 * Run: node scripts/check-drift.mjs
 * Exit codes: 0 = healthy, 1 = mild drift, 2 = strong drift, 3 = critical drift
 */

import { readFileSync, readdirSync, statSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { execSync } from 'child_process';

const __dirname = dirname(fileURLToPath(import.meta.url));
const WORKSPACE = join(__dirname, '..', '..');

// Find most recent memory file
function getLatestMemory() {
  const memDir = join(WORKSPACE, 'memory');
  let latest = null;
  let latestMtime = 0;
  try {
    for (const f of readdirSync(memDir).filter(f => f.endsWith('.md'))) {
      const p = join(memDir, f);
      try {
        const m = statSync(p).mtimeMs;
        if (m > latestMtime) { latestMtime = m; latest = p; }
      } catch (e) {}
    }
  } catch (e) {}
  return latest;
}

let driftScore = 0;
let warnings = [];

const latestMemPath = getLatestMemory();
let content = '';

if (latestMemPath) {
  try {
    content = readFileSync(latestMemPath, 'utf8');
  } catch (e) {
    content = '';
  }
} else {
  console.log('=== Mission Drift Governor ===');
  console.log('No memory file found — healthy baseline');
  process.exit(0);
}

const lines = content.split('\n');
const sectionCount = lines.filter(l => l.startsWith('## ')).length;
const holding = (content.match(/Holding\./g) || []).length;
const tunnelAlive = (content.match(/Tunnel alive/g) || []).length;
const monitoring = (content.match(/Monitoring\./g) || []).length;

// Real field/proof entries
const realProof = lines.filter(l => 
  /Proof:|^## .*Field Study|^## .*pushed|^## .*committed|^## .*created|^## .*Decision:|^## .*Wake|^## .*MCP|^## .*Python|^## .*Docker|^## .*Go SDK|^## .*CHANGELOG/g.test(l.trim())
).length;
const fieldStudy = lines.filter(l => 
  /Field Study|x402 releases|Bazaar|ERC-8004 call|registry call|MCP|Bankr balance|x402 ecosystem|^## .*MCP|^## .*Field|^## .*Bazaar/g.test(l.trim())
).length;

// Count pure monitoring entries (Monitoring. Tunnel alive. No pulse.)
const pureMonitoring = (content.match(/Monitoring\. Tunnel alive\. No pulse\./g) || []).length;
const pureHold = (content.match(/## .* Quiet hold\s*\n\s*Tunnel alive\.\s*Holding\./gs) || []).length;

// Session state stale check
try {
  const statePath = join(WORKSPACE, 'state', 'session-state.json');
  const state = JSON.parse(readFileSync(statePath, 'utf8'));
  
  if (state.nextAction && /waiting for Tomas|Awaiting|Holding/.test(state.nextAction)) {
    driftScore += 1;
    warnings.push('nextAction still in wait-hold pattern');
  }
  
  if (state.updated) {
    const hoursSince = (Date.now() - new Date(state.updated).getTime()) / 1000 / 3600;
    if (hoursSince > 48) {
      driftScore += 2;
      warnings.push(`Session state unchanged for ${Math.round(hoursSince)}h`);
    }
  }
} catch (e) {}

// 1. Drift ratio: holds vs real entries
const totalReal = realProof + fieldStudy;
const driftRatio = holding / Math.max(totalReal, 1);
if (driftRatio > 15) {
  driftScore += 5;
  warnings.push(`${holding} holds vs ${totalReal} real entries — drift ratio ${Math.round(driftRatio)}:1 (critical)`);
} else if (driftRatio > 8) {
  driftScore += 3;
  warnings.push(`${holding} holds vs ${totalReal} real entries — drift ratio ${Math.round(driftRatio)}:1`);
} else if (driftRatio > 3) {
  driftScore += 1;
  warnings.push(`Drift ratio ${Math.round(driftRatio)}:1 — field work needed`);
}

// 2. Pure monitoring entries
if (pureMonitoring > 40) {
  driftScore += 3;
  warnings.push(`${pureMonitoring} consecutive monitoring-only entries — heartbeat became theater`);
} else if (pureMonitoring > 20) {
  driftScore += 2;
  warnings.push(`${pureMonitoring} monitoring-only entries — monitoring loop detected`);
}

// 3. Git activity check (find the right repo)
let gitHours = null;
const repos = [
  join(WORKSPACE, 'code', 'x402-agent-starter'),
  WORKSPACE
];
for (const repo of repos) {
  try {
    const log = execSync('git log --format="%ai" -1', { cwd: repo, timeout: 3000 }).toString().trim();
    if (log) {
      const hoursSince = (Date.now() - new Date(log).getTime()) / 1000 / 3600;
      if (gitHours === null || hoursSince < gitHours) gitHours = hoursSince;
    }
  } catch (e) {}
}

if (gitHours !== null) {
  if (gitHours < 12) driftScore -= 2;
  else if (gitHours < 24) driftScore -= 1;
  else if (gitHours > 72) {
    driftScore += 1;
    warnings.push(`Last git activity ${Math.round(gitHours)}h ago — no new commits while holding`);
  }
}

driftScore = Math.max(0, Math.min(driftScore, 10));

// Output
console.log('=== Mission Drift Governor v3 ===');
console.log(`Drift Score: ${driftScore}/10`);
console.log(`Memory: ${sectionCount} sections, ${holding} holds, ${pureMonitoring} pure monitoring`);
console.log(`Real field/proof entries: ${totalReal}`);
console.log(`Drift ratio: ${Math.round(driftRatio)}:1`);
if (gitHours !== null) console.log(`Git activity: ${Math.round(gitHours)}h ago`);

if (warnings.length > 0) {
  console.log('\nWarnings:');
  warnings.forEach(w => console.log(`  - ${w}`));
}

if (driftScore >= 7) {
  console.log('\n⚠️  CRITICAL DRIFT — Force lane switch + Telegram pulse required');
  process.exit(3);
} else if (driftScore >= 4) {
  console.log('\n⚠️  Strong drift — Run base-field-awareness, switch lane');
  process.exit(2);
} else if (driftScore >= 2) {
  console.log('\n⚡ Mild drift — Verify next move is mission-bearing');
  process.exit(1);
} else {
  console.log('\n✅ Healthy');
  process.exit(0);
}
