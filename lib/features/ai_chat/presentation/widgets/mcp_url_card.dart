/// The DPIP MCP server's address, for people building their own tools on it.
library;

import 'dart:convert';

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/network/api_paths.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class McpUrlCard extends StatelessWidget {
  const McpUrlCard({super.key});

  /// The shape most MCP clients take for a remote (Streamable HTTP) server.
  static final String configExample = const JsonEncoder.withIndent('  ')
      .convert({
        'mcpServers': {
          'dpip': {'type': 'http', 'url': ApiPaths.mcpPublicUrl},
        },
      });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final mono = theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace');
    return Material(
      color: colors.surfaceContainer,
      borderRadius: AppRadius.medium,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.aiMcpTitle, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.aiMcpBody,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SelectableText(ApiPaths.mcpPublicUrl, style: mono),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _copy(context, ApiPaths.mcpPublicUrl),
                  icon: const Icon(Icons.content_copy_outlined),
                  label: Text(l10n.aiMcpCopyUrl),
                ),
                OutlinedButton.icon(
                  onPressed: () => _copy(context, configExample),
                  icon: const Icon(Icons.data_object_outlined),
                  label: Text(l10n.aiMcpCopyConfig),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).aiMcpCopied)),
      );
  }
}
