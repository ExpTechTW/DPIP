import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/presentation/eew_realtime_controller.dart';
import 'package:dpip/features/earthquake/presentation/widgets/eew_card.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/empty_view.dart';
import 'package:dpip/shared/widgets/realtime_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Earthquake monitor — the live EEW feed rendered through the async-state
/// contract. The calm 99.9%-of-the-time state is "no active alert" over a live
/// feed; a stale/offline feed is flagged, and active alerts are listed.
class EarthquakePage extends StatelessWidget {
  const EarthquakePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.eewTitle)),
      body: Consumer<EewRealtimeController>(
        builder: (context, controller, _) {
          return RealtimeView<List<Eew>>(
            state: controller.state,
            builder: (context, alerts) => alerts.isEmpty
                ? EmptyView(
                    icon: Icons.check_circle_outline,
                    message: l10n.eewNone,
                  )
                : _EewAlertList(alerts: alerts),
          );
        },
      ),
    );
  }
}

/// The active EEW alerts, newest first.
class _EewAlertList extends StatelessWidget {
  const _EewAlertList({required this.alerts});

  final List<Eew> alerts;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      // extendBody: pad the bottom past the nav bar (its height comes through
      // MediaQuery) so the last card can scroll clear of it.
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
      ),
      itemCount: alerts.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => EewCard(eew: alerts[index]),
    );
  }
}
