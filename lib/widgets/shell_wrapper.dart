import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

class ShellWrapper extends StatelessWidget {
  final Widget child;

  const ShellWrapper(this.child, {super.key});

  bool _canPop(BuildContext context) {
    final lastMatch =
        context.router.routerDelegate.currentConfiguration.matches.lastOrNull;

    if (lastMatch is ShellRouteMatch) {
      return lastMatch.matches.length == 1;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) =>
      PopScope(canPop: _canPop(context), child: child);
}
