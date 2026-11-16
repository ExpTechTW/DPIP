/// Subscribes to accelerometer batches and publishes seismometer state.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/platform/accelerometer.dart';
import 'package:dpip/features/seismometer/domain/jma_intensity.dart';
import 'package:dpip/features/seismometer/domain/seismic_band_pass.dart';
import 'package:dpip/features/seismometer/domain/seismic_sampler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Lifecycle of a [SeismometerController] session.
enum SeismometerPhase {
  /// [SeismometerController.start] has not been called, or
  /// [SeismometerController.stop] has returned the controller here.
  idle,

  /// The accelerometer stream failed or closed.
  unavailable,

  /// The sampler is still measuring the offset.
  ///
  /// That window is the first three seconds of output: one second
  /// discarded, then two seconds averaged.
  calibrating,

  /// Calibration has finished and the 60 s intensity window is not full.
  ///
  /// A gap in the raw timestamps also lands here, because the calculator
  /// is emptied and has to fill again.
  buffering,

  /// The current window has produced an intensity result.
  measuring,
}

/// Last 30 seconds of band-passed motion at 50 Hz.
///
/// The buffer holds [capacity] samples. [length] grows until it is full,
/// then each new sample drops the oldest. Index 0 is the oldest sample.
final class SeismicWaveform {
  SeismicWaveform._();

  /// 30 seconds at [JmaIntensityCalculator.samplingRate].
  static const int capacity = 30 * JmaIntensityCalculator.samplingRate;

  final Float64List _h1 = Float64List(capacity);
  final Float64List _h2 = Float64List(capacity);
  final Float64List _v = Float64List(capacity);
  int _origin = 0;
  int _length = 0;

  /// Samples currently stored, at most [capacity].
  int get length => _length;

  /// Band-passed sampler h1 at [i], in gal. Index 0 is the oldest sample.
  double h1(int i) => _h1[_index(i)];

  /// Band-passed sampler h2 at [i], in gal. Index 0 is the oldest sample.
  double h2(int i) => _h2[_index(i)];

  /// Band-passed sampler v at [i], in gal. Index 0 is the oldest sample.
  double v(int i) => _v[_index(i)];

  void _push(double h1, double h2, double v) {
    final index = (_origin + _length) % capacity;
    _h1[index] = h1;
    _h2[index] = h2;
    _v[index] = v;
    if (_length < capacity) {
      _length++;
      return;
    }
    _origin++;
    if (_origin == capacity) _origin = 0;
  }

  void _clear() {
    _origin = 0;
    _length = 0;
  }

  int _index(int i) {
    if (i < 0 || i >= _length) {
      throw RangeError.index(i, this, 'i', null, _length);
    }
    return (_origin + i) % capacity;
  }
}

/// Drives a seismometer session from accelerometer batches.
///
/// [start] listens to the source, resamples through [SeismicSampler], and
/// feeds each calibrated sample to [JmaIntensityCalculator] and one
/// [SeismicBandPass] per axis. Listeners of this controller run when
/// [phase] changes and every 25 calibrated samples, which is half a
/// second at 50 Hz. [waveformRevision] fires once per batch so a trace
/// can repaint without rebuilding the rest of the page.
///
/// Two raw timestamps more than 200 ms apart are a gap. The calculator
/// and the three band-pass filters restart, [acceleration] returns to
/// zero, and the phase goes back to [SeismometerPhase.buffering] once
/// calibration has already finished. [sessionMax] and [peakAcceleration]
/// keep their values. [stop] drops the subscription and clears every
/// reading.
final class SeismometerController extends ChangeNotifier {
  /// [source] defaults to [accelerometerBatches]. Each [start] calls it
  /// again, so a later session gets a new subscription.
  SeismometerController({Stream<List<AccelerometerSample>> Function()? source})
    : _source = source ?? accelerometerBatches {
    _sampler = SeismicSampler(onSample: _onCalibrated, onGap: _onGap);
  }

  /// Calibrated samples between intensity updates. Half a second at 50 Hz.
  static const int _samplesPerTick = 25;

  final Stream<List<AccelerometerSample>> Function() _source;
  late final SeismicSampler _sampler;
  final JmaIntensityCalculator _calculator = JmaIntensityCalculator();
  final SeismicBandPass _bandH1 = SeismicBandPass();
  final SeismicBandPass _bandH2 = SeismicBandPass();
  final SeismicBandPass _bandV = SeismicBandPass();
  final SeismicWaveform _waveform = SeismicWaveform._();
  final _WaveformRevision _waveformRevision = _WaveformRevision();
  final _RawRate _rate = _RawRate();

  StreamSubscription<List<AccelerometerSample>>? _subscription;

  /// Identifies the subscription [start] created. Callbacks close over the
  /// value from their own [start] and ignore events once it has changed.
  int _generation = 0;

  var _active = false;
  var _phase = SeismometerPhase.idle;
  var _windowReady = false;
  var _sinceTick = 0;
  var _windowPeakSq = 0.0;
  var _acceleration = 0.0;
  var _peakAcceleration = 0.0;
  var _notify = false;
  var _gapThisSample = false;

  JmaIntensityResult? _latest;
  JmaIntensityResult? _sessionMax;

  /// Current lifecycle. Listeners run on the sample that changes it.
  SeismometerPhase get phase => _phase;

  /// Whole seconds left in calibration, rounded up.
  ///
  /// Zero once [SeismicSampler.calibrating] is false.
  int get calibrationRemainingSeconds {
    final remaining = _sampler.calibrationRemainingSamples;
    if (remaining <= 0) return 0;
    final rate = JmaIntensityCalculator.samplingRate;
    return (remaining + rate - 1) ~/ rate;
  }

  /// Fraction of the 60 s intensity window currently stored, from 0 to 1.
  double get bufferProgress {
    final fraction =
        _calculator.bufferedSamples / JmaIntensityCalculator.maxSamples;
    if (fraction <= 0) return 0;
    if (fraction >= 1) return 1;
    return fraction;
  }

  /// Most recent intensity result, or null before the first full window.
  ///
  /// A gap keeps this value until the next result replaces it.
  JmaIntensityResult? get latest => _latest;

  /// Result with the greatest [JmaIntensityResult.intensity] since [start]
  /// or the last [resetSession]. A gap keeps it.
  JmaIntensityResult? get sessionMax => _sessionMax;

  /// Largest triaxial band-passed vector length, in gal, over the latest
  /// completed half-second.
  ///
  /// A gap sets this back to zero until the next half-second completes.
  double get acceleration => _acceleration;

  /// Largest [acceleration] since [start] or the last [resetSession].
  ///
  /// A gap leaves it unchanged.
  double get peakAcceleration => _peakAcceleration;

  /// Raw samples per second over the newest five seconds of timestamps.
  ///
  /// The value is `(n - 1) / span`, where n is how many of those samples
  /// fall in the window and span is the time from the oldest of them to
  /// the newest. Fewer than two samples yields zero.
  double get sampleRateHz => _rate.hertz;

  /// Band-passed trace for the current session. The same instance is
  /// returned for the life of the controller.
  SeismicWaveform get waveform => _waveform;

  /// Fires once after each accelerometer batch has been applied.
  Listenable get waveformRevision => _waveformRevision;

  /// Subscribes to the accelerometer and begins calibration.
  ///
  /// A second call while a session is active does nothing. After [stop]
  /// or a stream failure, it starts a new calibration.
  void start() {
    if (_active) return;
    final generation = ++_generation;
    _active = true;
    _clearPipeline();
    _phase = SeismometerPhase.calibrating;
    notifyListeners();
    if (generation != _generation || !_active) return;

    final Stream<List<AccelerometerSample>> events;
    try {
      events = _source();
    } on Object catch (error, stackTrace) {
      if (generation != _generation) return;
      _onError(error, stackTrace);
      return;
    }
    final sub = events.listen(
      (batch) {
        if (generation != _generation) return;
        _onBatch(batch);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (generation != _generation) return;
        _onError(error, stackTrace);
      },
      onDone: () {
        if (generation != _generation) return;
        _onDone();
      },
    );
    if (generation != _generation || !_active) {
      unawaited(sub.cancel());
      return;
    }
    _subscription = sub;
  }

  /// Cancels the subscription, clears readings, and returns to
  /// [SeismometerPhase.idle].
  void stop() {
    if (!_active && _phase == SeismometerPhase.idle) return;
    _generation++;
    _active = false;
    final sub = _subscription;
    _subscription = null;
    if (sub != null) unawaited(sub.cancel());
    _clearPipeline();
    _notify = false;
    _gapThisSample = false;
    if (_phase != SeismometerPhase.idle) {
      _phase = SeismometerPhase.idle;
      notifyListeners();
    }
  }

  /// Clears [sessionMax] and [peakAcceleration]. Sampling continues.
  void resetSession() {
    _sessionMax = null;
    _peakAcceleration = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    _waveformRevision.dispose();
    super.dispose();
  }

  void _onBatch(List<AccelerometerSample> batch) {
    final generation = _generation;
    for (var i = 0; i < batch.length; i++) {
      if (generation != _generation || !_active) return;
      final sample = batch[i];
      _rate.add(sample.timestampNanos);
      _gapThisSample = false;
      _notify = false;
      // Listeners run after addRaw returns, so stop() from a listener
      // resets the sampler only once that call has finished.
      _sampler.addRaw(sample.timestampNanos, sample.x, sample.y, sample.z);
      if (generation != _generation || !_active) return;
      _publishSample();
    }
    if (generation != _generation || !_active) return;
    _waveformRevision.advance();
  }

  void _onCalibrated(double h1, double h2, double v) {
    _calculator.add(h1, h2, v);
    final filteredH1 = _bandH1.apply(h1);
    final filteredH2 = _bandH2.apply(h2);
    final filteredV = _bandV.apply(v);
    _waveform._push(filteredH1, filteredH2, filteredV);
    final magnitudeSq =
        filteredH1 * filteredH1 +
        filteredH2 * filteredH2 +
        filteredV * filteredV;
    if (magnitudeSq > _windowPeakSq) _windowPeakSq = magnitudeSq;
    _sinceTick++;
    if (_sinceTick < _samplesPerTick) return;
    _sinceTick = 0;
    _finishTick();
  }

  void _finishTick() {
    final result = _calculator.calculate();
    if (result != null) {
      _latest = result;
      _windowReady = true;
      final champion = _sessionMax;
      if (champion == null || result.intensity > champion.intensity) {
        _sessionMax = result;
      }
    }
    final acceleration = math.sqrt(_windowPeakSq);
    _windowPeakSq = 0;
    _acceleration = acceleration;
    if (acceleration > _peakAcceleration) _peakAcceleration = acceleration;
    _notify = true;
  }

  void _onGap() {
    _calculator.reset();
    _bandH1.reset();
    _bandH2.reset();
    _bandV.reset();
    _sinceTick = 0;
    _windowPeakSq = 0;
    _acceleration = 0;
    _windowReady = false;
    _gapThisSample = true;
  }

  void _publishSample() {
    final next = _readPhase();
    final phaseChanged = next != _phase;
    if (phaseChanged) _phase = next;
    if (!_notify && !phaseChanged && !_gapThisSample) return;
    _notify = false;
    _gapThisSample = false;
    notifyListeners();
  }

  SeismometerPhase _readPhase() {
    if (_sampler.calibrating) return SeismometerPhase.calibrating;
    if (!_windowReady) return SeismometerPhase.buffering;
    return SeismometerPhase.measuring;
  }

  void _onError(Object error, StackTrace stackTrace) {
    if (!_active) return;
    if (error is! PlatformException || error.code != 'unavailable') {
      Log.handle(error, stackTrace, 'Seismometer accelerometer stream failed');
    }
    _becomeUnavailable();
  }

  void _onDone() {
    if (!_active) return;
    Log.warning('Seismometer accelerometer stream closed');
    _becomeUnavailable();
  }

  void _becomeUnavailable() {
    _generation++;
    _active = false;
    final sub = _subscription;
    _subscription = null;
    if (sub != null) unawaited(sub.cancel());
    _phase = SeismometerPhase.unavailable;
    notifyListeners();
  }

  void _clearPipeline() {
    _sampler.reset();
    _calculator.reset();
    _bandH1.reset();
    _bandH2.reset();
    _bandV.reset();
    _waveform._clear();
    _rate.clear();
    _sinceTick = 0;
    _windowPeakSq = 0;
    _acceleration = 0;
    _peakAcceleration = 0;
    _latest = null;
    _sessionMax = null;
    _windowReady = false;
    _notify = false;
    _gapThisSample = false;
  }
}

/// Notifies once per applied accelerometer batch.
final class _WaveformRevision extends ChangeNotifier {
  void advance() => notifyListeners();
}

/// Timestamps of raw samples, kept so [SeismometerController.sampleRateHz]
/// can be read without allocating on the sample path.
///
/// The ring holds five seconds at 800 Hz. A faster sensor is measured
/// over the samples that still fit.
final class _RawRate {
  static const int _capacity = 4096;
  static const int _windowNanos = 5 * 1000000000;
  static const int _nanosPerSecond = 1000000000;

  final Int64List _nanos = Int64List(_capacity);
  int _write = 0;
  int _count = 0;

  void add(int timestampNanos) {
    _nanos[_write] = timestampNanos;
    _write++;
    if (_write == _capacity) _write = 0;
    if (_count < _capacity) _count++;
  }

  void clear() {
    _write = 0;
    _count = 0;
  }

  double get hertz {
    if (_count < 2) return 0;
    var index = _write == 0 ? _capacity - 1 : _write - 1;
    final newest = _nanos[index];
    final earliest = newest - _windowNanos;
    var inWindow = 0;
    var oldest = newest;
    for (var age = 0; age < _count; age++) {
      final timestamp = _nanos[index];
      if (timestamp < earliest || timestamp > newest) break;
      inWindow++;
      oldest = timestamp;
      if (index == 0) {
        index = _capacity - 1;
      } else {
        index--;
      }
    }
    final span = newest - oldest;
    if (inWindow < 2 || span <= 0) return 0;
    return (inWindow - 1) * _nanosPerSecond / span;
  }
}
