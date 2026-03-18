# CLI Taxonomy

This file captures the canonical command choices Roger should prefer before guessing.

## Intent: inspect unknown command
- canonical_command: `<command> --help`
- why_this_is_canonical: discover flags and subcommands before guessing
- proof_pattern: help text or explicit unsupported-flag error disappears
- fallback: `man <command>` or official docs
- anti_pattern: guessing flags from memory
- danger_level: low

## Intent: search code or text fast
- canonical_command: `rg <pattern> <path>`
- why_this_is_canonical: recursive, fast, script-friendly
- proof_pattern: matching lines and file paths
- fallback: `grep -R`
- anti_pattern: slow manual browsing through files
- danger_level: low

## Intent: inspect JSON state
- canonical_command: `jq . <file>` or `jq '<filter>' <file>`
- why_this_is_canonical: deterministic parsing of runtime files
- proof_pattern: valid JSON output and exact field extraction
- fallback: `python -m json.tool`
- anti_pattern: reading JSON as prose and guessing
- danger_level: low

## Intent: verify a URL or proof surface
- canonical_command: `curl -I <url>`
- why_this_is_canonical: cheap, direct reachability check
- proof_pattern: HTTP status and headers
- fallback: browser snapshot when HTTP alone is insufficient
- anti_pattern: assuming a link works because it looks plausible
- danger_level: low

## Intent: inspect repo and remote state
- canonical_command: `gh`, `git`, `rg`
- why_this_is_canonical: keeps repo and GitHub investigation scriptable
- proof_pattern: auth status, repo metadata, file diffs, issue/pr details
- fallback: browser if the CLI lane lacks a needed surface
- anti_pattern: using the browser as the first move for structured repo inspection
- danger_level: medium

## Intent: inspect OpenClaw runtime
- canonical_command: `openclaw`, `jq`, `qmd`
- why_this_is_canonical: these are the first-party surfaces for config, runtime, and indexed memory
- proof_pattern: config validation, status output, indexed search results
- fallback: read canon files directly
- anti_pattern: inventing OpenClaw behavior from stale memory
- danger_level: medium

## Intent: decide whether a GUI prompt is a real blocker
- canonical_command: read `OPERATIONS.md`, then inspect browser state or local auth status
- why_this_is_canonical: separates real human gates from normal agent-operable surfaces
- proof_pattern: explicit reason why the lane is blocked or recoverable
- fallback: Walter handoff or focused verifier run
- anti_pattern: assuming every visible login or chooser means `human_required`
- danger_level: high
