/// Turns irregular accelerometer samples into a steady 50 Hz stream with
/// the offset removed.
///
/// `addRaw` takes a timestamp in nanoseconds and x, y, z in gal. Timestamps
/// move forward; one that is not later than the previous raw sample is
/// ignored. Output points sit on a 20 ms grid that starts at the first raw
/// sample of the current segment. A point is the linear interpolation of
/// the two raw samples around it, and a point that lands on a raw sample
/// keeps that sample.
///
/// Two raw samples more than 200 ms apart are a gap. The grid starts again
/// at the later sample, `onGap` runs, and then that sample is processed.
/// Nothing is interpolated across the gap. The offset and the quiet-second
/// count stay as they are.
///
/// The first 50 output points are discarded. The mean of the next 100
/// becomes the offset on each axis. `onSample` is not called during those
/// 150 points. After that, every point is delivered as `h1 = x - offset`,
/// `h2 = y - offset`, `v = z - offset`.
///
/// Once delivery has started, each group of 50 points keeps a min, max, and
/// sum per axis. The group is quiet when every axis's max minus min stays
/// within the quiet threshold, 60 LSB converted to gal. Ninety quiet groups
/// in a row replace the offset with that last group's mean and set the quiet
/// count back to zero. A group that is not quiet sets the count back to
/// zero. The point that completes the ninetieth group is delivered with the
/// new offset.
class SeismicSampler {
  SeismicSampler({required this.onSample, required this.onGap});

  /// Each calibrated 50 Hz point. `h1` is x, `h2` is y, and `v` is z.
  final void Function(double h1, double h2, double v) onSample;

  /// Runs before the first point of a segment that starts after a gap.
  final void Function() onGap;

  /// Output points per second.
  static const int _sampleRateHz = 50;

  static const int _nanosPerMillisecond = 1000000;

  /// One step of the output grid: 1000 / [_sampleRateHz] milliseconds.
  static const int _outputPeriodNanos =
      (1000 ~/ _sampleRateHz) * _nanosPerMillisecond;

  /// Raw samples farther apart than 200 ms start a new segment.
  static const int _gapLimitNanos = 200 * _nanosPerMillisecond;

  /// Output points dropped before the offset average begins.
  static const int _discardSamples = _sampleRateHz;

  /// Output points whose mean becomes the first offset.
  static const int _averageSamples = _sampleRateHz * 2;

  static const int _calibrationSamples = _discardSamples + _averageSamples;

  /// Consecutive quiet seconds that replace the offset.
  static const int _quietSecondsNeeded = 90;

  /// ±2 g sensitivity, in LSB per g.
  static const int _lsbPerG = 16384;

  /// Peak-to-peak gal that still counts as quiet.
  ///
  /// 60 LSB times `(9.80665 * 100) / 16384`.
  static const double _quietThresholdGal = 60 * (9.80665 * 100 / _lsbPerG);

  final _Axis _x = _Axis();
  final _Axis _y = _Axis();
  final _Axis _z = _Axis();

  int? _previousNanos;
  double _previousX = 0;
  double _previousY = 0;
  double _previousZ = 0;
  int _nextOutputNanos = 0;

  int _calibrationSeen = 0;
  int _secondCount = 0;
  int _quietSecondCount = 0;

  /// True while the discard and averaging windows are still filling.
  bool get calibrating => _calibrationSeen < _calibrationSamples;

  /// Output points left before `onSample` is called.
  int get calibrationRemainingSamples => _calibrationSamples - _calibrationSeen;

  /// Drops the resample grid, the offset, and the calibration progress.
  void reset() {
    _previousNanos = null;
    _previousX = 0;
    _previousY = 0;
    _previousZ = 0;
    _nextOutputNanos = 0;
    _calibrationSeen = 0;
    _secondCount = 0;
    _quietSecondCount = 0;
    _x.reset();
    _y.reset();
    _z.reset();
  }

  /// Records one raw sample.
  ///
  /// [timestampNanos] is compared with the previous raw timestamp.
  /// [x], [y], and [z] are gal.
  void addRaw(int timestampNanos, double x, double y, double z) {
    final previousNanos = _previousNanos;
    if (previousNanos == null) {
      _startSegment(timestampNanos, x, y, z);
      return;
    }
    if (timestampNanos <= previousNanos) return;
    if (timestampNanos - previousNanos > _gapLimitNanos) {
      onGap();
      _startSegment(timestampNanos, x, y, z);
      return;
    }
    _emitSpanned(previousNanos, timestampNanos, x, y, z);
    _previousNanos = timestampNanos;
    _previousX = x;
    _previousY = y;
    _previousZ = z;
  }

  void _startSegment(int timestampNanos, double x, double y, double z) {
    _previousNanos = timestampNanos;
    _previousX = x;
    _previousY = y;
    _previousZ = z;
    _nextOutputNanos = timestampNanos + _outputPeriodNanos;
    _consume(x, y, z);
  }

  void _emitSpanned(
    int leftNanos,
    int rightNanos,
    double x,
    double y,
    double z,
  ) {
    var outputNanos = _nextOutputNanos;
    while (outputNanos <= rightNanos) {
      final span = rightNanos - leftNanos;
      final into = outputNanos - leftNanos;
      _consume(
        _interpolate(_previousX, x, into, span),
        _interpolate(_previousY, y, into, span),
        _interpolate(_previousZ, z, into, span),
      );
      outputNanos += _outputPeriodNanos;
    }
    _nextOutputNanos = outputNanos;
  }

  void _consume(double x, double y, double z) {
    if (_calibrationSeen < _discardSamples) {
      _calibrationSeen++;
      return;
    }
    if (_calibrationSeen < _calibrationSamples) {
      _x.addCalibration(x);
      _y.addCalibration(y);
      _z.addCalibration(z);
      _calibrationSeen++;
      if (_calibrationSeen == _calibrationSamples) {
        _x.adoptCalibrationMean(_averageSamples);
        _y.adoptCalibrationMean(_averageSamples);
        _z.adoptCalibrationMean(_averageSamples);
      }
      return;
    }
    _updateAutoZero(x, y, z);
    onSample(x - _x.offset, y - _y.offset, z - _z.offset);
  }

  void _updateAutoZero(double x, double y, double z) {
    _x.addSecond(x);
    _y.addSecond(y);
    _z.addSecond(z);
    _secondCount++;
    if (_secondCount < _sampleRateHz) return;

    final quiet =
        _x.peakToPeakWithin(_quietThresholdGal) &&
        _y.peakToPeakWithin(_quietThresholdGal) &&
        _z.peakToPeakWithin(_quietThresholdGal);
    if (quiet) {
      _quietSecondCount++;
      if (_quietSecondCount >= _quietSecondsNeeded) {
        _x.adoptSecondMean(_sampleRateHz);
        _y.adoptSecondMean(_sampleRateHz);
        _z.adoptSecondMean(_sampleRateHz);
        _quietSecondCount = 0;
      }
    } else {
      _quietSecondCount = 0;
    }
    _x.clearSecond();
    _y.clearSecond();
    _z.clearSecond();
    _secondCount = 0;
  }
}

/// Value of the grid point [into] nanoseconds into a raw span of [span].
///
/// A point that lands on either raw sample copies that sample.
double _interpolate(double left, double right, int into, int span) {
  if (into <= 0) return left;
  if (into >= span) return right;
  return left + (right - left) * (into / span);
}

/// Per-axis offset and the two windows that write it.
class _Axis {
  double offset = 0;
  double _calibrationSum = 0;
  double _secondSum = 0;
  double _secondMin = double.infinity;
  double _secondMax = double.negativeInfinity;

  void addCalibration(double value) {
    _calibrationSum += value;
  }

  void addSecond(double value) {
    _secondSum += value;
    if (value < _secondMin) _secondMin = value;
    if (value > _secondMax) _secondMax = value;
  }

  /// True when this second's max minus min does not exceed [range].
  bool peakToPeakWithin(double range) => _secondMax - _secondMin <= range;

  void adoptCalibrationMean(int count) {
    offset = _calibrationSum / count;
  }

  void adoptSecondMean(int count) {
    offset = _secondSum / count;
  }

  void clearSecond() {
    _secondSum = 0;
    _secondMin = double.infinity;
    _secondMax = double.negativeInfinity;
  }

  void reset() {
    offset = 0;
    _calibrationSum = 0;
    clearSecond();
  }
}
