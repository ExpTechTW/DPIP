import 'package:dpip/core/error/failure.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';

ImageSaveFailureReason imageSaveFailureReason(Failure failure) =>
    failure is ImageSaveFailure
    ? failure.reason
    : ImageSaveFailureReason.failed;

extension ReportImageSaveFeedback on ImageSaveFailureReason {
  String message(AppLocalizations l10n) => switch (this) {
    ImageSaveFailureReason.permissionDenied =>
      l10n.reportDetailImageSavePermissionDenied,
    ImageSaveFailureReason.permissionSettingsRequired =>
      l10n.reportDetailImageSaveSettingsRequired,
    ImageSaveFailureReason.permissionRestricted =>
      l10n.reportDetailImageSaveRestricted,
    ImageSaveFailureReason.unavailable => l10n.reportDetailImageSaveUnavailable,
    ImageSaveFailureReason.failed => l10n.reportDetailImageSaveFailed,
  };
}
