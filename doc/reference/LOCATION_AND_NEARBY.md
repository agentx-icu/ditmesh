# Location and People nearby

[简体中文](./LOCATION_AND_NEARBY.zh-CN.md)

Location is optional and off by default for each identity on this device.
Open **Me → Location** to grant foreground location access. **Use current
location** shows the latest coordinates and Maidenhead locator. The same
button in **Reference → Radio tools → Grid locator** fills latitude,
longitude and your own locator; the other station's locator stays as entered.
The chat menu offers **Send current location**: after a confirmation preview,
it sends one position to the selected conversation (every member in a group).
Received position cards show coordinates, a Maidenhead locator and send time,
with explicit map/copy actions. **View shared location** in a one-to-one chat
reads the latest valid received snapshot, without reading this device's
position, even with the Location switch off. Position cards never enter Morse
auto-play.

To discover people, also enable **Visible to people nearby**, accept the
privacy notice, then open **People nearby** from Contacts, Add friend or
Location settings. It shares a display name and coordinates rounded to about
100 m with participants within roughly 5 km. A location-enabled device can
use the grid tool without joining discovery. No location directory server is
used. Nearby uses Toxee's `toxee/nearby/v1` protocol and can discover compatible
clients. Discovery cells are transport only; they do not become chat groups
or appear in message history.

**Say hi** sends an encrypted intent to one selected peer after confirmation
that your Tox ID will be shared. The recipient can decline or send a Tox
friend request; the initiator then explicitly accepts it in the request inbox.
A matched reply shows both its nearby name and sender public key. Names,
coordinates and possession of a request nonce do not certify a real-world
identity. Nearby blocking hides a temporary discovery identity for the current
session; chat/contact blocking remains separate.

Discovery stops on backgrounding, hiding the app, disabling either switch,
closing the Tox session or replacing an identity. Closing the nearby page
stops discovery after five minutes; reopening cancels that timeout. Resume
restarts only while a nearby page is open. Deleting or replacing an identity
clears its location consent. Unsent coordinates, temporary discovery keys and nearby visibility are not included in exported backups. Explicitly sent/received location messages are saved in chat history and its backups.

The app uses `LocationSource` for device permission and position access. The
SDK-free `NearbyTransportProvider` capability supplies one-session transports;
`packages/ditmesh_chat` guards native calls against retired sessions. Android
uses framework LocationManager and asks for coarse/fine foreground permission;
Apple bundles localized usage descriptions, macOS has the location entitlement,
and iOS bypasses the always-location permission. Linux uses GeoClue; Windows
uses the system location provider. Permission denial and provider failures
show localized recovery actions.

Validation: `flutter test test/nearby` from `apps/ditmesh`; backend transport
coverage is `packages/ditmesh_chat/test/nearby_transport_test.dart`. The app's
localization, SDK import and file-size guards apply to this feature too.
