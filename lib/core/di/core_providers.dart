import 'package:dpip/core/di/shared_deps.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/realtime/realtime_service.dart';
import 'package:dpip/core/settings/area_selection.dart';
import 'package:dpip/core/settings/experimental_settings.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// App-wide, feature-agnostic providers: settings and shared services.
///
/// The first entry in the aggregate list in `app.dart`; feature modules add
/// their own after it.
List<SingleChildWidget> coreProviders(SharedDeps deps) => [
  ChangeNotifierProvider<RegionSelection>.value(value: deps.regions),
  ChangeNotifierProvider<ExperimentalSettings>.value(value: deps.experimental),
  ChangeNotifierProvider(create: (_) => AreaSelection()),
  Provider<RealtimeService>.value(value: deps.realtimeService),
  Provider<NotificationService>.value(value: deps.notificationService),
];
