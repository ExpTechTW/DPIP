/// Who is watching the RTS feed closely enough to need every frame.
///
/// The TREM stream has two speeds. Asked for `mode=live` it sends every frame,
/// about two a second; otherwise it sleeps and sends only the frames in which
/// a station is alerting. Only the 強震監視器 on screen reads the calm frames,
/// so the feed runs live while something holds it here and sleeps the rest of
/// the time — the difference is most of the stream's traffic, on a phone's
/// mobile data, all day.
///
/// Counted, not a flag: two surfaces can hold it at once, and the first to
/// let go must not put the other to sleep.
class RtsLiveDemand {
  int _holders = 0;
  final List<void Function()> _listeners = [];

  /// Whether anything currently needs every frame.
  bool get live => _holders > 0;

  void hold() {
    if (_holders++ == 0) _notify();
  }

  void release() {
    if (_holders == 0) return;
    if (--_holders == 0) _notify();
  }

  /// Called whenever [live] flips.
  void addListener(void Function() listener) => _listeners.add(listener);

  void removeListener(void Function() listener) => _listeners.remove(listener);

  void _notify() {
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }
}
