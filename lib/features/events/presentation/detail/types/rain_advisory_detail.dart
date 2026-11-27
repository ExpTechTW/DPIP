import 'package:dpip/features/events/domain/event_card.dart';
import 'package:dpip/features/events/presentation/detail/event_detail_blocks.dart';
import 'package:dpip/features/events/presentation/detail/event_type_detail.dart';
import 'package:material_ui/material_ui.dart';

/// The detail of heavy-rain, extremely-heavy-rain, torrential-rain and
/// extremely-torrential-rain.
///
/// The summary lists the townships the latest report covers. The `addition`
/// of these types holds only issue bookkeeping (`issueTime`, `released`,
/// `changed`, `end`) with township codes and no place names, so the names come
/// from the report's `area` and the township directory. Each report keeps the
/// default body, which is empty for these types.
final class RainAdvisoryDetail extends EventTypeDetail {
  const RainAdvisoryDetail();

  @override
  Widget? summary(BuildContext context, EventCardDetail detail) =>
      eventAffectedAreasSection(context, detail.latest.area);
}
