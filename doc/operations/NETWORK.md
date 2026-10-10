[简体中文](./NETWORK.zh-CN.md)

# Bootstrap nodes and LAN hosting

Open network settings from **Me**, or from the welcome/unlock screen before opening an identity. Node configuration is shared by this installation and does not require registration. Changing identity preserves it.

## Choose a mode

| Mode | Behavior |
|---|---|
| Automatic | Starts immediately with saved selection and numeric fallback seeds (IPv4, plus IPv6 where the node publishes it, so IPv6-only/NAT64 networks can start before the catalogue loads); refreshes the official HTTPS catalogue in the background and applies several valid online entries. |
| Manual | Uses the saved host, UDP port and public key. Public catalogue refresh does not replace the chosen node. A LAN peer can be configured this way on any platform. |
| LAN hosting | Desktop-only hosting of an independent UDP/DHT node; share its displayed address, actual bound UDP port and full DHT public key with other devices. |

The catalogue comes from [the official Tox node list](https://nodes.tox.chat/). A network/list failure is visible as fallback data. Catalogue UDP/TCP status and maintainer/location information are published metadata, rather than a live test from this device. Refresh, probe and selection are separate actions.

## Test and configure a node

The current-node panel shows the saved address, port and full public key. Test it directly in Automatic or Manual mode, including a saved node absent from the catalogue.

For a custom node, enter its host, port and 64-hex-character DHT public key, then test that exact tuple before applying it. Changing any field invalidates the previous result. IPv6 endpoints display with brackets; enter the address itself in the host field. Hostnames resolve asynchronously with a deadline before native calls.

| Probe result | Meaning |
|---|---|
| Reachable | This candidate answered a real DHT nodes request. |
| Unreachable | A request got no answer within the probe window, or its address could not resolve. Check address, port, key and network path. |
| Invalid | The descriptor is malformed. |
| UDP unavailable | A local UDP limitation prevented the probe; it does not establish that a TCP-capable node is unusable. |
| Probe unavailable | The isolated probe instance could not run; the interface reports the limitation separately. |

Each probe owns a temporary native instance with local discovery disabled, so an existing chat or nearby peer cannot produce a false positive. It preserves the live chat instance. A UDP/DHT answer does not test TCP relay reachability.

## Host a LAN node

On a desktop, select LAN mode, choose a preferred UDP port, and start hosting. Use the **actual** address and port shown after startup; another local process may already occupy the preferred port. Copy/share the full node details. Other devices on that network enter those details in Manual mode, including Android and iOS clients.

iPhone, iPad and macOS 15 or later require local-network access for these connections. Allow DitMesh's system prompt; if access was denied, enable it in system settings and retry the node test. The purpose text is localized in all ten languages. See [Apple's local-network privacy documentation](https://developer.apple.com/documentation/technotes/tn3179-understanding-local-network-privacy).

The key is the hosted node's DHT public key; a contact's Tox ID serves a different purpose. The host uses a separate private profile from the chat identity. Start/stop, failed startup and restart recovery preserve the previous public node configuration. LAN hosting does not start automatically after restarting the application; start it again and share the current displayed details.

Stop hosting before closing a node that other devices are using. The settings service restores the prior selection and retains its recovery journal if restoration fails, so retry remains possible. Closing the application cancels pending bootstrap work and releases owned native instances.

## Network recovery

Android/iOS path changes and application resume trigger guarded reconnection. Bursts are debounced, repeated kicks are rate-limited, and work stops when the session or selected mode changes. Both peers must be reachable for chat delivery; offline messages stay in DitMesh's durable local queue.

The Chat pending-message list lets you inspect queued and failed history rows, cancel a queued send, or retry a failed send. Status details follow local connectivity and peer presence. A sent check means the local transport accepted the message; a delivered check requires the actual peer receipt. Group delivery confirms at least one member. Neither receipt proves reading or listening.

Optional original keying rhythm is carried with messages between compatible DitMesh clients and retained in the local queue. Other clients continue receiving ordinary text. Group rhythm is optional metadata on a private channel: a text receipt does not prove that its rhythm arrived. See the [rhythm protocol](../rfcs/2026-10-09-keyed-rhythm.md).

Actual native/UI/CI evidence is recorded in [validation](../VALIDATION.md).
