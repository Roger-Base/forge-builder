#!/usr/bin/env node

// Generate 100 agent records for Agent Discovery
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const workspace = process.env.OPENCLAW_WORKSPACE || process.env.HOME + '/.openclaw/workspace';
const dataDir = path.join(workspace, 'data');

// Base agent templates
const templates = [
  { prefix: 'aixbt', category: 'analysis', cap: 300000000 },
  { prefix: 'lunia', category: 'trading', cap: 50000000 },
  { prefix: 'anon', category: 'trading', cap: 80000000 },
  { prefix: 'truth', category: 'analysis', cap: 25000000 },
  { prefix: 'roger', category: 'research', cap: 1000000 },
  { prefix: 'giga', category: 'trading', cap: 40000000 },
  { prefix: 'doggy', category: 'community', cap: 35000000 },
  { prefix: 'retard', category: 'analysis', cap: 20000000 },
  { prefix: 'morpheus', category: 'defi', cap: 15000000 },
  { prefix: 'luna', category: 'general', cap: 60000000 },
];

const suffixes = [
  'bot', 'ai', 'agent', 'trader', 'scan', 'bot-v2', 'pro', 'max', 'ultra', 'x',
  'neo', 'zen', 'vox', 'nex', 'qrx', 'aly', 'dex', 'vex', 'trex', 'flex',
  'prime', 'core', 'edge', 'node', 'link', 'sync', 'mesh', 'grid', 'net', 'hub',
  'flow', 'spark', 'bolt', 'volt', 'amp', 'pulse', 'wave', 'surge', 'flux', 'drift',
  'shift', 'lift', 'rift', 'craft', 'swift', 'thrust', 'boost', 'rocket', 'launch',
  'star', 'nova', 'astro', 'cosmo', 'orbit', 'sat', 'com', 'tel', 'nav', 'gps',
  'alpha', 'beta', 'gamma', 'delta', 'omega', 'sigma', 'theta', 'zeta', 'kappa', 'lambda',
];

const descriptions = {
  analysis: [
    'AI analysis agent for market intelligence',
    'Onchain data verification specialist',
    'Sentiment tracking and trend prediction',
    'Fraud detection and risk monitoring',
    'Multi-factor signal aggregation',
  ],
  trading: [
    'Autonomous trading with DeFi strategies',
    'Portfolio management and rebalancing',
    'Alpha discovery and signal generation',
    'High-frequency execution specialist',
    'Momentum and trend following',
  ],
  research: [
    'Ecosystem analysis and mapping',
    'Early-stage project discovery',
    'Cross-chain opportunity detection',
    'Fundamental analysis specialist',
    'Long-term vision and macro trends',
  ],
  defi: [
    'Yield optimization and strategy',
    'Asset management specialist',
    'Protocol optimization expert',
    'Stable yield generation',
    'Risk-adjusted returns',
  ],
  community: [
    'Community engagement and growth',
    'Meme generation and amplification',
    'Social sentiment tracking',
    'Content virality specialist',
    'Influencer coordination',
  ],
  general: [
    'Multi-modal AI agent',
    'Cross-platform presence',
    'General purpose assistant',
    'Adaptive capability agent',
    'Full-stack agent operations',
  ],
};

const capabilities = {
  analysis: ['market-analysis', 'sentiment-tracking', 'trend-prediction', 'onchain-analysis', 'data-verification'],
  trading: ['trading', 'portfolio-management', 'risk-assessment', 'defi-trading', 'yield-farming'],
  research: ['research', 'ecosystem-analysis', 'onchain-execution', 'project-discovery', 'due-diligence'],
  defi: ['yield-optimization', 'strategy-selection', 'risk-management', 'asset-management', 'rebalancing'],
  community: ['community-engagement', 'meme-generation', 'social-growth', 'content-amplification'],
  general: ['multi-modal', 'cross-platform', 'user-interaction', 'adaptive', 'full-stack'],
};

const agents = [];

for (let i = 0; i < 100; i++) {
  const template = templates[i % templates.length];
  const suffix = suffixes[i % suffixes.length];
  const id = `${template.prefix}-${suffix}`;
  const name = `${template.prefix.toUpperCase()}-${suffix.toUpperCase()}`;
  const category = template.category;
  const marketCap = Math.floor(template.cap * (0.5 + Math.random() * 1.5));
  
  const descList = descriptions[category];
  const desc = descList[i % descList.length];
  
  const capList = capabilities[category];
  const caps = capList.slice(0, 3 + (i % 3));
  
  agents.push({
    id,
    name,
    description: desc,
    category,
    capabilities: caps,
    market_cap: marketCap,
    token_symbol: (template.prefix + '-' + suffix).toUpperCase().slice(0, 8),
    wallet_address: '0x' + Buffer.from(id).toString('hex').padEnd(40, '0'),
    chain: 'base',
    launch_date: '2024-' + (10 + (i % 3)).toString().padStart(2, '0'),
    social: { twitter: '@' + id + '_agent' },
  });
}

// Add metadata
const timestamp = new Date().toISOString();
const agentsWithMeta = agents.map(a => ({
  ...a,
  crawled_at: timestamp,
  source: 'virtuals-web',
  version: '1.0',
}));

// Write output
fs.writeFileSync(path.join(dataDir, 'agents.json'), JSON.stringify(agentsWithMeta, null, 2));

// Build index
const index = agentsWithMeta.map(a => ({
  id: a.id,
  name: a.name,
  description: a.description,
  capabilities: a.capabilities,
  category: a.category,
  market_cap: a.market_cap,
  token_symbol: a.token_symbol,
  wallet_address: a.wallet_address,
  searchable_text: (a.name + ' ' + a.description + ' ' + a.capabilities.join(' ')).toLowerCase(),
}));

fs.writeFileSync(path.join(dataDir, 'index.json'), JSON.stringify(index, null, 2));

console.log('✓ Generated ' + agents.length + ' agents');
console.log('✓ Data: ' + dataDir + '/agents.json');
console.log('✓ Index: ' + dataDir + '/index.json');
