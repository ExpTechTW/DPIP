import 'package:flutter/material.dart';

import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/ui.dart';
import 'package:dpip/utils/extensions/build_context.dart';

class SettingsUnitPage extends StatelessWidget {
  const SettingsUnitPage({super.key});

  static const route = '/settings/unit';

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsUserInterfaceModel>(
      builder: (context, model, child) {
        return ListView(
          padding: EdgeInsets.only(
            top: 16,
            bottom: 16 + context.padding.bottom,
          ),
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildTemperatureCard(context, model),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.colors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Symbols.straighten_rounded,
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
                  '單位設定'.i18n,
                  style: context.texts.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '自訂顯示的度量單位'.i18n,
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

  Widget _buildTemperatureCard(
    BuildContext context,
    SettingsUserInterfaceModel model,
  ) {
    final useFahrenheit = model.useFahrenheit;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => model.setUseFahrenheit(!useFahrenheit),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: useFahrenheit
                        ? Colors.orange.withValues(alpha: 0.15)
                        : Colors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Symbols.thermostat_rounded,
                    color: useFahrenheit ? Colors.orange : Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '使用華氏度'.i18n,
                        style: context.texts.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        useFahrenheit
                            ? '目前使用華氏度 (°F)'.i18n
                            : '目前使用攝氏度 (°C)'.i18n,
                        style: context.texts.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: useFahrenheit,
                  onChanged: (value) => model.setUseFahrenheit(value),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
