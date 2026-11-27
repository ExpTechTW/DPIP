import 'package:dpip/features/events/presentation/detail/event_type_detail.dart';

/// The detail of announcement.
///
/// Its `addition` is only the push's internal `code`, with no link to open,
/// so there is no summary, and the default report body has no facts to show:
/// the shared page's title and text are the whole announcement.
final class AnnouncementDetail extends EventTypeDetail {
  const AnnouncementDetail();
}
