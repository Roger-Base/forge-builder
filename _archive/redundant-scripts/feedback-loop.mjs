#!/usr/bin/env node

/**
 * Roger Feedback Loop
 * Learns from my actions and improves behavior
 * Stage 5: Self-improving agent
 */

import { readFileSync, writeFileSync, existsSync, appendFileSync } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const BASE_DIR = path.join(__dirname, '..');

const FEEDBACK_FILE = path.join(BASE_DIR, 'memory', 'feedback-log.md');
const LEARNINGS_FILE = path.join(BASE_DIR, 'memory', 'learnings.md');

/**
 * Log an action result
 */
function logAction(action, result, score) {
  const timestamp = new Date().toISOString();
  const entry = `\n## ${timestamp}\n- Action: ${action}\n- Result: ${result}\n- Score: ${score}/10\n`;
  
  appendFileSync(FEEDBACK_FILE, entry);
  
  // If score is low, analyze why
  if (score < 5) {
    analyzeFailure(action, result);
  }
  
  // If score is high, extract what worked
  if (score >= 8) {
    extractSuccess(action, result);
  }
}

/**
 * Analyze failure
 */
function analyzeFailure(action, result) {
  const analysis = `\n### Failure Analysis: ${action}\n`;
  const guess = `- Likely cause: ${result.includes('timeout') ? 'Resource issue' : 'Wrong approach'}\n`;
  
  appendFileSync(LEARNINGS_FILE, analysis + guess);
}

/**
 * Extract success pattern
 */
function extractSuccess(action, result) {
  const success = `\n### Success Pattern: ${action}\n`;
  const pattern = `- What worked: ${result.slice(0, 100)}\n`;
  
  appendFileSync(LEARNINGS_FILE, success + pattern);
}

/**
 * Get learnings
 */
function getLearnings() {
  if (!existsSync(LEARNINGS_FILE)) {
    return 'No learnings yet';
  }
  return readFileSync(LEARNINGS_FILE, 'utf-8').slice(-2000);
}

/**
 * Main
 */
function main() {
  const args = process.argv.slice(2);
  
  if (args[0] === '--log') {
    const action = args[1] || 'unknown';
    const result = args[2] || 'completed';
    const score = parseInt(args[3]) || 5;
    
    logAction(action, result, score);
    console.log(`✅ Logged: ${action} (score: ${score})`);
  } else if (args[0] === '--learnings') {
    console.log(getLearnings());
  } else {
    console.log(`
ROGER FEEDBACK LOOP

Usage:
  --log <action> <result> <score>  Log an action result
  --learnings                       Show learnings

Example:
  node feedback-loop.mjs --log "post-twitter" "posted successfully" 8
    `);
  }
}

main();
