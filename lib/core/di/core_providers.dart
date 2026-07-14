import 'package:dpip/core/di/shared_deps.dart';
import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/realtime/realtime_service.dart';
import 'package:dpip/core/settings/experimental_settings.dart';
import 'package:dpip/core/settings/locale_controller.dart';
import 'package:dpip/core/settings/onboarding_store.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// App-wide, feature-agnostic providers: settings and shared services.
///
/// The first entry in the aggregate list in `app.dart`; feature modules add
/// their own after it.
List<SingleChildWidget> coreProviders(SharedDeps deps) => [
  ChangeNotifierProvider<RegionSelection>.value(value: deps.regions),
  ChangeNotifierProvider<ExperimentalSettings>.value(value: deps.experimental),
  ChangeNotifierProvider<RegionStore>.value(value: deps.regionStore),
  ChangeNotifierProvider<OnboardingStore>.value(value: deps.onboarding),
  ChangeNotifierProvider<LocaleController>.value(value: deps.locale),
  Provider<TownDirectory>.value(value: deps.townDirectory),
  Provider<LocationService>.value(value: deps.locationService),
  Provider<RealtimeService>.value(value: deps.realtimeService),
  Provider<NotificationService>.value(value: deps.notificationService),
];
