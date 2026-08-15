import 'package:dpip/core/settings/onboarding_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SettingsStore settings;

  Future<OnboardingStore> makeStore([bool complete = false]) async {
    settings = SettingsStore.inMemory(
      complete ? {'onboarding.complete': true} : {},
    );
    return OnboardingStore(settings);
  }

  test('defaults to incomplete', () async {
    expect((await makeStore()).isComplete, isFalse);
  });

  test('reads a persisted completion', () async {
    expect((await makeStore(true)).isComplete, isTrue);
  });

  test('complete() persists and notifies once', () async {
    final store = await makeStore();
    var notified = 0;
    store.addListener(() => notified++);

    await store.complete();
    expect(store.isComplete, isTrue);
    expect(notified, 1);

    // Idempotent: a second call neither re-persists nor re-notifies.
    await store.complete();
    expect(notified, 1);

    expect(settings.getBool(SettingKeys.onboardingComplete), isTrue);
  });
}
