/// Locale-aware words for speaking Taiwan's ten-step intensity scale.
library;

/// Returns a TTS-friendly label for a discrete CWA intensity [scale].
///
/// Symbols such as `5⁻` are intentionally avoided: platform speech engines
/// pronounce superscript signs inconsistently. Chinese, Japanese, and Korean
/// get their conventional weak/strong words; the Chinese split levels keep a
/// trailing `等級` because Google zh-TW can swallow a sentence-final `強` even
/// though it reports the utterance as completed. Other locales get unambiguous
/// English words inside their localized sentence.
String spokenIntensityLabel(int scale, String languageTag) {
  final level = scale.clamp(0, 9);
  final language = languageTag.toLowerCase();
  if (language.startsWith('zh')) {
    return const [
      '零級',
      '一級',
      '二級',
      '三級',
      '四級',
      '五弱等級',
      '五強等級',
      '六弱等級',
      '六強等級',
      '七級',
    ][level];
  }
  if (language.startsWith('ja')) {
    return const ['0', '1', '2', '3', '4', '5弱', '5強', '6弱', '6強', '7'][level];
  }
  if (language.startsWith('ko')) {
    return const ['0', '1', '2', '3', '4', '5약', '5강', '6약', '6강', '7'][level];
  }
  return const [
    'zero',
    'one',
    'two',
    'three',
    'four',
    'five lower',
    'five upper',
    'six lower',
    'six upper',
    'seven',
  ][level];
}
