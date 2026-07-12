import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// Disaster-event feed. Placeholder pending the events feature.
class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navEvents)),
      body: Center(child: Text(l10n.navEvents)),
    );
  }
}
