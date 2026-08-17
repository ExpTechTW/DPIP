/// The contributor strip under a changelog entry — one badge per `@handle`
/// mentioned in the body: avatar + name on a pill background.
///
/// Avatars come from [ChangelogRepository.avatarBytes], so the bytes round-trip
/// the app's ETag store (URL-addressed, like map tiles — revisiting a card is
/// a local read, not a network round trip). Each badge is tappable and opens
/// the contributor's GitHub profile.
library;

import 'dart:typed_data';

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/changelog/domain/changelog_repository.dart';
import 'package:dpip/features/changelog/domain/release_note.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// One row per contributor: overlapping avatar + `@login`, each tappable.
class ContributorStrip extends StatelessWidget {
  const ContributorStrip({super.key, required this.body});

  /// The release body to scan for `@login` handles.
  final String body;

  @override
  Widget build(BuildContext context) {
    final contributors = contributorsFromBody(body);
    if (contributors.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.xs,
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final contributor in contributors)
            _ContributorChip(contributor: contributor),
        ],
      ),
    );
  }
}

/// One badge — avatar + name on a shared pill, opening the profile on tap.
class _ContributorChip extends StatelessWidget {
  const _ContributorChip({required this.contributor});

  final ReleaseContributor contributor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final label = Theme.of(context).textTheme.labelLarge
        ?.copyWith(color: colors.onSurfaceVariant, fontWeight: FontWeight.w600);
    return Material(
      color: colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Avatar(contributor: contributor),
              SizedBox(width: AppSpacing.sm),
              Text(contributor.login, style: label),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final uri = Uri.tryParse(contributor.htmlUrl);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      // A dead profile link is a cosmetic failure — never surface an error for
      // what is, after all, a decorative strip.
    }
  }
}

/// One avatar circle: loads its bytes via the repository (ETag-cached), then
/// paints them; until then it shows the login's initial.
class _Avatar extends StatefulWidget {
  const _Avatar({required this.contributor});

  final ReleaseContributor contributor;

  @override
  State<_Avatar> createState() => _AvatarState();
}

class _AvatarState extends State<_Avatar> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await context.read<ChangelogRepository>().avatarBytes(
      widget.contributor.login,
    );
    if (!mounted) return;
    setState(() {
      _bytes = switch (result) {
        Ok(:final value) => value,
        Err() => null,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 12,
      backgroundColor: colors.surfaceContainerHighest,
      foregroundImage: _bytes == null ? null : MemoryImage(_bytes!),
      child: _bytes == null
          ? Text(
              widget.contributor.login.isEmpty
                  ? '?'
                  : widget.contributor.login[0].toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    );
  }
}
