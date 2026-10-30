import 'dart:async';

import 'package:dpip/core/network/api_paths.dart';
import 'package:dpip/features/ai_chat/domain/ai_connection.dart';
import 'package:dpip/features/ai_chat/domain/chat_message.dart';
import 'package:dpip/features/ai_chat/domain/chat_model.dart';
import 'package:dpip/features/ai_chat/presentation/ai_chat_controller.dart';
import 'package:dpip/features/ai_chat/presentation/ai_setup.dart';
import 'package:dpip/features/ai_chat/presentation/pages/ai_chat_page.dart';
import 'package:dpip/features/ai_chat/presentation/pages/ai_settings_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../fakes.dart';
import 'ai_chat_controller_test.dart' show FakeSettings;

void main() {
  late FakeSettings settings;
  late List<Stream<ModelEvent> Function()> script;

  setUp(() {
    settings = FakeSettings();
    script = [];
  });

  Future<void> pumpApp(WidgetTester tester) async {
    // Tall enough that every page is built whole: the pages are lazy lists,
    // and a button below the fold does not exist to be tapped.
    tester.view
      ..physicalSize = const Size(1200, 6000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const AiChatPage()),
        GoRoute(
          path: AppRoutes.aiSettingsPath,
          name: AppRoutes.aiSettings,
          builder: (_, _) => const AiSettingsPage(),
        ),
      ],
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AiSetup(settings)),
          ChangeNotifierProvider(
            create: (_) => AiChatController(
              settings: settings,
              models: (_, _) => FakeChatModel(script),
              tools: FakeToolHost(),
              places: () => const [],
              taipeiNow: () => DateTime.utc(2026, 10, 22),
            ),
          ),
        ],
        child: MaterialApp.router(
          locale: const Locale('zh', 'TW'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('the first visit explains, then opens the setup', (tester) async {
    settings.connection = AiConnection.empty;
    await pumpApp(tester);

    expect(find.text('金鑰只存在這支手機，對話不會儲存'), findsOneWidget);
    expect(find.text('AI 可能出錯'), findsOneWidget);
    expect(find.text(ApiPaths.mcpPublicUrl), findsOneWidget);

    await tester.tap(find.text('開始設定'));
    await tester.pumpAndSettle();

    expect(settings.introSeen, isTrue);
    expect(find.byType(AiSettingsPage), findsOneWidget);
  });

  testWidgets('without a service, the chat asks for one', (tester) async {
    settings
      ..seen = true
      ..connection = AiConnection.empty;
    await pumpApp(tester);
    expect(find.text('還沒設定 AI 服務'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('a suggestion is asked and answered, tools shown', (
    tester,
  ) async {
    settings.seen = true;
    script
      ..add(calls([const ToolCall(id: 'c', name: 'eew', arguments: '{}')]))
      ..add(says('目前**沒有**速報。'));
    await pumpApp(tester);

    expect(find.text('AI 可能出錯，緊急時請以官方警報為準。'), findsOneWidget);
    await tester.tap(find.text('最近有地震嗎？'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('最近有地震嗎？'), findsOneWidget);
    expect(find.text('已查詢地震資料'), findsOneWidget);
    expect(find.textContaining('速報', findRichText: true), findsWidgets);
  });

  testWidgets('a stopped answer says so', (tester) async {
    settings.seen = true;
    final silent = StreamController<ModelEvent>();
    script.add(() => silent.stream);
    await pumpApp(tester);

    await tester.enterText(find.byType(TextField), '慢慢說');
    await tester.pump();
    await tester.tap(find.byTooltip('傳送'));
    await tester.pump();
    expect(find.text('等待回應…'), findsOneWidget);

    await tester.tap(find.byTooltip('停止'));
    await tester.pump();
    expect(find.text('已停止'), findsOneWidget);
    expect(find.byTooltip('傳送'), findsOneWidget);
    unawaited(silent.close());
  });

  group('settings', () {
    Future<void> openSettings(WidgetTester tester) async {
      settings
        ..seen = true
        ..connection = AiConnection.empty
        ..key = 'sk-saved';
      await pumpApp(tester);
      await tester.tap(find.byTooltip('AI 設定'));
      await tester.pumpAndSettle();
    }

    testWidgets('plain http to another host is refused, with why', (
      tester,
    ) async {
      await openSettings(tester);
      await tester.enterText(
        find.widgetWithText(TextField, 'API 網址'),
        'http://192.168.1.5:11434/v1',
      );
      await tester.enterText(find.widgetWithText(TextField, '模型'), 'm');
      await tester.tap(find.text('儲存'));
      await tester.pump();
      expect(find.textContaining('請使用 https://'), findsOneWidget);
      expect(settings.connection.isComplete, isFalse);
    });

    testWidgets('a preset fills the URL; a blank key keeps the saved one', (
      tester,
    ) async {
      await openSettings(tester);
      expect(find.text('已儲存金鑰。留空會保留原本的金鑰。'), findsOneWidget);
      await tester.tap(find.text('OpenAI'));
      await tester.enterText(find.widgetWithText(TextField, '模型'), 'gpt-x');
      await tester.tap(find.text('儲存'));
      await tester.pumpAndSettle();

      expect(settings.connection.baseUrl, 'https://api.openai.com/v1');
      expect(settings.connection.model, 'gpt-x');
      expect(settings.key, 'sk-saved');
      // Saved and back to the chat.
      expect(find.byType(AiSettingsPage), findsNothing);
    });
  });
}
