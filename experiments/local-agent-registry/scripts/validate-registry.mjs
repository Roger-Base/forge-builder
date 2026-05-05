import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const registry = JSON.parse(await readFile(join(root, 'registry.json'), 'utf8'));
const ids = new Set();
const errors = [];

if (!Array.isArray(registry.agents) || registry.agents.length === 0) {
  errors.push('registry.agents must be a non-empty array');
}

for (const agent of registry.agents || []) {
  for (const key of ['id', 'name', 'type', 'status', 'description']) {
    if (!agent[key]) errors.push(`${agent.id || '<unknown>'}: missing ${key}`);
  }
  if (ids.has(agent.id)) errors.push(`${agent.id}: duplicate id`);
  ids.add(agent.id);
  if (!Array.isArray(agent.capabilities) || agent.capabilities.length === 0) {
    errors.push(`${agent.id}: capabilities must be non-empty`);
  }
  if (!agent.trust || typeof agent.trust !== 'object') {
    errors.push(`${agent.id}: trust object required`);
  }
}

if (errors.length) {
  console.error(JSON.stringify({ ok: false, errors }, null, 2));
  process.exit(1);
}

console.log(JSON.stringify({ ok: true, agents: registry.agents.length, capabilities: [...new Set(registry.agents.flatMap(a => a.capabilities))].length }, null, 2));
