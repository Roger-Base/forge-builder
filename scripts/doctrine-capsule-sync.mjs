#!/usr/bin/env node

import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'fs';
import path from 'path';

function parseArgs(argv) {
  const args = {};
  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    if (!token.startsWith('--')) continue;
    const key = token.slice(2);
    const value = argv[i + 1] && !argv[i + 1].startsWith('--') ? argv[++i] : 'true';
    args[key] = value;
  }
  return args;
}

function readJson(filePath, fallback = {}) {
  if (!existsSync(filePath)) return fallback;
  try {
    return JSON.parse(readFileSync(filePath, 'utf-8'));
  } catch {
    return fallback;
  }
}

function writeJson(filePath, payload) {
  mkdirSync(path.dirname(filePath), { recursive: true });
  writeFileSync(filePath, `${JSON.stringify(payload, null, 2)}\n`);
}

function unique(list) {
  return [...new Set((list || []).filter(Boolean))];
}

function upsertLedgerEntry(ledgerFile, entry) {
  const ledger = readJson(ledgerFile, {
    version: '1.0',
    agent: entry.agent,
    updated_at: new Date().toISOString(),
    editable_surfaces: {
      agent_can_edit: [
        'HEARTBEAT.md',
        'AGENTS.md:Doctrine Promotion Zone',
        'state/doctrine-ledger.json'
      ],
      human_only: [
        'MISSION.md',
        'IDENTITY.md',
        'SOUL.md',
        '/Users/roger/.openclaw/shared-spine/MOLTY_CONSTITUTION.md'
      ]
    },
    active_entries: []
  });

  const nextEntry = { ...entry };
  const existingIndex = (ledger.active_entries || []).findIndex((item) => item.id === entry.id);
  if (existingIndex >= 0) {
    const existing = ledger.active_entries[existingIndex];
    ledger.active_entries[existingIndex] = {
      ...existing,
      ...nextEntry,
      source_capsules: unique([...(existing.source_capsules || []), ...(nextEntry.source_capsules || [])])
    };
  } else {
    ledger.active_entries = [...(ledger.active_entries || []), nextEntry];
  }

  ledger.updated_at = new Date().toISOString();
  writeJson(ledgerFile, ledger);
}

function syncRoger(workspace, sharedSpine) {
  const stateDir = path.join(workspace, 'state');
  const auditFile = path.join(stateDir, 'roger-self-audit.json');
  const improvementFile = path.join(stateDir, 'roger-self-improvement.json');
  const sessionStateFile = path.join(stateDir, 'session-state.json');
  const ledgerFile = path.join(stateDir, 'doctrine-ledger.json');
  const audit = readJson(auditFile, {});
  const improvement = readJson(improvementFile, {});
  const sessionState = readJson(sessionStateFile, {});

  if (!audit.updated_at) {
    console.log('NO_CAPSULE Roger audit_missing');
    return null;
  }

  const stamp = String(audit.updated_at || new Date().toISOString()).slice(0, 10);
  const capsuleFile = path.join(sharedSpine, 'improvement-capsules', 'roger', `${stamp}-blocker-reclassification.json`);
  const activeWedge = sessionState.active_wedge?.id || improvement.active_wedge || audit.active_wedge || 'unknown';
  const stage = sessionState.active_wedge?.stage || improvement.stage || audit.stage || 'unknown';
  const tier = audit.self_reflection_needed ? 'benchmark_evidence' : 'exploratory_frontier';
  const claim = audit.self_reflection_needed
    ? 'Classify blockers before pushing the same build step. Partial or human-only blockers should trigger rerouting or bounded search instead of blind build pressure.'
    : 'Keep the current routing only while blocker classification still matches reality.';

  const evidence = unique([
    audit.verdict ? `${path.relative(workspace, auditFile)}: ${audit.verdict}` : null,
    improvement.issue ? `${path.relative(workspace, improvementFile)}: ${improvement.issue}` : null,
    sessionState.next_action?.type
      ? `${path.relative(workspace, sessionStateFile)}: next_action=${sessionState.next_action.type} on ${activeWedge}@${stage}`
      : null
  ]);

  const payload = {
    id: `roger-${stamp}-blocker-reclassification`,
    agent: 'Roger',
    created_at: audit.updated_at,
    claim,
    tier,
    status: tier === 'benchmark_evidence' ? 'accepted_local' : 'proposed',
    benchmark_note: audit.self_reflection_needed
      ? 'Live self-audit and routing logic agree that blocker classification must happen before more build pressure.'
      : 'Routing remains provisional until repeated use confirms the rule.',
    evidence,
    boundary_conditions: unique([
      audit.blocker_scope === 'partial_wedge'
        ? 'Applies when a wedge is already shipped and the remaining blocker is only partial.'
        : null,
      audit.human_action_required
        ? 'Applies when the remaining blocker is human-scoped or credential-scoped.'
        : null,
      'Does not treat credentials as irrelevant; it treats them as scoped reality rather than universal stop signs.'
    ]),
    affected_files: [
      'HEARTBEAT.md',
      'AGENTS.md',
      'state/doctrine-ledger.json',
      'state/session-state.json'
    ],
    proposed_edits: [
      'Classify blockers before resuming next_action.',
      'Route to direction_review or bounded LEARN/search/verify when the blocker is partial or human-only.',
      'Keep the control path aligned with actual wedge state.'
    ],
    rollback: 'If repeated runs show that this doctrine hides real blockers or suppresses necessary execution, demote it and restore the earlier routing.',
    source_artifacts: [auditFile, improvementFile, sessionStateFile].filter(existsSync)
  };

  writeJson(capsuleFile, payload);

  upsertLedgerEntry(ledgerFile, {
    id: 'roger-blocker-reclassification',
    tier: tier === 'benchmark_evidence' ? 'benchmark_evidence' : 'exploratory_frontier',
    rule: 'Classify blockers before resuming next_action. Partial or human-only blockers must not automatically become more build pressure.',
    boundary: 'Applies when a wedge is already shipped or the remaining blocker is only credential/human scoped.',
    source_capsules: [capsuleFile],
    status: 'active',
    agent: 'Roger'
  });

  upsertLedgerEntry(ledgerFile, {
    id: 'roger-search-mode-on-stall',
    tier: audit.self_reflection_needed ? 'benchmark_evidence' : 'exploratory_frontier',
    rule: 'If Roger is blocked but still has agency, enter bounded LEARN/search/verify mode on the same wedge before switching away.',
    boundary: 'Applies when the blockage is not truly terminal and local research may unlock the next move.',
    source_capsules: [capsuleFile],
    status: 'active',
    agent: 'Roger'
  });

  console.log(`CAPSULE_SYNC_OK ${capsuleFile}`);
  return capsuleFile;
}

function syncWalter(workspace, sharedSpine) {
  const stateDir = path.join(workspace, 'state');
  const evalFile = path.join(stateDir, 'walter-self-evaluation.json');
  const sessionStateFile = path.join(stateDir, 'session-state.json');
  const ledgerFile = path.join(stateDir, 'doctrine-ledger.json');
  const evaluation = readJson(evalFile, {});
  const sessionState = readJson(sessionStateFile, {});

  if (!evaluation.version) {
    console.log('NO_CAPSULE Walter evaluation_missing');
    return null;
  }

  const createdAt = evaluation.timestamp || evaluation.created_at || new Date().toISOString();
  const stamp = String(createdAt).slice(0, 10);
  const capsuleFile = path.join(sharedSpine, 'improvement-capsules', 'walter', `${stamp}-work-before-meta.json`);
  const missionStatus = evaluation.learning_mission_this_cycle?.mission_execution_status || 'unknown';
  const completed = missionStatus === 'completed';
  const tier = completed ? 'benchmark_evidence' : 'exploratory_frontier';

  const payload = {
    id: `walter-${stamp}-work-before-meta`,
    agent: 'Walter',
    created_at: createdAt,
    claim: 'When self-improvement detects infrastructure theater, Walter should complete one bounded work output from an existing queue before building more tooling or frameworks.',
    tier,
    status: completed ? 'accepted_local' : 'proposed',
    benchmark_note: completed
      ? 'Walter recorded a completed bounded work cycle with tangible output and no new scripts built.'
      : 'Walter identified the pattern, but repeated completed work cycles are still needed before promotion.',
    evidence: unique([
      evaluation.thisCycleWeakness ? `${path.relative(workspace, evalFile)}: ${evaluation.thisCycleWeakness}` : null,
      evaluation.fix ? `${path.relative(workspace, evalFile)}: ${evaluation.fix}` : null,
      evaluation.learning_mission_this_cycle?.last_cycle_update
        ? `${path.relative(workspace, evalFile)}: ${evaluation.learning_mission_this_cycle.last_cycle_update}`
        : null,
      sessionState.verdict ? `${path.relative(workspace, sessionStateFile)}: verdict=${sessionState.verdict}` : null
    ]),
    boundary_conditions: [
      'Applies to self-improvement, research, and architecture cycles where Walter is tempted to build more infrastructure instead of producing output.',
      'Does not ban bounded implementation; it blocks unnecessary new mechanisms that replace real work.',
      'If the current task truly requires a new mechanism, Walter should state the dependency and keep the build bounded.'
    ],
    affected_files: [
      'HEARTBEAT.md',
      'AGENTS.md',
      'state/doctrine-ledger.json'
    ],
    proposed_edits: [
      'If infrastructure theater is detected, complete one bounded queue task before new tooling.',
      'Prefer research, distillation, and output over new meta-frameworks.',
      'Keep self-improvement tied to evidence of real work.'
    ],
    rollback: 'If later evidence shows the rule blocks necessary bounded implementation, demote it and narrow the boundary to pure meta-sprawl cases.',
    source_artifacts: [evalFile, sessionStateFile].filter(existsSync)
  };

  writeJson(capsuleFile, payload);

  upsertLedgerEntry(ledgerFile, {
    id: 'walter-work-before-tooling',
    tier,
    rule: 'When Walter detects infrastructure theater, finish one bounded work output from an existing queue before building more tooling.',
    boundary: 'Applies to self-improvement, research, and architecture cycles where new meta-systems would displace real output.',
    source_capsules: [capsuleFile],
    status: 'active',
    agent: 'Walter'
  });

  upsertLedgerEntry(ledgerFile, {
    id: 'walter-no-meta-sprawl-on-block',
    tier,
    rule: 'When blocked, search deeper or distill harder before inventing a new framework.',
    boundary: 'Applies to structural uncertainty and self-improvement work.',
    source_capsules: [capsuleFile],
    status: 'active',
    agent: 'Walter'
  });

  console.log(`CAPSULE_SYNC_OK ${capsuleFile}`);
  return capsuleFile;
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  const agent = args.agent;
  const workspace = args.workspace || (agent === 'Walter'
    ? path.join(process.env.HOME || '/Users/roger', '.openclaw', 'workspace-walter')
    : path.join(process.env.HOME || '/Users/roger', '.openclaw', 'workspace'));

  if (!agent || !['Roger', 'Walter'].includes(agent)) {
    console.error('Usage: doctrine-capsule-sync.mjs --agent Roger|Walter [--workspace /abs/path]');
    process.exit(1);
  }

  const sharedSpine = path.join(process.env.HOME || '/Users/roger', '.openclaw', 'shared-spine');
  mkdirSync(path.join(sharedSpine, 'improvement-capsules', agent.toLowerCase()), { recursive: true });

  if (agent === 'Roger') {
    syncRoger(workspace, sharedSpine);
    return;
  }

  syncWalter(workspace, sharedSpine);
}

main();
