/// Providers for the LoRa mesh feature — the chat controller behind the mesh
/// page. (The BLE transport itself lives in `core/meshtastic` and is provided
/// by the core providers.)
library;

import 'package:dpip/core/di/shared_deps.dart';
import 'package:dpip/features/meshtastic/presentation/mesh_chat_controller.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// The mesh chat state: nodes and the persisted message log.
///
/// **Eager** (`lazy: false`), unlike most feature state. `MeshLink` reconnects
/// to a saved radio at startup and the message stream is a broadcast stream:
/// anything arriving with no listener is gone. A log that only starts
/// recording when the user happens to open the page would lose exactly the
/// messages that arrived while they weren't looking. Creating it costs a prefs
/// read and two stream subscriptions — no BLE work of its own.
List<SingleChildWidget> meshtasticProviders(SharedDeps deps) => [
  ChangeNotifierProvider<MeshChatController>(
    lazy: false,
    create: (_) => MeshChatController(
      deps.meshtastic,
      deps.meshLink,
      deps.meshNodes,
      deps.meshStore,
    ),
  ),
];
