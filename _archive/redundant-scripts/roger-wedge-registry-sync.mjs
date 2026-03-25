#!/usr/bin/env node
import fs from 'fs/promises';
import path from 'path';

const workspace = process.env.OPENCLAW_WORKSPACE || path.join(process.env.HOME, '.openclaw', 'workspace');
const outFile = path.join(workspace, 'state', 'wedge-registry.json');
const nowIso = new Date().toISOString().replace(/\.\d{3}Z$/, 'Z');

async function writeJson(file, data) {
  await fs.mkdir(path.dirname(file), { recursive: true });
  const tmp = path.join(
    path.dirname(file),
    `.${path.basename(file)}.${process.pid}.${Date.now()}.${Math.random().toString(16).slice(2)}.tmp`
  );
  await fs.writeFile(tmp, `${JSON.stringify(data, null, 2)}\n`);
  await fs.rename(tmp, file);
}

async function main() {
  const registry = {
    version: '1.0',
    agent: 'Roger',
    authority: 'local_wedge_registry',
    updated_at: nowIso,
    wedges: [
      {
        id: 'agent-trust-discovery',
        artifact: {
          command: 'cd ~/.openclaw/workspace && bash scripts/refresh-agent-trust-discovery.sh docs/wedges/agent-trust-discovery/demo-output.md',
          target: 'docs/wedges/agent-trust-discovery/demo-output.md',
          proof_expected: 'fresh live lookup output captured in the canonical agent-trust-discovery demo surface',
          lane: 'services/erc8004-agent-lookup + refresh-agent-trust-discovery.sh'
        }
      },
      {
        id: 'defai-yield-agent',
        artifact: {
          command: 'cd ~/.openclaw/workspace && bash scripts/refresh-defai-yield-artifacts.sh docs/wedges/defai-yield-agent/P1-yield-scan.md',
          target: 'docs/wedges/defai-yield-agent/P1-yield-scan.md',
          proof_expected: 'fresh canonical P1 yield scan or failure trace recorded on the defai-yield-agent wedge',
          lane: 'defai-yield-scan.js + refresh-defai-yield-artifacts.sh'
        }
      },
      {
        id: 'agent_security_scanner',
        artifact: {
          command: 'cd ~/.openclaw/workspace && bash scripts/agent-security-scanner.sh --target skills/security-audit-toolkit/SKILL.md --output state/runtime/security-audit-toolkit-scan-$(date -u +%Y%m%d-%H%M%S).md',
          target: 'state/runtime/security-audit-toolkit-scan-*.md',
          proof_expected: 'fresh security audit on security-audit-toolkit',
          lane: 'skills/agent-evaluation/SKILL.md + scripts/agent-security-scanner.sh'
        }
      },
      {
        id: 'base_account_miniapp_probe',
        artifact: {
          command: 'cd ~/.openclaw/workspace && bash scripts/base_mini_app_monitor_demo.sh',
          target: 'docs/wedges/base_account_miniapp_probe/demo-output.md',
          proof_expected: 'fresh demo output for the miniapp probe wedge',
          lane: 'base_mini_app_monitor_demo.sh'
        }
      }
    ],
    learn_checkpoint: {
      command: 'date +%s',
      target: 'none',
      proof_expected: 'learn phase checkpoint',
      lane: 'none'
    }
  };

  await writeJson(outFile, registry);
  console.log(`ROGER_WEDGE_REGISTRY_SYNC_OK ${outFile}`);
}

main().catch((error) => {
  console.error(error.stack || String(error));
  process.exit(1);
});
