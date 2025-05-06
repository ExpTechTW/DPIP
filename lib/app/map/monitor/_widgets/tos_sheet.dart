import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:dpip/utils/extensions/build_context.dart';

class TosBottomSheet extends StatefulWidget {
  const TosBottomSheet({super.key});

  @override
  State<TosBottomSheet> createState() => _TosBottomSheetState();
}

class _TosBottomSheetState extends State<TosBottomSheet> {
  bool _isAgreeUnlocked = false;
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.position.atEdge && _controller.position.pixels > 0) {
        setState(() => _isAgreeUnlocked = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  controller: _controller,
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight + 1),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Column(
                              children: [
                                Icon(Symbols.monitor_heart_rounded, size: 36, color: context.colors.secondary),
                                const SizedBox(height: 16),
                                Text(
                                    context.i18n.monitor,
                                    style: context.theme.textTheme.headlineMedium,
                                    textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(context.i18n.trem_service_description, style: context.theme.textTheme.bodyLarge),
                          ),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: context.colors.errorContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              context.i18n.real_time_magnitude_warning,
                              style: context.theme.textTheme.bodyLarge!.copyWith(color: context.colors.onErrorContainer),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: context.colors.errorContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              context.i18n.trem_station_warning,
                              style: context.theme.textTheme.bodyLarge!.copyWith(color: context.colors.onErrorContainer),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: context.colors.surfaceContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(context.i18n.trem_monitor_description, style: context.theme.textTheme.bodyLarge),
                          ),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: context.colors.surfaceContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(context.i18n.station_noise_warning, style: context.theme.textTheme.bodyLarge),
                          ),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: context.colors.surfaceContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(context.i18n.trem_net_deployment, style: context.theme.textTheme.bodyLarge),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: () => context.pop(false), child: Text(context.i18n.disagree)),
                FilledButton(onPressed: _isAgreeUnlocked ? () => context.pop(true) : null, child: Text(context.i18n.agree)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
