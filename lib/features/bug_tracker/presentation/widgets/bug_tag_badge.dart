/// 標籤徽章與篩選 chip — the tracker's known tags, drawn GitHub-issues-style.
///
/// Two renderings share one vocabulary:
///
/// - [BugTagBadge] — the coloured display badge used on cards and headers.
/// - [BugTagFilterChip] — the interactive filter above the list: **unselected
///   reads as quiet neutral grey** so an entire row of filters stays calm;
///   **selected adopts the display badge's colouring** (alpha background +
///   matching border + accent text), referencing the changelog's 測試版 chip
///   construction. The state change is unmistakable without shouting.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:flutter/material.dart';

/// Which known tag this is, driving the badge's icon and accent colour.
enum BugTagKind {
  bug,
  duplicate,
  confirmed,
  improvement,
  api,
  needsInfo,
  inProgress,
  fixed,
  wontfix,
  invalid,
  vulnerability,
  other;

  /// Tags arrive as the forum's bilingual labels; after cleaning they carry
  /// the Chinese head only (`臭蟲`, `處理中`…), so exact Chinese matches lead
  /// and English keywords stay as a tolerant fallback.
  static BugTagKind of(String tag) {
    final t = tag.trim().toLowerCase();
    // l10n-ignore: server tag value
    if (t.contains('duplicate') || tag == '重複') {
      return duplicate;
    }
    // l10n-ignore: server tag value
    if (t.contains('confirmed') || tag == '已確認') {
      return confirmed;
    }
    // l10n-ignore: server tag value
    if (t.contains('fixed') || tag == '已解決') {
      return fixed;
    }
    // l10n-ignore: server tag value
    if (t.contains('wontfix') || tag == '無法解決') {
      return wontfix;
    }
    // l10n-ignore: server tag value
    if (t.contains('invalid') || tag == '無效') {
      return invalid;
    }
    // l10n-ignore: server tag value
    if (t.contains('improvement') || tag == '增強') {
      return improvement;
    }
    // l10n-ignore: server tag value
    if (t.contains('triage') || tag == '需要更多資訊') {
      return needsInfo;
    }
    // l10n-ignore: server tag value
    if (t.contains('progress') || tag == '處理中') {
      return inProgress;
    }
    // l10n-ignore: server tag value
    if (t.contains('vulnerab') || tag == '漏洞') {
      return vulnerability;
    }
    // l10n-ignore: server tag value
    if (t == 'api') {
      return api;
    }
    // l10n-ignore: server tag value
    if (t.contains('bug') || tag == '臭蟲') {
      return bug;
    }
    return other;
  }
}

/// The accent colour each kind renders with — one hue per state, close to
/// GitHub's label palette.
Color bugTagAccent(BugTagKind kind) => switch (kind) {
  BugTagKind.bug => const Color(0xFFD1242F),
  BugTagKind.vulnerability => const Color(0xFFBC4C00),
  BugTagKind.confirmed => const Color(0xFF0969DA),
  BugTagKind.fixed => const Color(0xFF1A7F37),
  BugTagKind.improvement => const Color(0xFF8250DF),
  BugTagKind.api => const Color(0xFF6639BA),
  BugTagKind.inProgress => const Color(0xFFBF8700),
  BugTagKind.needsInfo => const Color(0xFF9A6700),
  BugTagKind.duplicate => const Color(0xFF6E7781),
  BugTagKind.wontfix => const Color(0xFF57606A),
  BugTagKind.invalid => const Color(0xFF0550AE),
  BugTagKind.other => const Color(0xFF6E7781),
};

IconData? _iconFor(BugTagKind kind) => switch (kind) {
  BugTagKind.bug => Icons.bug_report_outlined,
  BugTagKind.vulnerability => Icons.gpp_maybe_outlined,
  BugTagKind.confirmed => Icons.task_alt,
  BugTagKind.fixed => Icons.check_circle_outlined,
  BugTagKind.improvement => Icons.auto_awesome,
  BugTagKind.api => Icons.api,
  BugTagKind.inProgress => Icons.autorenew,
  BugTagKind.needsInfo => Icons.help_outline,
  BugTagKind.duplicate => Icons.content_copy,
  BugTagKind.wontfix => Icons.block,
  BugTagKind.invalid => Icons.cancel_outlined,
  BugTagKind.other => null,
};

/// The coloured display badge — icon plus the tag verbatim on a soft tint of
/// its own accent. Used wherever tags are metadata (cards, headers).
class BugTagBadge extends StatelessWidget {
  const BugTagBadge({super.key, required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kind = BugTagKind.of(tag);
    final accent = bugTagAccent(kind);
    final icon = _iconFor(kind);
    // Same construction as the changelog's type chips: soft alpha fill, a
    // matching hairline border, and the label itself painted in the accent —
    // the colouring effect the 測試版 badge established.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: accent),
            const SizedBox(width: 4),
          ],
          Text(
            tag,
            style: theme.textTheme.labelSmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// The interactive filter chip above the list.
///
/// Unselected is deliberately quiet — neutral grey, matching how GitHub dims
/// labels you haven't picked. Selected adopts the display badge's colouring
/// ([bugTagAccent] tint plus accent text and a check mark), so the active
/// filter reads at a glance.
class BugTagFilterChip extends StatelessWidget {
  const BugTagFilterChip({
    super.key,
    required this.tag,
    required this.selected,
    required this.onSelected,
  });

  final String tag;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final kind = BugTagKind.of(tag);
    final accent = bugTagAccent(kind);
    final icon = _iconFor(kind);
    return InkWell(
      onTap: () => onSelected(!selected),
      borderRadius: AppRadius.small,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          // 選中採測試版 chip 的上色效果（alpha 底＋同色邊框＋accent 文字），
          // 與卡片上的顯示徽章同一族；未選維持安靜的中性灰。
          color: selected
              ? accent.withValues(alpha: 0.14)
              : colors.surfaceContainerHighest,
          borderRadius: AppRadius.small,
          border: Border.all(
            color: selected ? accent : colors.outlineVariant,
            width: selected ? 1.2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 12,
                color: selected ? accent : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              tag,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected ? accent : colors.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: selected ? 0.2 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
