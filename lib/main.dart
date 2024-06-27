import 'dart:io';

import 'package:dpip/app/android.dart';
import 'package:flutter/material.dart';

void main() {
  if (Platform.isIOS) {
    /* TODO: ios app */
    throw UnimplementedError();
  } else {
    runApp(const AndroidApp());
  }
}
