/// Settings feature providers.
library;

import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'package:dpip/core/di/shared_deps.dart';
import 'package:dpip/features/settings/data/haste_api.dart';
import 'package:dpip/features/settings/domain/dump_uploader.dart';

/// Exposes [DumpUploader] for the developer page's diagnostics dump.
///
/// Built here rather than in the page so presentation depends on the contract
/// and not on the paste service behind it — and here rather than in
/// `core/di`, because core must not know a feature exists.
List<SingleChildWidget> settingsProviders(SharedDeps deps) => [
  Provider<DumpUploader>.value(value: HasteApi(deps.apiClient)),
];
