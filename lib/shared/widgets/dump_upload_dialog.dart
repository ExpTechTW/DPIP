/// Privacy confirmation shown before a diagnostics dump leaves the device.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// Returns whether sensitive personal values may be included, or null when the
/// user cancels. A fresh dialog always starts private-by-default.
Future<bool?> showDumpUploadDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => const DumpUploadDialog(),
  );
}

class DumpUploadDialog extends StatefulWidget {
  const DumpUploadDialog({super.key});

  @override
  State<DumpUploadDialog> createState() => _DumpUploadDialogState();
}

class _DumpUploadDialogState extends State<DumpUploadDialog> {
  bool _includeSensitive = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      scrollable: true,
      icon: const Icon(Icons.privacy_tip_outlined),
      title: Text(l10n.moreDumpDiagnostics),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.moreDumpDiagnosticsHint),
          const SizedBox(height: AppSpacing.md),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _includeSensitive,
            title: Text(l10n.dumpIncludeSensitive),
            subtitle: Text(l10n.dumpIncludeSensitiveHint),
            onChanged: (value) {
              setState(() => _includeSensitive = value ?? false);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(_includeSensitive),
          icon: const Icon(Icons.cloud_upload_outlined),
          label: Text(l10n.dumpUpload),
        ),
      ],
    );
  }
}
