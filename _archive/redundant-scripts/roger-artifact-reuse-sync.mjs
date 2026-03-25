#!/usr/bin/env node
import fs from 'fs/promises';
import path from 'path';

const workspace = process.env.OPENCLAW_WORKSPACE || path.join(process.env.HOME, '.openclaw', 'workspace');
const stateFile = path.join(workspace, 'state', 'session-state.json');
const registryFile = path.join(workspace, 'state', 'artifact-registry.json');
const outFile = path.join(workspace, 'state', 'reuse-plan.json');

const nowIso = new Date().toISOString().replace(/\.\d{3}Z$/, 'Z');
const preferredFiles = ['demo-output.md', 'proof-page.md', 'sample-audit.md', 'README.md', 'proof-spec.md', 'research-packet.md'];

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

function bundleMatches(bundle, wedge) {
  const id = normalize(bundle.id);
  const target = normalize(wedge);
  if (!target) return false;
  if (id.includes(target) || target.includes(id)) return true;
  return (bundle.paths || []).some((item) => normalize(item).includes(target));
}

function pickTargetPath(paths) {
  const ranked = [...paths].sort((a, b) => {
    const aIndex = preferredFiles.findIndex((name) => a.endsWith(name));
    const bIndex = preferredFiles.findIndex((name) => b.endsWith(name));
    const safeA = aIndex === -1 ? 999 : aIndex;
    const safeB = bIndex === -1 ? 999 : bIndex;
    return safeA - safeB;
  });
  return ranked[0] || null;
}

async function main() {
  const state = await readJson(stateFile, {});
  const registry = await readJson(registryFile, { current_artifacts: [] });
  const activeWedge = state.active_wedge?.id || '';
  const bundle = (registry.current_artifacts || []).find((item) => bundleMatches(item, activeWedge)) || null;
  const existingPaths = [];
  for (const rel of bundle?.paths || []) {
    if (await exists(path.join(workspace, rel))) existingPaths.push(rel);
  }
  const targetPath = pickTargetPath(existingPaths);
  const recommendation = bundle
    ? (normalize(state.blocker_class) === 'human-only'
        ? 'reuse_existing_bundle_while_blocked'
        : 'reuse_existing_bundle')
    : 'new_artifact_allowed';

  const note = bundle
    ? (bundle.reuse_notes || `Update ${bundle.id} before opening a replacement surface.`)
    : `No canonical bundle matched ${activeWedge}; new bounded artifact creation is allowed if it serves the current wedge.`;

  const output = {
    version: '1.0',
    agent: 'Roger',
    updated_at: nowIso,
    active_wedge: activeWedge,
    recommendation,
    blocker_class: state.blocker_class || 'none',
    bundle_id: bundle?.id || null,
    bundle_status: bundle?.status || null,
    note,
    target_path: targetPath,
    target_paths: existingPaths,
    preferred_action: bundle ? 'update_or_extend_existing' : 'bounded_new_delta',
    source_registry: 'state/artifact-registry.json'
  };

  await writeJson(outFile, output);
  console.log(`ROGER_ARTIFACT_REUSE_SYNC_OK ${recommendation} ${targetPath || 'no-target'}`);
}

main().catch((error) => {
  console.error(error.stack || String(error));
  process.exit(1);
});
