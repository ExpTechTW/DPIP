import 'dart:async';

import 'package:dpip/core/realtime/realtime_channel.dart';
import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:flutter/foundation.dart';

/// Bridges a [RealtimeChannel]'s [Stream] to the app's `provider` +
/// [ChangeNotifier] convention.
///
/// Seeds from the channel's synchronous latest state (so a widget that reads it
/// immediately after construction sees real data, not a blank), then rebuilds on
/// each emission. Feature-specific controllers subclass this to add typed
/// getters and register a distinct provider type.
class RealtimeNotifier<T> extends ChangeNotifier {
  RealtimeNotifier(this._channel) : _state = _channel.state {
    _subscription = _channel.states.listen(_onState);
  }

  final RealtimeChannel<T> _channel;
  late final StreamSubscription<RealtimeState<T>> _subscription;
  RealtimeState<T> _state;

  /// The latest freshness snapshot.
  RealtimeState<T> get state => _state;

  void _onState(RealtimeState<T> next) {
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
