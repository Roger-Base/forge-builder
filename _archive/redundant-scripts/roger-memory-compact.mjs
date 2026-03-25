#!/usr/bin/env node
import fs from 'fs/promises';
import path from 'path';

const workspace = process.env.OPENCLAW_WORKSPACE || path.join(process.env.HOME, '.openclaw', 'workspace');
const stateFile = path.join(workspace, 'state', 'session-state.json');
const decisionsFile = path.join(workspace, 'state', 'decision-registry.json');
const artifactsFile = path.join(workspace, 'state', 'artifact-registry.json');
const reuseFile = path.join(workspace, 'state', 'reuse-plan.json');
const capabilityFile = path.join(workspace, 'state', 'capability-activation.json');
const synthesisFile = path.join(workspace, 'state', 'synthesis-registry.json');
const activeMemoryFile = path.join(workspace, 'MEMORY_ACTIVE.md');
const durableMemoryFile = path.join(workspace, 'MEMORY.md');

const ACTIVE_START = '<!-- OPENCLAW_MANAGED_ACTIVE_START -->';
const ACTIVE_END = '<!-- OPENCLAW_MANAGED_ACTIVE_END -->';
const DURABLE_START = '<!-- OPENCLAW_MANAGED_DURABLE_START -->';
const DURABLE_END = '<!-- OPENCLAW_MANAGED_DURABLE_END -->';

const now = new Date();
const nowIso = now.toISOString().replace(/\.\d{3}Z$/, 'Z');
const today = nowIso.slice(0, 10);
const yesterday = new Date(now.getTime() - 86400000).toISOString().slice(0, 10);

async function readJson(file, fallback = null) {
  try {
    return JSON.parse(await fs.readFile(file, 'utf8'));
  } catch {
    return fallback;
  }
}

async function readText(file, fallback = '') {
  try {
    return await fs.readFile(file, 'utf8');
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

function replaceManagedBlock(original, start, end, body) {
  const block = `${start}\n${body.trimEnd()}\n${end}`;
  if (original.includes(start) && original.includes(end)) {
    return original.replace(new RegExp(`${escapeRegExp(start)}[\\s\\S]*?${escapeRegExp(end)}`), block);
  }
  const trimmed = original.trimEnd();
  return `${trimmed}\n\n${block}\n`;
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function pickHighlights(text, limit = 8) {
  const lines = text.split('\n').map((line) => line.trim()).filter(Boolean);
  const picks = [];
  for (const line of lines) {
    if (line.startsWith('- ') || line.startsWith('1.') || line.startsWith('2.') || line.startsWith('3.')) {
      picks.push(line);
    }
    if (picks.length >= limit) break;
  }
  return picks;
}

async function main() {
  const state = (await readJson(stateFile, {})) || {};
  const decisions = (await readJson(decisionsFile, { decisions: [] })) || {};
  const artifacts = (await readJson(artifactsFile, { current_artifacts: [] })) || {};
  const reuse = (await readJson(reuseFile, {})) || {};
  const capability = (await readJson(capabilityFile, {})) || {};
  const synthesis = (await readJson(synthesisFile, {})) || {};
  const dailyTodayPath = path.join(workspace, 'memory', `${today}.md`);
  const dailyYesterdayPath = path.join(workspace, 'memory', `${yesterday}.md`);
  const dailyToday = await readText(dailyTodayPath, '');
  const dailyYesterday = await readText(dailyYesterdayPath, '');
  const activeMemory = await readText(activeMemoryFile, '');
  const durableMemory = await readText(durableMemoryFile, '');

  const highlights = [
    ...pickHighlights(dailyToday, 6),
    ...pickHighlights(dailyYesterday, 4)
  ].slice(0, 8);

  const activeBody = `
## Managed Active Context

- updated_at: ${nowIso}
- active_wedge: ${state.active_wedge?.id || 'unknown'}
- stage: ${state.active_wedge?.stage || state.stage || 'unknown'}
- planner_mode: ${state.planner_mode || 'unknown'}
- worker_mode: ${state.worker_mode || 'unknown'}
- current_lane: ${state.current_lane || capability.selected_skill_or_lane || 'unknown'}
- blocker_class: ${state.blocker_class || 'none'}
- next_action: ${state.next_action?.type || 'unknown'}
- proof_expected: ${state.next_action?.proof_expected || 'unknown'}
- reuse_recommendation: ${reuse.recommendation || 'none'}
- reuse_target: ${reuse.target_path || 'none'}
- last_artifact_change_at: ${state.last_artifact_change_at || 'unknown'}

## Active Memory Refs

- memory/${today}.md
- memory/${yesterday}.md
- state/session-state.json
- state/reuse-plan.json
- state/artifact-registry.json
- state/decision-registry.json
- state/synthesis-registry.json
- synthesis/CURRENT.md
- state/priority-queue.json

## Recent Real Work Highlights

${highlights.length ? highlights.map((line) => `- ${line.replace(/^- /, '')}`).join('\n') : '- No recent daily-memory highlights captured yet.'}
`;

  const durableDecisions = (decisions.decisions || []).slice(0, 6).map((item) => (
    `- ${item.id}: ${item.decision}${item.boundary ? ` Boundary: ${item.boundary}` : ''}`
  ));
  const durableArtifacts = (artifacts.current_artifacts || []).slice(0, 4).map((item) => (
    `- ${item.id}: ${item.status}${item.reuse_notes ? ` | ${item.reuse_notes}` : ''}`
  ));

  const durableBody = `
## Managed Durable Context

- updated_at: ${nowIso}
- memory_stack: daily -> MEMORY_ACTIVE -> MEMORY
- synthesis_surface: ${synthesis.current_doc || 'synthesis/CURRENT.md'}
- retrieval_priority: local memory first, then local registries, then shared spine for doctrine/handoffs only

## Active Durable Decisions

${durableDecisions.length ? durableDecisions.join('\n') : '- No durable decisions registered yet.'}

## Canonical Reusable Artifacts

${durableArtifacts.length ? durableArtifacts.join('\n') : '- No reusable artifacts registered yet.'}
`;

  await fs.writeFile(activeMemoryFile, replaceManagedBlock(activeMemory, ACTIVE_START, ACTIVE_END, activeBody));
  await fs.writeFile(durableMemoryFile, replaceManagedBlock(durableMemory, DURABLE_START, DURABLE_END, durableBody));
  console.log(`ROGER_MEMORY_COMPACT_OK ${await exists(dailyTodayPath) ? `memory/${today}.md` : 'no-daily'}`);
}

main().catch((error) => {
  console.error(error.stack || String(error));
  process.exit(1);
});
