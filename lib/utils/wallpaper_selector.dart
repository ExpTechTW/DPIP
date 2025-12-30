import 'dart:math' as math;

class WallpaperSelector {
  static const List<String> dayWallpapers = [
    'assets/wallpaper/day/autumn_park.jpg',
    'assets/wallpaper/day/city_foggy.jpg',
    'assets/wallpaper/day/forest_pink_mist.jpg',
    'assets/wallpaper/day/forest_sunray.jpg',
    'assets/wallpaper/day/village_cherry_blossom.jpg',
  ];

  static const List<String> duskWallpapers = [
    'assets/wallpaper/dusk/japanese_rooftop.jpg',
    'assets/wallpaper/dusk/mountain_sunset.jpg',
    'assets/wallpaper/dusk/suburb_sunset.jpg',
    'assets/wallpaper/dusk/vending_machine.jpg',
  ];

  static const List<String> nightWallpapers = [
    'assets/wallpaper/night/cabin_lightning.jpg',
    'assets/wallpaper/night/city_rooftop_stars.jpg',
    'assets/wallpaper/night/city_street_blue.jpg',
    'assets/wallpaper/night/forest_moonlight.jpg',
    'assets/wallpaper/night/halloween_forest.jpg',
    'assets/wallpaper/night/japanese_street_moon.jpg',
    'assets/wallpaper/night/lighthouse_coast.jpg',
    'assets/wallpaper/night/tokyo_alley_neon.jpg',
    'assets/wallpaper/night/town_hillside.jpg',
  ];

  static String selectWallpaper(DateTime utc8Time) {
    final hour = utc8Time.hour;
    final dayOfYear = utc8Time.difference(DateTime(utc8Time.year, 1, 1)).inDays + 1;
    final random = math.Random(utc8Time.year * 365 + dayOfYear);

    if (hour >= 6 && hour < 18) {
      return dayWallpapers[random.nextInt(dayWallpapers.length)];
    } else if (hour >= 18 && hour < 20) {
      return duskWallpapers[random.nextInt(duskWallpapers.length)];
    } else {
      return nightWallpapers[random.nextInt(nightWallpapers.length)];
    }
  }

  static DateTime getUtc8Time() {
    final now = DateTime.now().toUtc();
    return now.add(const Duration(hours: 8));
  }
}

