import 'package:talker_flutter/talker_flutter.dart';

class CustomLoggerFormatter implements LoggerFormatter {
  const CustomLoggerFormatter();

  @override
  String fmt(LogDetails details, TalkerLoggerSettings settings) {
    final msg = details.message?.toString() ?? '';
    if (!settings.enableColors) {
      return msg;
    }
    return msg.split('\n').map((e) => details.pen.write(e)).join('\n');
  }
}

class TalkerManager {
  TalkerManager._();

  static final Talker _instance = Talker(
    logger: TalkerLogger(formatter: const CustomLoggerFormatter()),
  );

  static Talker get instance => _instance;
}
