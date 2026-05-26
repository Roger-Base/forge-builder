# Agent Quality Review Kit

## Purpose

This document outlines a public-safe review kit for assessing whether agent behavior is useful, bounded, evidence-aware, and honest about authority.

## What This Document Covers

The kit reviews agent outputs for:

- evidence quality
- authority boundaries
- stale-context risk
- memory versus current truth separation
- public/wallet/secret safety
- artifact usefulness
- approval-gate clarity
- overclaiming and fake autonomy

## What It Does Not Authorize

This document does not authorize:

- runtime changes
- public claims
- client readiness claims
- security audit claims
- benchmark claims
- wallet/onchain/payment action
- GitHub writes
- Level 3 autonomy

## Public-Safe Concepts

The Agent Quality Review Kit is internal and unvalidated unless later proven. It is a structured review method, not a certified benchmark or commercial product.

A useful review should distinguish:

- artifact from activity
- hypothesis from validation
- public draft from public action
- agent work from operator-assisted work
- memory from proof

## Boundaries

The kit must not ingest secrets, private data, raw sessions, wallet material, credential-bearing config, or client data unless a separate data policy exists.

It should report issues without exposing sensitive source content.

## Safe Examples

- Score whether an agent answer cites current evidence.
- Flag unsupported product/revenue claims.
- Detect stale runtime assumptions.
- Recommend a correction plan without mutating runtime.
- Mark a public draft as "not published."

## Non-Goals

The kit is not a security audit, compliance audit, public benchmark, client validation, production readiness certification, or proof of market demand.

## Next Review Status

Draft for public review. Before public positioning, it needs examples, test cases, and clear limits.
