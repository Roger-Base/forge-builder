#!/usr/bin/env node

/**
 * Roger Self-Improvement Loop
 * Analyzes feedback and makes one concrete improvement
 */

import { readFileSync, appendFileSync, existsSync } from 'fs';
import { fileURLToPath } from 'url';
import path from 'path';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const LEARNINGS_FILE = path.join(__dirname, '..', 'memory', 'learnings.md');
const MEMORY_ACTIVE = path.join(__dirname, '..', 'MEMORY_ACTIVE.md');

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

/**
 * Make one concrete improvement
 */
function makeImprovement(analysis) {
  // If too much "continuous" work without self-improvement, flag it
  if (analysis.categories.continuous > 5 && analysis.categories.selfImprovement === 0) {
    return {
      issue: 'Too much continuous operation, not enough self-improvement',
      action: 'Add self-improvement focus to heartbeat'
    };
  }
  
  // If coordination is happening, that's good
  if (analysis.categories.coordination > 0) {
    return {
      issue: null,
      action: 'Continue Walter coordination - it is working'
    };
  }
  
  return {
    issue: 'Need more self-improvement patterns',
    action: 'Create self-reflection habit'
  };
}

/**
 * Update memory with insight - ONLY if there's real content
 */
function updateMemory(analysis, improvement) {
  // GATE: Don't write empty noise to MEMORY_ACTIVE
  // Only write if there's real analysis or a specific improvement
  if (analysis.patterns === 0 && analysis.failures === 0 && !improvement.issue) {
    console.log('\n⏭️  SKIPPED: No real patterns or improvements to record');
    return;
  }
  
  const timestamp = new Date().toISOString();
  const insight = `\n## Self-Improvement Insight (${timestamp})\n`;
  const content = `
- Total patterns: ${analysis.patterns}
- Failures: ${analysis.failures}
- Category breakdown: ${JSON.stringify(analysis.categories)}

**Issue found:** ${improvement.issue || 'None'}
**Action:** ${improvement.action}

`;
  
  appendFileSync(MEMORY_ACTIVE, insight + content);
  console.log('\n✅ Updated MEMORY_ACTIVE with insight');
}

function main() {
  console.log('🔍 Analyzing self-improvement patterns...\n');
  
  const analysis = analyzeLearnings();
  const improvement = makeImprovement(analysis);
  
  console.log('📊 ANALYSIS:');
  console.log(`  Patterns: ${analysis.patterns}`);
  console.log(`  Failures: ${analysis.failures}`);
  console.log('\n📈 CATEGORIES:');
  console.log(`  Continuous work: ${analysis.categories.continuous}`);
  console.log(`  Self-improvement: ${analysis.categories.selfImprovement}`);
  console.log(`  Build/Create: ${analysis.categories.build}`);
  console.log(`  Coordination: ${analysis.categories.coordination}`);
  
  console.log('\n🎯 IMPROVEMENT:');
  console.log(`  Issue: ${improvement.issue || 'None'}`);
  console.log(`  Action: ${improvement.action}`);
  
  // Update memory
  updateMemory(analysis, improvement);
  console.log('\n✅ Updated MEMORY_ACTIVE with insight');
}

main();
