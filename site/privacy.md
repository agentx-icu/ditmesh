---
layout: page
title: Privacy policy
permalink: /privacy/
lang: en
last_updated: 2026-10-08
---

[简体中文]({{ '/zh-CN/privacy/' | relative_url }}) · Updated: {{ page.last_updated }}

DitMesh is a peer-to-peer Morse chat application on Android, iOS, macOS, Linux and Windows. There is no developer messaging server, centralized registration, advertising, analytics or tracking code. Support is through public GitHub issues; do not post private messages, identities or backups there.

## Local data

The app stores your Tox identity, contacts, groups, message history, drafts, bookmarks, practice data, preferences, key bindings and any saved recordings in its private application storage. The identity profile can be protected with a password; message history and practice files are not encrypted at rest. Device access and backups therefore matter. Encrypted exports are saved or shared only when you request them.

Bootstrap settings are shared by this installation. Desktop LAN hosting uses a separate local node profile. These network settings are retained when you change or delete a chat identity.

Me → Delete identity removes its local account data. Messages already sent remain on recipients' devices. Operating-system backups and copies you previously exported have their own retention rules. DitMesh and MorseCQ keep independent application data.

## Network data

Messages and profile information are sent to contacts or groups using Tox encryption. The network uses public bootstrap nodes to find peers; there is no developer server storing undelivered messages. Offline messages wait on the sender's device until both peers are reachable.

Automatic bootstrap and explicit catalogue refresh request the public node list from `https://nodes.tox.chat/json`; that server receives the connection's IP address. Node tests send DHT requests to the selected address. Desktop LAN hosting opens a UDP socket and displays local network addresses and a public DHT key for you to share; chat identity secrets are not included in those node details.

Tox directly connects friends and does not conceal their IP addresses from each other. Bootstrap/DHT nodes see network connections, using temporary DHT keys; a public Tox ID does not by itself disclose your private identity key. See the [Tox project's privacy explanation](https://tox.chat/faq.html). Your displayed name/status and group messages are visible to their intended peers.

## Optional permissions

- Local network (Apple platforms): connect to manually configured LAN nodes or host a desktop LAN node.
- Camera: scan a Tox ID QR code on the device.
- Microphone: decode Morse audio locally; save a recording only when requested.
- Notifications: local message alerts and routing; no push server.
- File picker/share: explicitly import or export backups and materials. A chosen cloud file provider or browser link uses that provider's network services.

## Blocking and changes

Blocking hides that peer's messages, requests and invites on your device. There is no central operator who can remove another peer's stored messages. Updated data handling will be reflected here with a new date.

[Support]({{ '/support/' | relative_url }}) · [GitHub issues]({{ site.support_url }})
