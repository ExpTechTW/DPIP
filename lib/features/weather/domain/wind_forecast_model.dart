/// One selectable numerical weather prediction (數值預報) model on the map —
/// ECMWF or GFS — rendered as a wind-field overlay from the `wind` tile
/// endpoints.
///
/// [key] is the `?model=` value the wind tile endpoints accept. [subtitle] is
/// the layer picker's secondary line — the model's grid and time step in the
/// service's own notation (`0.25° · 1 h`). It is pure data (not display prose),
/// so it stays out of the ARB files and reads the same in every locale.
///
/// The display order here is the layer-picker order. Coverage and step follow
/// `satellite-tiles-go/web/index.html` (GFS hourly to +16 days, ECMWF every 3
/// hours to +10 days).
enum WindForecastModel {
  ecmwf('ecmwf', '0.25° · 3 h'),
  gfs('gfs', '0.25° · 1 h');

  const WindForecastModel(this.key, this.subtitle);

  /// The `?model=` value naming this model on the wind tile endpoints.
  final String key;

  /// Picker subtitle — the model's grid resolution and time step.
  final String subtitle;
}
