import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:dpip/core/meshtastic/mesh_link.dart';
import 'package:dpip/core/settings/prefs.dart';
import 'package:dpip/features/meshtastic/presentation/mesh_chat_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/meshtastic/fake_mesh_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MeshMessage message(String text, {int from = 1, int seconds = 0}) =>
      MeshMessage(
        from: from,
        channel: 0,
        text: text,
        timestamp: DateTime.utc(2026, 1, 1).add(Duration(seconds: seconds)),
      );

  Future<(MeshChatController, FakeMeshService)> makeController([
    Map<String, Object> initial = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(initial);
    final service = FakeMeshService();
    final prefs = Prefs(await SharedPreferences.getInstance());
    return (
      MeshChatController(service, MeshLink(service, prefs), prefs),
      service,
    );
  }

  /// Lets the controller's fire-and-forget persist settle.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('keeps the newest messages first, capped at maxMessages', () async {
    final (controller, service) = await makeController();
    for (var i = 0; i < MeshChatController.maxMessages + 10; i++) {
      service.messages.add(message('m$i', seconds: i));
    }
    await settle();

    expect(controller.messages.length, MeshChatController.maxMessages);
    expect(controller.messages.first.text, 'm59');
    expect(controller.messages.last.text, 'm10');
  });

  test('persists the log and restores it into a new controller', () async {
    final (controller, service) = await makeController();
    service.messages.add(message('hello'));
    await settle();
    controller.dispose();

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('meshtastic.messages');
    expect(stored, hasLength(1));

    final (restored, _) = await makeController({
      'meshtastic.messages': stored!,
    });
    expect(restored.messages.single.text, 'hello');
    expect(restored.messages.single.outgoing, isFalse);
  });

  test('drops a message the log already holds', () async {
    final (controller, service) = await makeController();
    service.messages
      ..add(message('same'))
      ..add(message('same'));
    await settle();

    expect(controller.messages, hasLength(1));
  });

  test('records a sent message as outgoing, and not a failed one', () async {
    final (controller, service) = await makeController();

    expect(await controller.send('  hi  '), isNull);
    expect(service.sentText, ['hi']);
    expect(controller.messages.single.text, 'hi');
    expect(controller.messages.single.outgoing, isTrue);

    service.sendFailure = const UnexpectedFailure('radio busy');
    expect(await controller.send('nope'), 'radio busy');
    expect(controller.messages, hasLength(1));
  });

  test('clearMessages empties the log and its storage', () async {
    final (controller, service) = await makeController();
    service.messages.add(message('bye'));
    await settle();

    controller.clearMessages();
    await settle();

    expect(controller.messages, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('meshtastic.messages'), isEmpty);
  });

  test('ignores a corrupt stored entry instead of losing the log', () async {
    final (controller, service) = await makeController();
    service.messages.add(message('good'));
    await settle();
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('meshtastic.messages')!;

    final (restored, _) = await makeController({
      'meshtastic.messages': ['not json', ...stored],
    });
    expect(restored.messages.single.text, 'good');
  });
}
