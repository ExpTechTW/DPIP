part of '../exptech.dart';

/// App meta endpoint methods.
mixin AppEndpoints {
  /// Fetches Crowdin localization progress for all languages.
  Future<Result<List<CrowdinLocalizationProgress>, String>>
  getLocalizationProgress() async {
    try {
      final res = await _dio.get('https://exptech.dev/api/v1/dpip/locale');
      final data = (res.data['data'] as List).cast<Map<String, dynamic>>();
      return Ok(data.map(CrowdinLocalizationProgress.fromMap).toList());
    } catch (_) {
      return const Err('無法從 Crowdin 取得翻譯狀態');
    }
  }

  /// Fetches GitHub release notes for DPIP Pocket.
  Future<Result<List<GithubRelease>, String>> getReleases() async {
    try {
      final res = await _dio.get(
        'https://api.github.com/repos/ExpTechTW/DPIP-Pocket/releases',
      );
      return Ok(
        (res.data as List)
            .cast<Map<String, dynamic>>()
            .map(GithubRelease.fromMap)
            .toList(),
      );
    } catch (_) {
      return const Err('無法從 GitHub 取得更新紀錄');
    }
  }

  /// Fetches the current announcements.
  Future<List<Announcement>> getAnnouncement() async {
    final res = await _dio.get('${api(1)}/v1/dpip/announcement');
    return (res.data as List)
        .map((e) => Announcement.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches the notification history.
  Future<List<NotificationRecord>> getNotificationHistory() async {
    final res = await _dio.get('${api(1)}/v1/notify/history');
    return (res.data as List)
        .map((e) => NotificationRecord.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches server status for the past 24 hours.
  Future<List<ServerStatus>> getStatus() async {
    final res = await _dio.get(
      'https://status.exptech.dev/api/v1/status/data',
      queryParameters: {'duration': '1d'},
    );
    return (res.data as List)
        .map((e) => ServerStatus.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
