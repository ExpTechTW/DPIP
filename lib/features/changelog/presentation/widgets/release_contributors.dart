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

/// A stack of overlapping contributor avatars, each tappable.
///
/// Avatars come from [ChangelogRepository.avatarBytes], so the bytes round-trip
/// the app's ETag store (URL-addressed, like map tiles — revisiting a card is
/// a local read, not a network round trip).
class ContributorStrip extends StatelessWidget {
  const ContributorStrip({
    super.key,
    required this.body,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.sm,
      AppSpacing.lg,
      AppSpacing.md,
    ),
  });

  /// The release body to scan for `@login` handles.
  final String body;

  /// Outside padding. When the strip shares a row with the release's GitHub
  /// button, the row owns the spacing and this is `EdgeInsets.zero`.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final contributors = contributorsFromBody(body);
    if (contributors.isEmpty) return const SizedBox.shrink();
    const maxAvatars = 5;
    final shown = contributors.take(maxAvatars);
    final hidden = contributors.length - shown.length;
    return Padding(
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: _stackWidth(shown.length),
            height: _Avatar.size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (final (i, contributor) in shown.indexed)
                  Positioned(
                    left: i * (_Avatar.size - _overlap),
                    child: _ContributorAvatar(contributor: contributor),
                  ),
              ],
            ),
          ),
          if (hidden > 0) ...[
            const SizedBox(width: AppSpacing.xs),
            _MoreChip(count: hidden),
          ],
        ],
      ),
    );
  }
}

/// How much of each avatar the next one covers.
const _overlap = 14.0;

double _stackWidth(int count) =>
    count == 0 ? 0 : (count - 1) * (_Avatar.size - _overlap) + _Avatar.size;

/// The tail of a full stack — `+N` for everyone the pile could not hold,
/// tapping it opens the first hidden profile.
class _MoreChip extends StatelessWidget {
  const _MoreChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: _Avatar.size - 4,
      height: _Avatar.size - 4,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.surfaceContainerHighest,
        border: Border.all(color: colors.surface, width: 2),
      ),
      child: Text(
        '+$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 9,
          color: colors.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// One avatar circle: loads its bytes via the repository (ETag-cached), then
/// paints them; until then it shows the login's initial. Opens the profile on
/// tap.
class _ContributorAvatar extends StatelessWidget {
  const _ContributorAvatar({required this.contributor});

  final ReleaseContributor contributor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: contributor.login,
      child: Material(
        color: colors.surfaceContainerHighest,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _open(context),
          child: _Avatar(contributor: contributor),
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

  /// Diameter of the circle, including the border.
  static const size = 28.0;

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
      width: _Avatar.size,
      height: _Avatar.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.surfaceContainerHighest,
        border: Border.all(
          color: colors.surface, // the card behind, so overlaps read as layers
          width: 2,
        ),
      ),
      child: CircleAvatar(
        radius: _Avatar.size / 2 - 2,
        backgroundColor: colors.surfaceContainerHighest,
        foregroundImage: _bytes == null ? null : MemoryImage(_bytes!),
        child: _bytes == null
            ? Text(
                widget.contributor.login.isEmpty
                    ? '?'
                    : widget.contributor.login[0].toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              )
            : null,
      ),
    );
  }
}
