---
layout: page
title: Support
permalink: /support/
lang: en
last_updated: 2026-10-08
---

[简体中文]({{ '/zh-CN/support/' | relative_url }})

Open [GitHub issues]({{ site.support_url }}) for help. Issues are public: never post private messages, identity files, passphrases or backups. There is no e-mail support.

**How do I start?** Create a local Tox identity or restore a backup. There is no phone/e-mail registration. For account-free offline learning, use the separate MorseCQ app.

**Can I type a message?** Chat messages are keyed using a straight key or iambic paddles, by touch or keyboard. The decoded draft is read-only.

**Does iPhone include chat?** Yes, DitMesh includes chat on all five target platforms. Source/CI iOS packages are unsigned and require signing before installation. This does not imply current App Store availability.

**Why is a message pending?** Both peers must be reachable. There is no server push or offline relay store. Keep the app running; use connection diagnostics and the send retry/cancel actions when appropriate.

**Bootstrap settings.** Open network settings from the welcome/unlock screen or Me. Automatic mode uses saved/default nodes and refreshes the official Tox catalogue; Manual mode keeps your chosen host, UDP port and public key. Test the currently saved node or a catalogue entry. A successful DHT response confirms that node's UDP reachability; it does not prove TCP relay connectivity or that every chat peer is online.

**Local-network chat.** Start a LAN node on a desktop and share its displayed address, actual UDP port and DHT public key. On another device, enter those details in Manual mode. The node key differs from a friend's Tox ID. Allow Apple's local-network permission when prompted. LAN hosting must be started again after restarting the app.

**Language and appearance.** Me settings offer English, Simplified/Traditional Chinese, Japanese, Korean, German, French, Spanish, Portuguese and Russian, with Classic, Modern, Radio, Paper and Cartoon styles.

**How do I add or block a friend?** Use Chat → contacts to exchange Tox IDs or QR codes. Block from conversations, requests, invites or group members; manage the list under Me → Blocked people.

**Can you recover my identity?** No. Keep an encrypted backup and its passphrase. Restore current DitMesh backups explicitly through the application.

**Native backend failed to start.** Use a complete release package or rebuild/stage the platform Tim2Tox library. A production error must not be mistaken for a working demonstration chat.

**Delete local data.** Use Me → Delete identity or uninstall. Recipient copies and previous exports remain under their owners' control.
