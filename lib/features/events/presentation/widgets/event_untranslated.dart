/// The caution that a card is shown in its original text.
library;

import 'package:dpip/app/theme/app_caution.dart';
import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// A small yellow tag on a list row whose card is not translated into the
/// reader's language yet, so the original text below it is not a mistake.
class EventUntranslatedTag extends StatelessWidget {
  const EventUntranslatedTag({super.key});

  @override
  Widget build(BuildContext context) {
    final ink = AppCaution.onContainer(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppCaution.container(context),
        borderRadius: AppRadius.small,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs / 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.translate, size: 12, color: ink),
            const SizedBox(width: AppSpacing.xs),
            Text(
              AppLocalizations.of(context).eventUntranslatedTag,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: ink, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// The yellow notice on a report shown in its original text: its translation
/// into the reader's language is not done yet.
class EventUntranslatedNotice extends StatelessWidget {
  const EventUntranslatedNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final ink = AppCaution.onContainer(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppCaution.container(context),
        borderRadius: AppRadius.small,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.translate, size: 18, color: ink),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                AppLocalizations.of(context).eventUntranslatedNotice,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
