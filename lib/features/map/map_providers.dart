/// Provider wiring for the map tab.
library;

import 'package:dpip/shared/map/map_immersive.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Map-tab view state shared with the app shell.
///
/// Only one map surface is on screen at a time, so its immersive toggle is one
/// app-wide value rather than state inside the scaffold: `MainShell` has to
/// read the same value to hide the bottom navigation, and it sits above every
/// branch in the tree.
List<SingleChildWidget> mapProviders() => [
  ChangeNotifierProvider(create: (_) => MapImmersiveController()),
];
