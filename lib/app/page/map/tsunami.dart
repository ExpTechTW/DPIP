import 'package:dpip/api/exptech.dart';
import 'package:dpip/app/page/map/tsunami_estimate_list.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../model/tsunami/tsunami.dart';

class TsunamiMap extends StatefulWidget {
  const TsunamiMap({super.key});
  @override
  State<StatefulWidget> createState() => _TsunamiMapState();
}

class _TsunamiMapState extends State<TsunamiMap> {
  Tsunami? tsunami;
  String tsunamiStatus = "";
  bool refreshingTsunami = true;
  refreshTsunami() async {
    refreshingTsunami = true;
    var idList = await ExpTech().getTsunamiList();
    var id = "";
    if (idList.isNotEmpty) {
      id = idList[2];
      tsunami = await ExpTech().getTsunami(id);
      (tsunami?.status == 0)
          ? tsunamiStatus = "發布"
          : (tsunami?.status == 1)
              ? tsunamiStatus = "更新"
              : tsunamiStatus = "解除";
    }
    setState(() {
      refreshingTsunami = false;
    });
    return tsunami;
  }

  @override
  void initState() {
    super.initState();
    refreshTsunami();
  }

  @override
  Widget build(BuildContext context) {
    const sheetInitialSize = 0.2;
    return Positioned.fill(
      child: DraggableScrollableSheet(
        initialChildSize: sheetInitialSize,
        minChildSize: sheetInitialSize,
        snap: true,
        builder: (context, scrollController) {
          return Container(
            color: context.colors.surface.withOpacity(0.9),
            child: ListView(
              controller: scrollController,
              children: [
                SizedBox(
                  height: 24,
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.colors.onSurfaceVariant.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20),
                  child: refreshingTsunami == true
                      ? Container()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tsunami == null ? "近期無海嘯資訊" : "海嘯警報",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                color: context.colors.onSurface,
                              ),
                            ),
                            tsunami != null
                                ? Text(
                                    "${tsunami?.id}號 第${tsunami?.serial}報",
                                    style: TextStyle(
                                      fontSize: 14,
                                      letterSpacing: 1,
                                      color: context.colors.onSurface,
                                    ),
                                  )
                                : Container(),
                            Text(
                              "2024/07/01 00:00 $tsunamiStatus",
                              style: TextStyle(
                                fontSize: 14,
                                letterSpacing: 1,
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(
                              height: 30,
                            ),
                            Text(
                              "${tsunami?.content}",
                              style: TextStyle(
                                fontSize: 18,
                                letterSpacing: 2,
                                color: context.colors.onSurface,
                              ),
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            tsunami != null
                                ? tsunami?.info.type == "estimate"
                                    ? Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "預估海嘯到達時間及波高",
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 2,
                                              color: context.colors.onSurface,
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          TsunamiEstimateList(tsunamiList: tsunami!.info.data),
                                        ],
                                      )
                                    : Text(
                                        "各地觀測到的海嘯",
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 2,
                                          color: context.colors.onSurface,
                                        ),
                                      )
                                : Container(),
                          ],
                        ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
