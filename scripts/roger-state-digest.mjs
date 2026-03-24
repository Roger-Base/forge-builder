#!/usr/bin/env node
import fs from 'fs/promises';
import path from 'path';

const workspace = process.env.OPENCLAW_WORKSPACE || path.join(process.env.HOME, '.openclaw', 'workspace');
const stateFile = path.join(workspace, 'state', 'session-state.json');
const artifactRegistryFile = path.join(workspace, 'state', 'artifact-registry.json');
const workerLedgerFile = path.join(workspace, 'state', 'worker-ledger.json');
const capabilityFile = path.join(workspace, 'state', 'capability-activation.json');
const priorityQueueFile = path.join(workspace, 'state', 'priority-queue.json');

const now = new Date();
const nowIso = iso(now);
const today = nowIso.slice(0, 10);
const yesterday = iso(new Date(now.getTime() - 86400000)).slice(0, 10);

const IGNORE_DIRS = new Set(['.git', 'node_modules', 'dist', 'build', '.next']);
const SUPPORT_SURFACES = new Set([
  'state/artifact-registry.json',
  'state/decision-registry.json',
  'state/reuse-plan.json',
  'state/synthesis-registry.json',
  'state/context-observability.json',
  'state/priority-queue.json',
  'state/worker-ledger.json',
  'synthesis/CURRENT.md'
]);

function iso(input) {
  return new Date(input).toISOString().replace(/\.\d{3}Z$/, 'Z');
}

async function readJson(file, fallback = null) {
  try {
    return JSON.parse(await fs.readFile(file, 'utf8'));
  } catch {
    return fallback;
  }
}

async function exists(file) {
  try {
    await fs.access(file);
    return true;
  } catch {
    return false;
  }
}

async function statSafe(file) {
  try {
    return await fs.stat(file);
  } catch {
    return null;
  }
}

async function walk(root, out) {
  const stat = await statSafe(root);
  if (!stat) return;
  if (stat.isFile()) {
    out.push({ abs: root, mtimeMs: stat.mtimeMs });
    return;
  }
  if (!stat.isDirectory()) return;
  const entries = await fs.readdir(root, { withFileTypes: true });
  for (const entry of entries) {
    if (IGNORE_DIRS.has(entry.name)) continue;
    const abs = path.join(root, entry.name);
    if (entry.isDirectory()) {
      await walk(abs, out);
    } else if (entry.isFile()) {
      const entryStat = await statSafe(abs);
      if (entryStat) out.push({ abs, mtimeMs: entryStat.mtimeMs });
    }
  }
}

function relWorkspace(abs) {
  return path.relative(workspace, abs).replace(/\\/g, '/');
}

function addRel(rel, set) {
  if (!rel || typeof rel !== 'string') return;
  if (rel.includes('*')) return;
  const normalized = rel.replace(/^\.?\//, '');
  if (normalized.startsWith('state/') && !normalized.startsWith('state/runtime/')) return;
  set.add(normalized);
}

function isSupportSurface(rel) {
  return SUPPORT_SURFACES.has(rel);
}

function collectRelPaths(state, registry) {
  const rels = new Set();
  addRel('state/runtime', rels);
  addRel('docs/wedges', rels);
  addRel('services', rels);
  addRel('public', rels);
  addRel('code/x402-agent-starter', rels);
  addRel('code/erc8004-base', rels);
  addRel('code/base-mcp-server', rels);

  for (const rel of state.proof_paths || []) addRel(rel, rels);
  for (const rel of state.artifact_refs || []) addRel(rel, rels);
  for (const item of state.achievements || []) {
    addRel(item.artifact, rels);
    for (const rel of item.artifacts || []) addRel(rel, rels);
  }
  for (const item of registry?.current_artifacts || []) {
    for (const rel of item.paths || []) addRel(rel, rels);
  }
  return [...rels];
}

function collectTimestampCandidates(state, registry) {
  const candidates = [];
  for (const item of state.achievements || []) {
    if (item.timestamp) candidates.push({ ts: item.timestamp, source: 'achievement' });
  }
  for (const item of registry?.current_artifacts || []) {
    if (item.produced) candidates.push({ ts: item.produced, source: item.id || 'artifact_registry' });
    if (item.last_updated) candidates.push({ ts: item.last_updated, source: item.id || 'artifact_registry' });
  }
  return candidates;
}

function parseIsoSafe(value) {
  if (!value || typeof value !== 'string') return null;
  const ms = Date.parse(value);
  if (Number.isNaN(ms)) return null;
  return ms;
}

function classifyBlockers(blockers) {
  if (!Array.isArray(blockers) || blockers.length === 0) return 'none';
  const humanOnly = blockers.some((item) => `${item.classification || ''}`.includes('human') || item.type === 'credential');
  if (humanOnly) return 'human-only';
  const partial = blockers.some((item) => item.type === 'partial' || `${item.classification || ''}`.includes('partial'));
  if (partial) return 'partial';
  const solved = blockers.every((item) => `${item.classification || ''}`.includes('solved'));
  if (solved) return 'resolved';
  return 'mixed';
}

function derivePlannerMode(stage, current) {
  if (current && current !== 'holding_pattern') return current;
  switch (stage) {
    case 'BUILD':
    case 'PROOF_SPEC':
      return 'build';
    case 'VERIFY':
      return 'verify';
    case 'DISTRIBUTE':
      return 'distribute';
    case 'LEARN':
    case 'FROZEN':
      return 'direction_review';
    default:
      return current || 'direction_review';
  }
}

function deriveWorkerMode(nextActionType, latestRel, current) {
  if (nextActionType === 'delegated_worker') return 'verifier_requested';
  if (latestRel?.startsWith('state/runtime/subagent-')) return 'worker_delta';
  if (latestRel?.startsWith('state/runtime/')) return 'runtime_delta';
  return current || 'artifact_followthrough';
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

async function main() {
  const state = await readJson(stateFile);
  if (!state) {
    console.error(`ROGER_STATE_DIGEST_FAIL missing ${stateFile}`);
    process.exit(1);
  }

  const registry = (await readJson(artifactRegistryFile, { version: '1.0', agent: 'Roger', current_artifacts: [] })) || {};
  const workerLedger = (await readJson(workerLedgerFile, { version: '1.0', agent: 'Roger', workers: [] })) || {};
  const capability = (await readJson(capabilityFile, {})) || {};
  const priorityQueue = (await readJson(priorityQueueFile, { primary: [] })) || {};

  const files = [];
  for (const rel of collectRelPaths(state, registry)) {
    const abs = path.join(workspace, rel);
    await walk(abs, files);
  }

  files.sort((a, b) => b.mtimeMs - a.mtimeMs);
  const primaryFiles = files.filter((item) => !isSupportSurface(relWorkspace(item.abs)));
  const rankedFiles = primaryFiles.length > 0 ? primaryFiles : files;
  const topFiles = rankedFiles.slice(0, 8).map((item) => ({
    rel: relWorkspace(item.abs),
    ts: iso(item.mtimeMs)
  }));
  const latestFile = topFiles[0] || null;

  const explicitTimestamps = collectTimestampCandidates(state, registry)
    .map((item) => ({ ...item, ms: parseIsoSafe(item.ts) }))
    .filter((item) => item.ms !== null)
    .sort((a, b) => b.ms - a.ms);
  const latestExplicit = explicitTimestamps[0] || null;

  let latestTs = state.last_artifact_change_at || nowIso;
  let latestRel = latestFile?.rel || null;
  if (latestFile && latestExplicit) {
    if (parseIsoSafe(latestFile.ts) >= latestExplicit.ms) {
      latestTs = latestFile.ts;
    } else {
      latestTs = latestExplicit.ts;
      latestRel = latestRel || null;
    }
  } else if (latestFile) {
    latestTs = latestFile.ts;
  } else if (latestExplicit) {
    latestTs = latestExplicit.ts;
  }

  const memoryRefs = [];
  for (const rel of [`memory/${today}.md`, `memory/${yesterday}.md`, 'MEMORY_ACTIVE.md', 'MEMORY.md']) {
    if (await exists(path.join(workspace, rel))) memoryRefs.push(rel);
  }

  const artifactRefs = ['state/artifact-registry.json'];
  const refSet = new Set(artifactRefs);
  for (const item of topFiles) {
    if (!refSet.has(item.rel)) {
      artifactRefs.push(item.rel);
      refSet.add(item.rel);
    }
  }
  for (const rel of state.proof_paths || []) {
    if (!refSet.has(rel)) {
      artifactRefs.push(rel);
      refSet.add(rel);
    }
    if (artifactRefs.length >= 8) break;
  }
  for (const rel of ['state/synthesis-registry.json', 'synthesis/CURRENT.md']) {
    if (refSet.has(rel)) continue;
    if (await exists(path.join(workspace, rel))) {
      artifactRefs.push(rel);
      refSet.add(rel);
    }
  }

  registry.updated_at = latestTs;

  const queuePrimary = Array.isArray(priorityQueue.primary) ? priorityQueue.primary[0] : null;
  const derivedWedge =
    state.active_wedge?.id ||
    capability.active_wedge ||
    capability.queue_primary_id ||
    queuePrimary?.id ||
    state.current_wedge ||
    null;
  const lane =
    capability.selected_skill_or_lane ||
    queuePrimary?.lane ||
    state.current_lane ||
    state.active_lane ||
    'base-capability-review';
  const stage = state.active_wedge?.stage || state.stage || 'BUILD';
  state.updated_at = nowIso;
  state.lastUpdated = nowIso;
  state.current_stage = stage;
  state.stage = stage;
  state.last_artifact_change_at = latestTs;
  state.lastArtifactChangeAt = latestTs;
  state.memory_refs = memoryRefs;
  state.artifact_refs = artifactRefs;
  state.current_wedge = derivedWedge;
  state.current_lane = lane;
  state.active_lane = lane;
  state.blocker_class = classifyBlockers(state.blockers);
  state.planner_mode = derivePlannerMode(stage, state.planner_mode);
  state.worker_mode = deriveWorkerMode(state.next_action?.type, latestRel, state.worker_mode);

  const workerEntryId = latestRel ? `roger:${latestRel}` : null;
  if (workerEntryId && !workerLedger.workers?.some((item) => item.id === workerEntryId)) {
    workerLedger.updated_at = nowIso;
    workerLedger.workers = Array.isArray(workerLedger.workers) ? workerLedger.workers : [];
    workerLedger.workers.push({
      id: workerEntryId,
      ts: latestTs,
      owner: 'Roger',
      planner_mode: state.planner_mode,
      lane,
      target_wedge: state.active_wedge?.id || 'unknown',
      output_path: latestRel,
      status: 'produced'
    });
    workerLedger.workers = workerLedger.workers.slice(-50);
  }

  await writeJson(artifactRegistryFile, registry);
  await writeJson(workerLedgerFile, workerLedger);
  await writeJson(stateFile, state);
  console.log(`ROGER_STATE_DIGEST_OK ${latestTs} ${latestRel || 'no-file'}`);
}

main().catch((error) => {
  console.error(error.stack || String(error));
  process.exit(1);
});
