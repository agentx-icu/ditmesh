# ditmesh 1.2.0+4 release candidate

Date: 2026-11-25 (Asia/Shanghai).

## Changes

Progression from a real self-practice message to an existing friend or QR contact, first-round-trip guidance, a local human-timing website demo, and all mainline fixes since v1.1.0.

Every release now publishes `release-manifest.json` with exact asset URLs, sizes, SHA-256 values and explicit unverified/unsigned signing status. The companion site can prepare a synchronization PR automatically and retains a static fallback.

## Candidate qualification

This note records candidate scope, not completed distribution approval. Record the final commit, workflow URL, final asset hashes, signer and install/upgrade results before promoting a stable release. Do not replace packages belonging to a published version.

- Local focused checks: see the activation verification note in this repository.
- CI on final candidate: pending.
- Previous-version installation and data continuity: pending final matching artifacts.
- Connected Android/iOS hardware and Bluetooth route testing: unavailable at task start; no phones were connected.
- Authorized production signing/channel: not selected for this candidate. Existing developer or ad-hoc signatures do not establish production distribution.
- Participant observation: use the supplied local observation scripts/templates; no recruitment or user outcomes are claimed.

## Promotion

After final CI succeeds, create tag `v1.2.0` at the reviewed commit. Existing build workflows produce and verify installable packages (MorseCQ and DitMesh create drafts). Publish only after channel/signing and upgrade evidence are complete. Publish or refresh the release manifest after release publication, then synchronize the site and regenerate its language pages. Its stable download links must continue to describe the actual published version until promotion.
