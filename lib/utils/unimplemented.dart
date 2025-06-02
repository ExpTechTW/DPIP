import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';

/// Show a snack bar to indicate that the feature is not implemented.
///
/// This is a temporary helper function for development.
// TODO(kamiya4047): Remove this function after release.
void showUnimplementedSnackBar(BuildContext context) {
  if (!context.mounted) return;

  context.scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Not Implemented')));
}
