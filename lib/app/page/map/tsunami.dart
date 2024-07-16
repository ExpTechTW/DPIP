import 'package:dpip/api/exptech.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TsunamiMap extends StatelessWidget {
  const TsunamiMap({super.key});

  refreshTsunami() async {
    var idList = await ExpTech().getTsunamiList();
    var id = idList[0];
    var tsunami = ExpTech().getTsunami(id);
    return tsunami;
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "近期無海嘯資訊",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: context.colors.onSurface,
                        ),
                      ),
                      Text(
                        "2024/07/01 00:00 更新",
                        style: TextStyle(
                          fontSize: 14,
                          letterSpacing: 1,
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
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
