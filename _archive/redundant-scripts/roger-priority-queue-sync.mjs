#!/usr/bin/env node
import fs from 'fs/promises';
import path from 'path';

const workspace = process.env.OPENCLAW_WORKSPACE || path.join(process.env.HOME, '.openclaw', 'workspace');
const stateFile = path.join(workspace, 'state', 'session-state.json');
const synthFile = path.join(workspace, 'state', 'synthesis-registry.json');
const reuseFile = path.join(workspace, 'state', 'reuse-plan.json');
const registryFile = path.join(workspace, 'state', 'artifact-registry.json');
const queueFile = path.join(workspace, 'state', 'priority-queue.json');

const nowIso = new Date().toISOString().replace(/\.\d{3}Z$/, 'Z');

async function readJson(file, fallback = null) {
  try {
    return JSON.parse(await fs.readFile(file, 'utf8'));
  } catch {
    return fallback;
  }
}

async function writeJson(file, data) {
  await fs.mkdir(path.dirname(file), { recursive: true });
  const tmp = path.join(
    path.dirname(file),
    `.${path.basename(file)}.${process.pid}.${Date.now()}.${Math.random().toString(16).slice(2)}.tmp`
  );
  await fs.writeFile(tmp, `${JSON.stringify(data, null, 2)}\n`);
  await fs.rename(tmp, file);
}

function normalize(value) {
  return `${value || ''}`.toLowerCase();
}

function queueStatus(state, reuse) {
  const blockerClass = state.blocker_class || 'none';
  const nextType = state.next_action?.type || '';
  if ((reuse.recommendation || '').startsWith('reuse_existing_bundle') && nextType === 'artifact_delta') {
    return blockerClass === 'human-only' ? 'ready_refresh_despite_human_blockers' : 'ready_reuse';
  }
  if (blockerClass === 'human-only') return 'blocked_human_only';
  if (blockerClass === 'partial') return 'ready_search_verify';
  return 'ready';
}

function deriveBundleWedge(bundleId, paths = []) {
  const id = normalize(bundleId);
  if (id.includes('agent-trust-discovery')) return 'agent-trust-discovery';
  if (id.includes('defai-yield-agent')) return 'defai-yield-agent';
  if (id.includes('agent-security-scanner')) return 'agent_security_scanner';
  for (const rel of paths) {
    const p = normalize(rel);
    if (p.includes('agent-trust-discovery')) return 'agent-trust-discovery';
    if (p.includes('defai-yield-agent')) return 'defai-yield-agent';
    if (p.includes('agent_security_scanner')) return 'agent_security_scanner';
  }
  return bundleId;
}

function secondaryStatus(bundle) {
  const status = normalize(bundle.status);
  if (status.includes('waiting_human_blocker')) return 'blocked_human_only';
  if (status.includes('partial')) return 'ready_verify_after_unblock';
  if (status.includes('published') || status.includes('ready') || status.includes('current')) return 'ready';
  return 'holding';
}

async function main() {
  const state = await readJson(stateFile, {});
  const synth = await readJson(synthFile, {});
  const reuse = await readJson(reuseFile, {});
  const registry = await readJson(registryFile, { current_artifacts: [] });

  const activeWedge = state.active_wedge?.id || synth.active_wedge || 'unknown';
  const activeLane = synth.current_lane || state.current_lane || 'builder-execution';
  const activeStatus = queueStatus(state, reuse);
  const primaryNoteBase = synth.proof_expected
    ? `Current proof target: ${synth.proof_expected}.`
    : `Current next action: ${state.next_action?.type || 'continue_current'}.`;
  const primaryNote = reuse.note
    ? `${primaryNoteBase} Reuse rule: ${reuse.note}`
    : primaryNoteBase;

  const secondary = [];
  for (const bundle of registry.current_artifacts || []) {
    const wedgeId = deriveBundleWedge(bundle.id, bundle.paths || []);
    if (wedgeId === activeWedge) continue;
    secondary.push({
      id: wedgeId,
      lane: bundle.paths?.[0] || 'artifact-family',
      status: secondaryStatus(bundle),
      note: bundle.reuse_notes || `Maintain ${bundle.id} as a reusable surface.`
    });
  }

  const queue = {
    version: '1.0',
    agent: 'Roger',
    updated_at: nowIso,
    primary: [
      {
        id: activeWedge,
        lane: activeLane,
        status: activeStatus,
        note: primaryNote
      }
    ],
    secondary: secondary.slice(0, 4),
    maintenance: [
      {
        id: 'artifact-reuse',
        lane: 'audit',
        status: reuse.target_path ? 'ready' : 'watch',
        note: reuse.note || 'Check canonical bundle reuse before opening a replacement surface.'
      },
      {
        id: 'synthesis-anchor',
        lane: 'synthesize',
        status: 'ready',
        note: `Keep synthesis aligned with ${activeWedge} before widening scope.`
      }
    ]
  };

  await writeJson(queueFile, queue);
  console.log(`ROGER_PRIORITY_QUEUE_SYNC_OK ${activeWedge} ${activeStatus}`);
}

main().catch((error) => {
  console.error(error.stack || String(error));
  process.exit(1);
});
