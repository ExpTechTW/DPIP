import 'package:dpip/model/report/earthquake_report.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class IntensityList extends StatelessWidget {
  final EarthquakeReport report;

  const IntensityList({super.key, required this.report});

  List<Widget> intensityList(EarthquakeReport report) {
    List<Widget> containers = [];
    for (var area in report.list.entries) {
      for (var town in area.value.town.entries) {
        print(town);
        containers.add(
          Container(
            padding: EdgeInsets.all(8),
            margin: EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  town.key,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  '${town.value.intensity}',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        );
      }
    }
    return containers;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        children: intensityList(report),
      ),
    );
  }
}
