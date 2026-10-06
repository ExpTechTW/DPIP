import 'dart:async';

import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/geo/location_status.dart';
import 'package:dpip/core/geo/town_boundaries.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/permissions/permission_outcome.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

TownDirectory _dir() => TownDirectory.fromJson({
  '100': {
    'city': '臺北',
    'town': '中正',
    'lat': 25.03,
    'lng': 121.52,
    'cityLevel': '市',
    'townLevel': '區',
  },
  '970': {
    'city': '花蓮',
    'town': '花蓮',
    'lat': 23.99,
    'lng': 121.60,
    'cityLevel': '縣',
    'townLevel': '市',
  },
});

void main() {
  test('resolves the nearest township from a GPS fix', () async {
    final service = LocationService(
      _dir(),
      isAvailable: () async => true,
      fix: () async => (lat: 25.05, lng: 121.55),
    );
    expect((await service.currentTown())?.code, '100');
  });

  test('null when location is unavailable (services off / denied)', () async {
    final service = LocationService(
      _dir(),
      isAvailable: () async => false,
      fix: () async => (lat: 25.05, lng: 121.55),
    );
    expect(await service.currentTown(), isNull);
  });

  test('null when no fix could be obtained', () async {
    final service = LocationService(
      _dir(),
      isAvailable: () async => true,
      fix: () async => null,
    );
    expect(await service.currentTown(), isNull);
  });

  test('a fix error degrades to null, never throws', () async {
    final service = LocationService(
      _dir(),
      isAvailable: () async => true,
      fix: () async => throw Exception('gps timeout'),
    );
    expect(await service.currentTown(), isNull);
  });

  test('lastKnownFix serves the cached fix without a live read', () async {
    var liveReads = 0;
    final service = LocationService(
      _dir(),
      lastKnown: () async => (lat: 25.05, lng: 121.55),
      fix: () async {
        liveReads++;
        return (lat: 25.05, lng: 121.55);
      },
    );
    expect(await service.lastKnownFix(), (lat: 25.05, lng: 121.55));
    expect(liveReads, 0, reason: 'the live read must not run');
  });

  test('lastKnownFix is null when no cached fix exists', () async {
    final service = LocationService(
      _dir(),
      lastKnown: () async => null,
      fix: () async => (lat: 25.05, lng: 121.55),
    );
    expect(await service.lastKnownFix(), isNull);
  });

  test('a lastKnownFix fault degrades to null, never throws', () async {
    final service = LocationService(
      _dir(),
      lastKnown: () async => throw Exception('platform fault'),
    );
    expect(await service.lastKnownFix(), isNull);
  });

  test('a GPS timeout is a null fix, not a crash', () async {
    final service = LocationService(
      _dir(),
      isAvailable: () async => true,
      fix: () async => throw TimeoutException('gps'),
    );
    expect(await service.currentTown(), isNull);
    expect(await service.currentFix(), isNull);
  });

  test(
    'townAt uses a boundary hit, a miss, and nearest when nothing contains it',
    () async {
      final boundaries = TownBoundaries.fromDecoded({
        '100': {
          'b': [121.5, 25.0, 121.6, 25.1],
          'p': [
            [
              [121.5, 25.0, 121.6, 25.0, 121.6, 25.1, 121.5, 25.1, 121.5, 25.0],
            ],
          ],
        },
        'missing': {
          'b': [120.0, 20.0, 120.1, 20.1],
          'p': [
            [
              [120.0, 20.0, 120.1, 20.0, 120.1, 20.1, 120.0, 20.1, 120.0, 20.0],
            ],
          ],
        },
      });
      final service = LocationService(
        _dir(),
        boundaries: Future.value(boundaries),
      );
      expect((await service.townAt(25.05, 121.55))?.code, '100');
      expect(await service.townAt(20.05, 120.05), isNull);
      expect((await service.townAt(23.99, 121.60))?.code, '970');

      final nearest = LocationService(_dir());
      expect((await nearest.townAt(25.05, 121.55))?.code, '100');
    },
  );

  _platformCases();
}

/// The default geolocator seams. `Platform` stays whatever this host is;
/// the plugin instance is the seam the service already calls.
void _platformCases() {
  group('default geolocator', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    const settingsChannel = MethodChannel(
      'flutter.baseflow.com/permissions/methods',
    );
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    late GeolocatorPlatform original;
    late _FakeGeolocator geo;

    setUp(() {
      original = GeolocatorPlatform.instance;
      geo = _FakeGeolocator();
      GeolocatorPlatform.instance = geo;
    });

    tearDown(() {
      GeolocatorPlatform.instance = original;
      messenger.setMockMethodCallHandler(settingsChannel, null);
      unawaited(geo.statuses.close());
      unawaited(geo.positions.close());
    });

    LocationService service() => LocationService(_dir());

    Position fresh() => _position(DateTime.now());
    Position stale() =>
        _position(DateTime.now().subtract(const Duration(minutes: 11)));
    Position future() =>
        _position(DateTime.now().add(const Duration(minutes: 1)));

    test('status follows services and the permission the OS reports', () async {
      geo.services = false;
      expect(await service().status(), LocationStatus.serviceOff);

      geo.services = true;
      for (final (permission, status) in <(LocationPermission, LocationStatus)>[
        (LocationPermission.always, LocationStatus.ready),
        (LocationPermission.whileInUse, LocationStatus.whileInUseOnly),
        (LocationPermission.deniedForever, LocationStatus.deniedForever),
        (LocationPermission.denied, LocationStatus.denied),
        (LocationPermission.unableToDetermine, LocationStatus.denied),
      ]) {
        geo.permission = permission;
        expect(await service().status(), status);
      }

      geo.throwServices = true;
      expect(await service().status(), LocationStatus.denied);
    });

    test(
      'currentFix prefers a fresh cache and falls through otherwise',
      () async {
        geo
          ..services = true
          ..permission = LocationPermission.whileInUse
          ..lastKnown = fresh();
        expect(await service().currentFix(), (lat: 25.05, lng: 121.55));
        expect(geo.currentCalls, 0);

        geo
          ..lastKnown = stale()
          ..current = _position(
            DateTime.now(),
            latitude: 23.99,
            longitude: 121.6,
          );
        expect(await service().currentFix(), (lat: 23.99, lng: 121.6));
        expect(geo.currentCalls, 1);

        geo
          ..lastKnown = future()
          ..currentCalls = 0;
        expect(await service().currentFix(), (lat: 23.99, lng: 121.6));
        expect(geo.currentCalls, 1);

        geo.lastKnown = null;
        await service().currentFix();
        expect(geo.currentCalls, 2);

        geo.services = false;
        expect(await service().currentFix(), isNull);

        geo
          ..services = true
          ..permission = LocationPermission.denied;
        expect(await service().currentFix(), isNull);

        geo
          ..permission = LocationPermission.always
          ..currentError = TimeoutException('gps');
        expect(await service().currentFix(), isNull);

        geo.currentError = StateError('gps');
        expect(await service().currentFix(), isNull);
      },
    );

    test('permission requests, grants and the settings fallback', () async {
      final location = service();
      geo.permission = LocationPermission.deniedForever;
      expect(
        await location.requestPermission(),
        PermissionOutcome.needsSettings,
      );

      geo
        ..permission = LocationPermission.denied
        ..afterRequest = LocationPermission.whileInUse;
      expect(await location.requestPermission(), PermissionOutcome.granted);

      geo
        ..permission = LocationPermission.denied
        ..afterRequest = LocationPermission.denied;
      expect(await location.requestPermission(), PermissionOutcome.denied);

      geo
        ..permission = LocationPermission.denied
        ..afterRequest = LocationPermission.deniedForever;
      expect(
        await location.requestPermission(),
        PermissionOutcome.needsSettings,
      );

      geo
        ..permission = LocationPermission.always
        ..afterRequest = null;
      expect(await location.requestPermission(), PermissionOutcome.granted);

      geo.throwRequest = true;
      geo.permission = LocationPermission.denied;
      expect(await location.requestPermission(), PermissionOutcome.denied);
      geo.throwRequest = false;

      geo.permission = LocationPermission.whileInUse;
      expect(await location.granted(), isTrue);
      expect(await location.backgroundGranted(), isFalse);
      geo.permission = LocationPermission.always;
      expect(await location.backgroundGranted(), isTrue);
      geo.checkError = StateError('permission');
      expect(await location.granted(), isFalse);
      expect(await location.backgroundGranted(), isFalse);
      geo.checkError = null;

      geo.permission = LocationPermission.always;
      expect(await location.requestBackground(), PermissionOutcome.granted);
      geo.permission = LocationPermission.deniedForever;
      expect(
        await location.requestBackground(),
        PermissionOutcome.needsSettings,
      );
      geo
        ..permission = LocationPermission.whileInUse
        ..afterRequest = LocationPermission.always;
      expect(await location.requestBackground(), PermissionOutcome.granted);
      geo
        ..permission = LocationPermission.whileInUse
        ..afterRequest = LocationPermission.whileInUse;
      expect(
        await location.requestBackground(),
        PermissionOutcome.needsSettings,
      );
      geo.throwRequest = true;
      expect(await location.requestBackground(), PermissionOutcome.denied);

      messenger.setMockMethodCallHandler(settingsChannel, (call) async {
        expect(call.method, 'openAppSettings');
        return true;
      });
      expect(await location.openSettings(), isTrue);
      messenger.setMockMethodCallHandler(settingsChannel, (call) async {
        throw PlatformException(code: 'settings');
      });
      expect(await location.openSettings(), isFalse);
    });

    test('service and position streams forward the plugin', () async {
      final location = service();
      final services = location.serviceEnabledStream().take(2).toList();
      geo.statuses.add(ServiceStatus.enabled);
      geo.statuses.add(ServiceStatus.disabled);
      expect(await services, [true, false]);

      final fixes = location
          .positionStream(distanceFilterMeters: 10)
          .take(1)
          .toList();
      geo.positions.add(
        _position(DateTime.now(), latitude: 23.5, longitude: 121.1),
      );
      expect(await fixes, [(lat: 23.5, lng: 121.1)]);
    });
  });
}

class _FakeGeolocator extends GeolocatorPlatform {
  bool services = true;
  bool throwServices = false;
  bool throwRequest = false;
  LocationPermission permission = LocationPermission.denied;
  LocationPermission? afterRequest;
  Object? checkError;
  Object? currentError;
  Position? lastKnown;
  Position? current;
  int currentCalls = 0;
  final statuses = StreamController<ServiceStatus>();
  final positions = StreamController<Position>();

  @override
  Future<bool> isLocationServiceEnabled() async {
    if (throwServices) throw StateError('services');
    return services;
  }

  @override
  Future<LocationPermission> checkPermission() async {
    final error = checkError;
    if (error != null) throw error;
    return permission;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    if (throwRequest) throw StateError('request');
    final next = afterRequest;
    if (next != null) permission = next;
    return permission;
  }

  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async => lastKnown;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    currentCalls++;
    final error = currentError;
    if (error != null) throw error;
    return current ?? _position(DateTime.now());
  }

  @override
  Stream<ServiceStatus> getServiceStatusStream() => statuses.stream;

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) =>
      positions.stream;
}

Position _position(
  DateTime timestamp, {
  double latitude = 25.05,
  double longitude = 121.55,
}) => Position(
  latitude: latitude,
  longitude: longitude,
  timestamp: timestamp,
  accuracy: 1,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);
