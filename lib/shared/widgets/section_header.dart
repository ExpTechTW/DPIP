import 'package:dpip/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// A settings / menu section header — a small primary-tinted label above a
/// group of rows. Shared so every list groups its sections identically.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});

  /// The section title.
  final String title;

  /// An optional action (e.g. a sort-toggle icon button) aligned to the row's
  /// end — null by default, which renders identically to a plain title.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
