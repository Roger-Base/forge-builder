# GitHub Surface Policy

## Purpose

This document defines public-safe rules for using an agent-owned GitHub repository as a workbench while preventing secret leaks, unsafe claims, and uncontrolled repository mutation.

## What This Document Covers

It covers repository planning, branch discipline, pull request defaults, path allowlists, secret scanning, rollback expectations, and public claim boundaries.

## What It Does Not Authorize

This document does not authorize:

- direct pushes to protected branches
- unreviewed pull requests
- issue creation without approval
- merges or releases
- repo settings changes
- publishing secrets, credentials, private data, raw sessions, wallet material, or unsupported public claims
- Level 3 autonomous GitHub action

## Public-Safe Concepts

GitHub access is not public claim authority.

Repo ownership does not allow unsafe commits. Every write should be scoped to exact paths, reviewed for secrets, and reversible.

History is quarry, not authority. Old content can preserve useful context, but it must be classified before reuse.

## Boundaries

Use exact path staging. Do not use broad staging for mixed worktrees.

Do not include secrets in commits, diffs, PR bodies, issue text, logs, screenshots, comments, release notes, or labels.

PR-only is the default for public repository changes unless a stricter gate applies.

## Safe Examples

- Prepare a docs-only branch with public-safe content.
- Open a draft PR with a clear file list and no authority activation.
- Use a redacted rollback note: close PR, revert commit, or delete branch after review.
- State that a document is policy scaffolding, not live autonomy.

## Non-Goals

This document is not a GitHub credential guide, repo secrets guide, deployment policy, CI secrets policy, release process, or autonomous merge policy.

## Next Review Status

Draft for public review. Before use, confirm repo ownership, branch policy, path scope, and secret-scan procedure.
