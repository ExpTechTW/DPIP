/// Providers for the notification feature — the settings repository behind the
/// notify page. (Push transport lives in `core/notifications`, provided by the
/// core providers.)
library;

import 'package:dpip/core/di/shared_deps.dart';
import 'package:dpip/features/notification/data/notify_api.dart';
import 'package:dpip/features/notification/data/notify_repository_impl.dart';
import 'package:dpip/features/notification/domain/notify_repository.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// The notify settings repository (fetch/set the per-channel push filters).
List<SingleChildWidget> notificationProviders(SharedDeps deps) => [
  Provider<NotifyRepository>.value(
    value: NotifyRepositoryImpl(NotifyApi(deps.apiClient)),
  ),
];
