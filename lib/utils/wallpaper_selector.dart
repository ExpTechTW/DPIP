class WallpaperSelector {
  static String debugWallpaperPath = '';

  static const List<String> dayWallpapers = [
    'assets/wallpaper/day/autumn_park.jpg',
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
    'assets/wallpaper/night/town_hillside.jpg',
  ];

  static int _hashDate(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    return (date.year * 1000 + dayOfYear) % 2147483647;
  }

  static String selectWallpaper(DateTime utc8Time) {
    if (debugWallpaperPath.isNotEmpty) {
      return debugWallpaperPath;
    }

    final hour = utc8Time.hour;
    final dateHash = _hashDate(utc8Time);
    final periodHash = hour >= 6 && hour < 18
        ? 0
        : (hour >= 18 && hour < 20 ? 1 : 2);
    final combinedHash = (dateHash * 3 + periodHash) % 2147483647;

    if (hour >= 6 && hour < 18) {
      final index = combinedHash % dayWallpapers.length;
      return dayWallpapers[index];
    } else if (hour >= 18 && hour < 20) {
      final index = combinedHash % duskWallpapers.length;
      return duskWallpapers[index];
    } else {
      final index = combinedHash % nightWallpapers.length;
      return nightWallpapers[index];
    }
  }

  static DateTime getUtc8Time() {
    final now = DateTime.now().toUtc();
    return now.add(const Duration(hours: 8));
  }
}
