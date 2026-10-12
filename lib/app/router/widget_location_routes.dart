import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:dpip/shared/navigation/widget_location_link.dart';

/// Retains the latest Widget tap through onboarding. Stripping the parameter
/// before building Home lets go_router deliver a subsequent identical URL.
final class WidgetLocationRoutes {
  final requests = WidgetLocationRequests();

  String? redirect({required bool onboardingComplete, required Uri uri}) {
    final atHome = uri.path == AppRoutes.homePath;
    final atOnboarding = uri.path == AppRoutes.onboardingPath;
    if (atHome &&
        uri.queryParametersAll.containsKey(WidgetLocationLink.queryKey)) {
      requests.request(WidgetLocationLink.parse(uri));
      return onboardingComplete ? AppRoutes.homePath : AppRoutes.onboardingPath;
    }
    if (!onboardingComplete && !atOnboarding) return AppRoutes.onboardingPath;
    if (onboardingComplete && atOnboarding) return AppRoutes.homePath;
    return null;
  }

  WidgetLocationLink? takePending() => requests.takePending();
}
