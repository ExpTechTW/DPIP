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
