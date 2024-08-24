import "package:freezed_annotation/freezed_annotation.dart";

part "localization_progress.g.dart";

@JsonSerializable()
class CrowdinLocalizationProgress {
  final String id;
  final String language;
  final double translation;
  final double approval;

  const CrowdinLocalizationProgress({
    required this.id,
    required this.language,
    required this.translation,
    required this.approval,
  });

  factory CrowdinLocalizationProgress.fromJson(Map<String, dynamic> json) =>
      _$CrowdinLocalizationProgressFromJson(json);

  Map<String, dynamic> toJson() => _$CrowdinLocalizationProgressToJson(this);
}
