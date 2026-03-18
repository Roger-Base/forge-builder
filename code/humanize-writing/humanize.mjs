#!/usr/bin/env node

/**
 * Humanize Any Writing
 * Turns robotic AI content into natural human writing
 */

import { readFileSync, writeFileSync, existsSync } from 'fs';
import { fileURLToPath } from 'url';
import path from 'path';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const args = process.argv.slice(2);
const inputFile = args[0];
const tone = args.includes('--tone') ? args[args.indexOf('--tone') + 1] : 'casual';

/**
 * AI Patterns to detect and fix
 */
const AI_PATTERNS = {
  overUsedBulletPoints: {
    pattern: /^[•\-\*]\s+/gm,
    fix: 'Use varied list styles or prose'
  },
  genericTransitions: {
    words: ['furthermore', 'additionally', 'moreover', 'consequently', 'therefore', 'subsequently'],
    fix: 'Use natural transitions like "also", "so", "then"'
  },
  hedgingLanguage: {
    pattern: /(it is important to note|it should be noted|it is worth mentioning|one could argue|it seems|it appears)/gi,
    fix: 'Be direct and confident'
  },
  excessiveFormality: {
    pattern: /(please find attached|kindly|per our discussion|as aforementioned|in order to)/gi,
    fix: 'Use conversational language'
  },
  perfectGrammar: {
    pattern: /[.!?]\s+[A-Z][a-z]+[,]/g,
    fix: 'Vary sentence length and structure'
  }
};

/**
 * Tone-specific transformations
 */
const TONE_TRANSFORMATIONS = {
  casual: {
    contractions: true,
    contractionsMap: {
      'cannot': "can't",
      'do not': "don't",
      'it is': "it's",
      'they are': "they're",
      'we are': "we're",
      'I am': "I'm",
      'will not': "won't",
      'would not': "wouldn't",
      'should not': "shouldn't",
      'could not': "couldn't",
      'in order to': "to",
      'please': '',
      'thank you': 'thanks',
      'kindly': ''
    },
    filler: ['very', 'really', 'actually', 'basically', 'literally']
  },
  professional: {
    contractions: true,
    contractionsMap: {
      'cannot': "cannot",
      'do not': "do not",
      'it is': "it is",
      'in order to': "to"
    },
    filler: ['literally', 'basically']
  }
};

/**
 * Humanize text
 */
function humanize(text, tone = 'casual') {
  let result = text;
  const transform = TONE_TRANSFORMATIONS[tone] || TONE_TRANSFORMATIONS.casual;
  
  // Apply contractions
  if (transform.contractions && transform.contractionsMap) {
    for (const [from, to] of Object.entries(transform.contractionsMap)) {
      result = result.replace(new RegExp(from, 'gi'), to);
    }
  }
  
  // Remove filler words
  if (transform.filler) {
    for (const word of transform.filler) {
      result = result.replace(new RegExp(`\\b${word}\\b`, 'gi'), '');
    }
  }
  
  // Fix hedging
  result = result.replace(AI_PATTERNS.hedgingLanguage.pattern, AI_PATTERNS.hedgingLanguage.fix);
  
  // Fix excessive formality
  result = result.replace(AI_PATTERNS.excessiveFormality.pattern, '');
  
  // Clean up double spaces
  result = result.replace(/\s+/g, ' ');
  
  // Clean up punctuation
  result = result.replace(/,\s*,/g, ',');
  result = result.replace(/\.\s*\./g, '.');
  
  return result.trim();
}

/**
 * Calculate human realism score
 */
function calculateScore(original, humanized) {
  let score = 50; // Base score
  
  // Check for contractions (good)
  const contractions = (humanized.match(/'/g) || []).length;
  score += Math.min(contractions * 3, 15);
  
  // Check for varied sentence length
  const sentences = humanized.split(/[.!?]+/).filter(s => s.trim().length > 0);
  const lengths = sentences.map(s => s.split(' ').length);
  const avgLength = lengths.reduce((a, b) => a + b, 0) / lengths.length;
  const variance = lengths.reduce((acc, len) => acc + Math.pow(len - avgLength, 2), 0) / lengths.length;
  
  // Good variance = more human
  if (variance > 10) score += 10;
  if (variance < 5) score -= 10;
  
  // Check for filler words
  const fillers = (humanized.match(/\b(very|really|basically|literally|actually)\b/gi) || []).length;
  score -= fillers * 5;
  
  // Cap score
  return Math.max(10, Math.min(100, score));
}

/**
 * Main
 */
function main() {
  if (!inputFile) {
    console.log(`
HUMANIZE ANY WRITING

Usage: node humanize.js <file> [options]

Options:
  --tone <casual|professional|academic|creative>

Example:
  node humanize.js article.md --tone casual
`);
    return;
  }
  
  if (!existsSync(inputFile)) {
    console.log(`❌ File not found: ${inputFile}`);
    return;
  }
  
  const original = readFileSync(inputFile, 'utf-8');
  const humanized = humanize(original, tone);
  const score = calculateScore(original, humanized);
  
  console.log('\n═══════════════════════════════════════');
  console.log('       HUMANIZE RESULTS');
  console.log('═══════════════════════════════════════\n');
  
  console.log(`📊 Human Realism Score: ${score}/100`);
  console.log(`🎨 Tone: ${tone}\n`);
  
  console.log('───────────────────────────────────────');
  console.log('HUMANIZED TEXT:');
  console.log('───────────────────────────────────────\n');
  console.log(humanized);
  
  console.log('\n═══════════════════════════════════════');
  
  // Save to file
  const outputFile = inputFile.replace('.md', '-humanized.md');
  writeFileSync(outputFile, humanized);
  console.log(`\n✅ Saved to: ${outputFile}`);
}

main();
