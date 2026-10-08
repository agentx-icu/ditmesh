[简体中文](./2026-09-30-tim2tox-message-annotation.zh-CN.md)

# RFC: message annotation on the wire (Tim2Tox track D, item 1)

> Status: **draft, not yet filed upstream** (2026-09-30). Target repository:
> `agentx-icu/tim2tox` (submodule pin `9d4245a`). Companion items of track D —
> Dart-side custom packet API, lossy packet API, `failed` message status — are
> listed in §7 and get their own proposals.

## 1. Problem

`FfiChatService.sendTextWithResult(peerId, text, {cloudCustomData})` stores
`cloudCustomData` **locally only**: the receiver's `ChatMessage` never carries it
(`dart/lib/service/ffi_chat_service.dart`, "One-shot cloudCustomData … carries no
cloudCustomData"). `sendGroupTextWithResult` has no such parameter at all.

Two consumers need structured, per-message metadata that travels with the text:

- **toxee**: reply quotes and forward metadata (`V2TIM` `cloudCustomData`) are
  shown on the sender's side and silently dropped on the receiver's — a known
  gap of the hybrid runtime.
- **DitMesh**: v2 "recorded keying" (plan §5.2 layer two) must ship the sender's
  keyed timing (`wpm`, Farnsworth, quantised element durations) next to the plain
  text, so the listener can replay what was actually keyed. v1 sends plain text
  and plays it at the listener's speed precisely because this is missing.

Both want the same thing: an opaque JSON blob correlated with one text message,
delivered to the same peer or group, merged into that message on arrival, never
rendered as a message of its own.

## 2. Non-goals

- Not a general custom-message type: `kGenericCustom` (control `Type = 3`)
  already exists for standalone payloads and renders as its own bubble.
- No fragmentation: an annotation must fit in one lossless custom packet
  (≤ 1.2 KB payload after the header). Larger payloads are a caller error.
- No change to the text message itself; old clients keep receiving the text
  unchanged and ignore the annotation (see §5).

## 3. Wire format

Reuse the existing control frame (`source/Tim2ToxPacketIds.h`: packet id
`kControl = 184`, magic `T2TC`, `source/Tim2ToxControlPacket.h`) and add one
type:

```cpp
enum class Type : uint8_t {
    kReceipt = 1,
    kReaction = 2,
    kGenericCustom = 3,
    kGroupIdentity = 4,
    kMessageAnnotation = 5,   // NEW
};
```

Body (UTF-8 JSON, one object):

| Field | Type | Meaning |
|---|---|---|
| `v` | int | annotation schema version, `1` |
| `h` | string | correlation key: hex of the first 8 bytes of `sha256(utf8(text))` of the annotated text message |
| `n` | int | sender-side sequence number of the annotation (disambiguates two identical texts sent close together; the receiver pairs by `h` and takes the oldest unpaired one) |
| `data` | object | opaque application payload; keys are namespaced by the application (`"toxee"`, `"ditmesh"`, …) |

Why not a message id: message ids are **local** on both sides today — the
sender mints `${ms}_${seq}_$selfId` for its row
(`ffi_chat_service.dart`, C2C send path) and the receiver mints its own
`${ms}_${seq}_$from` for the inbound row; nothing travels on the wire that
both ends share, and the existing receipts already correlate by a text-derived
key for the same reason (`'dup:$text'.hashCode`). The digest is what both ends
can compute from the bytes that did travel.

Example (DitMesh):

```json
{"v":1,"h":"9a3f0c1e77b2d4a0","n":17,"data":{"ditmesh":{"v":1,"wpm":15,"fw":8,"keyed":true,"t":"<base64 varint timing>"}}}
```

Size rule: `Encode()` rejects a body over the lossless custom packet limit and
returns `nullopt`, exactly as today for the other types; the Dart side surfaces
that as an error result, not a silent drop.

## 4. Sender behaviour

- **C2C**: `sendTextWithResult(peerId, text, cloudCustomData: json)` sends a
  `kMessageAnnotation` frame **first** (`h` = digest of the text, `n` = next
  sequence), then the text as today. The frame goes through the same lossless
  custom packet path as receipts; whether the receiver sees it before or after
  the text does not matter (§5 holds either side for a bounded time).
- **Group (NGC)**: new parameter `sendGroupTextWithResult(groupId, text,
  {cloudCustomData})`. Group custom packets are wrapped with a kind tag
  (`UnwrapTim2ToxGroupPacket(kTim2ToxGroupPacketCustomMessage, …)` in
  `V2TIMManagerImpl::HandleGroupCustomPacket`), and the existing kind is
  materialised as a visible custom message. The annotation therefore uses a
  **new kind** `kTim2ToxGroupPacketAnnotation`, which the handler routes to the
  annotation path before the custom-message path; the body is the same JSON as
  the C2C frame. Conference groups cannot carry custom packets: the parameter is
  accepted and ignored there, and the result reports
  `annotationDelivered: false`.
- **Offline queue**: an annotation is queued together with its text (one queue
  entry holds both) so they replay in order when the peer comes online. A
  queued text without its annotation, or vice versa, never happens.
- The local `ChatMessage` keeps `cloudCustomData` as today (sender-side view
  unchanged).

## 5. Receiver behaviour

- On `kMessageAnnotation` (C2C frame or the group packet kind): hold it in a
  small map keyed by **sender and digest** — (`peer`, `h`) for C2C,
  (`group`, `sender peer id`, `h`) for NGC, where the sender is the packet's
  `peer_id` as delivered by toxcore, never a field of the body — for a bounded
  time (30 s / 64 entries). Two members sending the same text therefore never
  receive each other's annotation. When a text arrives from that peer whose digest matches, attach the
  oldest unpaired annotation: set `cloudCustomData` (replace, not merge: one
  annotation per message) and remove it from the map. If the text arrived
  first, the inbound path keeps the digest of the last few messages per peer
  (same bound) so a late annotation still finds its row and emits a
  message-updated event. Unpaired entries expire with a log line.
- The annotation is **never** materialised as a `ChatMessage`, so no bubble,
  no unread count, no notification.
- Old clients (`Type` unknown) already ignore unknown control types in
  `Decode()` — verify with the existing `Tim2ToxControlPacketTest` and add a
  case: a build without this RFC receives `Type = 5` and drops it silently.
- Applications ignore `data` keys they do not own.

## 6. API surface

Dart (`FfiChatService`):

- `sendTextWithResult(..., {String? cloudCustomData})` — semantics change:
  now transmitted. Result gains `bool annotationDelivered`.
- `sendGroupTextWithResult(..., {String? cloudCustomData})` — new parameter.
- `Stream<ChatMessage> messageUpdates` (or the existing message-changed
  channel) fires when an annotation lands on an already-displayed message.

FFI: one new export pair mirroring the receipt path
(`tim2tox_ffi_send_message_annotation`, callback `messageAnnotation`), or an
extension of the existing send-text call carrying the optional blob; the
latter keeps the ABI byte-matching constraint simpler (one call, one optional
pointer). Prefer the extension.

## 7. Related track D items (separate proposals)

1. **Dart-side custom packet API** — expose lossless custom packets
   (`kLosslessCustomRangeStart..End`) to Dart so applications can define their
   own packet types without touching C++.
2. **Lossy packet API** — required for real-time keying (plan §5.5):
   head-of-line blocking on the lossless path makes live keying unusable over a
   TCP relay.
3. **`failed` message status** — the polling path cannot distinguish `failed`
   from `sent`; `MessageStatus.failed` is never produced today.

## 8. Test plan

- `Tim2ToxControlPacketTest`: encode/decode round trip for `Type = 5`,
  over-size rejection, unknown-type drop.
- Headless two-instance test (tim2tox `auto_tests` style): A sends text +
  annotation to B; B's `ChatMessage` shows `cloudCustomData`; reversed arrival
  order handled; annotation to an offline peer replays with the text.
- toxee: reply quote round trip between two builds.
- DitMesh: `ditmesh_chat/test/native_smoke_test.dart` gains a
  self-annotated send once the API exists.

## Change log

- **2026-09-30 v0.1** First draft, written from ditmesh's plan §5.2 and the
  Tim2Tox control-frame sources at pin `9d4245a`. Not yet filed upstream.
- **2026-09-30 v0.2** Review fixes: correlation by text digest + sender
  sequence instead of `clientMessageID` (message ids are local on both ends);
  the annotation frame is sent before the text and either arrival order is
  held; NGC needs its own group packet kind because the existing custom kind is
  rendered as a message; group pairing is keyed by the sending peer as well as
  the digest.
