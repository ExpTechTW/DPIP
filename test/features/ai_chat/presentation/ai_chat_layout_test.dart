import 'package:dpip/features/ai_chat/presentation/ai_chat_controller.dart';
import 'package:dpip/features/ai_chat/presentation/ai_setup.dart';
import 'package:dpip/features/ai_chat/presentation/pages/ai_chat_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../fakes.dart';
import 'ai_chat_controller_test.dart' show FakeSettings;

/// The AI page as the router shows it: a full-screen page pushed over the
/// shell, on a phone with a gesture bar. The question field must clear the
/// gesture area, and clear the keyboard when it is up.
void main() {
  /// The gesture area at the bottom, in logical pixels.
  const gestureBar = 34.0;

  Future<void> pumpPage(WidgetTester tester, {double keyboard = 0}) async {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3
      // The OS reports no bottom padding under an open keyboard.
      ..padding = FakeViewPadding(bottom: keyboard > 0 ? 0 : gestureBar * 3)
      ..viewInsets = FakeViewPadding(bottom: keyboard * 3);
    addTearDown(tester.view.reset);
    final settings = FakeSettings()..seen = true;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AiSetup(settings)),
          ChangeNotifierProvider(
            create: (_) => AiChatController(
              settings: settings,
              models: (_, _) => FakeChatModel(const []),
              tools: FakeToolHost(),
              places: () => const [],
              taipeiNow: () => DateTime.utc(2026),
            ),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('zh', 'TW'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AiChatPage(),
        ),
      ),
    );
    await tester.pump();
  }

  double fieldBottom(WidgetTester tester) =>
      tester.getRect(find.byType(TextField)).bottom;

  double screenHeight(WidgetTester tester) =>
      tester.view.physicalSize.height / tester.view.devicePixelRatio;

  testWidgets('the question field and its note clear the gesture bar', (
    tester,
  ) async {
    await pumpPage(tester);
    final limit = screenHeight(tester) - gestureBar;
    expect(fieldBottom(tester), lessThanOrEqualTo(limit));
    final disclaimer = tester.getRect(find.text('AI 可能出錯，緊急時請以官方警報為準。'));
    expect(disclaimer.bottom, lessThanOrEqualTo(limit));
  });

  testWidgets('the question field sits above the keyboard', (tester) async {
    const keyboard = 300.0;
    await pumpPage(tester, keyboard: keyboard);
    expect(
      fieldBottom(tester),
      lessThanOrEqualTo(screenHeight(tester) - keyboard),
    );
  });
}
