import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dpip/features/earthquake/domain/earthquake_report_snapshot.dart';
import 'package:dpip/features/earthquake/domain/earthquake_share_input.dart';
import 'package:flutter/foundation.dart';

final class ReportPictureFixtures {
  ReportPictureFixtures._(this.snapshot, this.stationCount);

  static const _modern = String.fromEnvironment('DPIP_REPORT_PICTURE_CORE_V2');
  static const _historical = String.fromEnvironment(
    'DPIP_REPORT_PICTURE_HISTORICAL',
  );
  static const reportId = '115000-2026-0422-111524';
  static const sourceHash =
      'e6761038a7eea6b8afa58c936693f35d663bd5ca1ecdb2ad4613b72e2d46e4c1';
  static const historicalId = '105006-2016-0206-035726';
  static const _historicalHash =
      '45846febd73dde3e0d2bb29f456093cdb27663dee9b0217a6655c9eaf59a4971';

  final EarthquakeReportSnapshot snapshot;
  final int stationCount;

  static bool get hasVerifiedSource => _modern.isNotEmpty;

  static Uint8List get golden =>
      base64Decode(const String.fromEnvironment('DPIP_REPORT_PICTURE_FIXTURE'));

  static ReportPictureFixtures loadVerified() {
    if (!hasVerifiedSource) {
      throw StateError(
        'Offline fixture missing. Use tool/dev/qa_report_picture.sh.',
      );
    }
    final snapshot = EarthquakeReportSnapshot.decode(
      base64Decode(_modern),
      requestedReportId: reportId,
    );
    final report = snapshot.report;
    final stationCount = report.list.values.fold(
      0,
      (count, area) => count + area.town.length,
    );
    if (!snapshot.hasMatchingReportId ||
        snapshot.bodySha256 != sourceHash ||
        snapshot.sourceNumbers['/mag'] != '3.9' ||
        !report.location.contains('臺東縣近海') ||
        report.list.length != 2 ||
        report.list['臺東縣']?.intensity != 2 ||
        report.list['花蓮縣']?.intensity != 1 ||
        stationCount != 5) {
      throw StateError('Unexpected Core v2 report or source evidence');
    }
    return ReportPictureFixtures._(snapshot, stationCount);
  }

  EarthquakeShareInputV2 verifiedInput() {
    final input = adaptEarthquakeShareSnapshot(
      snapshot,
      identities: VerifiedEarthquakeReportIdentities(
        bodySha256: sourceHash,
        // The Core v2 dataset contract documents this body's 0–9 encoding and
        // `mag` as ML; the adapter no longer assumes that from the report ID.
        scale: ReportIntensityScale.cwa2020,
        magnitudeIsMl: true,
        countyCodes: const {'臺東縣': '10014', '花蓮縣': '10015'},
        stationCodes: const {
          ('臺東縣', '成功'): 'CHK',
          ('臺東縣', '長濱'): 'ECB',
          ('臺東縣', '池上'): 'ECS',
          ('臺東縣', '東河'): 'EDH',
          ('花蓮縣', '紅葉'): 'EHY',
        },
      ),
    );
    if (input is UnsupportedEarthquakeShareInput) throw input;
    final verified = input as EarthquakeShareInputV2;
    final expected = golden;
    if (sha256.convert(expected).toString() !=
            'c1f0964146bf1b2b50b19ea65f7d5b791bf9be02b2a91f52a8851cae6dfb3330' ||
        !listEquals(verified.bytes, expected)) {
      throw StateError(
        'The adapter output differs from the verified Share Input v2 fixture',
      );
    }
    return verified;
  }

  EarthquakeShareInput withoutIdentities() =>
      adaptEarthquakeShareSnapshot(snapshot);

  static EarthquakeShareInput historicalWithoutIdentities() {
    final snapshot = EarthquakeReportSnapshot.decode(
      base64Decode(_historical),
      requestedReportId: historicalId,
    );
    if (snapshot.bodySha256 != _historicalHash) {
      throw StateError('Unexpected historical body');
    }
    return adaptEarthquakeShareSnapshot(
      snapshot,
      identities: VerifiedEarthquakeReportIdentities(
        bodySha256: _historicalHash,
        scale: ReportIntensityScale.cwa2020,
        magnitudeIsMl: true,
        countyCodes: const {},
        stationCodes: const {},
      ),
    );
  }
}
