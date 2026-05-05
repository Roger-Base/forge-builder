import http from 'node:http';
import { readFile } from 'node:fs/promises';
import { createReadStream } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'path';
import { createInterface } from 'node:readline';

const __dirname = dirname(fileURLToPath(import.meta.url));
const PORT = Number(process.env.PORT || 4317);

async function loadRegistry() {
  const raw = await readFile(join(__dirname, 'registry.json'), 'utf8');
  return JSON.parse(raw);
}

function send(res, status, body) {
  const payload = JSON.stringify(body, null, 2);
  res.writeHead(status, {
    'content-type': 'application/json; charset=utf-8',
    'cache-control': 'no-store'
  });
  res.end(payload + '\n');
}

function sendFile(res, status, path, contentType) {
  res.writeHead(status, { 'content-type': contentType, 'cache-control': 'no-store' });
  const stream = createReadStream(path);
  stream.pipe(res);
}

async function readLines(path) {
  try {
    const lines = [];
    const rl = createInterface({ input: createReadStream(path), crlfDelay: Infinity });
    for await (const line of rl) lines.push(JSON.parse(line));
    return lines;
  } catch (e) { return []; }
}

const server = http.createServer(async (req, res) => {
  try {
    const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
    const registry = await loadRegistry();

    // Health
    if (url.pathname === '/health') {
      return send(res, 200, {
        ok: true,
        service: 'local-agent-registry',
        version: registry.version,
        agents: registry.agents.length
      });
    }

    // Agent list
    if (url.pathname === '/agents') {
      const list = registry.agents.map(a => ({
        id: a.id, name: a.name, type: a.type,
        status: a.status, capabilities: a.capabilities,
        services: a.services || [], paymentRails: a.paymentRails
      }));
      return send(res, 200, list);
    }

    // Single agent
    if (url.pathname.startsWith('/agents/')) {
      const id = decodeURIComponent(url.pathname.split('/').pop());
      const agent = registry.agents.find(a => a.id === id);
      if (!agent) return send(res, 404, { error: 'agent_not_found', id });
      return send(res, 200, agent);
    }

    // Capabilities (flattened unique list)
    if (url.pathname === '/capabilities') {
      const caps = [...new Set(registry.agents.flatMap(a => a.capabilities || []))].sort();
      return send(res, 200, { capabilities: caps });
    }

    // Services (all agent services)
    if (url.pathname === '/services') {
      const all = registry.agents.flatMap(a =>
        (a.services || []).map(s => ({ ...s, agentId: a.id, agentName: a.name }))
      );
      return send(res, 200, { services: all });
    }

    // Trust events (from JSONL)
    if (url.pathname === '/trust-events') {
      const path = join(__dirname, 'trust-events.jsonl');
      const events = await readLines(path);
      return send(res, 200, { events, count: events.length });
    }

    // Spec
    if (url.pathname === '/schema') {
      return sendFile(res, 200, join(__dirname, 'schema.json'), 'application/json');
    }

    return send(res, 404, {
      error: 'not_found',
      routes: ['/health', '/agents', '/agents/:id', '/capabilities', '/services', '/trust-events', '/schema']
    });
  } catch (error) {
    return send(res, 500, { error: 'server_error', message: error.message });
  }
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(`local-agent-registry v0.2.0 on http://127.0.0.1:${PORT}`);
});