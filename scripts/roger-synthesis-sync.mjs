#!/usr/bin/env node
import fs from 'fs/promises';
import path from 'path';

const workspace = process.env.OPENCLAW_WORKSPACE || path.join(process.env.HOME, '.openclaw', 'workspace');
const spine = path.join(process.env.HOME, '.openclaw', 'shared-spine');

const stateFile = path.join(workspace, 'state', 'session-state.json');
const bestFile = path.join(workspace, 'state', 'best-next-move.json');
const decisionsFile = path.join(workspace, 'state', 'decision-registry.json');
const artifactsFile = path.join(workspace, 'state', 'artifact-registry.json');
const registryFile = path.join(workspace, 'state', 'synthesis-registry.json');
const currentFile = path.join(workspace, 'synthesis', 'CURRENT.md');
const portfolioFile = path.join(spine, 'PORTFOLIO_LEDGER.json');

const START = '<!-- OPENCLAW_MANAGED_SYNTHESIS_START -->';
const END = '<!-- OPENCLAW_MANAGED_SYNTHESIS_END -->';
const nowIso = new Date().toISOString().replace(/\.\d{3}Z$/, 'Z');

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

async function ensureDir(dir) {
  await fs.mkdir(dir, { recursive: true });
}

function rel(file) {
  return path.relative(workspace, file).replace(/\\/g, '/');
}

function replaceManagedBlock(original, body) {
  const block = `${START}\n${body.trimEnd()}\n${END}`;
  if (original.includes(START) && original.includes(END)) {
    return original.replace(new RegExp(`${escapeRegExp(START)}[\\s\\S]*?${escapeRegExp(END)}`), block);
  }
  const header = original.trim().length
    ? original.trimEnd()
    : '# Roger Current Synthesis\n\nThis file is a living synthesis surface. The managed block is regenerated from live state, memory, decisions, and artifacts.\n';
  return `${header}\n\n${block}\n`;
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function asList(items, empty) {
  return items.length ? items.join('\n') : `- ${empty}`;
}

async function main() {
  const state = (await readJson(stateFile, {})) || {};
  const best = (await readJson(bestFile, {})) || {};
  const decisions = (await readJson(decisionsFile, { decisions: [] })) || { decisions: [] };
  const artifacts = (await readJson(artifactsFile, { current_artifacts: [] })) || { current_artifacts: [] };
  const portfolio = (await readJson(portfolioFile, {})) || {};
  const current = await readText(currentFile, '');

  const blockerLines = Array.isArray(state.blockers) && state.blockers.length
    ? state.blockers.map((item) => `- ${item.id || item.type || 'blocker'}${item.classification ? ` (${item.classification})` : ''}`)
    : ['- none'];

  const artifactLines = (artifacts.current_artifacts || []).slice(0, 6).map((item) => {
    const firstPath = (item.paths || [])[0] || 'no-path';
    return `- ${item.id}: ${item.status || 'unknown'} -> ${firstPath}`;
  });

  const decisionLines = (decisions.decisions || []).slice(0, 6).map((item) => {
    const boundary = item.boundary ? ` | boundary: ${item.boundary}` : '';
    return `- ${item.id}: ${item.decision}${boundary}`;
  });

  const candidateLines = (best.candidates || []).slice(0, 3).map((item) => (
    `- ${item.id}: ${item.why_this_move || item.selected_skill_or_lane || 'no rationale'}`
  ));

  const managedBody = `
## Managed Synthesis

- updated_at: ${nowIso}
- active_wedge: ${state.active_wedge?.id || 'unknown'}
- stage: ${state.active_wedge?.stage || state.stage || 'unknown'}
- shared_primary: ${portfolio.primary_id || portfolio.roger?.primary_wedge || 'unknown'}
- shared_reserve: ${portfolio.reserve_id || portfolio.roger?.reserve_wedge || 'unknown'}
- planner_mode: ${state.planner_mode || 'unknown'}
- worker_mode: ${state.worker_mode || 'unknown'}
- current_lane: ${state.current_lane || 'unknown'}
- blocker_class: ${state.blocker_class || 'none'}

## Current Thesis

- Roger's current product/proof lane is \`${state.active_wedge?.id || 'unknown'}\`.
- The strongest immediate move is \`${best.winner?.id || state.next_action?.type || 'unknown'}\` on \`${best.winner?.selected_skill_or_lane || state.current_lane || 'unknown'}\`.
- Reuse before replacement remains the live rule: update the strongest existing proof surface before opening a new wedge surface.

## What Is Actually True Now

- next_action: ${state.next_action?.type || 'unknown'}
- proof_expected: ${state.next_action?.proof_expected || 'unknown'}
- reuse_target: ${best.winner?.target || state.next_action?.target || 'none'}
- winner_margin: ${best.winner_margin ?? 'unknown'}

## Blockers

${blockerLines.join('\n')}

## Canonical Reusable Surfaces

${asList(artifactLines, 'No reusable surfaces registered yet.')}

## Durable Decisions

${asList(decisionLines, 'No promoted decisions registered yet.')}

## Near-Term Routing

${asList(candidateLines, 'No candidate ranking available.')}
`;

  const registry = {
    version: '1.0',
    agent: 'Roger',
    updated_at: nowIso,
    current_doc: rel(currentFile),
    active_wedge: state.active_wedge?.id || 'unknown',
    stage: state.active_wedge?.stage || state.stage || 'unknown',
    planner_mode: state.planner_mode || 'unknown',
    current_lane: state.current_lane || 'unknown',
    blocker_class: state.blocker_class || 'none',
    shared_primary: portfolio.primary_id || portfolio.roger?.primary_wedge || 'unknown',
    shared_reserve: portfolio.reserve_id || portfolio.roger?.reserve_wedge || 'unknown',
    supporting_artifacts: (artifacts.current_artifacts || []).slice(0, 8).flatMap((item) => item.paths || []).slice(0, 8),
    decision_refs: (decisions.decisions || []).slice(0, 8).map((item) => item.id),
    next_action_type: state.next_action?.type || 'unknown',
    proof_expected: state.next_action?.proof_expected || 'unknown'
  };

  await ensureDir(path.dirname(currentFile));
  await fs.writeFile(currentFile, replaceManagedBlock(current, managedBody));
  await fs.writeFile(registryFile, `${JSON.stringify(registry, null, 2)}\n`);
  console.log(`ROGER_SYNTHESIS_SYNC_OK ${rel(currentFile)}`);
}

main().catch((error) => {
  console.error(error.stack || String(error));
  process.exit(1);
});
