import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults put the home region first and a change notifies', () {
    final selection = RegionSelection(SettingsStore.inMemory());
    expect(selection.lb, LbRegion.tpe1);
    expect(selection.core, CoreRegion.tnn1);
    expect(selection.lbOrder.first, LbRegion.tpe1);
    expect(selection.coreOrder.first, CoreRegion.tnn1);

    var notified = 0;
    selection.addListener(() => notified++);
    selection.lb = LbRegion.khh1;
    selection.core = CoreRegion.tyo1;
    expect(selection.lbOrder, [LbRegion.khh1, LbRegion.tpe1]);
    expect(selection.coreOrder, [CoreRegion.tyo1, CoreRegion.tnn1]);
    expect(notified, 2);

    selection.lb = LbRegion.khh1;
    expect(notified, 2);
  });
}
