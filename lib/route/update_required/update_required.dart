import 'package:dpip/util/extension/build_context.dart';
import 'package:flutter/material.dart';

class UpdateRequiredPage extends StatelessWidget {
  const UpdateRequiredPage({super.key});

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
                Icon(
                  Icons.system_update,
                  size: 120,
                  color: context.colors.onPrimary,
                ),
                const SizedBox(height: 32),
                Text(
                  '發現新版本',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colors.onPrimary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  '更新至最新版本以獲得最佳體驗',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: context.colors.onPrimary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        _buildVersionInfo('目前版本', "1.0.0", Colors.red.shade400),
                        const SizedBox(height: 12),
                        _buildVersionInfo('最新版本', "2.3.4", Colors.green.shade400),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Implement update logic
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: context.colors.onPrimary,
                    backgroundColor: context.colors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: const Text('立即更新', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // TODO: Implement skip logic
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    '暫時略過',
                    style: TextStyle(fontSize: 16, color: Colors.blue.shade700),
                  ),
                ),
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
            color: versionColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            version,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: versionColor,
            ),
          ),
        ),
      ],
    );
  }
}
