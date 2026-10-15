/// The last onboarding step: choose how much to be alerted about — one of the
/// notification presets — instead of nine separate channel decisions.
///
/// It comes after the permissions step on purpose. The choice is written to
/// the server under this device's push token, and a backend that has never
/// seen the token answers 401 until a position has been registered for it;
/// the repository's recovery does that, with the location grant the step
/// before asks for. Asked earlier, the first write on a fresh install would
/// fail for want of a permission the user had not been offered yet.
///
/// Applying is never a condition of finishing: onboarding must not hold the
/// app hostage to a network call. A failure says so, offers a retry — which
/// resumes, since only the channels still differing are sent — and a way
/// through. Leaving that way keeps whatever the server already holds, and
/// every preset and the server's own defaults keep EEW on, so no path out of
/// this page silences earthquake warnings.
///
/// Only first launches see it: `OnboardingStore` gates the whole flow, so an
/// upgrade never rewrites settings someone already chose.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/features/notification/domain/notify_preset.dart';
import 'package:dpip/features/notification/domain/notify_preset_applier.dart';
import 'package:dpip/features/notification/domain/notify_repository.dart';
import 'package:dpip/features/onboarding/presentation/widgets/onboarding_scaffold.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OnboardingNotifyPresetsPage extends StatefulWidget {
  const OnboardingNotifyPresetsPage({
    super.key,
    required this.onFinish,
    this.requestSpacing = NotifyPresetApplier.requestSpacing,
  });

  /// Called once the preset is saved, or when the user leaves without it.
  final VoidCallback onFinish;

  /// The gap between two notify requests (see [NotifyPresetApplier]).
  final Duration requestSpacing;

  @override
  State<OnboardingNotifyPresetsPage> createState() =>
      _OnboardingNotifyPresetsPageState();
}

/// What the step is doing, for the bottom action and the message above it.
enum _Phase { choosing, applying, failed }

class _OnboardingNotifyPresetsPageState
    extends State<OnboardingNotifyPresetsPage> {
  /// Preselected: the combination meant for someone who has not thought about
  /// it yet, which is everyone on this screen.
  NotifyPreset _choice = NotifyPreset.recommended;
  _Phase _phase = _Phase.choosing;

  /// Why the last attempt failed — shown, and announced, above the retry.
  String? _error;

  Future<void> _apply() async {
    final l10n = AppLocalizations.of(context);
    final token = context.read<NotificationService>().token;
    // No token yet is not permanent — iOS hands it over a moment after the
    // notification grant — so it is a failure with a retry, not a dead end.
    if (token == null || token.isEmpty) {
      setState(() {
        _phase = _Phase.failed;
        _error = l10n.notifyUnavailable;
      });
      return;
    }

    setState(() {
      _phase = _Phase.applying;
      _error = null;
    });
    final applier = NotifyPresetApplier(
      context.read<NotifyRepository>(),
      spacing: widget.requestSpacing,
    );
    final result = await applier.apply(
      token,
      _choice,
      isCancelled: () => !mounted,
    );
    if (!mounted) return;
    if (result.isOk) {
      widget.onFinish();
      return;
    }
    setState(() {
      _phase = _Phase.failed;
      _error = l10n.notifySetFailed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final applying = _phase == _Phase.applying;

    // The settings page's labels live in the notification feature's
    // presentation layer, which this feature may not import; the strings are
    // the same keys, so the wording still has one home.
    final options = [
      (
        preset: NotifyPreset.recommended,
        title: l10n.notifyPresetRecommended,
        description: l10n.notifyPresetRecommendedDescription,
        icon: Icons.recommend_outlined,
      ),
      (
        preset: NotifyPreset.all,
        title: l10n.notifyPresetAll,
        description: l10n.notifyPresetAllDescription,
        icon: Icons.notifications_active_outlined,
      ),
      (
        preset: NotifyPreset.emergencyOnly,
        title: l10n.notifyPresetEmergencyOnly,
        description: l10n.notifyPresetEmergencyOnlyDescription,
        icon: Icons.notification_important_outlined,
      ),
    ];

    return OnboardingScaffold(
      requireScrollToEnd: false,
      actionBuilder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_error != null) ...[
            Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          OnboardingCta(
            label: switch (_phase) {
              _Phase.choosing => l10n.onboardingStart,
              _Phase.applying => l10n.notifyPresetApplying,
              _Phase.failed => l10n.commonRetry,
            },
            onPressed: applying ? null : _apply,
          ),
          if (_phase == _Phase.failed)
            TextButton(
              onPressed: widget.onFinish,
              child: Text(l10n.onboardingNotifySkip),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.onboardingNotifyTitle,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.onboardingNotifyBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          RadioGroup<NotifyPreset>(
            groupValue: _choice,
            onChanged: (preset) {
              if (preset == null || applying) return;
              setState(() {
                _choice = preset;
                // A new choice is a fresh attempt, not a retry of the old one.
                _phase = _Phase.choosing;
                _error = null;
              });
            },
            child: Column(
              children: [
                for (final option in options)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _PresetCard(
                      preset: option.preset,
                      title: option.title,
                      description: option.description,
                      icon: option.icon,
                      selected: option.preset == _choice,
                      enabled: !applying,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One preset as a radio card: the same surface and corner as the permission
/// rows on the step before, so the two steps read as one flow, with the
/// chosen card outlined in primary rather than marked by the radio alone.
///
/// A [RadioListTile] underneath, so a screen reader hears a radio button in a
/// group of three, checked or not, and the whole card is the touch target.
class _PresetCard extends StatelessWidget {
  const _PresetCard({
    required this.preset,
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.enabled,
  });

  final NotifyPreset preset;
  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: colors.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.medium,
        side: BorderSide(
          color: selected ? colors.primary : colors.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: RadioListTile<NotifyPreset>(
        value: preset,
        enabled: enabled,
        controlAffinity: ListTileControlAffinity.trailing,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        secondary: Icon(
          icon,
          color: selected ? colors.primary : colors.onSurfaceVariant,
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
