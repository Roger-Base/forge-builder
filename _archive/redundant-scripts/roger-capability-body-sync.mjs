#!/usr/bin/env node
import fs from 'fs/promises';
import path from 'path';

const workspace = process.env.OPENCLAW_WORKSPACE || path.join(process.env.HOME, '.openclaw', 'workspace');
const outFile = path.join(workspace, 'state', 'capability-body.json');
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
  const body = {
    version: '1.0',
    agent: 'Roger',
    updated_at: nowIso,
    authority: 'local_openclaw_capability_body',
    posture: {
      kernel: 'OpenClaw',
      rule: 'ETHSkills first, then choose the smallest correct Base lane.',
      never_flatten: 'Do not collapse market execution, exact contract execution, verification, identity, and commerce into one generic tool.'
    },
    identities: {
      bankr_roger: {
        config_path: '~/.bankr/config.json',
        evm_wallet: '0x984d6741e2c6559b1e655b6dbb3a38662fe2c123',
        sol_wallet: 'AeyePdw7yk3QdfJP3EzNpyy4EF5hgtxkcxPCMKHAYp2y',
        status: 'verified_2026-03-21'
      },
      bankr_walter_peer: {
        config_path: '~/.bankr-walter/config.json',
        evm_wallet: '0x13d4389aa99ec76b0599606ebef7f0947ce70445',
        sol_wallet: 'DxbzJ4acMAqMXFDSf49ZAfFh7kHBn1Psz5cPbNJdh7kj',
        status: 'verified_2026-03-21',
        boundary: 'Walter is a distinct actor, not Roger under another config.'
      }
    },
    domain_spine: {
      id: 'ethskills',
      path: 'skills/ethskills/SKILL.md',
      role: 'first_question_before_build',
      proof_rule: 'Clarify problem, inspect local artifacts, verify patterns, choose smallest lane, define proof surface.'
    },
    lane_registry: [
      {
        id: 'public_product_surface',
        capability: 'public_builder_execution',
        path: 'services/erc8004-agent-lookup',
        local_surfaces: ['services/erc8004-agent-lookup/', 'docs/wedges/agent-trust-discovery/demo-output.md'],
        use_for: ['service_refresh', 'product_proof', 'public_lookup_surfaces', 'canonical_demo_update'],
        avoid_for: ['wallet_execution', 'broad_market_analysis']
      },
      {
        id: 'proof_distribution',
        capability: 'proof_distribution',
        path: 'scripts/github-proof-surface-check.sh',
        local_surfaces: ['scripts/github-proof-surface-check.sh', 'docs/wedges/agent-trust-discovery/proof-page.md'],
        use_for: ['proof_surface_sync', 'github_visibility', 'distribution_checks'],
        avoid_for: ['pretending_visibility_is_execution']
      },
      {
        id: 'market_execution',
        capability: 'bankr_market_execution',
        path: 'skills/bankr/SKILL.md',
        local_surfaces: ['skills/bankr/SKILL.md'],
        use_for: ['balances', 'portfolio_views', 'swaps', 'transfers', 'token_launch', 'high_level_wallet_actions'],
        avoid_for: ['exact_aave_calls', 'morpho_contract_interaction', 'precise_low_level_protocol_execution'],
        identity: 'bankr_roger'
      },
      {
        id: 'protocol_execution',
        capability: 'evm_protocol_execution',
        path: 'skills/evm-wallet/SKILL.md',
        local_surfaces: ['skills/evm-wallet/SKILL.md', 'skills/evm-wallet/src/contract.js'],
        use_for: ['exact_contract_interaction', 'approvals', 'reads', 'writes', 'aave', 'morpho', 'base_contract_calls'],
        avoid_for: ['broad_market_prompting', 'portfolio_chat'],
        identity: 'self_sovereign_wallet'
      },
      {
        id: 'verification_monitoring',
        capability: 'onchain_verification',
        path: 'skills/onchain/SKILL.md',
        local_surfaces: ['skills/onchain/SKILL.md', 'skills/agent-evaluation/SKILL.md'],
        use_for: ['balances', 'tx_lookup', 'portfolio_checks', 'gas', 'market_state', 'behavior_eval'],
        avoid_for: ['state_mutation', 'wallet_writes_without_confirmed_lane']
      },
      {
        id: 'identity_distribution',
        capability: 'base_identity_distribution',
        path: 'skills/basename-agent/SKILL.md',
        local_surfaces: ['skills/basename-agent/SKILL.md', 'skills/basemail/SKILL.md'],
        use_for: ['basename', 'basemail', 'agent_identity', 'distribution_surfaces'],
        avoid_for: ['unverified_claims_without_identity_need']
      },
      {
        id: 'commerce_rails',
        capability: 'x402_commerce',
        path: 'skills/crypto-agent-payments/SKILL.md',
        local_surfaces: ['skills/crypto-agent-payments/SKILL.md', 'code/x402-agent-starter'],
        use_for: ['agent_payments', 'payment_rails', 'commerce_prototypes', 'mcp_payment_connectors'],
        avoid_for: ['treating_payments_as_identity_or_contract_execution']
      },
      {
        id: 'connector_surface',
        capability: 'mcp_connector_execution',
        path: 'skills/mcporter/SKILL.md',
        local_surfaces: ['skills/mcporter/SKILL.md', 'config/mcporter.json', 'code/base-mcp-server'],
        use_for: ['mcp_tools', 'github_mcp', 'filesystem_mcp', 'base_gas_mcp', 'connector_transport'],
        avoid_for: ['pretending_connector_transport_is_domain_strategy']
      }
    ],
    routing_rules: [
      {
        problem_class: 'public_service_or_proof_surface',
        lane_id: 'public_product_surface',
        first_surface: 'services/erc8004-agent-lookup/'
      },
      {
        problem_class: 'high_level_market_or_wallet_action',
        lane_id: 'market_execution',
        first_surface: 'skills/bankr/SKILL.md'
      },
      {
        problem_class: 'exact_contract_interaction',
        lane_id: 'protocol_execution',
        first_surface: 'skills/evm-wallet/SKILL.md'
      },
      {
        problem_class: 'state_verification_or_monitoring',
        lane_id: 'verification_monitoring',
        first_surface: 'skills/onchain/SKILL.md'
      },
      {
        problem_class: 'identity_or_distribution',
        lane_id: 'identity_distribution',
        first_surface: 'skills/basename-agent/SKILL.md'
      },
      {
        problem_class: 'agent_commerce_or_payment_rail',
        lane_id: 'commerce_rails',
        first_surface: 'skills/crypto-agent-payments/SKILL.md'
      },
      {
        problem_class: 'external_tool_or_mcp_connector',
        lane_id: 'connector_surface',
        first_surface: 'skills/mcporter/SKILL.md'
      }
    ],
    wedge_bindings: [
      {
        wedge_id: 'agent-trust-discovery',
        intent_defaults: {
          build: 'public_product_surface',
          verify: 'proof_distribution',
          audit: 'verification_monitoring',
          default: 'public_product_surface'
        }
      },
      {
        wedge_id: 'agent_security_scanner',
        intent_defaults: {
          build: 'verification_monitoring',
          verify: 'verification_monitoring',
          audit: 'verification_monitoring',
          distribute: 'proof_distribution',
          default: 'verification_monitoring'
        }
      },
      {
        wedge_id: 'defai-yield-agent',
        intent_defaults: {
          build: 'protocol_execution',
          verify: 'verification_monitoring',
          search: 'market_execution',
          distribute: 'proof_distribution',
          default: 'protocol_execution'
        }
      },
      {
        wedge_id: 'base_account_miniapp_probe',
        intent_defaults: {
          build: 'connector_surface',
          verify: 'verification_monitoring',
          distribute: 'proof_distribution',
          default: 'connector_surface'
        }
      },
      {
        wedge_id: 'erc8004-agent-lookup-service',
        intent_defaults: {
          build: 'public_product_surface',
          verify: 'proof_distribution',
          default: 'public_product_surface'
        }
      }
    ],
    intent_defaults: {
      build: 'public_product_surface',
      verify: 'verification_monitoring',
      audit: 'verification_monitoring',
      distribute: 'proof_distribution',
      search: 'market_execution',
      default: 'public_product_surface'
    },
    local_code_surfaces: [
      'services/erc8004-agent-lookup/',
      'code/base-mcp-server',
      'code/x402-agent-starter'
    ],
    required_sources_before_build: [
      'skills/ethskills/SKILL.md',
      'state/capability-body.json',
      'state/planner-doctrine.json',
      'state/priority-queue.json',
      'state/artifact-registry.json',
      'state/decision-registry.json',
      'state/synthesis-registry.json',
      'config/mcporter.json'
    ]
  };

  await writeJson(outFile, body);
  console.log(`ROGER_CAPABILITY_BODY_SYNC_OK ${outFile}`);
}

main().catch((error) => {
  console.error(error.stack || String(error));
  process.exit(1);
});
