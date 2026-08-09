/// The static CWA RTS "box" grid: coarse rectangular cells covering Taiwan,
/// each keyed by an integer id. For large events the RTS feed reports live
/// intensity per box id (`Rts.box`) instead of per station; joining those ids
/// against this grid turns them into map polygons. Pure domain data — the
/// grid itself is loaded by the data layer and injected here.
class RtsBoxGrid {
  const RtsBoxGrid(this.rings);

  /// Each box's closed polygon ring (`[lon, lat]` pairs), keyed by its id.
  final Map<int, List<List<double>>> rings;
}
