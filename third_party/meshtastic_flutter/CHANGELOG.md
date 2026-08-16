## 0.0.1

* Initial release
* Complete Meshtastic BLE protocol implementation
* Support for device discovery, connection, and communication
* Real-time packet and node information streaming
* Text messaging and position sharing
* Configuration access and node management
* Comprehensive error handling and type safety
* Cross-platform support (Android/iOS)


## 0.0.2

* Upgraded dependency versions


## 0.0.3

* Replace deprecated Code


## 0.0.3+dpip (local fork)

* Deliver the packets a radio queues while no phone is connected: `fromradio`
  is now drained until the mailbox is empty instead of stopping at
  `config_complete_id`. The firmware only replays that backlog *after* the
  config handshake (`PhoneAPI` → `STATE_SEND_PACKETS`) and never notifies
  `fromnum` for it, so the old read loop dropped every message that arrived
  during a disconnect.
* `fromnum` notifications now always trigger a drain; the previous
  `fromNum > lastSeen` guard stopped delivering packets after a radio reboot
  reset the counter.
* Reads are single-flight — a notification arriving mid-drain no longer starts
  a second, interleaved read loop on the same characteristic.
* An unparseable packet is skipped instead of aborting the read loop, and a
  failed config download reports an error instead of stalling in `configuring`.
* `_configComplete` is cleared on an unexpected disconnect so a reconnect
  re-runs the handshake (and the backlog replay).

### DPIP data plane + provisioning

* `sendData(portnum:…)` — arbitrary app ports, any channel, broadcast or
  direct. `from` is left unset because the firmware overwrites it, and a zero
  `from` is what marks a packet local.
* `sendAdmin(AdminMessage)` + `adminStream` — local administration of the
  attached radio (channel table, LoRa config) and its replies. Local admin is
  exempt from the remote-admin session key precisely because `from == 0`.
* `connectToId(remoteId)` — reconnect to a known radio without scanning first.
* `myNodeNum` / `channels` / `loraConfig` accessors.
* Fixed: the LoRa config was being lost. `Config` carries its sections in a
  protobuf **oneof** and the radio sends one section per packet, so the single
  `_config` field only ever kept the last section of the download (bluetooth).
  The LoRa section is now captured separately.

### Cross-platform fixes (adversarial review)

* `scanForDevices` now **always terminates**. It used to `await for` over
  `FlutterBluePlus.scanResults`, which is a broadcast stream that is never
  closed and emits nothing on `stopScan` — so with no radio in range the
  generator hung forever, and with it every caller waiting on the scan's end
  (the picker's spinner, and any reconnect that fell back to a scan).
* Writes to `toradio` use a long write. iOS caps a plain write at the ATT MTU
  minus 3 (~182 B) against Android's 509, so full-size payloads sent fine on
  Android and threw on iOS.
* Dropped the explicit `requestMtu(512)` — `connect()` already negotiates it on
  Android and ignores it elsewhere; this only bought a second round trip.
* `cacheChannel` keeps the channel table current after a write.
* `sendData` returns the **packet id** it sent with, and accepts `hopLimit`.
  The id is the only handle on a packet once it leaves — the radio names it in
  a `QueueStatus` and in every `ClientNotification` refusal, and a reply
  carries it in `decoded.request_id`.
* Packet ids are a random-seeded counter, not `millisecondsSinceEpoch`: two
  sends in one millisecond produced the same id, and the firmware drops a
  duplicate id silently (`wasSeenRecently`) — indistinguishable from a packet
  that went out unanswered.
* `hop_limit` is no longer hardcoded to 3 — on *any* send (data, text,
  position). The firmware substitutes its configured value only when the field
  is 0 *and* `want_ack` is set, so the constant was obeyed rather than
  corrected: a mesh configured for 5 hops had its chat, its position
  broadcasts and its traceroutes all capped at 3. Now read from the radio's
  accumulated `lora` config (not `_config`, which each config section
  overwrites), clamped to `HOP_MAX` (7 — the header reserves 3 bits) and
  falling back to `HOP_RELIABLE` (3) until the config download lands.
* Text and position sends share the packet-id counter and the UNSET priority
  too, instead of each minting its own wall-clock id.
* `priority` is left UNSET instead of pinned to `DEFAULT`, so the firmware's
  `fixPriority()` can promote a `want_response` packet to RELIABLE — and it is
  no longer first in line for eviction when the TX queue fills.
* New `noticeStream`: `FromRadio.client_notification` is delivered instead of
  discarded, and `queue_status` is logged. These are how the radio says it
  refused to send ("Multi-hop traceroute to broadcast address is not allowed",
  "TraceRoute can only be sent once every 30 seconds"); dropping them made
  every in-radio rejection look exactly like a send that was never answered.
* `NodeInfoWrapper.hopsAway` — read through `hasHopsAway()`, so an unset
  `optional uint32` stays null instead of reading as `0` ("direct neighbour"),
  which is a plausible and wrong claim about reach.
* `LocalStats` is no longer discarded. `_absorbTelemetry` early-returned on
  `!hasDeviceMetrics()`, which threw away every other `Telemetry` variant —
  including the radio's own counter block (packets rx/tx/bad/duplicate, relays
  performed and cancelled, free heap, uptime). The firmware sends it to the
  phone only, never over the air, so it is the cheapest ground truth available
  and none of it reached Dart. New `localStatsStream` + `localStats`.
* `telemetry.pb.dart` / `telemetry.pbenum.dart` are exported from the package
  barrel; `LocalStats` was unreachable to consumers without it.
* `MeshtasticClient` takes an injectable `now` clock, and every timestamp it
  stamps (`_metricsAt`, the connection-status stamp, the position packet's
  `time`) comes from it instead of `DateTime.now()`. A host that windows or
  plots those timestamps against a corrected clock was otherwise comparing two
  different clocks: on a phone whose clock is wrong, "when did this reading
  arrive" came out as the offset rather than the age, and a 24-hour retention
  window cut in the wrong place. Defaults to `DateTime.now` so the package
  stays standalone.
