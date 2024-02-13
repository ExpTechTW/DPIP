import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/api.dart';

import 'dart:math';

class ReportPage extends StatefulWidget {
  const ReportPage({Key? key}) : super(key: key);

  static Map<String, dynamic> data = {};

  @override
  _ReportPage createState() => _ReportPage();
}

var data, earthquakeNo = "", earthquakeNo_text = "", level = 0, Lv_str = "";
List<Color> intensity_back = const [
  Color(0xff6B7878),
  Color(0xff1E6EE6),
  Color(0xff32B464),
  Color(0xffFFE05D),
  Color(0xffFFAA13),
  Color(0xffEF700F),
  Color(0xffE60000),
  Color(0xffA00000),
  Color(0xff5D0090),
];
List<Widget> _List_children = <Widget>[];

class _ReportPage extends State<ReportPage> {
  final List<Marker> markers = [];
  List<bool> _expanded = [];

  int randomNum(int max) {
    return Random().nextInt(max) + 1;
  }

   @override
  void initState() {
    render();
    super.initState();
  }

  Future<void> render() async {
    data ??=
        await get("https://lb-${randomNum(4)}.exptech.com.tw/api/v2/eq/report/${ReportPage.data["id"]}");
    earthquakeNo = data['id'].substring(0, 6);
    var last3 = earthquakeNo.substring(earthquakeNo.length - 3);

    if (last3 != '000') {
      earthquakeNo_text = "顯著有感地震";
    } else {
      earthquakeNo_text = "小區域有感地震";
      earthquakeNo = "";
    }

    var keys = data["list"].keys.toList();
    level = data["list"][keys[0]]["int"];
    Lv_str = int_to_str_en(level);
    _expanded = List<bool>.generate(data["list"].length, (index) => false);

    var dateTime = DateTime.fromMillisecondsSinceEpoch(data["time"]);
    var dateStr = "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
    var timeStr = "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}";
    var formatted = "$dateStr $timeStr";

    Marker ep_marker = Marker(
      point: LatLng(
          data["lat"].toDouble(), data["lon"].toDouble()),
      builder: (ctx) => Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.close,
            color: Colors.red,
            size: 24,
          ),
        ],
      ),
    );

    markers.add(ep_marker);

    _List_children = <Widget>[];
    _List_children.add(
      Center(
        child: Container(
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.grey[600],
            borderRadius: BorderRadius.circular(2.5),
          ),
        ),
      ),
    );
    _List_children.add(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
        child: Wrap(
          alignment: WrapAlignment.center, // 用於水平置中Wrap中的子部件
          crossAxisAlignment: WrapCrossAlignment.center, // 用於垂直置中Wrap中的子部件
          spacing: 20, // 水平間隔
          runSpacing: 20, // 垂直間隔，當換行時使用
          children: [
            Text(
              earthquakeNo_text,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              earthquakeNo,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF4C31C),
              ),
            ),
            Wrap(
              alignment: WrapAlignment.center, // 用於水平置中Wrap中的子部件
              crossAxisAlignment: WrapCrossAlignment.center, // 用於垂直置中Wrap中的子部件
              spacing: 20, // 水平間隔
              runSpacing: 20, // 垂直間隔，當換行時使用
              children: [
                Text(
                  "最大震度: ",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  Lv_str,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: intensity_back[level - 1],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    _List_children.add(
      Padding(
        padding: const EdgeInsets.all(5),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xff333439),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "發生時間: ",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      formatted,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "震央位置: ",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      data["loc"]
                          .substring(data["loc"].indexOf("(") + 1,
                              data["loc"].indexOf(")"))
                          .replaceAll("位於", ""),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    // 檢查可用寬度是否足以容納標籤和值
                    // 這裡的 200 是 Text("深度: ") 和 Text("${data["depth"].toStringAsFixed(1)} KM") 結合後的估計寬度
                    // 這個值可能需要根據實際內容和樣式進行調整
                    bool canFit = constraints.maxWidth > 200;

                    if (canFit) {
                      // 如果可以容納，則保持在同一行
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "規模: \u3000 M ${data["mag"].toStringAsFixed(1)}",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            "深度: \u3000 ${data["depth"].toStringAsFixed(1)} KM",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      );
                    } else {
                      // 如果不能容納，則將 "深度" 組合換行
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "規模: \u3000 M ${data["mag"].toStringAsFixed(1)}",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "深度: \u3000 ${data["depth"].toStringAsFixed(1)} KM",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ); //2023/11/4進度，以上暫定已修改完畢
    _List_children.add(
      Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "各地震度",
              style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: Colors.white),
            ),
          ],
        ),
      ),
    );

    data["list"].keys.forEach((area) {
      _expanded.add(false);
      List<Widget> areaChildren = [];
      var maxStationLevel = 0;

      data["list"][area]["town"].keys.forEach((station) {
        var station_level = data["list"][area]["town"][station]["int"];
        var st_Lv_str = int_to_str_en(station_level);
        if (station_level > maxStationLevel) {
          maxStationLevel = station_level;
        }
        Marker marker = Marker(
          point: LatLng(data["list"][area]["town"][station]["lat"].toDouble(),
              data["list"][area]["town"][station]["lon"].toDouble()),
          builder: (ctx) => Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: intensity_back[station_level - 1],
                ),
              ),
              Text(
                st_Lv_str,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        );
        markers.add(marker);

        areaChildren.add(
          Padding(
            padding: const EdgeInsets.all(5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${station}",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      st_Lv_str,
                      style: TextStyle(
                        fontSize: 20,
                        color: intensity_back[station_level - 1],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      });

      _List_children.add(
        Padding(
          padding: const EdgeInsets.all(5),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xff333439),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: ExpansionTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${area}",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      int_to_str_en(maxStationLevel),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: intensity_back[maxStationLevel - 1],
                      ),
                    ),
                  ],
                ),
                children: areaChildren,
              ),
            ),
          ),
        ),
      );
    });

    print(data);
    if (mounted) setState(() {});
    return Future.value();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Stack(
                  children: [
                    // 中央的文本
                    Center(
                      child: Text(
                        "詳細地震報告",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // 左側的返回箭頭按鈕
                    Positioned(
                      left: 0,
                      child: IconButton(
                        icon:
                            Icon(Icons.arrow_back_ios_new, color: Colors.white),
                        onPressed: () {
                          Navigator.pop(context); // 返回上一頁
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 400,
                  child: FlutterMap(
                    // key: ValueKey(_page),
                    // mapController: mapController,
                    options: MapOptions(
                      center: const LatLng(23.8, 120.1),
                      zoom: 7,
                      minZoom: 7,
                      maxZoom: 9,
                      interactiveFlags:
                          InteractiveFlag.all - InteractiveFlag.rotate,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            "https://api.mapbox.com/styles/v1/whes1015/clne7f5m500jd01re1psi1cd2/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1Ijoid2hlczEwMTUiLCJhIjoiY2xuZTRhbmhxMGIzczJtazN5Mzg0M2JscCJ9.BHkuZTYbP7Bg1U9SfLE-Cg",
                      ),
                      MarkerLayer(
                        markers: markers,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.4,
              maxChildSize: 1.0,
              builder:
                  (BuildContext context, ScrollController scrollController) {
                return Container(
                  color: Colors.black.withOpacity(0.8),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context)
                          .copyWith(overscroll: false),
                      child: ListView(
                        controller: scrollController,
                        children: _List_children.toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
