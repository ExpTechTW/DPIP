import 'dart:async';

import 'package:dpip/utils/log.dart';
import 'package:flutter_compass/flutter_compass.dart';

class CompassService {
  CompassService._();

  static final CompassService _instance = CompassService._();
  static CompassService get instance => _instance;

  StreamController<CompassEvent>? _controller;
  StreamSubscription<CompassEvent>? _sourceSubscription;
  double _lastHeading = 0.0;
  bool _isInitialized = false;

  Stream<CompassEvent>? get events => _controller?.stream;

  double get lastHeading => _lastHeading;

  bool get isInitialized => _isInitialized;

  bool get hasCompass => _isInitialized && _controller != null;

  Future<void> initialize() async {
    if (_isInitialized) {
      TalkerManager.instance.debug('CompassService: already initialized');
      return;
    }

    TalkerManager.instance.debug('CompassService: initializing...');

    try {
      final sourceStream = FlutterCompass.events;
      if (sourceStream == null) {
        TalkerManager.instance.debug('CompassService: compass not available');
        _isInitialized = true;
        return;
      }

      _controller = StreamController<CompassEvent>.broadcast(
        onListen: () {
          TalkerManager.instance.debug('CompassService: first listener added');
        },
        onCancel: () {
          TalkerManager.instance.debug('CompassService: last listener removed');
        },
      );

      _sourceSubscription = sourceStream.listen(
        (event) {
          if (event.heading != null) {
            _lastHeading = event.heading!;
          }
          _controller?.add(event);
        },
        onError: (Object error) {
          TalkerManager.instance.error('CompassService: stream error', error);
          _controller?.addError(error);
        },
        onDone: () {
          TalkerManager.instance.debug('CompassService: source stream done');
          _controller?.close();
        },
      );

      _isInitialized = true;
      TalkerManager.instance.debug('CompassService: initialized successfully');
    } catch (e, s) {
      TalkerManager.instance.error(
        'CompassService: initialization failed',
        e,
        s,
      );
      _isInitialized = true;
    }
  }

  Future<void> dispose() async {
    TalkerManager.instance.debug('CompassService: disposing...');
    await _sourceSubscription?.cancel();
    _sourceSubscription = null;
    await _controller?.close();
    _controller = null;
    _isInitialized = false;
  }
}
