# Local Sync

Local Sync exchanges library data directly between Musify installations on the
same local network. It is optional, off by default, and needs no account,
backend or API key.

## Pairing and use

1. Update every device to a build that includes Local Sync.
2. Enable **Settings → Local sync → Sync over local network** on each device.
3. Open **Devices** on one device and choose the other device.
4. Enter the six-digit PIN shown on the receiving device into the initiating
   device. Pairing finishes automatically, with no extra approval button.
5. Choose the data categories on each device. Only categories enabled on
   **both** devices are exchanged.

Public device IDs alone do not grant access. Long-press a paired device to
forget it. Pair each desired
connection when using three or more devices. Automatic sync contacts all
reachable paired devices and forwards received changes to other peers.

With automatic sync enabled, syncing runs at startup, when returning to the
app, shortly after library changes, and periodically. Manual sync is also
available. Apps must be running; mobile background suspension can delay sync.
Offline mode pauses automatic sync. An unreachable peer or another Wi-Fi
network leaves data and pairings intact, with retries when it becomes reachable.

## Data and conflict rules

| Category | Behavior |
|---|---|
| Favourites | Songs identified by ID; additions and removals propagate. |
| Playlists | Online, liked and custom playlists, folders, membership, order and pins. Distinct IDs with the same name stay distinct. Pins obey the app limit. |
| Recently played | Latest play metadata and the higher existing play count per song; recent list obeys the app limit. |
| Listening recap | Copies complete month snapshots, including stored history. A conflicting month uses the higher total listening time, then play count and a stable tie break. Counts and time are never added across devices. |
| Search history | Entries and removals propagate. |
| Radio favourites | Station IDs and removals propagate. |

Settings, offline mode, downloaded audio, device paths and credentials stay local.
This shares the library portion of backup data, rather than importing
`settings.hive` or copying device-specific storage.

A recap conflict of 200 and 300 minutes keeps the **entire 300-minute month**,
not 500 minutes or a union of its songs. This avoids counting a copied recap
again. Independent listening on two devices is not added together. A missing
month is copied. The recap UI continues to apply upstream retention and song
limits. Explicitly clearing the recap starts a new generation so an older peer
cannot restore the cleared listening data.

The current library format is version 3. Update both devices before syncing;
older peers are refused before a library is sent, and existing data and pairing
secrets are retained. Version-2 local metadata is migrated automatically.

Changes use logical versions and stable device tie breaks, rather than relying
on wall-clock modification times. Two simultaneous edits to the same item have
one deterministic winner. For recap and recently played, a deletion starts a
new generation and wins edits from the previous generation. Intentionally adding
the item again after receiving the deletion starts another generation; its old
counts do not return. Complete recap months are selected without combining one
month's value with another version's identity. Deletion markers prevent offline peers from reviving
removed items; a later intentional addition can restore an item. These markers
are retained while the devices may still need them, so sync metadata can grow.

## Failures and privacy

Payloads are validated before import. Embedded playlist artwork is preserved
(up to 16 MiB per data URI), with a 64 MiB limit on each encrypted wire message.
Ordinary text fields retain their smaller limit. All storage operations use a single serialized queue. Imports keep a durable recovery journal;
if the app closes during a write, startup restores the interrupted transaction
before retrying. Edits made after that write are preserved. A backup restore
pauses sync while its storage files are replaced. Export a backup before enabling
sync on existing data; sync is not a backup or an undo history.

Pairing uses SRP-6a with a random six-digit PIN and the fixed RFC 5054
2048-bit group. Only the receiving device displays the PIN; a password proof
authenticates it without sending the PIN over the network. The derived pair
secret remains on the devices. A challenge expires after 60 seconds, is consumed
after one proof attempt, and new requests are rate limited. Pairings are stored
per device; pair again after reinstalling or clearing app data. Library requests
and replies use AES-256-GCM with route/peer binding, request IDs and persisted
sequence counters to reject replay. A public discovery
ID is not a credential. Discovery still advertises device name, platform and
port on the LAN. Trusted paired devices can modify the selected library data;
forget devices you no longer control. Someone with access to the device's
private app storage can read its pairing secrets.

Discovery uses UDP port `53531`; the local HTTP server binds an available TCP
port. The JSON library messages on that transport are encrypted. No router port
forwarding is required. Guest Wi-Fi, AP isolation, VPN routing, firewalls and
Android battery restrictions can prevent discovery or delivery. Windows may ask
for private-network access. There is no remote/cloud fallback or Internet sync.

## Implementation and checks

- `local_sync_service.dart`: discovery, pairing, authenticated transport and retries.
- `local_sync/sync_security.dart`: pairing and encryption.
- `local_sync/sync_merge.dart`: versioned merge and recap rules.
- `library_merge_service.dart`: Hive export, validation, journal and recovery.
- `local_sync_page.dart` and settings: devices and category selection.

`flutter test` covers merges, categories, authentication, replay and recovery.
`.github/scripts/test_local_sync_peers.py` launches
three independent Flutter processes with separate storage and real HTTP servers;
it checks convergence, deletions, conflicts, reconnects, simultaneous requests
and recovery after killing a process during a write. Real Wi-Fi discovery and
mobile background behavior still require testing on physical devices.

The original local-network approach was inspired by
[Sonora](https://github.com/gmstyle/sonora).
