/// Events feature providers — the DPIP disaster-event history repository.
library;

import 'package:dpip/core/di/shared_deps.dart';
import 'package:dpip/features/events/data/event_api.dart';
import 'package:dpip/features/events/data/event_repository_impl.dart';
import 'package:dpip/features/events/domain/event_repository.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Exposes the [EventRepository] so the events timeline can consume it without
/// importing the feature's `data/`.
List<SingleChildWidget> eventsProviders(SharedDeps deps) => [
  Provider<EventRepository>.value(
    value: EventRepositoryImpl(EventApi(deps.apiClient)),
  ),
];
