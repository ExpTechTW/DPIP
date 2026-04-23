/// Home screen layout providing the [HomeLocationModel] to descendant widgets.
library;

import 'package:dpip/app/home_old/_models/home_location.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Wraps [child] in a [Scaffold] and provides a [HomeLocationModel] scoped to
/// the home feature.
class HomeLayout extends StatelessWidget {
  /// The widget subtree that receives [HomeLocationModel].
  final Widget child;

  /// Creates a [HomeLayout] with the given [child].
  const HomeLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChangeNotifierProvider<HomeLocationModel>(
        create: (context) => HomeLocationModel(),
        child: child,
      ),
    );
  }
}
