import 'package:flutter/material.dart';

class WeatherWarning extends StatefulWidget {
  const WeatherWarning({super.key});

  @override
  State<WeatherWarning> createState() => _WeatherWarning();
}

class _WeatherWarning extends State<WeatherWarning> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "頁面製作中",
        style: TextStyle(fontSize: 20, color: Colors.white),
      ),
    );
  }
}
