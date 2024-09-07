import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:dpip/api/exptech.dart';
import 'package:dpip/model/weather/weather.dart';

class RankingTemperatureTab extends StatefulWidget {
  const RankingTemperatureTab({super.key});

  @override
  State<RankingTemperatureTab> createState() => _RankingTemperatureTabState();
}

class _RankingTemperatureTabState extends State<RankingTemperatureTab> {
  List<WeatherStation> validWeatherStations = [];

  Future<void> refresh() async {
    final weatherList = await ExpTech().getWeatherList();
    final latestWeatherData = await ExpTech().getWeather(weatherList.last);

    setState(() {
      validWeatherStations = latestWeatherData.where((station) => station.data.air.temperature != -99).toList();
      validWeatherStations.sort((a, b) => b.data.air.temperature.compareTo(a.data.air.temperature));
    });
  }

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Widget _buildListItem(WeatherStation station, int rank) {
    return Row(
      children: [
        _buildRankIndicator(rank),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            "${station.station.name}: ${station.data.air.temperature.toStringAsFixed(1)}°C",
            style: TextStyle(fontSize: rank == 1 ? 20 : 16),
          ),
        ),
      ],
    );
  }

  Widget _buildRankIndicator(int rank) {
    return rank == 1 ? const Icon(Symbols.trophy_rounded) : Text("$rank");
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(),
    );
  }
}
