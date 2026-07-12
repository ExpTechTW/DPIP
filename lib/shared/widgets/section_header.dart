import 'package:dpip/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// A settings / menu section header — a small primary-tinted label above a
/// group of rows. Shared so every list groups its sections identically.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key});

  /// The section title.
  final String title;

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
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
