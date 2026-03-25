#!/usr/bin/env node

import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'fs';
import { fileURLToPath } from 'url';
import path from 'path';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const workspace = process.env.OPENCLAW_WORKSPACE || path.join(process.env.HOME || '', '.openclaw', 'workspace');
const stateFile = path.join(workspace, 'state', 'session-state.json');
const bestNextMoveFile = path.join(workspace, 'state', 'best-next-move.json');
const outFile = path.join(workspace, 'state', 'roger-self-audit.json');

function readJson(filePath, fallback = {}) {
  if (!existsSync(filePath)) return fallback;
  try {
    return JSON.parse(readFileSync(filePath, 'utf-8'));
  } catch {
    return fallback;
  }
}

const state = readJson(stateFile, {});
const bestNextMove = readJson(bestNextMoveFile, {});

const stage = state.active_wedge?.stage || 'unknown';
const activeWedge = state.active_wedge?.id || 'unknown';
const activeUrl = state.active_wedge?.url || '';
const nextAction = state.next_action || {};
const nextType = nextAction.type || 'unknown';
const nextCommand = nextAction.command || '';
const blockers = Array.isArray(state.blockers) ? state.blockers : [];
const winnerId = bestNextMove.winner?.id || '';
const winnerIntent = bestNextMove.winner?.intent || '';

const reasons = [];
const questions = [];

let credentialBlocker = false;
let humanActionRequired = false;
let blockerScope = 'none';
let selfReflectionNeeded = false;
let wedgeAlreadyShipped = false;
let recommendedNextMove = 'continue_current';

for (const blocker of blockers) {
  const text = [
    blocker?.id,
    blocker?.type,
    blocker?.description,
    blocker?.impact,
    blocker?.fix
  ]
    .filter(Boolean)
    .join(' ')
    .toLowerCase();

  if (
    blocker?.type === 'credential' ||
    text.includes('credential') ||
    text.includes('env var') ||
    text.includes('api key') ||
    text.includes('deployer_key') ||
    text.includes('key_missing')
  ) {
    credentialBlocker = true;
  }

  if (
    text.includes('human needed') ||
    text.includes('human required') ||
    text.includes('human input') ||
    text.includes('human action')
  ) {
    humanActionRequired = true;
  }
}

if (activeUrl && ['DEPLOYED', 'DISTRIBUTE'].includes(stage)) {
  wedgeAlreadyShipped = true;
}

if (credentialBlocker && wedgeAlreadyShipped) {
  blockerScope = 'partial_wedge';
  selfReflectionNeeded = true;
  recommendedNextMove = 'direction_review';
  reasons.push(
    'The active wedge is already shipped or deployed, so the missing credential is not a full-system blocker.'
  );
  questions.push('Is this credential gap blocking the whole wedge or only one optional deployment step?');
  questions.push('What unblocked work remains on this wedge before treating it as stuck?');
}

if (humanActionRequired && credentialBlocker) {
  selfReflectionNeeded = true;
  recommendedNextMove = 'direction_review';
  reasons.push(
    'The current blocker includes human-required credential work, which Roger should classify instead of repeatedly pushing against.'
  );
  questions.push('Should this be held for human action while Roger switches to an unblocked lane?');
}

if (['artifact_delta', 'build', 'credential'].includes(nextType) && (credentialBlocker || humanActionRequired)) {
  selfReflectionNeeded = true;
  reasons.push(
    'The current next action still points into build or credential pressure while blocker reality is unresolved.'
  );
  questions.push('Am I continuing build behavior because it feels productive, or because it truly unlocks the mission?');
}

if (winnerId === 'artifact_delta' && blockerScope === 'partial_wedge') {
  selfReflectionNeeded = true;
  recommendedNextMove = 'direction_review';
  reasons.push(
    'best-next-move is still favoring build even though the blocker only applies to a partial post-deploy step.'
  );
}

if (winnerIntent === 'build' && wedgeAlreadyShipped) {
  selfReflectionNeeded = true;
  reasons.push('The wedge is already shipped, so another build-first move needs explicit justification.');
  questions.push('Is more building the real need here, or is the real need judgment, verification, or routing?');
}

if (state.direction_review?.required === true) {
  recommendedNextMove = 'direction_review';
}

const verdict = selfReflectionNeeded
  ? 'Stop treating the current blocker as automatic build pressure. Re-classify the blocker, then route deliberately.'
  : 'No urgent self-audit correction detected from the current runtime state.';

const recommendedAction = selfReflectionNeeded
  ? 'Run a direction review or other bounded reality-check before further build pressure on the same wedge.'
  : 'Continue the current bounded thread.';

mkdirSync(path.dirname(outFile), { recursive: true });

const payload = {
  version: '1.0',
  updated_at: new Date().toISOString(),
  active_wedge: activeWedge,
  stage,
  wedge_already_shipped: wedgeAlreadyShipped,
  next_action_type: nextType,
  next_action_command: nextCommand,
  best_next_move_winner: winnerId || null,
  best_next_move_intent: winnerIntent || null,
  has_blockers: blockers.length > 0,
  credential_blocker: credentialBlocker,
  human_action_required: humanActionRequired,
  blocker_scope: blockerScope,
  self_reflection_needed: selfReflectionNeeded,
  recommended_next_move: recommendedNextMove,
  recommended_action: recommendedAction,
  verdict,
  reasons,
  questions
};

writeFileSync(outFile, `${JSON.stringify(payload, null, 2)}\n`);
console.log(`ROGER_SELF_AUDIT_OK ${outFile}`);
