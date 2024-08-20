// radar_map.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:dpip/widget/list/time_selector.dart';
import 'package:dpip/widget/map/map.dart';

class RadarMap extends StatefulWidget {
  const RadarMap({Key? key}) : super(key: key);

  @override
  _RadarMapState createState() => _RadarMapState();
}

class _RadarMapState extends State<RadarMap> {
  final mapController = Completer<MapLibreMapController>();
  DateTime _selectedTime = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        DpipMap(
          onMapCreated: (controller) async {
            mapController.complete(controller);
            await controller.setSymbolIconAllowOverlap(true);
            await controller.setSymbolIconIgnorePlacement(true);
          },
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            color: Colors.white.withOpacity(0),
            child: TimeSelector(
              initialTime: _selectedTime,
              onTimeSelected: (time) {
                setState(() {
                  _selectedTime = time;
                });
                // 在這裡添加更新雷達圖層的邏輯
                print("Selected time: $_selectedTime");
              },
            ),
          ),
        ),
      ],
    );
  }
}