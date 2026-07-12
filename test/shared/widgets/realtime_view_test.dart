import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/realtime_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('en'),
  home: Scaffold(body: child),
);

RealtimeView<int> _view(RealtimeState<int> state) =>
    RealtimeView<int>(state: state, builder: (_, value) => Text('data $value'));

void main() {
  final t0 = DateTime.utc(2026);

  testWidgets('connecting with no data → loading', (tester) async {
    await tester.pumpWidget(
      _wrap(_view(const RealtimeState<int>.connecting())),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Connecting…'), findsOneWidget);
  });

  testWidgets('offline with no data → error, no content', (tester) async {
    await tester.pumpWidget(
      _wrap(_view(const RealtimeState<int>(status: RealtimeStatus.offline))),
    );
    expect(find.text('Connection lost'), findsOneWidget);
    expect(find.text('data 0'), findsNothing);
  });

  testWidgets('live with data → content, no banner', (tester) async {
    await tester.pumpWidget(
      _wrap(
        _view(
          RealtimeState<int>(
            status: RealtimeStatus.live,
            data: 7,
            dataTime: t0,
          ),
        ),
      ),
    );
    expect(find.text('data 7'), findsOneWidget);
    expect(find.text('Data may be out of date'), findsNothing);
  });

  testWidgets('stale with data → content + stale banner', (tester) async {
    await tester.pumpWidget(
      _wrap(
        _view(
          RealtimeState<int>(
            status: RealtimeStatus.stale,
            data: 7,
            dataTime: t0,
          ),
        ),
      ),
    );
    expect(find.text('data 7'), findsOneWidget);
    expect(find.text('Data may be out of date'), findsOneWidget);
  });

  testWidgets('offline with data → content + offline banner', (tester) async {
    await tester.pumpWidget(
      _wrap(
        _view(
          RealtimeState<int>(
            status: RealtimeStatus.offline,
            data: 7,
            dataTime: t0,
          ),
        ),
      ),
    );
    expect(find.text('data 7'), findsOneWidget); // last known data still shown
    expect(find.text('Connection lost'), findsOneWidget);
  });
}
