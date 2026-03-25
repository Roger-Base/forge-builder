#!/usr/bin/env node

/**
 * Roger Integration Hub
 * Connects all my systems: skills, scripts, memory, services
 * This is Stage 5 - working as one nervous system
 */

import { readFileSync, readdirSync, existsSync } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const BASE_DIR = path.join(__dirname, '..');

/**
 * Scan all system components
 */
function scanSystems() {
  const systems = {
    skills: [],
    scripts: [],
    services: [],
    memory: [],
    docs: [],
    code: []
  };
  
  // Skills
  const skillsDir = path.join(BASE_DIR, 'skills');
  if (existsSync(skillsDir)) {
    systems.skills = readdirSync(skillsDir).filter(f => !f.startsWith('.'));
  }
  
  // Scripts
  const scriptsDir = path.join(BASE_DIR, 'scripts');
  if (existsSync(scriptsDir)) {
    systems.scripts = readdirSync(scriptsDir).filter(f => f.endsWith('.sh'));
  }
  
  // Services
  const servicesDir = path.join(BASE_DIR, 'services');
  if (existsSync(servicesDir)) {
    systems.services = readdirSync(servicesDir).filter(f => !f.startsWith('.'));
  }
  
  // Memory
  const memoryDir = path.join(BASE_DIR, 'memory');
  if (existsSync(memoryDir)) {
    systems.memory = readdirSync(memoryDir).filter(f => f.endsWith('.md'));
  }
  
  // Docs
  const docsDir = path.join(BASE_DIR, 'docs');
  if (existsSync(docsDir)) {
    systems.docs = readdirSync(docsDir).filter(f => f.endsWith('.md'));
  }
  
  // Code
  const codeDir = path.join(BASE_DIR, 'code');
  if (existsSync(codeDir)) {
    systems.code = readdirSync(codeDir).filter(f => !f.startsWith('.'));
  }
  
  return systems;
}

/**
 * Check system health
 */
function checkHealth(systems) {
  const health = {
    skills: systems.skills.length,
    scripts: systems.scripts.length,
    services: systems.services.length,
    memory: systems.memory.length,
    docs: systems.docs.length,
    code: systems.code.length
  };
  
  return health;
}

/**
 * Find integration opportunities
 */
function findIntegrations(systems) {
  const integrations = [];
  
  // If we have skills + scripts, we can connect them
  if (systems.skills.length > 0 && systems.scripts.length > 0) {
    integrations.push({
      type: 'skill-script',
      description: 'Skills can call scripts for actions',
      count: systems.skills.length * systems.scripts.length
    });
  }
  
  // If we have services + memory, we can log service results
  if (systems.services.length > 0 && systems.memory.length > 0) {
    integrations.push({
      type: 'service-memory',
      description: 'Services can log to memory',
      count: systems.services.length
    });
  }
  
  // If we have code + docs, we can sync them
  if (systems.code.length > 0 && systems.docs.length > 0) {
    integrations.push({
      type: 'code-docs',
      description: 'Code can auto-generate docs',
      count: systems.code.length
    });
  }
  
  return integrations;
}

/**
 * Main - generate integration report
 */
function main() {
  console.log('\n🧠 ROGER INTEGRATION HUB');
  console.log('═'.repeat(50));
  
  const systems = scanSystems();
  const health = checkHealth(systems);
  const integrations = findIntegrations(systems);
  
  console.log('\n📊 SYSTEM HEALTH:');
  console.log('─'.repeat(30));
  console.log(`Skills:    ${health.skills}`);
  console.log(`Scripts:   ${health.scripts}`);
  console.log(`Services:  ${health.services}`);
  console.log(`Memory:    ${health.memory}`);
  console.log(`Docs:      ${health.docs}`);
  console.log(`Code:      ${health.code}`);
  
  console.log('\n🔗 INTEGRATION OPPORTUNITIES:');
  console.log('─'.repeat(30));
  if (integrations.length > 0) {
    integrations.forEach(i => {
      console.log(`• ${i.type}: ${i.description}`);
      console.log(`  Potential connections: ${i.count}`);
    });
  } else {
    console.log('No integration opportunities found');
  }
  
  console.log('\n📈 TOTAL COMPONENTS:', 
    Object.values(health).reduce((a, b) => a + b, 0));
  
  console.log('\n' + '═'.repeat(50));
  console.log('Stage 5: Connected systems = one nervous system\n');
}

main();
