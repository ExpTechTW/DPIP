import 'package:dpip/view/welcome/welcome_notify.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../global.dart';

class WelcomeEarthquakePage extends StatefulWidget {
  const WelcomeEarthquakePage({Key? key}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _WelcomeEarthquakePageState();
}

class _WelcomeEarthquakePageState extends State<WelcomeEarthquakePage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("強震監視器"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "請詳閱以下說明後，再選擇是否開啟強震監視器功能",
                style: TextStyle(fontSize: 16),
              ),
              Flexible(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.lerp(const Color(0xFF009E8B), Colors.transparent, 0.5)!,
                          Color.lerp(const Color(0xFF203864), Colors.transparent, 0.5)!
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(color: const Color(0xFF606060), width: 2),
                    ),
                    child: const Markdown(
                      data: "- 強震監視器是由 TREM（臺灣即時地震監測）觀測到 全臺 現在的震動做為即時震度顯示的功能。\n"
                          "- 地震發生當下，可以透過站點顏色變化，觀察地震波傳播情形。\n"
                          "- 中央氣象署發布強震即時警報（地震速報）後，圖層上會顯示出 P 波（藍色）S 波（紅色）的預估地震波傳播狀況。\n"
                          "- 顯示的即時震度不是中央氣象署所提供的資料，因此可能與中央氣象署觀測到的震度不一致，應以中央氣象署公布之資訊為主。\n"
                          "- 由於日常雜訊（汽車、工廠、施工等）影響，平時站點可能也會有顏色變化。另外，由於是即時資料，當下無法判斷是否是故障，所以也有可能因為站點故障而改變顏色。"
                          "\n"
                          "### 注意：若關閉此功能，也無法看到地圖上發布中的地震速報。",
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF009E8B), Color(0xFF203864)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          await Global.preference.setBool("monitor", true);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const WelcomeNotifyPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                        ),
                        child: const Text(
                          "開啟",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Container(
                      decoration:
                          BoxDecoration(borderRadius: BorderRadius.circular(15), color: const Color(0xFF505050)),
                      child: ElevatedButton(
                        onPressed: () async {
                          await Global.preference.setBool("monitor", false);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const WelcomeNotifyPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                        ),
                        child: const Text(
                          "不開啟",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
