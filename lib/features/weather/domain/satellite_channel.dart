/// One selectable Himawari-9 AHI view on the map — either a raw band (B01–B16)
/// or a derived product (True Color, overshooting top, cloud-top temperature,
/// …) the tile service can render.
///
/// [key] is the `?channel=` value the satellite tile endpoints accept: a raw
/// band's decimal number, or a named product. Bands and products are the same
/// kind of choice from a client's point of view — which imagery do I want — so
/// they share the one enum; the wire only differs in whether [key] is numeric.
///
/// The display order here is the layer-picker order: visible through thermal
/// bands first, then the RGB / difference / Level-2 products. See
/// `satellite-tiles-go/docs.md` for what each one is.
enum SatelliteChannel {
  visibleBlue('1'),
  visibleGreen('2'),
  visibleRed('3'),
  nir('4'),
  nirPhase('5'),
  nirCloud('6'),
  swir('7'),
  wvUpper('8'),
  wvMid('9'),
  wvLow('10'),
  so2('11'),
  ozone('12'),
  irClean('13'),
  irLong('14'),
  irLong2('15'),
  co2('16'),
  truecolor('truecolor'),
  naturalcolor('naturalcolor'),
  ash('ash'),
  dust('dust'),
  airmass('airmass'),
  nightmicrophysics('nightmicrophysics'),
  watervapor('watervapor'),
  btdSplit('btd_split'),
  btdFog('btd_fog'),
  btdWvirw('btd_wvirw'),
  btdSo2('btd_so2'),
  btdCo2('btd_co2'),
  btdOzone('btd_ozone'),
  cloudtop('cloudtop'),
  cloudmask('cloudmask'),
  sst('sst'),
  ndvi('ndvi'),
  ndwi('ndwi'),
  mndwi('mndwi');

  const SatelliteChannel(this.key);

  /// The `?channel=` value naming this view on the tile endpoints.
  final String key;
}
