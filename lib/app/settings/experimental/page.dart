import 'dart:async';

import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/widgets/list/segmented_list.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class SettingsExperimentalPage extends StatefulWidget {
  const SettingsExperimentalPage({super.key});

  @override
  State<SettingsExperimentalPage> createState() =>
      _SettingsExperimentalPageState();
}

class _SettingsExperimentalPageState extends State<SettingsExperimentalPage> {
  bool _launchToMonitor = Preference.experimentalLaunchToMonitor ?? false;

  Future<void> _showEnableWarningDialog({
    required String featureName,
    required VoidCallback onConfirm,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          _ExperimentalWarningDialog(featureName: featureName),
    );

    if (confirmed == true) {
      onConfirm();
    }
  }

  void _toggleLaunchToMonitor(bool value) {
    if (value) {
      _showEnableWarningDialog(
        featureName: '啟動時進入強震監視器'.i18n,
        onConfirm: () {
          setState(() => _launchToMonitor = true);
          Preference.experimentalLaunchToMonitor = true;
        },
      );
    } else {
      setState(() => _launchToMonitor = false);
      Preference.experimentalLaunchToMonitor = false;
    }
  }

  Widget _buildIconContainer({
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.colors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Symbols.science_rounded,
              color: context.colors.onPrimaryContainer,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '實驗性功能'.i18n,
                  style: context.texts.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '搶先體驗開發中的新功能'.i18n,
                  style: context.texts.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Symbols.warning_rounded,
              color: Colors.amber[700],
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '注意'.i18n,
                  style: context.texts.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.amber[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '這些功能仍在開發中，可能會不穩定或在未來的版本中變更。'.i18n,
                  style: context.texts.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(
        top: 8,
        bottom: 16 + context.padding.bottom,
      ),
      children: [
        _buildHeader(context),
        _buildWarningCard(context),

        // 啟動行為
        SegmentedList(
          label: Text('啟動行為'.i18n),
          children: [
            SegmentedListTile(
              isFirst: true,
              isLast: true,
              leading: _buildIconContainer(
                icon: Symbols.monitor_heart_rounded,
                color: Colors.red,
              ),
              title: Text('啟動時進入強震監視器'.i18n),
              subtitle: Text('開啟 App 時直接進入強震監視器地圖'.i18n),
              trailing: Switch(
                value: _launchToMonitor,
                onChanged: _toggleLaunchToMonitor,
              ),
              onTap: () => _toggleLaunchToMonitor(!_launchToMonitor),
            ),
          ],
        ),
      ],
    );
  }
}

class _ExperimentalWarningDialog extends StatefulWidget {
  final String featureName;

  const _ExperimentalWarningDialog({required this.featureName});

  @override
  State<_ExperimentalWarningDialog> createState() =>
      _ExperimentalWarningDialogState();
}

class _ExperimentalWarningDialogState
    extends State<_ExperimentalWarningDialog> {
  int _countdown = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm = _countdown == 0;

    return AlertDialog(
      icon: Icon(
        Symbols.warning_rounded,
        color: Colors.amber[700],
        size: 48,
      ),
      title: Text('啟用實驗性功能'.i18n),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '你即將啟用：'.i18n,
            style: context.texts.bodyMedium,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Symbols.science_rounded,
                  color: context.colors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.featureName,
                    style: context.texts.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '此功能為實驗性質，可能會造成應用程式不穩定或行為異常。如遇問題，請至設定中關閉此功能。'.i18n,
            style: context.texts.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('取消'.i18n),
        ),
        FilledButton(
          onPressed: canConfirm ? () => Navigator.of(context).pop(true) : null,
          child: Text(
            canConfirm ? '啟用'.i18n : '${_countdown}s',
          ),
        ),
      ],
    );
  }
}
