/// Collapsible detail sheet for a tapped AED on the disaster-prevention map.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/disaster_map/domain/aed_detail.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Peek / rest / full sheet for AED detail — same detent mechanics as the
/// station / typhoon panels.
class AedSheet extends StatefulWidget {
  const AedSheet({
    super.key,
    required this.selectionId,
    required this.selectionRevision,
    required this.detail,
    required this.previewName,
    required this.previewPlace,
    required this.onClose,
  });

  final ValueListenable<int?> selectionId;
  final ValueListenable<int> selectionRevision;
  final ValueListenable<AedDetail?> detail;
  final ValueListenable<String?> previewName;
  final ValueListenable<String?> previewPlace;
  final VoidCallback onClose;

  static const double peekExtent = 0.14;
  static const double _rest = 0.42;
  static const double _expanded = 1.0;
  static const double _atTopEpsilon = 0.02;

  static bool _isAtTop(double extent) => extent >= _expanded - _atTopEpsilon;

  @override
  State<AedSheet> createState() => _AedSheetState();
}

class _AedSheetState extends State<AedSheet> {
  final ValueNotifier<double> _extent = ValueNotifier(AedSheet.peekExtent);
  int? _seededRevision;
  int? _seededId;

  @override
  void dispose() {
    _extent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return ValueListenableBuilder<int>(
      valueListenable: widget.selectionRevision,
      builder: (context, revision, _) => ValueListenableBuilder<int?>(
        valueListenable: widget.selectionId,
        builder: (context, selectedId, _) {
          final selected = selectedId != null;
          final initial = selected ? AedSheet._rest : AedSheet.peekExtent;
          if (revision != _seededRevision || selectedId != _seededId) {
            _seededRevision = revision;
            _seededId = selectedId;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _extent.value = initial;
            });
          }
          return NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              _extent.value = notification.extent;
              return false;
            },
            child: Align(
              alignment: Alignment.bottomCenter,
              child: DraggableScrollableSheet(
                key: ValueKey(selected ? 'aed-$revision' : 'aed-peek'),
                expand: false,
                initialChildSize: initial,
                minChildSize: AedSheet.peekExtent,
                maxChildSize: AedSheet._expanded,
                snap: true,
                snapSizes: const [AedSheet._rest],
                builder: (context, scrollController) {
                  return ValueListenableBuilder<double>(
                    valueListenable: _extent,
                    builder: (context, extent, _) {
                      final atTop = AedSheet._isAtTop(extent);
                      final topInset = MediaQuery.viewPaddingOf(context).top;
                      return AnnotatedRegion<SystemUiOverlayStyle>(
                        value: SystemUiOverlayStyle(
                          statusBarColor: atTop
                              ? colors.surface
                              : Colors.transparent,
                          statusBarIconBrightness:
                              theme.brightness == Brightness.dark
                              ? Brightness.light
                              : Brightness.dark,
                          statusBarBrightness: theme.brightness,
                        ),
                        child: _Surface(
                          flushTop: atTop,
                          child: Padding(
                            padding: EdgeInsets.only(top: atTop ? topInset : 0),
                            child: ListView(
                              controller: scrollController,
                              padding: EdgeInsets.only(
                                bottom:
                                    MediaQuery.viewPaddingOf(context).bottom +
                                    AppSpacing.md,
                              ),
                              children: [
                                _Grip(extent: _extent),
                                if (!selected)
                                  _Hint()
                                else
                                  _Body(
                                    detail: widget.detail,
                                    previewName: widget.previewName,
                                    previewPlace: widget.previewPlace,
                                    onClose: widget.onClose,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child, this.flushTop = false});

  final Widget child;
  final bool flushTop;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = flushTop ? BorderRadius.zero : AppRadius.topSheet;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: radius,
        boxShadow: flushTop
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, -2),
                ),
              ],
      ),
      child: ClipRRect(borderRadius: radius, child: child),
    );
  }
}

class _Grip extends StatefulWidget {
  const _Grip({required this.extent});

  final ValueListenable<double> extent;

  @override
  State<_Grip> createState() => _GripState();
}

class _GripState extends State<_Grip> {
  late bool _show = !AedSheet._isAtTop(widget.extent.value);

  @override
  void initState() {
    super.initState();
    widget.extent.addListener(_onExtent);
  }

  @override
  void didUpdateWidget(_Grip old) {
    super.didUpdateWidget(old);
    if (old.extent != widget.extent) {
      old.extent.removeListener(_onExtent);
      widget.extent.addListener(_onExtent);
      _onExtent();
    }
  }

  @override
  void dispose() {
    widget.extent.removeListener(_onExtent);
    super.dispose();
  }

  void _onExtent() {
    final next = !AedSheet._isAtTop(widget.extent.value);
    if (next == _show) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final show = !AedSheet._isAtTop(widget.extent.value);
      if (show != _show) setState(() => _show = show);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: colors.onSurfaceVariant.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
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
        AppSpacing.lg,
      ),
      child: Text(
        l10n.aedSheetEmpty,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return ValueListenableBuilder<AedDetail?>(
      valueListenable: detail,
      builder: (context, d, _) {
        final name = d?.name ?? previewName.value ?? l10n.mapLayerAed;
        final place = d?.place ?? previewPlace.value ?? '';
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.medical_services, color: colors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
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
              if (d == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else ...[
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
            ],
          ),
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
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
