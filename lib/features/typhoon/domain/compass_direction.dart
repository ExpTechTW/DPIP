/// 16-point compass codes (`WNW`, …) → CWA Chinese / English labels.
library;

/// CWA bulletin labels for a track `dir` code. Unknown codes pass through.
({String zh, String en})? compassDirection(String? code) {
  if (code == null || code.isEmpty) return null;
  final key = code.trim().toUpperCase();
  return _table[key];
}

const _table = <String, ({String zh, String en})>{
  'N': (zh: '北', en: 'north'),
  'NNE': (zh: '北北東', en: 'north-northeast'),
  'NE': (zh: '東北', en: 'northeast'),
  'ENE': (zh: '東北東', en: 'east-northeast'),
  'E': (zh: '東', en: 'east'),
  'ESE': (zh: '東南東', en: 'east-southeast'),
  'SE': (zh: '東南', en: 'southeast'),
  'SSE': (zh: '南南東', en: 'south-southeast'),
  'S': (zh: '南', en: 'south'),
  'SSW': (zh: '南南西', en: 'south-southwest'),
  'SW': (zh: '西南', en: 'southwest'),
  'WSW': (zh: '西南西', en: 'west-southwest'),
  'W': (zh: '西', en: 'west'),
  'WNW': (zh: '西北西', en: 'west-northwest'),
  'NW': (zh: '西北', en: 'northwest'),
  'NNW': (zh: '北北西', en: 'north-northwest'),
};
