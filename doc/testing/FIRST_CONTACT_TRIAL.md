# First contact trial: three pairs

[简体中文](FIRST_CONTACT_TRIAL.zh-CN.md)

Purpose: observe whether two people can reach each other and complete an actual CQ/reply exchange. This document is a task script, not evidence that a trial has happened.

Recruit three pairs of people who already know each other. Ask for consent before observing. Use pair codes P01–P03 and device codes A/B, not names, Tox IDs, phone numbers or personal chat. Each person controls their own identity and backup. Do not collect key files, passwords, microphone recordings or unredacted production logs. Participation and local observation export are optional; the app and site add no analytics.

## First session (about 15 minutes)

1. Record the app version/build, artifact SHA-256, platform, install/update source and network category for each device. Use actual installed bytes; distinguish development, owner-signed and store delivery.
2. Without coaching, ask each person to create or import their own identity and make a backup. Stop the task on unexpected identity/data replacement.
3. Ask A to key CQ in note-to-self, preview, send and play it. Ask: “Who received that message?” Expected answer: only this device.
4. Ask A to contact B using the next-contact action and existing Tox ID/QR flow. B explicitly accepts. Observe whether they can recognize online/offline states.
5. A keys CQ to B. Record send time and the first observed queued/sent/delivered states. B plays it and keys R. A plays R. Only this real return message completes the round trip. Record any help or abandoned step.
6. Both compare original rhythm and their own speed. If original timing is unavailable, record the visible fallback; do not mark a synthesized replay as the sender's actual timing.
7. Ask each person to explain queued, sent and delivered. A group receipt means at least one member received; no receipt proves everyone listened.

## Network and lifecycle follow-up

Use the same consenting pair and nonsensitive CQ/R messages. Keep identity backups outside the app before upgrade tests.

| Scenario | Observe |
| --- | --- |
| Different Wi-Fi networks; then Wi-Fi versus cellular | Actual peer connection, time to real receipt and reply. Local loopback is separate evidence. |
| B loses connectivity, then reconnects | A's shown state, preserved pending item, receipt after recovery, duplicate bubbles/replies. An unconfirmed sent state is not success. |
| One phone locks or app backgrounds, then returns | Whether receiving stops, whether the UI explains it, and whether an explicit return/retry recovers. No push service or background guarantee is assumed. |
| Close/restart each app | Message history, draft and original-timing replay remain correct. |
| Actual previous-version upgrade on the same signed channel | Identity, contacts, history and drafts survive. New-key or development-certificate reinstall is not an upgrade test. |

Use `first_contact_observation.template.json` once per pair. Leave unperformed fields as null and statuses as `not_run`. Describe observed failures before suggesting a fix. Keep the local file private until both participants approve a redacted export. Target: all three pairs finish a real CQ/reply without author help; this is a proposed goal, not a measured result.
