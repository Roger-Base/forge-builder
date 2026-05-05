#!/usr/bin/env node
/**
 * Mission Drift Governor — quick version
 * Finds the largest memory file (most lived days = most signal) and checks for drift.
 * Run: node scripts/quick-drift-check.mjs
 * Exit: 0=healthy, 1=mild, 2=strong, 3=critical drift
 */
import { readFileSync, statSync, readdirSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const WORKSPACE = join(__dirname, '..', '..', '..');

let driftScore = 0;
let warnings = [];

// Find largest memory by size (most content = most signal)
const memFiles = readdirSync(WORKSPACE + '/memory').filter(f => f.endsWith('.md'));
let latestMem = 'memory/2026-05-05.md';
let largestSize = 0;
for (const f of memFiles) {
  try {
    const s = statSync(WORKSPACE + '/memory/' + f).size;
    if (s > largestSize) { largestSize = s; latestMem = 'memory/' + f; }
  } catch (e) {}
}

const content = readFileSync(WORKSPACE + '/' + latestMem, 'utf8');
const lines = content.split('\n');
const holding = (content.match(/Holding\./g) || []).length;
const sectionCount = lines.filter(l => l.startsWith('## ')).length;

const realProof = lines.filter(l => 
  /Proof:|^## .*Field Study|^## .*pushed|^## .*committed|^## .*created|^## .*Decision:|^## .*Wake|^## .*MCP|^## .*Docker|^## .*Go SDK|^## .*Python|^## .*CHANGELOG/g.test(l.trim())
).length;

const fieldStudy = lines.filter(l => 
  /Field Study|x402 releases|Bazaar|ERC-8004|registry|MCP|Bankr balance|^## .*MCP|^## .*Field|^## .*Bazaar/g.test(l.trim())
).length;

const pureMonitoring = (content.match(/Monitoring\. Tunnel alive\. No pulse\./g) || []).length;
const totalReal = realProof + fieldStudy;
const driftRatio = holding / Math.max(totalReal, 1);

if (driftRatio > 15) { driftScore += 5; warnings.push(`${holding} holds vs ${totalReal} real entries, ratio ${Math.round(driftRatio)}:1 — critical`); }
else if (driftRatio > 8) { driftScore += 3; warnings.push(`Drift ratio ${Math.round(driftRatio)}:1`); }
else if (driftRatio > 3) { driftScore += 1; }

if (pureMonitoring > 40) { driftScore += 3; warnings.push(`${pureMonitoring} monitoring-only entries — heartbeat is theater`); }
else if (pureMonitoring > 20) { driftScore += 2; warnings.push(`${pureMonitoring} monitoring-only entries`); }

driftScore = Math.max(0, Math.min(driftScore, 10));

console.log('=== Mission Drift Governor ===');
console.log(`Memory: ${latestMem} (${largestSize} bytes, ${sectionCount} sections)`);
console.log(`Holding: ${holding}, Real field/proof: ${totalReal}, Pure monitoring: ${pureMonitoring}`);
console.log(`Drift ratio: ${Math.round(driftRatio)}:1`);
if (warnings.length > 0) warnings.forEach(w => console.log(`⚠️  ${w}`));
console.log(`Drift Score: ${driftScore}/10`);

if (driftScore >= 7) { console.log('⚠️  CRITICAL DRIFT — force lane switch + pulse required'); process.exit(3); }
else if (driftScore >= 4) { console.log('⚠️  Strong drift — run base-field-awareness, switch lane'); process.exit(2); }
else if (driftScore >= 2) { console.log('⚡ Mild drift — verify next move is mission-bearing'); process.exit(1); }
else { console.log('✅ Healthy — no drift detected'); process.exit(0); }
