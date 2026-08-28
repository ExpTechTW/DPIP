/// Tells the user, once, that a newer build of their channel exists.
///
/// Mounted in the app shell, it renders nothing: one check after the first
/// frame, and a dialog only if there is something to say. The check is cheap
/// and mostly free — it reuses the changelog's GitHub request, which is
/// ETag-revalidated and gzip-negotiated by [ApiClient], so a launch with no new
/// release costs a `304` with an empty body.
///
/// Everything that decides *whether* to speak is pure and lives in
/// `update_check.dart`; this file only performs the effects — read the version,
/// ask the platform where the build came from, fetch, remember, show.
library;

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/version/app_build.dart';
import 'package:dpip/core/platform/install_source.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/changelog/domain/changelog_repository.dart';
import 'package:dpip/features/changelog/domain/release_note.dart';
import 'package:dpip/features/changelog/domain/update_check.dart';
import 'package:dpip/features/changelog/domain/update_destination.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdatePrompt extends StatefulWidget {
  const UpdatePrompt({super.key});

  @override
  State<UpdatePrompt> createState() => _UpdatePromptState();
}

class _UpdatePromptState extends State<UpdatePrompt> {
  @override
  void initState() {
    super.initState();
    // After the first frame: a launch must not wait on GitHub, and a dialog
    // needs a Navigator that is already mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    // Read the providers before any await — the element may be gone after.
    final settings = context.read<SettingsStore>();
    final repository = context.read<ChangelogRepository>();
    try {
      final info = await PackageInfo.fromPlatform();
      final source = await InstallSourceService.load();
      final result = await repository.releases();
      final releases = result.valueOrNull;
      if (releases == null) {
        // A failed check is silence, not an error banner: the app works fine
        // on the version it has, and there is nothing the user could do.
        Log.debug('update check: ${result.failureOrNull}');
        return;
      }
      final update = findUpdate(
        releases: releases,
        currentVersion: info.version,
        currentBuild: AppBuild.code,
        promptedVersion: settings.getString(SettingKeys.updatePromptedVersion),
        promptedBuild: settings.getInt(SettingKeys.updatePromptedBuild) ?? 0,
        installSource: source,
      );
      Log.info(
        'update check: current=${AppBuild.label} build=${AppBuild.code} '
        'source=${source.name} offer=${update?.tagName ?? 'none'}',
      );
      if (update == null || !mounted) return;

      // Recorded *before* showing, so this version is offered exactly once —
      // whichever button ends the dialog, and even if the process is killed
      // while it is on screen. A user who wants it again has the changelog.
      await settings.setString(
        SettingKeys.updatePromptedVersion,
        update.tagName,
      );
      final code = buildCodeOf(update);
      if (code != null) {
        await settings.setInt(SettingKeys.updatePromptedBuild, code);
      }
      if (!mounted) return;
      await _show(update, source);
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'update check');
    }
  }

  Future<void> _show(ReleaseNote update, InstallSource source) async {
    final l10n = AppLocalizations.of(context);
    final version = update.tagName.startsWith('v')
        ? update.tagName
        : 'v${update.tagName}';
    final action = await showDialog<_UpdateAction>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.system_update_outlined),
        title: Text(l10n.updateAvailableTitle),
        content: Text(l10n.updateAvailableBody(version)),
        // A regular AlertDialog OverflowBar stacks these three buttons at the
        // trailing edge on a phone, making them look detached from each other.
        // Keep the two alternatives together and give the primary destination
        // a stable, full-width row at every supported phone width.
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () =>
                          Navigator.pop(context, _UpdateAction.skip),
                      child: Text(l10n.updateSkip),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () =>
                          Navigator.pop(context, _UpdateAction.changelog),
                      child: Text(l10n.updateViewChangelog),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                onPressed: () => Navigator.pop(context, _UpdateAction.update),
                child: Text(_updateLabel(l10n, source)),
              ),
            ],
          ),
        ],
      ),
    );
    if (!mounted) return;
    switch (action) {
      case _UpdateAction.changelog:
        context.pushNamed(AppRoutes.changelog);
      case _UpdateAction.update:
        await _openStore(source, update.htmlUrl);
      case _UpdateAction.skip:
      case null:
        break;
    }
  }

  /// The update button names where it goes — a tester sent to TestFlight and a
  /// user sent to the App Store are different promises.
  String _updateLabel(AppLocalizations l10n, InstallSource source) =>
      switch (source) {
        InstallSource.appStore => l10n.updateOpenAppStore,
        InstallSource.testFlight => l10n.updateOpenTestFlight,
        InstallSource.playStore => l10n.updateOpenPlayStore,
        InstallSource.development ||
        InstallSource.github ||
        InstallSource.unknown => l10n.updateDownload,
      };

  Future<void> _openStore(InstallSource source, String releaseUrl) async {
    final destination = updateDestinationFor(source, releaseUrl: releaseUrl);
    for (final url in {destination.scheme, destination.web}) {
      try {
        if (await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        )) {
          return;
        }
        // `false` means nothing handled it — the store app isn't installed.
        Log.warning('update: $url was not handled');
      } catch (error, stackTrace) {
        Log.handle(error, stackTrace, 'open update destination $url');
      }
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

enum _UpdateAction { skip, changelog, update }
