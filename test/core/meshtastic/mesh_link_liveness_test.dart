import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:dpip/core/meshtastic/mesh_link.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_mesh_service.dart';

/// A radio that accepts the link and is gone by the time the connect returns.
///
/// Every `disconnected` during an attempt is written off as the transport's
/// own disconnect-before-connect, so this drop is invisible to the status
/// listener — without the post-connect liveness check the link would never
/// come back.
class _VanishingService extends FakeMeshService {
  @override
  Future<Result<void>> connectToId(String id) async {
    final result = await super.connectToId(id);
    isConnected = false;
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('retries when the radio drops during the connect itself', () async {
    final service = _VanishingService();
    final link = MeshLink(service, SettingsStore.inMemory({}));
    link.start();

    await link.attach(const MeshDevice(id: 'AA:BB', name: 'radio'));

    expect(link.isConnected, isFalse);
    // `reconnecting` stays false — nothing was ever connected — but a retry
    // must still be queued, which is the whole point.
    expect(link.willRetry, isTrue);
  });
}
