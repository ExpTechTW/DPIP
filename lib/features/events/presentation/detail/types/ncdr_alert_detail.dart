import 'package:dpip/features/events/domain/event_card.dart';
import 'package:dpip/features/events/presentation/detail/event_detail_blocks.dart';
import 'package:dpip/features/events/presentation/detail/event_type_detail.dart';
import 'package:material_ui/material_ui.dart';

/// The detail of thunderstorm, seawave, workSchlClos, debrisFlowLandSlide,
/// roadClose, floodSensor and barrierLake.
///
/// Only `workSchlClos` has a summary: the townships its latest report covers,
/// grouped by city. The others have nothing the title, the text and the facts
/// do not already show — `thunderstorm`, `seawave` and `barrierLake` carry no
/// `addition` and no `area`, `debrisFlowLandSlide`'s `addition` is the light
/// its title names, and `roadClose` / `floodSensor` show their road, place and
/// station as facts. Each report keeps the default body.
final class NcdrAlertDetail extends EventTypeDetail {
  const NcdrAlertDetail();

  @override
  Widget? summary(BuildContext context, EventCardDetail detail) {
    final latest = detail.latest;
    return switch (latest.type) {
      'workSchlClos' => eventAffectedAreasSection(context, latest.area),
      _ => null,
    };
  }
}
