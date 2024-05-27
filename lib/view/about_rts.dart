import 'dart:io';

import 'package:dpip/util/extension.dart';
import 'package:dpip/view/about_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AboutRts extends StatefulWidget {
  const AboutRts({super.key});

  @override
  _AboutRtsState createState() => _AboutRtsState();
}

class _AboutRtsState extends State<AboutRts> {
  final RtsState rtsState = RtsState();

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text("幫助"),
        ),
        child: ListView(
          children: [
            buildCupertinoListTile(
              context,
              title: "什麼是強震監視器？",
              isExpanded: rtsState.isSeismometerExpanded,
              onTap: () => setState(() => rtsState.toggleSeismometerExpansion()),
              content: const Text(
                "強震監視器是由 TREM （臺灣即時地震監測）觀測到 全臺 現在的震動 做為即時震度顯示的功能。\n\n"
                    "地震發生當下，可以透過站點顏色變化，觀察地震波傳播情形。\n\n"
                    "中央氣象署發布強震即時警報（地震速報）後，圖層上會顯示出 P 波（藍色） S 波（紅色）的預估地震波傳播狀況。\n\n"
                    "顯示的實時震度不是中央氣象署所提供的資料，因此可能與中央氣象署觀測到的震度不一致，應以中央氣象署公布之資訊為主。\n\n"
                    "由於日常雜訊（汽車、工廠、施工等）影響，平時站點可能也會有顏色變化。另外，由於是即時資料，當下無法判斷是否是故障，所以也有可能因為站點故障而改變顏色。",
              ),
            ),
            const Divider(),
            buildCupertinoListTile(
              context,
              title: "關於 TREM-Net",
              isExpanded: rtsState.isTremNetExpanded,
              onTap: () => setState(() => rtsState.toggleTremNetExpansion()),
              content: const Text(
                  "2022 年 6 月初開始於全臺各地部署站點，TREM-Net（TREM 地震觀測網）由兩個觀測網組成，分別為 SE-Net（強震觀測網「加速度儀」）及 MS-Net（微震觀測網「速度儀」），共同紀錄地震時的各項數據。"),
            ),
            const Divider(),
            buildCupertinoListTile(
              context,
              title: "什麼是P波與S波？又分別是代表什麼？",
              isExpanded: rtsState.isWaveExplanationExpanded,
              onTap: () => setState(() => rtsState.toggleWaveExplanationExpansion()),
              content: const Text(
                  "地震發生時因干涉或疊加會產生P波、S波兩種震動波，P波(上下)傳遞速度較快破壞力較小，S波(前後左右) 傳遞速度較慢破壞力大通常是導致災害的的關鍵。"),
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text("幫助"),
        ),
        body: ListView(
          children: [
            ExpansionTile(
              title: const Text("什麼是強震監視器？"),
              childrenPadding: const EdgeInsets.all(16),
              children: [
                Text(
                  "強震監視器是由 TREM （臺灣即時地震監測）觀測到 全臺 現在的震動 做為即時震度顯示的功能。",
                  style: TextStyle(color: context.colors.onSurface, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  "地震發生當下，可以透過站點顏色變化，觀察地震波傳播情形。",
                  style: TextStyle(color: context.colors.onSurface, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  "中央氣象署發布強震即時警報（地震速報）後，圖層上會顯示出 P 波（藍色） S 波（紅色）的預估地震波傳播狀況。",
                  style: TextStyle(color: context.colors.onSurface, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  "顯示的實時震度不是中央氣象署所提供的資料，因此可能與中央氣象署觀測到的震度不一致，應以中央氣象署公布之資訊為主。",
                  style: TextStyle(color: context.colors.onSurface, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  "由於日常雜訊（汽車、工廠、施工等）影響，平時站點可能也會有顏色變化。另外，由於是即時資料，當下無法判斷是否是故障，所以也有可能因為站點故障而改變顏色。",
                  style: TextStyle(color: context.colors.onSurface, fontSize: 16),
                ),
              ],
            ),
            ExpansionTile(
              title: const Text("關於 TREM-Net"),
              childrenPadding: const EdgeInsets.all(16),
              children: [
                Text(
                  "2022 年 6 月初開始於全臺各地部署站點，TREM-Net（TREM 地震觀測網）由兩個觀測網組成，分別為 SE-Net（強震觀測網「加速度儀」）及 MS-Net（微震觀測網「速度儀」），共同紀錄地震時的各項數據。",
                  style: TextStyle(color: context.colors.onSurface, fontSize: 16),
                ),
              ],
            ),
            ExpansionTile(
              title: const Text("什麼是P波與S波？又分別是代表什麼？"),
              childrenPadding: const EdgeInsets.all(16),
              children: [
                Text(
                  "地震發生時因干涉或疊加會產生P波、S波兩種震動波，P波(上下) 傳遞速度較快破壞力較小，S波(前後左右)傳遞速度較慢破壞力大通常是導致災害的的關鍵。",
                  style: TextStyle(color: context.colors.onSurface, fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget buildCupertinoListTile(
      BuildContext context, {
        required String title,
        required bool isExpanded,
        required VoidCallback onTap,
        required Widget content,
      }) {
    return Column(
      children: [
        CupertinoListTile(
          title: Text(title),
          trailing: AnimatedRotation(
            turns: isExpanded ? 0.25 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(CupertinoIcons.right_chevron),
          ),
          onTap: onTap,
        ),
        Visibility(
          visible: isExpanded,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: content,
          ),
        ),
      ],
    );
  }
}
