# Agent-Owned Surface Policy

## Purpose

This document defines public-safe principles for treating agent-owned surfaces as work surfaces without turning custody into unrestricted authority.

## What This Document Covers

It covers surface classes used by autonomous or semi-autonomous agent systems:

- agent-owned local surfaces
- agent-owned account surfaces
- agent-owned credential surfaces
- agent-owned wallet/signing surfaces
- user-private surfaces
- shared/system-critical surfaces
- external/client surfaces
- public-disclosure surfaces

## What It Does Not Authorize

This document does not authorize:

- public posting
- GitHub writes
- credential disclosure
- wallet signing, payment, or trading
- runtime or infrastructure mutation
- destructive cleanup
- access to private user, client, or third-party systems
- Level 3 autonomous execution

## Public-Safe Concepts

Agent-owned surfaces are not default blockers. They can be legitimate work surfaces when ownership, scope, limits, logging, recovery, and stop conditions are clear.

Custody is not disclosure. A system may hold or route credentials without exposing their values in reports, logs, pull requests, prompts, screenshots, or public artifacts.

Wallet custody is not signing authority. A signer or wallet surface can be documented, simulated, and governed without allowing transaction execution.

## Boundaries

Sensitive values must not be copied into public docs, logs, commits, issues, pull requests, chats, or screenshots.

External/client surfaces require explicit scope and data-handling rules before any use.

Shared/system-critical surfaces require review, backup, rollback, and verification before mutation.

## Safe Examples

- Classify a repo as agent-owned before planning work.
- Draft a redacted credential-use policy without key values.
- Create a wallet/signing policy skeleton without addresses, seed phrases, private keys, transaction payloads, or balances.
- Write a public explanation of custody versus disclosure.

## Non-Goals

This policy is not a credential store, wallet policy, runtime runbook, permission grant, public claim policy, or incident log.

## Next Review Status

Draft for public review. It should be reviewed for overbroad authority language before adoption.
