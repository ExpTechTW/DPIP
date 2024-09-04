import 'dart:io';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/core/ios_get_location.dart';
import 'package:dpip/global.dart';
import 'package:dpip/model/history.dart';
import 'package:flutter/material.dart';

class HistoryLocationTab extends StatefulWidget {
  const HistoryLocationTab({super.key});

  @override
  State<HistoryLocationTab> createState() => _HistoryLocationTabState();
}

class _HistoryLocationTabState extends State<HistoryLocationTab> {
  final list = GlobalKey<RefreshIndicatorState>();
  bool isLoading = true;
  List<History> historyList = [];

  String? city;
  String? town;
  String? region;

  Future<void> refreshHistoryList() async {
    setState(() => isLoading = true);
    try {
      final data = await ExpTech().getHistoryRegion(region!);
      setState(() {
        historyList = data.reversed.toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS && (Global.preference.getBool("auto-location") ?? false)) {
      getSavedLocation();
    }
    final code = Global.preference.getInt("user-code");
    city = Global.location[code.toString()]?.city;
    town = Global.location[code.toString()]?.town;
    region = code.toString();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      key: list,
      child: ListView(),
      onRefresh: refreshHistoryList,
    );
  }
}
