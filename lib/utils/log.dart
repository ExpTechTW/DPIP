import 'package:talker_flutter/talker_flutter.dart';

class TalkerManager {
  TalkerManager._();

  static final Talker _instance = Talker();

  static Talker get instance => _instance;
}
