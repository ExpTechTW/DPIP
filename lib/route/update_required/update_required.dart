import 'dart:io';

import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:dpip/app_old/dpip.dart';
import 'package:dpip/global.dart';
import 'package:dpip/utils/extensions/build_context.dart';

class UpdateRequiredPage extends StatelessWidget {
  final bool showSkipButton;
  final String lastVersion;

  const UpdateRequiredPage({super.key, this.showSkipButton = true, this.lastVersion = ''});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [context.colors.primary, context.colors.onPrimary],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.system_update, size: 120, color: context.colors.onPrimary),
                const SizedBox(height: 32),
                Text(
                  '發現新版本',
                  style: context.theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.onPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  '更新至最新版本以獲得最佳體驗',
                  style: context.theme.textTheme.bodyLarge?.copyWith(color: context.colors.onPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        _buildVersionInfo('目前版本', Global.packageInfo.version, Colors.red.shade400),
                        const SizedBox(height: 12),
                        _buildVersionInfo('最新版本', lastVersion, Colors.green.shade400),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    if (Platform.isIOS) {
                      launchUrl(
                        Uri.parse(
                          'https://apps.apple.com/tw/app/dpip-%E7%81%BD%E5%AE%B3%E5%A4%A9%E6%B0%A3%E8%88%87%E5%9C%B0%E9%9C%87%E9%80%9F%E5%A0%B1/id6468026362',
                        ),
                      );
                    } else {
                      launchUrl(Uri.parse('https://play.google.com/store/apps/details?id=com.exptech.dpip'));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: context.colors.onPrimary,
                    backgroundColor: context.colors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                  child: const Text('立即更新', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                if (showSkipButton) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Global.preference.setInt('update-skip', DateTime.now().millisecondsSinceEpoch);
                      Navigator.pop(context);
                      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const Dpip()),
                        (Route<dynamic> route) => false,
                      );
                    },
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: Text('暫時略過', style: TextStyle(fontSize: 16, color: Colors.blue.shade700)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVersionInfo(String label, String version, Color versionColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: versionColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(version, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: versionColor)),
        ),
      ],
    );
  }
}
