/// Collapsible detail sheet for a tapped point on the disaster-prevention map
/// (AED / restroom / shelter) — same detent mechanics as the station / typhoon
/// panels. The body adapts to whichever sub-layer is selected.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/disaster_map/domain/aed_detail.dart';
import 'package:dpip/features/disaster_map/domain/restroom_detail.dart';
import 'package:dpip/features/disaster_map/domain/shelter_detail.dart';
import 'package:dpip/features/map/presentation/layers/disaster_map_layer.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/color_hex.dart';
import 'package:dpip/shared/map/maps_launcher.dart';
import 'package:dpip/shared/widgets/loading_view.dart';
import 'package:dpip/shared/widgets/sheet_extent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Peek / rest / full sheet for DPM detail.
class DpmSheet extends StatefulWidget {
  const DpmSheet({
    super.key,
    required this.aed,
    required this.restroom,
    required this.shelter,
    required this.onClose,
  });

  final DpmSubLayer<AedDetail> aed;
  final DpmSubLayer<RestroomDetail> restroom;
  final DpmSubLayer<ShelterDetail> shelter;
  final VoidCallback onClose;

  static const double peekExtent = 0.24;
  static const double _rest = 0.42;
  static const double _expanded = 1.0;

  @override
  State<DpmSheet> createState() => _DpmSheetState();
}

class _DpmSheetState extends State<DpmSheet> {
  final ValueNotifier<double> _extent = ValueNotifier(DpmSheet.peekExtent);
  DpmSubLayerBase? _seededSub;
  int? _seededRevision;
  int? _seededId;

  List<DpmSubLayerBase> get _subs => [
    widget.aed,
    widget.restroom,
    widget.shelter,
  ];

  @override
  void dispose() {
    _extent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allState = Listenable.merge([
      for (final s in _subs)
        Listenable.merge([
          s.selectionId,
          s.selectionRevision,
          s.visible,
          for (final f in s.filters.values) f.values,
        ]),
    ]);
    return ListenableBuilder(
      listenable: allState,
      builder: (context, _) {
        DpmSubLayerBase? active;
        for (final s in _subs) {
          if (s.selectionId.value != null) {
            active = s;
            break;
          }
        }
        final selected = active != null;
        final revision = active?.selectionRevision.value ?? 0;
        final selectedId = active?.selectionId.value;
        final initial = selected ? DpmSheet._rest : DpmSheet.peekExtent;
        if (active != _seededSub ||
            revision != _seededRevision ||
            selectedId != _seededId) {
          _seededSub = active;
          _seededRevision = revision;
          _seededId = selectedId;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _extent.value = initial;
          });
        }
        return ExtentSheetChrome(
          extent: _extent,
          keyValue: selected ? 'dpm-${active.id}-$revision' : 'dpm-peek',
          initial: initial,
          min: DpmSheet.peekExtent,
          max: DpmSheet._expanded,
          snapSizes: const [DpmSheet._rest],
          content: (context, scrollController) => ListView(
            controller: scrollController,
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewPaddingOf(context).bottom + AppSpacing.md,
            ),
            children: [
              SheetGrip(extent: _extent),
              if (!selected) _Hint() else _dispatchBody(context, active!),
            ],
          ),
        );
      },
    );
  }

  Widget _dispatchBody(BuildContext context, DpmSubLayerBase sub) {
    final accent =
        colorFromHexRgb(sub.color) ?? Theme.of(context).colorScheme.primary;
    if (identical(sub, widget.aed)) {
      return _AedBody(
        accent: accent,
        detail: widget.aed.detail,
        previewName: widget.aed.previewName,
        previewPlace: widget.aed.previewPlace,
        onClose: widget.onClose,
      );
    }
    if (identical(sub, widget.restroom)) {
      return _RestroomBody(
        accent: accent,
        detail: widget.restroom.detail,
        previewName: widget.restroom.previewName,
        previewPlace: widget.restroom.previewPlace,
        onClose: widget.onClose,
      );
    }
    return _ShelterBody(
      accent: accent,
      detail: widget.shelter.detail,
      previewName: widget.shelter.previewName,
      previewPlace: widget.shelter.previewPlace,
      onClose: widget.onClose,
    );
  }
}

class _Hint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Text(
        l10n.dpmSheetEmpty,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Restroom venue-category label for a `type2` code.
String _restroomCategoryLabel(AppLocalizations l10n, int type2) =>
    switch (type2) {
      1 => l10n.restroomCategoryTransport,
      2 => l10n.restroomCategoryPark,
      3 => l10n.restroomCategoryCommercial,
      4 => l10n.restroomCategoryReligious,
      5 => l10n.restroomCategoryCultural,
      6 => l10n.restroomCategoryGovernment,
      7 => l10n.restroomCategoryWelfare,
      8 => l10n.restroomCategoryTourist,
      9 => l10n.restroomCategoryLeisure,
      10 => l10n.restroomCategoryOther,
      _ => '',
    };

class _AedBody extends StatelessWidget {
  const _AedBody({
    required this.accent,
    required this.detail,
    required this.previewName,
    required this.previewPlace,
    required this.onClose,
  });

  final Color accent;
  final ValueListenable<AedDetail?> detail;
  final ValueListenable<String?> previewName;
  final ValueListenable<String?> previewPlace;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ValueListenableBuilder<AedDetail?>(
      valueListenable: detail,
      builder: (context, d, _) {
        final name = d?.name ?? previewName.value ?? l10n.mapLayerAed;
        final place = d?.place ?? previewPlace.value ?? '';
        return _Header(
          accent: accent,
          icon: Icons.medical_services,
          name: name,
          place: place,
          onClose: onClose,
          mapsTarget: d == null
              ? null
              : MapLaunchTarget(lat: d.lat, lng: d.lng, label: d.name),
          body: d == null
              ? [_Loading()]
              : [
                  _Row(
                    icon: Icons.place_outlined,
                    label: l10n.aedAddress,
                    value: d.address,
                  ),
                  _Row(
                    icon: Icons.map_outlined,
                    label: l10n.aedRegion,
                    value: [
                      d.city,
                      d.district,
                    ].where((s) => s.isNotEmpty).join(' '),
                  ),
                  _Divider(),
                  _Row(
                    icon: Icons.category_outlined,
                    label: l10n.aedCategory,
                    value: d.category,
                  ),
                  _Row(
                    icon: Icons.label_outline,
                    label: l10n.aedType,
                    value: d.type,
                  ),
                  _Row(
                    icon: Icons.description_outlined,
                    label: l10n.aedPlaceDesc,
                    value: d.placeDesc,
                  ),
                  _Row(
                    icon: Icons.notes_outlined,
                    label: l10n.aedDescription,
                    value: d.description,
                  ),
                  _Divider(),
                  _Row(
                    icon: Icons.schedule_outlined,
                    label: l10n.aedHoursWeekday,
                    value: _hours(d.weekdayStart, d.weekdayEnd),
                  ),
                  _Row(
                    icon: Icons.schedule_outlined,
                    label: l10n.aedHoursSaturday,
                    value: _hours(d.saturdayStart, d.saturdayEnd),
                  ),
                  _Row(
                    icon: Icons.schedule_outlined,
                    label: l10n.aedHoursSunday,
                    value: _hours(d.sundayStart, d.sundayEnd),
                  ),
                  _Row(
                    icon: Icons.info_outline,
                    label: l10n.aedOpenRemark,
                    value: d.openRemark,
                  ),
                  _Divider(),
                  _Row(
                    icon: Icons.phone_outlined,
                    label: l10n.aedEmergencyPhone,
                    value: d.emergencyPhone,
                    emphasized: true,
                    onTap: () => _dialPhone(context, d.emergencyPhone),
                  ),
                ],
        );
      },
    );
  }

  static void _dialPhone(BuildContext context, String phone) {
    callPhoneNumber(phone).then((opened) {
      if (!opened && context.mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.mapAppCallFailed)));
      }
    });
  }

  static String _hours(String start, String end) {
    if (start.isEmpty && end.isEmpty) return '';
    if (start.isEmpty) return end;
    if (end.isEmpty) return start;
    return '$start – $end';
  }
}

class _RestroomBody extends StatelessWidget {
  const _RestroomBody({
    required this.accent,
    required this.detail,
    required this.previewName,
    required this.previewPlace,
    required this.onClose,
  });

  final Color accent;
  final ValueListenable<RestroomDetail?> detail;
  final ValueListenable<String?> previewName;
  final ValueListenable<String?> previewPlace;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ValueListenableBuilder<RestroomDetail?>(
      valueListenable: detail,
      builder: (context, d, _) {
        final name = d?.name ?? previewName.value ?? l10n.mapLayerRestroom;
        final place = d?.address ?? previewPlace.value ?? '';
        return _Header(
          accent: accent,
          icon: Icons.wc,
          name: name,
          place: place,
          onClose: onClose,
          mapsTarget: d == null
              ? null
              : MapLaunchTarget(
                  lat: d.latitude,
                  lng: d.longitude,
                  label: d.name,
                ),
          body: d == null
              ? [_Loading()]
              : [
                  _Row(
                    icon: Icons.wc_outlined,
                    label: l10n.restroomTypeLabel,
                    value: DisasterMapLayer.restroomTypeLabel(l10n, d.type),
                  ),
                  _Row(
                    icon: Icons.category_outlined,
                    label: l10n.restroomCategoryLabel,
                    value: _restroomCategoryLabel(l10n, d.type2),
                  ),
                  _Divider(),
                  _Row(
                    icon: Icons.star_outline,
                    label: l10n.restroomGradeLabel,
                    value: _restroomGrade(l10n, d.typegrade),
                    emphasized: true,
                  ),
                ],
        );
      },
    );
  }

  static String _restroomGrade(AppLocalizations l10n, int grade) =>
      switch (grade) {
        3 => l10n.restroomGradeExcellent,
        2 => l10n.restroomGradeGood,
        1 => l10n.restroomGradeAverage,
        -1 => l10n.restroomGradePoor,
        _ => '',
      };
}

class _ShelterBody extends StatelessWidget {
  const _ShelterBody({
    required this.accent,
    required this.detail,
    required this.previewName,
    required this.previewPlace,
    required this.onClose,
  });

  final Color accent;
  final ValueListenable<ShelterDetail?> detail;
  final ValueListenable<String?> previewName;
  final ValueListenable<String?> previewPlace;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ValueListenableBuilder<ShelterDetail?>(
      valueListenable: detail,
      builder: (context, d, _) {
        final name = d?.name ?? previewName.value ?? l10n.mapLayerShelter;
        final place = d?.address ?? previewPlace.value ?? '';
        return _Header(
          accent: accent,
          icon: Icons.home_work,
          name: name,
          place: place,
          onClose: onClose,
          mapsTarget: d == null
              ? null
              : MapLaunchTarget(lat: d.lat, lng: d.lng, label: d.name),
          body: d == null
              ? [_Loading()]
              : [
                  _Row(
                    icon: Icons.groups_outlined,
                    label: l10n.shelterCapacityLabel,
                    value: l10n.shelterCapacityValue(d.capacity),
                    emphasized: true,
                  ),
                  _Divider(),
                  _Row(
                    icon: Icons.category_outlined,
                    label: l10n.shelterCategoryLabel,
                    value: d.category.join(', '),
                  ),
                  _Row(
                    icon: Icons.home_outlined,
                    label: l10n.shelterIndoorLabel,
                    value: d.indoor ? l10n.dpmYes : l10n.dpmNo,
                  ),
                  _Row(
                    icon: Icons.park_outlined,
                    label: l10n.shelterOutdoorLabel,
                    value: d.outdoor ? l10n.dpmYes : l10n.dpmNo,
                  ),
                  _Row(
                    icon: Icons.favorite_outline,
                    label: l10n.shelterVulnerableOkLabel,
                    value: d.vulnerableOk ? l10n.dpmYes : l10n.dpmNo,
                  ),
                ],
        );
      },
    );
  }
}

/// Title row + optional subtitle + detail rows for a DPM point.
///
/// The badge echoes the sub-layer's marker colour, so a sheet about an AED
/// reads as red, a restroom blue, a shelter orange — the header is the one
/// place on the sheet that names which of the three the point is.
class _Header extends StatelessWidget {
  const _Header({
    required this.accent,
    required this.icon,
    required this.name,
    required this.place,
    required this.onClose,
    this.mapsTarget,
    required this.body,
  });

  final Color accent;
  final IconData icon;
  final String name;
  final String place;
  final VoidCallback onClose;
  final MapLaunchTarget? mapsTarget;
  final List<Widget> body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      if (place.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          place,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (mapsTarget != null)
                IconButton.filledTonal(
                  tooltip: l10n.dpmOpenInMaps,
                  onPressed: () => pickAndOpenMapApp(context, mapsTarget!),
                  icon: const Icon(Icons.directions_outlined),
                ),
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: onClose,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...body,
        ],
      ),
    );
  }
}

/// A thin rule grouping related detail rows — the only structure the sheets
/// body gets, so a long AED list reads as address / category / hours / contact
/// instead of one undifferentiated wall.
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Divider(
        height: 1,
        color: Theme.of(context).colorScheme.outlineVariant
            .withValues(alpha: 0.5),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Center(child: InlineLoading()),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.icon,
    this.emphasized = false,
    this.onTap,
  });

  final String label;
  final String value;

  /// Leading glyph for the row, so a long list scans by picture before text.
  final IconData? icon;

  /// Draws the value in the theme's primary colour — for the one number a
  /// reader is actually here for (capacity, grade, emergency phone).
  final bool emphasized;

  /// Makes the whole row tappable (e.g. dialling the emergency phone) and
  /// hints at it with a trailing chevron.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final icon = this.icon;
    final onTap = this.onTap;
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 18, color: colors.onSurfaceVariant),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
                  color: emphasized ? colors.primary : null,
                ),
              ),
            ],
          ),
        ),
        if (onTap != null)
          Icon(Icons.chevron_right, size: 20, color: colors.onSurfaceVariant),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: onTap == null
          ? row
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppSpacing.xs),
              child: row,
            ),
    );
  }
}
