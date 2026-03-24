#!/usr/bin/env node

/**
 * Roger Self-Improvement Loop
 * Analyzes runtime truth and records one concrete improvement
 */

import { readFileSync, appendFileSync, existsSync, writeFileSync } from 'fs';
import { fileURLToPath } from 'url';
import path from 'path';
import { execFileSync } from 'child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const STATE_DIR = path.join(__dirname, '..', 'state');
const LEARNINGS_FILE = path.join(__dirname, '..', 'memory', 'learnings.md');
const MEMORY_ACTIVE = path.join(__dirname, '..', 'MEMORY_ACTIVE.md');
const STATE_FILE = path.join(STATE_DIR, 'session-state.json');
const AUDIT_FILE = path.join(STATE_DIR, 'roger-self-audit.json');
const IMPROVEMENT_FILE = path.join(STATE_DIR, 'roger-self-improvement.json');
const DOCTRINE_SYNC_SCRIPT = path.join(__dirname, 'doctrine-capsule-sync.mjs');
const ACTIVE_SURFACE_SYNC = path.join(__dirname, 'active-surface-sync.sh');

function readJson(filePath, fallback = {}) {
  if (!existsSync(filePath)) {
    return fallback;
  }
  try {
    return JSON.parse(readFileSync(filePath, 'utf-8'));
  } catch {
    return fallback;
  }
}

/**
 * Analyze learnings and find patterns
 */
function analyzeLearnings() {
  if (!existsSync(LEARNINGS_FILE)) {
    return { patterns: [], improvements: [] };
  }
  
  const content = readFileSync(LEARNINGS_FILE, 'utf-8');
  
  // Extract success patterns - match until next ### or end of file
  const successPatterns = content.match(/### Success Pattern: [^\n]+/g) || [];
  
  // Extract failure analyses
  const failures = content.match(/### Failure Analysis: [^\n]+/g) || [];
  
  // Count categories
  const categories = {
    continuous: successPatterns.filter(p => p.includes('continuous') || p.includes('Stage 5')).length,
    selfImprovement: successPatterns.filter(p => p.includes('self') || p.includes('improve')).length,
    build: successPatterns.filter(p => p.includes('build') || p.includes('create')).length,
    coordination: successPatterns.filter(p => p.includes('handoff') || p.includes('Walter')).length
  };
  
  return {
    patterns: successPatterns.length,
    failures: failures.length,
    categories
  };
}

function ensureAudit() {
  if (!existsSync(AUDIT_FILE)) {
    execFileSync(process.execPath, [path.join(__dirname, 'roger-self-audit.mjs')], {
      stdio: 'ignore'
    });
  }
  return readJson(AUDIT_FILE, {});
}

/**
 * Make one concrete improvement
 */
function makeImprovement(analysis, audit, state) {
  if (audit.self_reflection_needed) {
    return {
      issue: audit.verdict,
      action: audit.recommended_action || 'Run a bounded reality-check before further build pressure.',
      questions: audit.questions || [],
      recommendedNextMove: audit.recommended_next_move || 'direction_review',
      activeWedge: state.active_wedge?.id || null
    };
  }

  // If too much "continuous" work without self-improvement, flag it
  if (analysis.categories.continuous > 5 && analysis.categories.selfImprovement === 0) {
    return {
      issue: 'Too much continuous operation, not enough self-improvement',
      action: 'Add self-improvement focus to heartbeat',
      questions: [],
      recommendedNextMove: 'continue_current',
      activeWedge: state.active_wedge?.id || null
    };
  }
  
  // If coordination is happening, that's good
  if (analysis.categories.coordination > 0) {
    return {
      issue: null,
      action: 'Continue Walter coordination - it is working',
      questions: [],
      recommendedNextMove: 'continue_current',
      activeWedge: state.active_wedge?.id || null
    };
  }
  
  return {
    issue: 'Need more self-improvement patterns',
    action: 'Create self-reflection habit',
    questions: [],
    recommendedNextMove: 'continue_current',
    activeWedge: state.active_wedge?.id || null
  };
}

/**
 * Update memory with insight - ONLY if there's real new content
 */
function updateMemory(analysis, improvement, audit, state) {
  // GATE: Don't write empty noise to MEMORY_ACTIVE
  // Only write if there's real analysis or a specific improvement
  if (analysis.patterns === 0 && analysis.failures === 0 && !improvement.issue) {
    console.log('\n⏭️  SKIPPED: No real patterns or improvements to record');
    return;
  }

  // DEDUP GATE: If this is a cron-triggered self-reflection entry identical to the
  // last recorded improvement, skip the write — it is repeated noise.
  // Only write if the issue is new or analysis content exists.
  const lastState = readJson(IMPROVEMENT_FILE, {});
  const isDuplicateReflection = (
    improvement.issue &&
    improvement.issue === lastState.issue &&
    analysis.patterns === 0 &&
    analysis.failures === 0 &&
    !improvement.extra_delta
  );
  if (isDuplicateReflection) {
    console.log('\n⏭️  SKIPPED: Duplicate self-reflection entry — no new delta since last run');
    return;
  }
  
  const timestamp = new Date().toISOString();
  const insight = `\n## Self-Improvement Insight (${timestamp})\n`;
  const content = `
- Active wedge: ${state.active_wedge?.id || 'unknown'} @ ${state.active_wedge?.stage || 'unknown'}
- Audit recommended move: ${audit.recommended_next_move || 'continue_current'}
- Total patterns: ${analysis.patterns}
- Failures: ${analysis.failures}
- Category breakdown: ${JSON.stringify(analysis.categories)}

**Issue found:** ${improvement.issue || 'None'}
**Action:** ${improvement.action}
**Questions:** ${improvement.questions && improvement.questions.length ? improvement.questions.join(' | ') : 'None'}

`;
  
  // Content gate: only write real signal to MEMORY_ACTIVE
  // Empty entries (patterns=0, failures=0, no real issue) are noise that degrades MEMORY_ACTIVE
  const hasRealContent = analysis.patterns > 0 || analysis.failures > 0 ||
    (improvement.issue && !improvement.issue.includes('Need more'));
  if (hasRealContent) {
    appendFileSync(MEMORY_ACTIVE, insight + content);
    console.log('\n✅ Updated MEMORY_ACTIVE with insight');
  } else {
    console.log('\n⏭️ No real content — skipping MEMORY_ACTIVE write (content gate active)');
  }
}

function syncDoctrineCapsule() {
  if (!existsSync(DOCTRINE_SYNC_SCRIPT)) {
    return null;
  }
  try {
    const output = execFileSync(process.execPath, [
      DOCTRINE_SYNC_SCRIPT,
      '--agent',
      'Roger',
      '--workspace',
      path.join(__dirname, '..')
    ], {
      encoding: 'utf-8'
    }).trim();
    const match = output.match(/CAPSULE_SYNC_OK\s+(.+)$/);
    return match ? match[1] : null;
  } catch {
    return null;
  }
}

function writeImprovementState(analysis, improvement, audit, state, capsulePath) {
  const payload = {
    updated_at: new Date().toISOString(),
    active_wedge: state.active_wedge?.id || null,
    stage: state.active_wedge?.stage || null,
    issue: improvement.issue,
    action: improvement.action,
    questions: improvement.questions || [],
    recommended_next_move: improvement.recommendedNextMove || 'continue_current',
    audit_verdict: audit.verdict || null,
    capsule_path: capsulePath,
    learnings_summary: {
      patterns: analysis.patterns,
      failures: analysis.failures,
      categories: analysis.categories
    }
  };
  writeFileSync(IMPROVEMENT_FILE, `${JSON.stringify(payload, null, 2)}\n`);
}

function syncCanonicalState() {
  if (!existsSync(ACTIVE_SURFACE_SYNC)) {
    return;
  }
  try {
    execFileSync('bash', [ACTIVE_SURFACE_SYNC], {
      stdio: 'ignore'
    });
    console.log('\n✅ Canonical state sync completed');
  } catch {
    console.log('\n⚠️ Canonical state sync failed after self-improvement');
  }
}

function main() {
  console.log('🔍 Analyzing self-improvement patterns...\n');
  
  const analysis = analyzeLearnings();
  const state = readJson(STATE_FILE, {});
  const audit = ensureAudit();
  const improvement = makeImprovement(analysis, audit, state);
  
  console.log('📊 ANALYSIS:');
  console.log(`  Patterns: ${analysis.patterns}`);
  console.log(`  Failures: ${analysis.failures}`);
  console.log('\n📈 CATEGORIES:');
  console.log(`  Continuous work: ${analysis.categories.continuous}`);
  console.log(`  Self-improvement: ${analysis.categories.selfImprovement}`);
  console.log(`  Build/Create: ${analysis.categories.build}`);
  console.log(`  Coordination: ${analysis.categories.coordination}`);
  console.log('\n🧭 RUNTIME:');
  console.log(`  Active wedge: ${state.active_wedge?.id || 'unknown'} @ ${state.active_wedge?.stage || 'unknown'}`);
  console.log(`  Audit verdict: ${audit.verdict || 'none'}`);
  
  console.log('\n🎯 IMPROVEMENT:');
  console.log(`  Issue: ${improvement.issue || 'None'}`);
  console.log(`  Action: ${improvement.action}`);
  console.log(`  Recommended next move: ${improvement.recommendedNextMove}`);
  
  const capsulePath = syncDoctrineCapsule();
  writeImprovementState(analysis, improvement, audit, state, capsulePath);
  updateMemory(analysis, improvement, audit, state);
  syncCanonicalState();
}

main();
