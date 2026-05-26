# Repo Continuity Model

## Purpose

This document describes a public-safe model for resuming work in a historical agent-owned repository without trusting old content blindly.

## What This Document Covers

It covers how to classify historical repository content before reuse:

- current truth
- historical continuity
- useful quarry
- stale/quarantine
- unknown/needs review
- forbidden/sensitive

## What It Does Not Authorize

This document does not authorize:

- deleting history
- broad cleanup
- reset, clean, or stash operations
- broad staging
- direct protected-branch pushes
- publishing private body files
- committing secrets, raw sessions, wallet material, credential-bearing config, or private data
- Level 3 autonomous repository maintenance

## Public-Safe Concepts

History is quarry, not authority.

A historical repo can be a restored working surface while still requiring classification before commit, cleanup, publication, or authority promotion.

Useful old work should be preserved until reviewed. Stale or unsafe material should be quarantined, not silently erased.

## Boundaries

Before committing historical content:

- classify the file
- confirm ownership
- check for sensitive content
- stage exact paths only
- prefer PR review
- define rollback
- avoid unsupported public claims

## Safe Examples

- Keep public docs that describe safe concepts.
- Convert internal policies into redacted public docs.
- Exclude private body files from public PRs.
- Document why old content is quarry rather than current truth.

## Non-Goals

This is not a cleanup authorization, migration script, deletion plan, private memory archive, or public release checklist.

## Next Review Status

Draft for public review. It should be paired with a concrete path allowlist before repository writes.
