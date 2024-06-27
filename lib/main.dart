import 'dart:io';

import 'package:dpip/app/android.dart';
import 'package:dpip/app/ios.dart';
import 'package:flutter/material.dart';

void main() {
  if (Platform.isIOS) {
    runApp(const CupertinoDPIP());
  } else {
    runApp(const AndroidDPIP());
  }
}
