/// One selectable Himawari-9 AHI view on the map — either a raw band (B01–B16)
/// or a derived product (True Color, overshooting top, cloud-top temperature,
/// …) the tile service can render.
///
/// [key] is the `?channel=` value the satellite tile endpoints accept: a raw
/// band's decimal number, or a named product. Bands and products are the same
/// kind of choice from a client's point of view — which imagery do I want — so
/// they share the one enum; the wire only differs in whether [key] is numeric.
///
/// [subtitle] is the layer picker's secondary line: a band's wavelength, or a
/// product's formula / composition in the service's own notation (`B13−B15`,
/// `(B04−B03)/(B04+B03)`, `B03·B02·B01`). It is pure data (math and band ids,
/// not display prose), so it stays out of the ARB files and reads the same in
/// every locale.
///
/// The display order here is the layer-picker order: visible through thermal
/// bands first, then the RGB / difference / Level-2 products. See
/// `satellite-tiles-go/docs.md` for what each one is.
enum SatelliteChannel {
  visibleBlue('1', '0.47 µm'),
  visibleGreen('2', '0.51 µm'),
  visibleRed('3', '0.64 µm'),
  nir('4', '0.86 µm'),
  nirPhase('5', '1.6 µm'),
  nirCloud('6', '2.3 µm'),
  swir('7', '3.9 µm'),
  wvUpper('8', '6.2 µm'),
  wvMid('9', '6.9 µm'),
  wvLow('10', '7.3 µm'),
  so2('11', '8.6 µm'),
  ozone('12', '9.6 µm'),
  irClean('13', '10.4 µm'),
  irLong('14', '11.2 µm'),
  irLong2('15', '12.4 µm'),
  co2('16', '13.3 µm'),
  truecolor('truecolor', 'B03·B02·B01'),
  naturalcolor('naturalcolor', 'B05·B04·B03'),
  ash('ash', 'B13−B15 · B11−B13 · B13'),
  dust('dust', 'B13−B15 · B11−B13 · B13'),
  airmass('airmass', 'B10−B08 · B13−B12 · B08'),
  nightmicrophysics('nightmicrophysics', 'B13−B15 · B07−B13 · B13'),
  watervapor('watervapor', 'B08 · 6.2 µm'),
  btdSplit('btd_split', 'B13−B15'),
  btdFog('btd_fog', 'B07−B13'),
  btdWvirw('btd_wvirw', 'B08−B13'),
  btdSo2('btd_so2', 'B11−B13'),
  btdCo2('btd_co2', 'B16−B13'),
  btdOzone('btd_ozone', 'B12−B13'),
  cloudtop('cloudtop', 'AHI-CHGT'),
  cloudmask('cloudmask', 'AHI-CMSK'),
  sst('sst', 'ACSPO L3C'),
  ndvi('ndvi', '(B04−B03)/(B04+B03)'),
  ndwi('ndwi', '(B02−B04)/(B02+B04)'),
  mndwi('mndwi', '(B02−B06)/(B02+B06)');

  const SatelliteChannel(this.key, this.subtitle);

  /// The `?channel=` value naming this view on the tile endpoints.
  final String key;

  /// Picker subtitle — the band's wavelength, or the product's composition /
  /// formula in the tile service's band notation.
  final String subtitle;

  /// Whether this is a raw single band. Only bands accept a colour [style];
  /// named products carry their own palette (`?style=` is ignored for them).
  bool get isBand => int.tryParse(key) != null;

  /// Whether this band is **thermal infrared** (B07–B16).
  ///
  /// The `jma` (cloud-top enhancement) and `bd` (Dvorak BD) styles are
  /// temperature maps — they colour the cloud-top temperature field. Only IR
  /// bands carry that field. Visible / near-infrared bands (B01–B06) measure
  /// reflected sunlight and have no temperature, so [SatelliteStyle.gray] is
  /// their only meaningful rendering.
  bool get isThermal {
    final band = int.tryParse(key);
    return band != null && band >= 7;
  }
}

/// One colour rendering of a raw band (`?style=` on the tile endpoints).
///
/// Only [SatelliteChannel.isBand] channels honour this; the backend defaults to
/// [gray] when the parameter is absent, so the default needs no wire value.
enum SatelliteStyle {
  gray('gray'),
  jma('jma'),
  bd('bd');

  const SatelliteStyle(this.key);

  /// The `?style=` value naming this rendering.
  final String key;
}
