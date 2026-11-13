---
layout: page
title: Privacy policy
permalink: /privacy/
lang: en
last_updated: 2026-11-13
---

[简体中文]({{ '/zh-CN/privacy/' | relative_url }}) · Updated: {{ page.last_updated }}

DitMesh is a peer-to-peer Morse chat application on Android, iOS, macOS, Linux and Windows. There is no developer messaging server, centralized registration, or advertising. Support is through public GitHub issues; do not post private messages, identities or backups there.

Release builds on Android ask for privacy consent before starting the Tox backend. The app stores the accepted policy version on the device and asks again when that version changes.

## Local data

The app stores your Tox identity, contacts, groups, message history, drafts, bookmarks, practice data, preferences, key bindings and any saved recordings in its private application storage. The identity profile can be protected with a password; message history and practice files are not encrypted at rest. Device access and backups therefore matter. Encrypted exports are saved or shared only when you request them.

Bootstrap settings are shared by this installation. Desktop LAN hosting uses a separate local node profile. These network settings are retained when you change or delete a chat identity.

Me → Delete identity removes its local account data. Messages already sent remain on recipients' devices. Operating-system backups and copies you previously exported have their own retention rules. DitMesh and MorseCQ keep independent application data.

## Network data

Messages and profile information are sent to contacts or groups using Tox encryption. The network uses public bootstrap nodes to find peers; there is no developer server storing undelivered messages. Offline messages wait on the sender's device until both peers are reachable.

Automatic bootstrap and explicit catalogue refresh request the public node list from `https://nodes.tox.chat/json`; that server receives the connection's IP address. Node tests send DHT requests to the selected address. Desktop LAN hosting opens a UDP socket and displays local network addresses and a public DHT key for you to share; chat identity secrets are not included in those node details.

Tox directly connects friends and does not conceal their IP addresses from each other. Bootstrap/DHT nodes see network connections, using temporary DHT keys; a public Tox ID does not by itself disclose your private identity key. See the [Tox project's privacy explanation](https://tox.chat/faq.html). Your displayed name/status and group messages are visible to their intended peers.

On Android, Google ML Kit scans QR codes on the device. Google receives diagnostic and usage metrics, such as the app version, device information and scanner performance. Camera images and decoded QR contents are processed locally and are not sent to Google.

## Location and People nearby

Location and nearby visibility are separate, optional switches, off by default for each identity on this device. Current coordinates can fill the Maidenhead grid tool; unsent coordinates are kept in memory and are not included in exported backups. You can explicitly send a single location message to a contact or group, after previewing the coordinates. That message is retained in chat history on each recipient’s device and included when that history is backed up. Viewing received positions does not read your device location; a map provider receives the selected coordinates only when you choose to open its map. Location is read only while the app is in the foreground.

When you also enable nearby visibility and open People nearby, DitMesh uses the same Tox rendezvous protocol as Toxee. DitMesh shares your display name and approximate coordinates (rounded to about 100 m) in public Tox groups for your area. Anyone who joins one of those groups can receive this information. Joining does not require proof of identity or physical location. Nearby packets do not enter ordinary chats, message history or the group list. There is no location directory server. The network and operating system location provider have their own visibility into network connections and location requests.

A fresh discovery signing/encryption identity is created for each nearby session. Your Tox ID is disclosed only when you explicitly send or answer a nearby request; requests are encrypted to the selected participant, and friendship still requires acceptance. Closing the nearby page stops discovery after five minutes; hiding or suspending the app, disabling location/visibility or closing the Tox session stops it immediately. Session records expire, but other participants can retain information they received. Discovery blocking applies only to the current temporary discovery identity/session; ordinary chat blocking is separate.

## Optional permissions

- Local network (Apple platforms): connect to manually configured LAN nodes or host a desktop LAN node.
- Location: current coordinates, the grid locator, explicit chat location sharing and optional People nearby; no background location permission.
- Camera: scan a Tox ID QR code on the device.
- Microphone: decode Morse audio locally; save a recording only when requested.
- Notifications: local message alerts and routing; no push server.
- File picker/share: explicitly import or export backups and materials. A chosen cloud file provider or browser link uses that provider's network services.

## Blocking and changes

Blocking hides that peer's messages, requests and invites on your device. There is no central operator who can remove another peer's stored messages. Updated data handling will be reflected here with a new date.

[Support]({{ '/support/' | relative_url }}) · [GitHub issues]({{ site.support_url }})
