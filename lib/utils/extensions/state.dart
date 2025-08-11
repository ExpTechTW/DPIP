import 'package:flutter/material.dart';

extension StateExtension on State {
  @protected
  // ignore: invalid_use_of_protected_member
  void rebuild([void Function()? fn]) => setState(fn ?? () {});
}
