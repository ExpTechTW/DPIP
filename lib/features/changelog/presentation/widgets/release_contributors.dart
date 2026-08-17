/// The contributor strip under a changelog entry — the GitHub release footer
/// look: a stack of avatars for every `@handle` mentioned in the body.
///
/// Avatars come from [ChangelogRepository.avatarBytes], so the bytes round-trip
/// the app's ETag store (URL-addressed, like map tiles — revisiting a card is
/// a local read, not a network round trip). Each slot is one `CircleAvatar`
/// that fills when its bytes arrive and shows the login's initial otherwise.
library;

import 'dart:typed_data';

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/changelog/domain/changelog_repository.dart';
import 'package:dpip/features/changelog/domain/release_note.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// How many avatars show before the rest collapse into a `+N` tail.
const int _maxShown = 4;

/// One row: overlapping avatar circles, then the `+N` overflow pill.
class ContributorStrip extends StatelessWidget {
  const ContributorStrip({super.key, required this.body});

  /// The release body to scan for `@login` handles.
  final String body;

  @override
  Widget build(BuildContext context) {
    final contributors = contributorsFromBody(body);
    if (contributors.isEmpty) return const SizedBox.shrink();
    final shown = contributors.take(_maxShown).toList();
    final avatarWidth = 26 * shown.length - 6 * (shown.length - 1);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          SizedBox(
            width: avatarWidth.toDouble(),
            height: 26,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < shown.length; i++)
                  Positioned(
                    left: (i * 20).toDouble(),
                    child: _Avatar(contributor: shown[i]),
                  ),
              ],
            ),
          ),
          if (contributors.length > _maxShown) ...[
            const SizedBox(width: AppSpacing.xs),
            Text(
              '+${contributors.length - _maxShown}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
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
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // A ring of the card colour keeps overlapping avatars separable.
        border: Border.all(color: colors.surface, width: 2),
      ),
      child: CircleAvatar(
        radius: 13,
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
      ),
    );
  }
}
