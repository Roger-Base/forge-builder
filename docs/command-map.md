> LEGACY REFERENCE ONLY
>
> This file is preserved as historical/context material. It is not canonical in the v4 system.
> Use the active surface, core canon files, and `/Users/roger/.openclaw/shared-spine` first.

# Roger Command Map v3.1

Updated: 2026-03-08

Use this map to choose the smallest proof-producing command.

## Help First

Before unfamiliar commands or flags:
```bash
which <tool>
<tool> --help
```

For Roger's own scripts:
```bash
bash scripts/base-mission-loop.sh --help
bash scripts/base-mission-loop.sh --agent-help
bash scripts/agent-security-scanner.sh --help
bash scripts/agent-security-scanner.sh --agent-help
bash scripts/spawn-controller.sh --help
bash scripts/run-evaluator.sh --help
```

If command choice is still unclear, read:
- `docs/cli-taxonomy.md`
- `skills/cli-operator/SKILL.md`

## Session Start

```bash
cd ~/.openclaw/workspace && bash scripts/session-start-60s.sh
cd ~/.openclaw/workspace && bash scripts/runtime-enforcer.sh
cd ~/.openclaw/workspace && bash scripts/portfolio-tribunal.sh --validate
cd ~/.openclaw/workspace && bash scripts/stage-transition-guard.sh
```

## Runtime Health

```bash
openclaw status
openclaw config validate
bash scripts/kernel-audit.sh --quick
bash scripts/state-guard.sh --validate state/session-state.json
jq '{portfolio,active_wedge,next_action,decision_card,critic,subagent_policy,run_fitness}' state/session-state.json
```

## OpenClaw 2026.3.8 Update Commands

```bash
openclaw --version
openclaw backup create --only-config --verify --json
openclaw backup verify <archive.tar.gz> --json
openclaw acp --provenance meta
```

Use these lanes to prove update/backup/provenance after upgrades.

## Retrieval First

```bash
rg -n "<topic>" .
qmd search "<topic>" -c runtime
qmd search "<topic>" -c kernel
qmd search "<topic>" -c roger
```

## Portfolio and Wedge State

```bash
jq '{primary_id,reserve_id,projects}' state/project-ledger.json
jq '{selected_opportunity,active_wedge,reserve_wedge,maintenance_wedges}' state/base-opportunity-queue.json
bash scripts/base-mission-loop.sh --update-state
```

## Primary Wedge Build

```bash
bash scripts/agent-security-scanner.sh --sample --output docs/wedges/agent_security_scanner/sample-audit.md
```

## Controlled Delegation

```bash
bash scripts/spawn-controller.sh --role scout --why "packet evidence gap" --question "Collect only wedge-specific evidence"
bash scripts/spawn-controller.sh --role verifier --why "proof gap" --question "Verify proof paths and readiness"
bash scripts/spawn-controller.sh --role builder-spike --why "isolated delta" --question "Build one small artifact delta"
```

Inspect ledger:
```bash
jq '{max_parallel,allowed_roles,runs}' state/subagent-ledger.json
```

Close a run:
```bash
bash scripts/spawn-controller.sh --mark <entry-id> --status merged --merge-status accepted --deliverable <path>
```

## Run Fitness

```bash
bash scripts/run-evaluator.sh --lane primary-build --artifact docs/wedges/agent_security_scanner/sample-audit.md --update-state
bash scripts/run-evaluator.sh --lane verify-proof --proof https://example.com/proof --update-state
```

## Benchmarking

```bash
bash scripts/molty-benchmark-loop.sh --op base_gas_tracker_v2 --emit-brief
```

Use only when proof already exists and stage justifies differentiation.

## Proof Refresh

```bash
bash scripts/base-mission-loop.sh --refresh-proof --op base_gas_tracker_v2
```

## X / GitHub Lanes

```bash
bash skills/github-x-control/scripts/platform_preflight.sh
gh auth status
openclaw browser tabs --json
openclaw browser snapshot --interactive --labels
```

## Publish Gate

```bash
bash scripts/post-gate.sh <draft-file>
```
