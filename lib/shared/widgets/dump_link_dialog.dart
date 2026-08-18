/// The dialog shown after a diagnostics dump has been uploaded.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shows [url], which is already on the clipboard.
///
/// A dialog rather than a snackbar: a snackbar times out, and this is a URL
/// somebody has to carry into another app. It should wait for them.
Future<void> showDumpLinkDialog(BuildContext context, String url) {
  return showDialog<void>(
    context: context,
    builder: (context) => DumpLinkDialog(url: url),
  );
}

/// Confirms the upload and shows the link it produced.
class DumpLinkDialog extends StatelessWidget {
  const DumpLinkDialog({required this.url, super.key});

  /// The address the dump can be read at.
  final String url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      icon: const Icon(Icons.cloud_done_outlined),
      title: Text(l10n.dumpUploaded),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.dumpLinkCopied),
          const SizedBox(height: AppSpacing.md),
          // Selectable and shown in full: the clipboard is not the only way
          // this travels — a screenshot of this dialog has to be readable too,
          // and somebody pasting it into a public channel should be able to
          // see what they are about to send.
          SelectableText(
            url,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          // Does not close. The only reason to press it is that the first copy
          // was lost, and a dialog that leaves on the press cannot be pressed
          // twice.
          onPressed: () => Clipboard.setData(ClipboardData(text: url)),
          child: Text(l10n.dumpCopyAgain),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonClose),
        ),
      ],
    );
  }
}
