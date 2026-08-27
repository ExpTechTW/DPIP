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
///
/// The vocabulary is the tracker forum's, narrowed to what a DPIP reader can
/// actually see. The forum declares nineteen tags; seven of them —
/// `station`, `trem_lite`, `trem_variety`, `rts_map`, `es_net_wave`, `web`,
/// `plugin` — belong to ExpTech's other products, and the index endpoint is
/// already filtered to `dpip`, so they cannot arrive here. Measured over the
/// 200 most recent threads: `bug` 111, `fixed` 77, `confirmed` 44, `invalid`
/// 30, `in_triage` 23, `api` 22, `duplicate` 17, `improvement` 11,
/// `processing` 3, `wontfix` 2 — and `dpip` on all 200, which is why the data
/// layer drops it rather than rendering a badge that says nothing.
///
/// `vulnerability` has not appeared in that window but is kept: it is declared,
/// it is a security state, and falling through to neutral grey is the wrong
/// way to find that out.
enum BugTagKind {
  bug,
  duplicate,
  confirmed,
  improvement,
  api,
  inTriage,
  processing,
  fixed,
  wontfix,
  invalid,
  vulnerability,
  other;

  /// Tags reach the UI canonicalised to the forum's slugs by the data layer,
  /// so an exact match leads. The bilingual labels stay as a fallback — the
  /// detail endpoint still reflects Discord's raw `臭蟲 bug` form, and a body
  /// replayed from the offline store predates the canonicalisation.
  static BugTagKind of(String tag) {
    final trimmed = tag.trim();
    final space = trimmed.lastIndexOf(' ');
    final slug = (space < 0 ? trimmed : trimmed.substring(space + 1))
        .toLowerCase();
    return switch (slug) {
      // l10n-ignore: server tag value
      'bug' => BugTagKind.bug,
      // l10n-ignore: server tag value
      'duplicate' => BugTagKind.duplicate,
      // l10n-ignore: server tag value
      'confirmed' => BugTagKind.confirmed,
      // l10n-ignore: server tag value
      'improvement' => BugTagKind.improvement,
      // l10n-ignore: server tag value
      'api' => BugTagKind.api,
      // l10n-ignore: server tag value
      'in_triage' => BugTagKind.inTriage,
      // l10n-ignore: server tag value
      'processing' => BugTagKind.processing,
      // l10n-ignore: server tag value
      'fixed' => BugTagKind.fixed,
      // l10n-ignore: server tag value
      'wontfix' => BugTagKind.wontfix,
      // l10n-ignore: server tag value
      'invalid' => BugTagKind.invalid,
      // l10n-ignore: server tag value
      'vulnerability' => BugTagKind.vulnerability,
      _ => _fromLabel(trimmed),
    };
  }

  /// The Chinese head of a bilingual label, for payloads that never went
  /// through canonicalisation.
  static BugTagKind _fromLabel(String tag) => switch (tag) {
    // l10n-ignore: server tag value
    '臭蟲' => BugTagKind.bug,
    // l10n-ignore: server tag value
    '重複' => BugTagKind.duplicate,
    // l10n-ignore: server tag value
    '已確認' => BugTagKind.confirmed,
    // l10n-ignore: server tag value
    '增強' => BugTagKind.improvement,
    // l10n-ignore: server tag value
    '需要更多資訊' => BugTagKind.inTriage,
    // l10n-ignore: server tag value
    '處理中' => BugTagKind.processing,
    // l10n-ignore: server tag value
    '已解決' => BugTagKind.fixed,
    // l10n-ignore: server tag value
    '無法解決' => BugTagKind.wontfix,
    // l10n-ignore: server tag value
    '無效' => BugTagKind.invalid,
    // l10n-ignore: server tag value
    '漏洞' => BugTagKind.vulnerability,
    _ => BugTagKind.other,
  };
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
  BugTagKind.processing => const Color(0xFFBF8700),
  BugTagKind.inTriage => const Color(0xFF9A6700),
  BugTagKind.duplicate => const Color(0xFF6E7781),
  BugTagKind.wontfix => const Color(0xFF57606A),
  BugTagKind.invalid => const Color(0xFF0550AE),
  BugTagKind.other => const Color(0xFF6E7781),
};

/// The tag's display name, in formal Taiwanese Traditional Chinese.
///
/// Hardcoded rather than routed through `AppLocalizations`, by decision: this
/// is a fixed eleven-word vocabulary owned by the tracker, the tracker itself
/// is Chinese-only, and every thread it lists has a Chinese title and body. A
/// reader who cannot read the threads gains nothing from a translated badge.
/// The same call was made for the notification test payloads.
///
/// The forum's own Chinese labels are looser than these — `臭蟲` for a bug,
/// `無法解決` for wontfix (which says "cannot", where the tag means "will
/// not"), `已解決` for fixed (resolved, not repaired). These are the formal
/// readings of what the slug actually means.
///
/// An unknown tag falls through to its raw slug: better a reader sees
/// `es_net_wave` than a badge that has silently invented a name for it.
String bugTagLabel(BugTagKind kind, String raw) => switch (kind) {
  // l10n-ignore: tracker vocabulary, Chinese-only by design
  BugTagKind.bug => '錯誤',
  // l10n-ignore: tracker vocabulary, Chinese-only by design
  BugTagKind.inTriage => '待分類',
  // l10n-ignore: tracker vocabulary, Chinese-only by design
  BugTagKind.confirmed => '已確認',
  // l10n-ignore: tracker vocabulary, Chinese-only by design
  BugTagKind.processing => '處理中',
  // l10n-ignore: tracker vocabulary, Chinese-only by design
  BugTagKind.fixed => '已修復',
  // l10n-ignore: tracker vocabulary, Chinese-only by design
  BugTagKind.wontfix => '不予修復',
  // l10n-ignore: tracker vocabulary, Chinese-only by design
  BugTagKind.invalid => '無效',
  // l10n-ignore: tracker vocabulary, Chinese-only by design
  BugTagKind.duplicate => '重複回報',
  // l10n-ignore: tracker vocabulary, Chinese-only by design
  BugTagKind.improvement => '功能改進',
  // l10n-ignore: tracker vocabulary, Chinese-only by design
  BugTagKind.vulnerability => '安全漏洞',
  // l10n-ignore: an acronym, and read as one in Taiwan
  BugTagKind.api => 'API',
  BugTagKind.other => raw,
};

IconData? _iconFor(BugTagKind kind) => switch (kind) {
  BugTagKind.bug => Icons.bug_report_outlined,
  BugTagKind.vulnerability => Icons.gpp_maybe_outlined,
  BugTagKind.confirmed => Icons.task_alt,
  BugTagKind.fixed => Icons.check_circle_outlined,
  BugTagKind.improvement => Icons.auto_awesome,
  BugTagKind.api => Icons.api,
  BugTagKind.processing => Icons.autorenew,
  BugTagKind.inTriage => Icons.help_outline,
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
            bugTagLabel(kind, tag),
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
              bugTagLabel(kind, tag),
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
