import 'package:dpip/core/settings/home_sheet_extent.dart';
import 'package:dpip/features/home/presentation/home_reset_signal.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Home providers: the sheet-extent broadcast (drives the immersive chrome) and
/// the tab-reset signal.
List<SingleChildWidget> homeProviders() => [
  ChangeNotifierProvider(create: (_) => HomeSheetExtent()),
  ChangeNotifierProvider(create: (_) => HomeResetSignal()),
];
