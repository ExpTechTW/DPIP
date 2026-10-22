/// Hides a reasoning block a model writes into its answer text.
///
/// Reasoning models served without a reasoning parser (a self-hosted vLLM or
/// llama.cpp, typically) put their thinking in the content itself, wrapped in
/// `<think>…</think>` at the very start. That is not the answer, and it can
/// run to pages. Only a block that *opens* the answer is hidden; the tag
/// anywhere else is ordinary text.
library;

enum _State { undecided, thinking, answering }

class ThinkFilter {
  static const String _open = '<think>';
  static const String _close = '</think>';

  _State _state = _State.undecided;
  final StringBuffer _held = StringBuffer();

  /// Whether the last [add] was swallowed by an open reasoning block.
  bool get thinking => _state == _State.thinking;

  /// The part of [delta] that is answer text — possibly empty while the
  /// opening is still being decided or the model is still thinking.
  String add(String delta) {
    switch (_state) {
      case _State.answering:
        return delta;
      case _State.undecided:
        _held.write(delta);
        final text = _held.toString().trimLeft();
        if (text.length < _open.length && _open.startsWith(text)) return '';
        _held.clear();
        if (!text.startsWith(_open)) {
          _state = _State.answering;
          return text;
        }
        _state = _State.thinking;
        return _scan(text.substring(_open.length));
      case _State.thinking:
        final text = _held.toString() + delta;
        _held.clear();
        return _scan(text);
    }
  }

  /// What is still held back when the answer ends: a reply too short to have
  /// been a reasoning tag is still the reply.
  String flush() {
    final rest = _state == _State.undecided ? _held.toString().trimLeft() : '';
    _held.clear();
    return rest;
  }

  String _scan(String text) {
    final end = text.indexOf(_close);
    if (end == -1) {
      // Keep only enough to recognise a closing tag split across deltas.
      final keep = text.length < _close.length
          ? text.length
          : _close.length - 1;
      _held.write(text.substring(text.length - keep));
      return '';
    }
    _state = _State.answering;
    return text.substring(end + _close.length).trimLeft();
  }
}
