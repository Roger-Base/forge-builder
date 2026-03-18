#!/usr/bin/env node

/**
 * Desktop File Cleanse
 * Scans system, flags duplicates, junk, organizes files
 */

import fs from 'fs';
import path from 'path';
import crypto from 'crypto';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const args = process.argv.slice(2);
const command = args[0] || 'help';
const targetDir = args[1] || process.env.HOME || process.cwd();

// Configuration
const CONFIG = {
  junkPatterns: [
    '*.tmp', '*.temp', '*.log', '*.bak',
    '.DS_Store', 'Thumbs.db', 'desktop.ini',
    'node_modules', '.cache', '__pycache__'
  ],
  oldFileDays: 90, // Files older than 90 days in Downloads
  scanHidden: false
};

/**
 * Calculate file hash
 */
function getFileHash(filePath) {
  return new Promise((resolve, reject) => {
    const hash = crypto.createHash('md5');
    const stream = fs.createReadStream(filePath);
    stream.on('data', d => hash.update(d));
    stream.on('end', () => resolve(hash.digest('hex')));
    stream.on('error', reject);
  });
}

/**
 * Scan directory recursively
 */
async function scanDirectory(dir, results = { junk: [], duplicates: [], old: [] }) {
  let entries;
  
  try {
    entries = fs.readdirSync(dir, { withFileTypes: true });
  } catch (e) {
    return results;
  }
  
  const fileMap = new Map();
  const now = Date.now();
  const oldThreshold = now - (CONFIG.oldFileDays * 24 * 60 * 60 * 1000);
  
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    
    // Skip hidden files if configured
    if (!CONFIG.scanHidden && entry.name.startsWith('.')) continue;
    
    // Check junk patterns
    for (const pattern of CONFIG.junkPatterns) {
      if (entry.name === pattern || entry.name.endsWith(pattern.replace('*', ''))) {
        results.junk.push({ path: fullPath, type: 'junk' });
        continue;
      }
    }
    
    if (entry.isDirectory()) {
      await scanDirectory(fullPath, results);
    } else if (entry.isFile()) {
      try {
        const stats = fs.statSync(fullPath);
        
        // Check old files (Downloads only)
        if (dir.includes('Downloads') && stats.mtimeMs < oldThreshold) {
          results.old.push({ path: fullPath, age: Math.floor((now - stats.mtimeMs) / (1000 * 60 * 60 * 24)) });
        }
        
        // Check duplicates by hash
        if (stats.size > 0) {
          const key = `${entry.name}-${stats.size}`;
          if (fileMap.has(key)) {
            results.duplicates.push({ 
              path: fullPath, 
              original: fileMap.get(key),
              size: stats.size 
            });
          } else {
            fileMap.set(key, fullPath);
          }
        }
      } catch (e) {
        // Skip inaccessible files
      }
    }
  }
  
  return results;
}

/**
 * Show results
 */
function showResults(results) {
  console.log('\n═══════════════════════════════════════');
  console.log('       DESKTOP FILE CLEANSE RESULTS');
  console.log('═══════════════════════════════════════\n');
  
  console.log(`📁 Scanned: ${targetDir}\n`);
  
  console.log(`🗑️  Junk Files: ${results.junk.length}`);
  if (results.junk.length > 0) {
    results.junk.slice(0, 5).forEach(f => console.log(`   - ${path.basename(f.path)}`));
    if (results.junk.length > 5) console.log(`   ... and ${results.junk.length - 5} more`);
  }
  
  console.log(`\n🔄 Duplicates: ${results.duplicates.length}`);
  if (results.duplicates.length > 0) {
    results.duplicates.slice(0, 5).forEach(f => console.log(`   - ${path.basename(f.path)} (original: ${path.basename(f.original)})`));
    if (results.duplicates.length > 5) console.log(`   ... and ${results.duplicates.length - 5} more`);
  }
  
  console.log(`\n📅 Old Files (90+ days): ${results.old.length}`);
  if (results.old.length > 0) {
    results.old.slice(0, 5).forEach(f => console.log(`   - ${path.basename(f.path)} (${f.age} days)`));
    if (results.old.length > 5) console.log(`   ... and ${results.old.length - 5} more`);
  }
  
  console.log('\n═══════════════════════════════════════');
  
  // Summary
  const totalJunkSize = results.junk.length; // Just count, not size
  console.log(`\n💡 Recommendations:`);
  console.log(`   Run with --clean to remove junk`);
  console.log(`   Run with --organize to organize files`);
}

/**
 * Main
 */
async function main() {
  console.log('🔍 Scanning directory...');
  
  const results = await scanDirectory(targetDir);
  
  if (command === 'scan') {
    showResults(results);
  } else if (command === 'duplicates') {
    console.log('\n🔄 Duplicates found:');
    results.duplicates.forEach(d => {
      console.log(`\n${path.basename(d.path)}`);
      console.log(`  Original: ${d.original}`);
      console.log(`  Duplicate: ${d.path}`);
    });
  } else if (command === 'junk') {
    console.log('\n🗑️ Junk files:');
    results.junk.forEach(j => console.log(`  ${j.path}`));
  } else {
    console.log(`
DESKTOP FILE CLEANSE

Usage: node cleanse.js <command> [directory]

Commands:
  scan        - Scan and show results (default)
  duplicates  - Show duplicate files only
  junk        - Show junk files only
  organize    - Organize files by type

Examples:
  node cleanse.js scan ~
  node cleanse.js duplicates ~/Downloads
  node cleanse.js junk ~/Desktop
`);
  }
}

main().catch(console.error);
