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
                        spacing: 16,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Column(
                              children: [
                                Icon(Symbols.monitor_heart_rounded, size: 36, color: context.colors.secondary),
                                const SizedBox(height: 16),
                                Text(
                                    '強震監視器',
                                    style: context.theme.textTheme.headlineMedium,
                                    textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('在 DPIP 中可以查看來自 ExpTech 旗下 TREM 之強震監視器服務，請詳細閱讀以下條件，並選擇是否啟用。', style: context.theme.textTheme.bodyLarge),
                          ),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: context.colors.errorContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '顯示的即時震度不是中央氣象署所提供之資料，因此可能與中央氣象署觀測到的結果不一致，應以中央氣象署公布之資訊為主。',
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
                              '強震監視器使用之測站為 ExpTech 所有，不歸中央氣象署管理，請不要向中央氣象署傳遞故障或意見，會造成他們的困擾。',
                              style: context.theme.textTheme.bodyLarge!.copyWith(color: context.colors.onErrorContainer),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: context.colors.surfaceContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text('強震監視器是由 TREM（臺灣即時地震監測）觀測到全臺現在的震動，做為即時震度顯示的功能，地震發生當下可以透過站點顏色變化，觀察地震波傳播情形。', style: context.theme.textTheme.bodyLarge),
                          ),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: context.colors.surfaceContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text('由於日常雜訊（汽車、工廠、施工等）影響，平時站點可能也會有顏色變化。另外，由於是即時資料，當下無法判斷是否是故障，所以也有可能因為站點故障而改變顏色。', style: context.theme.textTheme.bodyLarge),
                          ),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: context.colors.surfaceContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text('2022 年 6 月初開始於全臺各地部署站點，TREM-Net（TREM 地震觀測網）由兩個觀測網組成，分別為 SE-Net（強震觀測網「加速度儀」）及 MS-Net（微震觀測網「速度儀」），共同紀錄地震時的各項數據。', style: context.theme.textTheme.bodyLarge),
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
                TextButton(onPressed: () => context.pop(false), child: const Text('不同意')),
                FilledButton(onPressed: _isAgreeUnlocked ? () => context.pop(true) : null, child: const Text('同意')),
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
