/// Language settings: pick the app-wide UI language, or follow the system.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/settings/language_options.dart';
import 'package:dpip/core/settings/locale_controller.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// A full-screen language list — "follow system" plus every supported language
/// by its own native name (derived from each ARB's `languageName`, never a
/// hardcoded list). The active choice carries a trailing check; tapping one
/// drives the app-wide [LocaleController].
class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = context.watch<LocaleController>().locale;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.languageSettings)),
      body: FutureBuilder<List<LanguageOption>>(
        future: loadLanguageOptions(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LoadingView();
          final options = snapshot.data!;
          return ListView(
            padding: EdgeInsets.only(
              bottom: AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              _LanguageTile(
                label: l10n.languageSystem,
                selected: current == null,
                onTap: () => context.read<LocaleController>().setLocale(null),
              ),
              for (final option in options)
                _LanguageTile(
                  label: option.name,
                  selected: current == option.locale,
                  onTap: () =>
                      context.read<LocaleController>().setLocale(option.locale),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// One language row — its name, and a trailing check when it's the active one.
class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      title: Text(label),
      trailing: selected ? Icon(Icons.check, color: colors.primary) : null,
      onTap: onTap,
    );
  }
}
