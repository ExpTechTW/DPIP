/// Status feature providers.
library;

import 'package:dpip/core/di/shared_deps.dart';
import 'package:dpip/features/status/data/cloudflare_status_api.dart';
import 'package:dpip/features/status/data/cloudflare_status_repository_impl.dart';
import 'package:dpip/features/status/data/server_status_api.dart';
import 'package:dpip/features/status/data/server_status_repository_impl.dart';
import 'package:dpip/features/status/domain/cloudflare_status_repository.dart';
import 'package:dpip/features/status/domain/server_status_repository.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Exposes the status repositories for the More → 伺服器狀態 screen.
///
/// The page depends on the domain interfaces only; the concrete Grafana /
/// Cloudflare implementations live here, at the feature root, so the page
/// never imports a data layer.
List<SingleChildWidget> statusProviders(SharedDeps deps) => [
  Provider<ServerStatusRepository>.value(
    value: ServerStatusRepositoryImpl(ServerStatusApi(deps.apiClient)),
  ),
  Provider<CloudflareStatusRepository>.value(
    value: CloudflareStatusRepositoryImpl(CloudflareStatusApi(deps.apiClient)),
  ),
];
