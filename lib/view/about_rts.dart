import 'dart:io';

import 'package:dpip/util/extension.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AboutRts extends StatefulWidget {
  const AboutRts({super.key});

  @override
  _AboutRtsState createState() => _AboutRtsState();
}

class _AboutRtsState extends State<AboutRts> {
  bool isExpanded1 = false;
  bool isExpanded2 = false;
  bool isExpanded3 = false;
  bool isExpanded4 = false;

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text("幫助"),
        ),
        child: ListView(
          children: [
            CupertinoListTile(
              title: const Text("什麼是強震監視器？"),
              trailing: AnimatedRotation(
                turns: isExpanded1 ? 0.25 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(CupertinoIcons.right_chevron),
              ),
              onTap: () {
                setState(() {
                  isExpanded1 = !isExpanded1;
                });
              },
            ),
            Visibility(
              visible: isExpanded1,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("強震監視器是由 TREM （臺灣即時地震監測）觀測到 全臺 現在的震動 做為即時震度顯示的功能。"),
                    SizedBox(height: 12),
                    Text("地震發生當下，可以透過站點顏色變化，觀察地震波傳播情形。"),
                    SizedBox(height: 12),
                    Text("中央氣象署發布強震即時警報（地震速報）後，圖層上會顯示出 P 波（藍色） S 波（紅色）的預估地震波傳播狀況。"),
                    SizedBox(height: 12),
                    Text("顯示的實時震度不是中央氣象署所提供的資料，因此可能與中央氣象署觀測到的震度不一致，應以中央氣象署公布之資訊為主。"),
                    SizedBox(height: 12),
                    Text("由於日常雜訊（汽車、工廠、施工等）影響，平時站點可能也會有顏色變化。另外，由於是即時資料，當下無法判斷是否是故障，所以也有可能因為站點故障而改變顏色。"),
                  ],
                ),
              ),
            ),
            const Divider(),
            CupertinoListTile(
              title: const Text("關於 TREM-Net"),
              trailing: AnimatedRotation(
                turns: isExpanded2 ? 0.25 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(CupertinoIcons.right_chevron),
              ),
              onTap: () {
                setState(() {
                  isExpanded2 = !isExpanded2;
                });
              },
            ),
            Visibility(
              visible: isExpanded2,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        "2022 年 6 月初開始於全臺各地部署站點， TREM-Net（TREM 地震觀測網）由兩個觀測網組成，分別為 SE-Net（強震觀測網「加速度儀」）及 MS-Net（微震觀測網「速度儀」），共同紀錄地震時的各項數據。"),
                  ],
                ),
              ),
            ),
            const Divider(),
            CupertinoListTile(
              title: const Text("什麼是P波與S波？又分別是代表什麼？"),
              trailing: AnimatedRotation(
                turns: isExpanded3 ? 0.25 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(CupertinoIcons.right_chevron),
              ),
              onTap: () {
                setState(() {
                  isExpanded3 = !isExpanded3;
                });
              },
            ),
            Visibility(
              visible: isExpanded3,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  ("地震發生時因 干涉 或 疊加 會產生 P波 S波 兩種震動波，P波(上下) 傳遞速度較快 破壞力較小，S波(前後左右) 傳遞速度較慢 破壞力大 通常是導致災害的的關鍵"),
                ),
              ),
            ),
            const Divider(),
            CupertinoListTile(
              title: const Text("TOS服務條款"),
              trailing: AnimatedRotation(
                turns: isExpanded4 ? 0.25 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(CupertinoIcons.right_chevron),
              ),
              onTap: () {
                setState(() {
                  isExpanded4 = !isExpanded4;
                });
              },
            ),
            Visibility(
              visible: isExpanded4,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                    "1. 透過使用服務，用戶被視為已同意使用條款\n2. 禁止未經允許的再分發\n3. 禁止轉售，TREM提供之資訊\n4. 禁止違反法律法規或違反公共秩序和道德的行為\n5. 任何資訊均以CWA中央氣象署發布資訊為準"),
              ),
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
                  "地震發生時因干涉或疊加會產生P波、S波 兩種震動波，P波(上下) 傳遞速度較快破壞力較小，S波(前後左右)傳遞速度較慢破壞力大通常是導致災害的的關鍵。",
                  style: TextStyle(color: context.colors.onSurface, fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }
}
