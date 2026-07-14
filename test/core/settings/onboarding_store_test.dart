import 'package:dpip/core/settings/onboarding_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dpip/core/settings/prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<OnboardingStore> makeStore([bool complete = false]) async {
    SharedPreferences.setMockInitialValues(
      complete ? {'onboarding.complete': true} : {},
    );
    return OnboardingStore(Prefs(await SharedPreferences.getInstance()));
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

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('onboarding.complete'), isTrue);
  });
}
