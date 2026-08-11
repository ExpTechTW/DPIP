/// Legend for one satellite channel — the channel's own colour key, followed
/// by the border reference (bright-yellow country/county, dark-yellow
/// township) that every channel shares.
///
/// The scales mirror the tile service's rendering (`satellite-tiles-go`): JMA
/// grayscale (colder = whiter) for the window channels, the −40 °C cloud-top
/// enhancement and the Dvorak BD ladder for the temperature styles, a
/// diverging ramp for the brightness-temperature differences, the categorical
/// cloud mask, the oceanographic SST ramp, and the vegetation/water index
/// ramps. RGB composites carry no single numerical scale — they are a colour
/// recipe — so they get a compositing note instead.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/weather/domain/satellite_channel.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/map_color_legend.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// The satellite layer's legend card, rebuilt when the band's [style] changes
/// (grayscale vs cloud-top vs Dvorak are three different keys).
class SatelliteLegend extends StatelessWidget {
  const SatelliteLegend({
    super.key,
    required this.channel,
    required this.style,
  });

  final SatelliteChannel channel;
  final ValueListenable<SatelliteStyle> style;

  static const Color _county = Color(0xFFFFD400);
  static const Color _town = Color(0xFFB79A00);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: style,
      builder: (context, _) {
        final transparency = _transparencyNote(context);
        return MapLegendCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _channelKey(context),
              if (transparency != null) ...[
                const SizedBox(height: AppSpacing.xs),
                transparency,
              ],
              const SizedBox(height: AppSpacing.sm),
              Divider(
                height: 1,
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: AppSpacing.sm),
              _boundaries(context),
            ],
          ),
        );
      },
    );
  }

  /// What transparent means for this channel — every product that draws pixels
  /// transparently explains the *why* here (the basemap showing through, or a
  /// specific no-signal case), so a reader never wonders what the empty parts
  /// of the image are. null when the product is effectively always opaque.
  Widget? _transparencyNote(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final String? text = switch (channel) {
      // Reflective bands: reflectance ≈ 0 (dark surfaces, night) is transparent.
      SatelliteChannel.visibleBlue ||
      SatelliteChannel.visibleGreen ||
      SatelliteChannel.visibleRed ||
      SatelliteChannel.nir ||
      SatelliteChannel.nirPhase ||
      SatelliteChannel.nirCloud => l10n.mapLayerSatelliteTransparentReflectance,
      // Thermal bands: the warm (clear-sky) end of every style is transparent.
      SatelliteChannel.swir ||
      SatelliteChannel.wvUpper ||
      SatelliteChannel.wvMid ||
      SatelliteChannel.wvLow ||
      SatelliteChannel.so2 ||
      SatelliteChannel.ozone ||
      SatelliteChannel.irClean ||
      SatelliteChannel.irLong ||
      SatelliteChannel.irLong2 ||
      SatelliteChannel.co2 => l10n.mapLayerSatelliteTransparentWarm,
      // The daytime RGBs fade out across the terminator.
      SatelliteChannel.truecolor ||
      SatelliteChannel.naturalcolor => l10n.mapLayerSatelliteTransparentNight,
      // Thermal RGB recipes cover the whole scene — no transparency.
      SatelliteChannel.ash ||
      SatelliteChannel.dust ||
      SatelliteChannel.airmass ||
      SatelliteChannel.nightmicrophysics => null,
      SatelliteChannel.watervapor => l10n.mapLayerSatelliteTransparentWarm,
      // Near-zero difference means no absorber — transparent, basemap shows.
      SatelliteChannel.btdSplit ||
      SatelliteChannel.btdFog ||
      SatelliteChannel.btdWvirw ||
      SatelliteChannel.btdSo2 ||
      SatelliteChannel.btdCo2 ||
      SatelliteChannel.btdOzone => l10n.mapLayerSatelliteTransparentZero,
      // Clear sky has no cloud-top value.
      SatelliteChannel.cloudtop => l10n.mapLayerSatelliteTransparentWarm,
      SatelliteChannel.cloudmask => l10n.mapLayerSatelliteTransparentClear,
      // The retrieval has no value over land.
      SatelliteChannel.sst => l10n.mapLayerSatelliteTransparentNoData,
      SatelliteChannel.ndvi => l10n.mapLayerSatelliteTransparentNoVegetation,
      SatelliteChannel.ndwi ||
      SatelliteChannel.mndwi => l10n.mapLayerSatelliteTransparentNoWater,
    };
    if (text == null) return null;
    return SymbolLegend(
      items: [
        SymbolLegendItem(
          swatch: const _SwatchBox(Color(0x00000000), ring: true),
          label: text,
        ),
      ],
    );
  }

  /// The value key this channel displays — a scale, a categorical list, or the
  /// RGB-compositing note for the colour recipes.
  Widget _channelKey(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (channel) {
      // Reflective bands (B01–B06): JMA grayscale on reflectance %, brighter
      // = more reflective.
      SatelliteChannel.visibleBlue ||
      SatelliteChannel.visibleGreen ||
      SatelliteChannel.visibleRed ||
      SatelliteChannel.nir ||
      SatelliteChannel.nirPhase ||
      SatelliteChannel.nirCloud => const ColorScaleLegend(
        unit: '%',
        appendUnit: true,
        stops: [(0, '#000000'), (50, '#808080'), (100, '#FFFFFF')],
      ),
      // Thermal bands (B07–B16) take the selected [style].
      SatelliteChannel.swir ||
      SatelliteChannel.wvUpper ||
      SatelliteChannel.wvMid ||
      SatelliteChannel.wvLow ||
      SatelliteChannel.so2 ||
      SatelliteChannel.ozone ||
      SatelliteChannel.irClean ||
      SatelliteChannel.irLong ||
      SatelliteChannel.irLong2 ||
      SatelliteChannel.co2 => _thermalKey(context),
      // Colour recipes — no single number to scale against.
      SatelliteChannel.truecolor ||
      SatelliteChannel.naturalcolor ||
      SatelliteChannel.ash ||
      SatelliteChannel.dust ||
      SatelliteChannel.airmass ||
      SatelliteChannel.nightmicrophysics => SymbolLegend(
        items: [
          SymbolLegendItem(
            swatch: const _RgbSwatch(),
            label: l10n.mapLayerSatelliteRgbComposite,
          ),
        ],
      ),
      SatelliteChannel.watervapor => const ColorScaleLegend(
        unit: 'K',
        appendUnit: true,
        stops: [(190, '#FFFFFF'), (235, '#7F7F7F'), (280, '#000000')],
      ),
      // Brightness-temperature differences: negative blue, zero transparent
      // (the basemap shows through), positive red.
      SatelliteChannel.btdSplit => _diverging(-3.0, 7.5),
      SatelliteChannel.btdFog => _diverging(-7.0, 2.9),
      SatelliteChannel.btdWvirw => _diverging(-40.0, 4.0),
      SatelliteChannel.btdSo2 => _diverging(-6.0, 6.0),
      SatelliteChannel.btdCo2 => _diverging(-40.0, 2.0),
      SatelliteChannel.btdOzone => _diverging(-41.5, 4.3),
      SatelliteChannel.cloudtop => const ColorScaleLegend(
        unit: 'K',
        appendUnit: true,
        stops: [(190, '#FFFFFF'), (245, '#7F7F7F'), (300, '#000000')],
      ),
      SatelliteChannel.cloudmask => _cloudMask(l10n),
      SatelliteChannel.sst => const ColorScaleLegend(
        unit: '°C',
        appendUnit: true,
        stops: [
          (-2, '#3C1478'),
          (3, '#2846C8'),
          (8, '#28A0DC'),
          (13, '#3CC8A0'),
          (18, '#AADC50'),
          (23, '#F5C832'),
          (28, '#F07828'),
          (32, '#C81E28'),
        ],
      ),
      SatelliteChannel.ndvi => const ColorScaleLegend(
        unit: 'NDVI',
        appendUnit: true,
        stops: [(0, '#C8AF6E'), (0.5, '#5F8A3A'), (1, '#196A23')],
      ),
      SatelliteChannel.ndwi => const ColorScaleLegend(
        unit: 'NDWI',
        appendUnit: true,
        stops: [(0, '#78BEE8'), (0.5, '#3C7FD0'), (1, '#0A3CB8')],
      ),
      SatelliteChannel.mndwi => const ColorScaleLegend(
        unit: 'MNDWI',
        appendUnit: true,
        stops: [(0, '#78BEE8'), (0.5, '#3C7FD0'), (1, '#0A3CB8')],
      ),
    };
  }

  /// The three thermal renderings: JMA grayscale, cloud-top enhancement, and
  /// the Dvorak BD ladder.
  Widget _thermalKey(BuildContext context) {
    return switch (style.value) {
      SatelliteStyle.gray => const ColorScaleLegend(
        unit: 'K',
        appendUnit: true,
        stops: [(190, '#FFFFFF'), (255, '#7F7F7F'), (320, '#000000')],
      ),
      SatelliteStyle.jma => const ColorScaleLegend(
        unit: '°C',
        appendUnit: true,
        stops: [
          (-45, '#7891D2'),
          (-52, '#2D55CD'),
          (-60, '#28A5DC'),
          (-68, '#46C86E'),
          (-76, '#F5E646'),
          (-84, '#F5962D'),
          (-92, '#D72D2D'),
        ],
      ),
      SatelliteStyle.bd => const SymbolLegend(
        items: [
          SymbolLegendItem(
            swatch: _SwatchBox(Color(0xFFE6E6E6)),
            label: '> −30 °C',
          ),
          SymbolLegendItem(
            swatch: _SwatchBox(Color(0xFF4B4B4B)),
            label: '−41…−53 °C',
          ),
          SymbolLegendItem(
            swatch: _SwatchBox(Color(0xFF000000)),
            label: '−63…−69 °C',
          ),
          SymbolLegendItem(
            swatch: _SwatchBox(Color(0xFFFFFFFF), ring: true),
            label: '−69…−75 °C',
          ),
          SymbolLegendItem(
            swatch: _SwatchBox(Color(0xFF828282)),
            label: '< −81 °C',
          ),
        ],
      ),
    };
  }

  /// Diverging difference scale on the tile service's [lo, hi] range — blue
  /// negative, near-zero the basemap, red positive.
  ColorScaleLegend _diverging(double lo, double hi) => ColorScaleLegend(
    unit: 'K',
    appendUnit: true,
    stops: [(lo, '#1E5AEB'), (0, '#E8ECF2'), (hi, '#E61E14')],
  );

  /// The four cloud-mask categories — clear is transparent on the map.
  Widget _cloudMask(AppLocalizations l10n) => SymbolLegend(
    items: [
      SymbolLegendItem(
        swatch: const _SwatchBox(Color(0x00000000), ring: true),
        label: l10n.mapLayerSatelliteCloudClear,
      ),
      SymbolLegendItem(
        swatch: const _SwatchBox(Color(0xFF78C8FF)),
        label: l10n.mapLayerSatelliteCloudProbablyClear,
      ),
      SymbolLegendItem(
        swatch: const _SwatchBox(Color(0xFFDCEBF5)),
        label: l10n.mapLayerSatelliteCloudProbablyCloudy,
      ),
      SymbolLegendItem(
        swatch: const _SwatchBox(Color(0xFFFFFFFF), ring: true),
        label: l10n.mapLayerSatelliteCloudCloudy,
      ),
    ],
  );

  /// The border reference every channel shares — bright-yellow country and
  /// county frame, dark-yellow township mesh, matching [SatelliteMapLayer]'s
  /// runtime line layers exactly.
  Widget _boundaries(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SymbolLegend(
      items: [
        SymbolLegendItem(
          swatch: const LineSwatch(color: _county, width: 1.0),
          label: l10n.mapLayerSatelliteGlobalOutline,
        ),
        SymbolLegendItem(
          swatch: const LineSwatch(color: _county, width: 1.0),
          label: l10n.radarCountyOutline,
        ),
        SymbolLegendItem(
          swatch: const LineSwatch(color: _town, width: 0.7),
          label: l10n.radarTownOutline,
        ),
      ],
    );
  }
}

/// R/G/B swatch marking an RGB-recipe composite.
class _RgbSwatch extends StatelessWidget {
  const _RgbSwatch();

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _RgbBar(Color(0xFFE61E14)),
      _RgbBar(Color(0xFF1E8A2E)),
      _RgbBar(Color(0xFF1E5AEB)),
    ],
  );
}

class _RgbBar extends StatelessWidget {
  const _RgbBar(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 7,
    height: 12,
    decoration: BoxDecoration(
      color: color,
      border: Border.all(color: const Color(0x22000000), width: 0.5),
    ),
  );
}

/// Small square swatch for a categorical (non-line) legend row; [ring] draws a
/// grey border so white or transparent fills stay visible on the card.
class _SwatchBox extends StatelessWidget {
  const _SwatchBox(this.color, {this.ring = false});

  final Color color;
  final bool ring;

  @override
  Widget build(BuildContext context) => Container(
    width: 12,
    height: 12,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(2),
      border: ring
          ? Border.all(color: const Color(0xFF9E9E9E), width: 1)
          : null,
    ),
  );
}
