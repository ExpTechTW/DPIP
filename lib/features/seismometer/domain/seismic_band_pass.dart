/// Band-pass used for the displayed waveform: 11 high-pass sections, then
/// 11 low-pass sections. [apply] takes one sample in gal and returns gal.
library;

const int _stageCount = 11;

const List<List<double>> _numHpf = [
  [0.9769037485204, 0.0, 0.0],
  [1.0, -2.0, 1.0],
  [0.9424328308459, 0.0, 0.0],
  [1.0, -2.0, 1.0],
  [0.9149691441131, 0.0, 0.0],
  [1.0, -2.0, 1.0],
  [0.8959987277275, 0.0, 0.0],
  [1.0, -2.0, 1.0],
  [0.8863374802187, 0.0, 0.0],
  [1.0, -2.0, 1.0],
  [1.0, 0.0, 0.0],
];

const List<List<double>> _denHpf = [
  [1.0, 0.0, 0.0],
  [1.0, -1.946073828052, 0.9615411660298],
  [1.0, 0.0, 0.0],
  [1.0, -1.877404882092, 0.8923264412918],
  [1.0, 0.0, 0.0],
  [1.0, -1.822694925196, 0.837181651256],
  [1.0, 0.0, 0.0],
  [1.0, -1.78490427193, 0.7990906389804],
  [1.0, 0.0, 0.0],
  [1.0, -1.765658260281, 0.7796916605933],
  [1.0, 0.0, 0.0],
];

const List<List<double>> _numLpf = [
  [0.8063260828207, 0.0, 0.0],
  [1.0, -0.3349099821478, 1.0],
  [0.8764452158503, 0.0, 0.0],
  [1.0, -0.08269016387548, 1.0],
  [0.8131516681065, 0.0, 0.0],
  [1.0, 0.5521204464881, 1.0],
  [1.228277124762, 0.0, 0.0],
  [1.0, 1.705652561121, 1.0],
  [0.00431639855615, 0.0, 0.0],
  [1.0, -0.4218227257396, 1.0],
  [1.0, 0.0, 0.0],
];

const List<List<double>> _denLpf = [
  [1.0, 0.0, 0.0],
  [1.0, -0.6719798550872, 0.938845023254],
  [1.0, 0.0, 0.0],
  [1.0, -0.8264759910073, 0.8561761588872],
  [1.0, 0.0, 0.0],
  [1.0, -1.10962299915, 0.7141202529829],
  [1.0, 0.0, 0.0],
  [1.0, -1.413006561919, 0.5638384962434],
  [1.0, 0.0, 0.0],
  [1.0, -0.6139497794955, 0.9834048810788],
  [1.0, 0.0, 0.0],
];

final class _Sos {
  _Sos(this.b0, this.b1, this.b2, this.a1, this.a2);

  final double b0;
  final double b1;
  final double b2;
  final double a1;
  final double a2;
  double z1 = 0.0;
  double z2 = 0.0;

  double apply(double x) {
    final out = b0 * x + z1;
    z1 = b1 * x - a1 * out + z2;
    z2 = b2 * x - a2 * out;
    return out;
  }

  void reset() {
    z1 = 0.0;
    z2 = 0.0;
  }
}

List<_Sos> _cascade(
  List<List<double>> numerator,
  List<List<double>> denominator,
) {
  assert(numerator.length == _stageCount);
  assert(denominator.length == _stageCount);
  final stages = <_Sos>[];
  for (var i = 0; i < _stageCount; i++) {
    var b0 = numerator[i][0];
    var b1 = numerator[i][1];
    var b2 = numerator[i][2];
    final a0 = denominator[i][0];
    var a1 = denominator[i][1];
    var a2 = denominator[i][2];
    if (a0 != 1.0) {
      b0 /= a0;
      b1 /= a0;
      b2 /= a0;
      a1 /= a0;
      a2 /= a0;
    }
    stages.add(_Sos(b0, b1, b2, a1, a2));
  }
  return stages;
}

double _run(List<_Sos> stages, double x) {
  var y = x;
  for (var i = 0; i < stages.length; i++) {
    y = stages[i].apply(y);
  }
  return y;
}

/// High-pass cascade followed by the low-pass cascade.
final class SeismicBandPass {
  SeismicBandPass()
    : _highPass = _cascade(_numHpf, _denHpf),
      _lowPass = _cascade(_numLpf, _denLpf);

  final List<_Sos> _highPass;
  final List<_Sos> _lowPass;

  /// Filters one sample. The high-pass cascade runs first, then the low-pass.
  double apply(double x) => _run(_lowPass, _run(_highPass, x));

  /// Clears the delay memory of both cascades. Coefficients stay in place.
  void reset() {
    for (var i = 0; i < _highPass.length; i++) {
      _highPass[i].reset();
    }
    for (var i = 0; i < _lowPass.length; i++) {
      _lowPass[i].reset();
    }
  }
}
