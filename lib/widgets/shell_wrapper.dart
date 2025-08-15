import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ShellWrapper extends StatelessWidget {
  const ShellWrapper(this.child, {super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final canPop = _canPop(context);
    return PopScope(canPop: canPop, child: child);
  }

  bool _canPop(BuildContext context) {
    // Skip if it's not IOS
    if (!Platform.isIOS) return true;

    final matches = GoRouter.of(context).routerDelegate.currentConfiguration.matches;

    final lastMatch = matches.lastOrNull;
    return lastMatch is ShellRouteMatch && _isAtShellRoot(lastMatch) || true;
  }

  /// Loop until we're at the last non-shell route
  bool _isAtShellRoot(ShellRouteMatch match) {
    final lastNested = match.matches.lastOrNull;

    if (lastNested is ShellRouteMatch) {
      return _isAtShellRoot(lastNested);
    }

    // Consider we're at root only if the shell contains one route
    return match.matches.length <= 1;
  }
}
