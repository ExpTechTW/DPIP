/// JMA instrumental intensity over a rolling 60 s window at 50 Hz.
///
/// Each axis holds [JmaIntensityCalculator.maxSamples] samples. [calculate]
/// returns null until that window is full. Later samples overwrite the oldest
/// ones, and the next [calculate] uses the 60 s that are in the ring.
library;

import 'dart:math' as math;
import 'dart:typed_data';

/// One intensity evaluation: the floored intensity, its class, and `a` in gal.
final class JmaIntensityResult {
  const JmaIntensityResult({
    required this.intensity,
    required this.intensityClass,
    required this.a,
  });

  /// Instrumental intensity: `2·log10(a) + 0.94`, rounded half away from zero
  /// to three decimal places, then floored to one decimal place.
  final double intensity;

  /// Class of [intensity]: "0", "1", "2", "3", "4", "5-", "5+", "6-", "6+", "7".
  final String intensityClass;

  /// Square root of the 15th-largest triaxial sum of squares, in gal.
  final double a;
}

/// 50 Hz, 60 s JMA instrumental-intensity calculator.
///
/// [add] appends one triaxial sample in gal. Work buffers for the FFT are
/// allocated once and reused on every [calculate].
final class JmaIntensityCalculator {
  /// Samples per second.
  static const int samplingRate = 50;

  /// Length of the ring, in seconds.
  static const int windowSeconds = 60;

  /// Samples retained per axis.
  static const int maxSamples = samplingRate * windowSeconds;

  static const int _topN = 15;
  static const int _nPad = 4096;
  static const int _nPadHalf = _nPad ~/ 2;
  static const int _fftStages = 12;

  final Float64List _h1 = Float64List(maxSamples);
  final Float64List _h2 = Float64List(maxSamples);
  final Float64List _v = Float64List(maxSamples);
  final Float64List _filters = Float64List(_nPadHalf);
  final Float64List _fftReal = Float64List(_nPad);
  final Float64List _fftImag = Float64List(_nPad);
  final Float64List _vectorSum = Float64List(maxSamples);

  int _bufferSize = 0;
  int _writeIndex = 0;

  JmaIntensityCalculator() {
    assert(
      (1 << _fftStages) == _nPad,
      'radix-2 stage count must match the padded length',
    );
    _buildFilters();
  }

  /// Samples currently stored. Stays at [maxSamples] once the ring is full.
  int get bufferedSamples => _bufferSize;

  /// Whether [calculate] has a full 60 s window to read.
  bool get hasEnoughData => _bufferSize >= maxSamples;

  /// Appends one sample. Axes are east-west, north-south, and vertical, in gal.
  void add(double h1, double h2, double v) {
    _h1[_writeIndex] = h1;
    _h2[_writeIndex] = h2;
    _v[_writeIndex] = v;
    _writeIndex++;
    if (_writeIndex >= maxSamples) _writeIndex = 0;
    if (_bufferSize < maxSamples) _bufferSize++;
  }

  /// Drops every stored sample. Filter coefficients stay in place.
  void reset() {
    _h1.fillRange(0, maxSamples, 0.0);
    _h2.fillRange(0, maxSamples, 0.0);
    _v.fillRange(0, maxSamples, 0.0);
    _bufferSize = 0;
    _writeIndex = 0;
  }

  /// Intensity of the current window, or null when fewer than [maxSamples]
  /// samples have been stored since the last [reset].
  JmaIntensityResult? calculate() {
    final currentN = _bufferSize;
    if (currentN < maxSamples) return null;

    _vectorSum.fillRange(0, currentN, 0.0);
    _accumulate(_h1, currentN);
    _accumulate(_h2, currentN);
    _accumulate(_v, currentN);

    final a = math.sqrt(_kthLargest(_vectorSum, currentN, _topN));
    final raw = 2.0 * (math.log(a) / math.ln10) + 0.94;
    final intensity = _floorIntensity(raw);
    return JmaIntensityResult(
      intensity: intensity,
      intensityClass: _classFor(intensity),
      a: a,
    );
  }

  void _accumulate(Float64List axis, int currentN) {
    final firstPart = maxSamples - _writeIndex;
    _fftReal.setRange(0, firstPart, axis, _writeIndex);
    _fftReal.setRange(firstPart, maxSamples, axis);
    _fftReal.fillRange(maxSamples, _nPad, 0.0);
    _fftImag.fillRange(0, _nPad, 0.0);

    _fft();
    for (var i = 0; i < _nPadHalf; i++) {
      final gain = _filters[i];
      _fftReal[i] *= gain;
      _fftImag[i] *= gain;
    }
    // Upper-half bin i reads the table at _nPad - i - 1, so bin i and bin
    // _nPad - i do not share a coefficient. Bin _nPadHalf uses the last entry.
    for (var i = _nPadHalf; i < _nPad; i++) {
      final gain = _filters[_nPad - i - 1];
      _fftReal[i] *= gain;
      _fftImag[i] *= gain;
    }
    _ifft();

    for (var i = 0; i < currentN; i++) {
      final value = _fftReal[i];
      _vectorSum[i] += value * value;
    }
  }

  void _buildFilters() {
    final dt = 1.0 / samplingRate;
    for (var i = 1; i < _nPadHalf; i++) {
      final freq = i / (_nPad * dt);
      _filters[i] = _combined(freq);
    }
  }

  static double _lowCut(double f) {
    final ratio = f * 2.0;
    final cubed = ratio * ratio * ratio;
    return math.sqrt(1.0 - math.exp(-cubed));
  }

  static double _highCut(double f) {
    final y = f * 0.1;
    final y2 = y * y;
    final denom =
        1.0 +
        y2 *
            (0.694 +
                y2 *
                    (0.241 +
                        y2 *
                            (0.0557 +
                                y2 *
                                    (0.009664 +
                                        y2 * (0.00134 + y2 * 0.000155)))));
    return 1.0 / math.sqrt(denom);
  }

  static double _period(double f) => f == 0.0 ? 0.0 : 1.0 / math.sqrt(f);

  static double _combined(double f) =>
      f == 0.0 ? 0.0 : _lowCut(f) * _highCut(f) * _period(f);

  void _bitReverse() {
    var j = 0;
    for (var i = 0; i < _nPad - 1; i++) {
      if (i < j) {
        final real = _fftReal[i];
        _fftReal[i] = _fftReal[j];
        _fftReal[j] = real;
        final imag = _fftImag[i];
        _fftImag[i] = _fftImag[j];
        _fftImag[j] = imag;
      }
      var k = _nPad >> 1;
      while (k <= j) {
        j -= k;
        k >>= 1;
      }
      j += k;
    }
  }

  void _fft() {
    if (_nPad <= 1) return;
    _bitReverse();
    for (var s = 1; s <= _fftStages; s++) {
      final m = 1 << s;
      final half = m >> 1;
      final angle = -2.0 * math.pi / m;
      final cosA = math.cos(angle);
      final sinA = math.sin(angle);
      for (var k = 0; k < _nPad; k += m) {
        var wR = 1.0;
        var wI = 0.0;
        for (var j = 0; j < half; j++) {
          final t = k + j;
          final u = t + half;
          final tR = wR * _fftReal[u] - wI * _fftImag[u];
          final tI = wR * _fftImag[u] + wI * _fftReal[u];
          _fftReal[u] = _fftReal[t] - tR;
          _fftImag[u] = _fftImag[t] - tI;
          _fftReal[t] += tR;
          _fftImag[t] += tI;
          final wT = wR;
          wR = wR * cosA - wI * sinA;
          wI = wT * sinA + wI * cosA;
        }
      }
    }
  }

  void _ifft() {
    for (var i = 0; i < _nPad; i++) {
      _fftImag[i] = -_fftImag[i];
    }
    _fft();
    final scale = _nPad.toDouble();
    for (var i = 0; i < _nPad; i++) {
      _fftReal[i] /= scale;
      _fftImag[i] = -_fftImag[i] / scale;
    }
  }

  /// [k]-th largest value in the first [n] entries. [values] is reordered.
  static double _kthLargest(Float64List values, int n, int k) {
    assert(n >= k && k >= 1);
    _sortAscending(values, n);
    return values[n - k];
  }

  static void _siftDown(Float64List values, int start, int end) {
    var root = start;
    while (true) {
      var child = (root << 1) + 1;
      if (child >= end) return;
      if (child + 1 < end && values[child] < values[child + 1]) child++;
      if (values[root] >= values[child]) return;
      final tmp = values[root];
      values[root] = values[child];
      values[child] = tmp;
      root = child;
    }
  }

  static void _sortAscending(Float64List values, int n) {
    for (var start = (n >> 1) - 1; start >= 0; start--) {
      _siftDown(values, start, n);
    }
    for (var end = n - 1; end > 0; end--) {
      final tmp = values[end];
      values[end] = values[0];
      values[0] = tmp;
      _siftDown(values, 0, end);
    }
  }

  /// Non-finite [raw] is preserved. A finite value is rounded to three
  /// decimals, half away from zero, then floored to one decimal.
  static double _floorIntensity(double raw) {
    if (!raw.isFinite) return raw;
    final rounded = (raw * 1000.0).roundToDouble() / 1000.0;
    return (rounded * 10.0).floorToDouble() / 10.0;
  }

  static String _classFor(double intensity) {
    if (intensity < 0.5) return '0';
    if (intensity < 1.5) return '1';
    if (intensity < 2.5) return '2';
    if (intensity < 3.5) return '3';
    if (intensity < 4.5) return '4';
    if (intensity < 5.0) return '5-';
    if (intensity < 5.5) return '5+';
    if (intensity < 6.0) return '6-';
    if (intensity < 6.5) return '6+';
    return '7';
  }
}
