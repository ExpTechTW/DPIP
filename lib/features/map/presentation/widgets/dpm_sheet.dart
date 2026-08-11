/// Collapsible detail sheet for a tapped point on the disaster-prevention map
/// (AED / restroom / shelter) — same detent mechanics as the station / typhoon
/// panels. The body adapts to whichever sub-layer is selected.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/disaster_map/domain/aed_detail.dart';
import 'package:dpip/features/disaster_map/domain/dpm_categories.dart';
import 'package:dpip/features/disaster_map/domain/restroom_detail.dart';
import 'package:dpip/features/disaster_map/domain/shelter_detail.dart';
import 'package:dpip/features/map/presentation/layers/disaster_map_layer.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
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
              if (!selected) ...[
                _Hint(),
                _Filters(restroom: widget.restroom, shelter: widget.shelter),
              ] else
                _dispatchBody(active!),
            ],
          ),
        );
      },
    );
  }

  Widget _dispatchBody(DpmSubLayerBase sub) {
    if (identical(sub, widget.aed)) {
      return _AedBody(
        detail: widget.aed.detail,
        previewName: widget.aed.previewName,
        previewPlace: widget.aed.previewPlace,
        onClose: widget.onClose,
      );
    }
    if (identical(sub, widget.restroom)) {
      return _RestroomBody(
        detail: widget.restroom.detail,
        previewName: widget.restroom.previewName,
        previewPlace: widget.restroom.previewPlace,
        onClose: widget.onClose,
      );
    }
    return _ShelterBody(
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

/// Category filters for the restroom / shelter sub-layers — a chip row per
/// filterable dimension ([DpmSubLayerBase.filters], which the map layer turns
/// into a MapLibre layer filter). Shown at peek, next to the hint; a section
/// hides with its layer.
class _Filters extends StatelessWidget {
  const _Filters({required this.restroom, required this.shelter});

  final DpmSubLayer<RestroomDetail> restroom;
  final DpmSubLayer<ShelterDetail> shelter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final restroomVenue = restroom.filters['type2']!;
    final restroomType = restroom.filters['type']!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (restroom.visible.value) ...[
            _FilterSection(
              title: l10n.dpmFilterSectionRestroom,
              chips: [
                for (final value in DpmCategories.restroom)
                  _categoryChip(
                    context,
                    active: restroomVenue.values,
                    value: value,
                    label: _restroomCategoryLabel(l10n, value),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _FilterSection(
              title: l10n.dpmFilterSectionRestroomType,
              chips: [
                for (final value in DpmCategories.restroomType)
                  _categoryChip(
                    context,
                    active: restroomType.values,
                    value: value,
                    label: DisasterMapLayer.restroomTypeLabel(l10n, value),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (shelter.visible.value)
            _FilterSection(
              title: l10n.dpmFilterSectionShelter,
              chips: [
                for (var i = 0; i < DpmCategories.shelter.length; i++)
                  _categoryChip(
                    context,
                    active: shelter.filters['category']!.values,
                    value: DpmCategories.shelter[i],
                    label: _shelterDisasterLabel(l10n, i),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _categoryChip(
    BuildContext context, {
    required ValueNotifier<Set<Object>> active,
    required Object value,
    required String label,
  }) {
    return FilterChip(
      selected: active.value.contains(value),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      onSelected: (on) {
        final next = Set<Object>.from(active.value);
        if (on) {
          next.add(value);
        } else {
          next.remove(value);
        }
        active.value = next;
      },
    );
  }
}

/// Labelled, horizontally scrollable chip row for one filter group.
class _FilterSection extends StatelessWidget {
  const _FilterSection({required this.title, required this.chips});

  final String title;
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < chips.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.xs),
                chips[i],
              ],
            ],
          ),
        ),
      ],
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

/// Shelter disaster-type label for a [DpmCategories.shelter] index.
String _shelterDisasterLabel(AppLocalizations l10n, int index) =>
    switch (index) {
      0 => l10n.dpmDisasterFlood,
      1 => l10n.dpmDisasterEarthquake,
      2 => l10n.dpmDisasterLandslide,
      3 => l10n.dpmDisasterTsunami,
      4 => l10n.dpmDisasterSlope,
      5 => l10n.dpmDisasterNuclear,
      _ => '',
    };

class _AedBody extends StatelessWidget {
  const _AedBody({
    required this.detail,
    required this.previewName,
    required this.previewPlace,
    required this.onClose,
  });

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
                  _Row(label: l10n.aedAddress, value: d.address),
                  _Row(
                    label: l10n.aedRegion,
                    value: [
                      d.city,
                      d.district,
                    ].where((s) => s.isNotEmpty).join(' '),
                  ),
                  _Row(label: l10n.aedCategory, value: d.category),
                  _Row(label: l10n.aedType, value: d.type),
                  _Row(label: l10n.aedPlaceDesc, value: d.placeDesc),
                  _Row(label: l10n.aedDescription, value: d.description),
                  _Row(
                    label: l10n.aedHoursWeekday,
                    value: _hours(d.weekdayStart, d.weekdayEnd),
                  ),
                  _Row(
                    label: l10n.aedHoursSaturday,
                    value: _hours(d.saturdayStart, d.saturdayEnd),
                  ),
                  _Row(
                    label: l10n.aedHoursSunday,
                    value: _hours(d.sundayStart, d.sundayEnd),
                  ),
                  _Row(label: l10n.aedOpenRemark, value: d.openRemark),
                  _Row(label: l10n.aedEmergencyPhone, value: d.emergencyPhone),
                ],
        );
      },
    );
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
    required this.detail,
    required this.previewName,
    required this.previewPlace,
    required this.onClose,
  });

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
                  _Row(label: l10n.dpmAddress, value: d.address),
                  _Row(
                    label: l10n.restroomTypeLabel,
                    value: DisasterMapLayer.restroomTypeLabel(l10n, d.type),
                  ),
                  _Row(
                    label: l10n.restroomCategoryLabel,
                    value: _restroomCategoryLabel(l10n, d.type2),
                  ),
                  _Row(
                    label: l10n.restroomGradeLabel,
                    value: _restroomGrade(l10n, d.typegrade),
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
    required this.detail,
    required this.previewName,
    required this.previewPlace,
    required this.onClose,
  });

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
                  _Row(label: l10n.shelterAddressLabel, value: d.address),
                  _Row(
                    label: l10n.shelterCapacityLabel,
                    value: l10n.shelterCapacityValue(d.capacity),
                  ),
                  _Row(
                    label: l10n.shelterCategoryLabel,
                    value: d.category.join(', '),
                  ),
                  _Row(
                    label: l10n.shelterIndoorLabel,
                    value: d.indoor ? l10n.dpmYes : l10n.dpmNo,
                  ),
                  _Row(
                    label: l10n.shelterOutdoorLabel,
                    value: d.outdoor ? l10n.dpmYes : l10n.dpmNo,
                  ),
                  _Row(
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
class _Header extends StatelessWidget {
  const _Header({
    required this.icon,
    required this.name,
    required this.place,
    required this.onClose,
    this.mapsTarget,
    required this.body,
  });

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
            children: [
              Icon(icon, color: colors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (mapsTarget != null)
                IconButton(
                  tooltip: l10n.dpmOpenInMaps,
                  onPressed: () => showMapAppPicker(context, mapsTarget!),
                  icon: const Icon(Icons.directions_outlined),
                ),
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: onClose,
                icon: const Icon(Icons.close),
              ),
            ],
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
          const SizedBox(height: AppSpacing.md),
          ...body,
        ],
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
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
