#include "intensity.h"

#include <clocale>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <vector>

// Parameters and the signal formulas are set by generate.sh (-D and its header).
#ifndef LCG_A
#error "compile through generate.sh"
#endif
#ifndef LCG_C
#error "compile through generate.sh"
#endif
#ifndef LCG_SEED
#error "compile through generate.sh"
#endif
#ifndef LCG_AMP_GAL
#error "compile through generate.sh"
#endif
#ifndef DURATION_SEC
#error "compile through generate.sh"
#endif
#ifndef RECORD_EVERY
#error "compile through generate.sh"
#endif
#ifndef BURST_START_SEC
#error "compile through generate.sh"
#endif
#ifndef BURST_END_SEC
#error "compile through generate.sh"
#endif
#ifndef BURST_HZ
#error "compile through generate.sh"
#endif
#ifndef BURST_GAL
#error "compile through generate.sh"
#endif

// Double closest to pi, matching dart:math pi.
static const double kPi = 3.141592653589793;

enum class Kind {
  kZeros,
  kH1Sine,
  kAxesSine,
  kH2Sine,
  kNoise,
  kNoiseBurst,
};

struct Spec {
  const char *id;
  Kind kind;
};

struct Record {
  int n;
  bool intensityFinite;
  double intensity;
  char cls[8];
  double a;
};

// state' = (LCG_A * state + LCG_C) mod 2^32, seed LCG_SEED.
// uniform = (state + 0.5) / 2^32, sample = (uniform * 2 - 1) * LCG_AMP_GAL.
struct Lcg {
  uint32_t state;

  double next() {
    state = state * static_cast<uint32_t>(LCG_A) + static_cast<uint32_t>(LCG_C);
    const double uniform = (static_cast<double>(state) + 0.5) / 4294967296.0;
    return (uniform * 2.0 - 1.0) * static_cast<double>(LCG_AMP_GAL);
  }
};

// t = index / SAMPLING_RATE. Sine is amp * sin(2 * pi * hz * t).
// Noise draws h1, then h2, then v. The burst adds BURST_GAL * sin(2 * pi *
// BURST_HZ * t) to every axis while BURST_START_SEC <= t < BURST_END_SEC.
static void sampleAt(Kind kind, int index, Lcg &lcg, double &h1, double &h2, double &v) {
  const double t = static_cast<double>(index) / static_cast<double>(SAMPLING_RATE);
  h1 = 0;
  h2 = 0;
  v = 0;
  switch (kind) {
  case Kind::kZeros:
    break;
  case Kind::kH1Sine:
    h1 = 10.0 * std::sin(2.0 * kPi * 1.0 * t);
    break;
  case Kind::kAxesSine:
    h1 = h2 = v = 50.0 * std::sin(2.0 * kPi * 2.0 * t);
    break;
  case Kind::kH2Sine:
    h2 = 200.0 * std::sin(2.0 * kPi * 5.0 * t);
    break;
  case Kind::kNoise:
    h1 = lcg.next();
    h2 = lcg.next();
    v = lcg.next();
    break;
  case Kind::kNoiseBurst:
    h1 = lcg.next();
    h2 = lcg.next();
    v = lcg.next();
    if (t >= static_cast<double>(BURST_START_SEC) && t < static_cast<double>(BURST_END_SEC)) {
      const double burst =
          static_cast<double>(BURST_GAL) * std::sin(2.0 * kPi * static_cast<double>(BURST_HZ) * t);
      h1 += burst;
      h2 += burst;
      v += burst;
    }
    break;
  }
}

static bool classOk(const char *cls) {
  if (cls[0] == '\0')
    return false;
  for (const char *p = cls; *p != '\0'; ++p) {
    const char c = *p;
    const bool digit = c >= '0' && c <= '9';
    const bool sign = c == '+' || c == '-';
    if (!digit && !sign)
      return false;
  }
  return true;
}

static bool runSignal(JMAIntensityCalculator &calc, const Spec &spec, int sampleCount,
                      std::vector<Record> &out) {
  calc.reset();
  Lcg lcg{static_cast<uint32_t>(LCG_SEED)};
  SeismicPacket packet{};
  int filled = 0;
  out.clear();
  for (int i = 0; i < sampleCount; ++i) {
    double h1, h2, v;
    sampleAt(spec.kind, i, lcg, h1, h2, v);
    packet.h1[filled] = static_cast<float>(h1);
    packet.h2[filled] = static_cast<float>(h2);
    packet.v[filled] = static_cast<float>(v);
    ++filled;
    if (filled < SAMPLES_PER_PACKET)
      continue;
    const int n = i + 1;
    const JMAIntensityResult result = calc.updateAndCalculate(packet);
    filled = 0;
    packet = SeismicPacket{};
    if (n < MAX_SAMPLES || n % RECORD_EVERY != 0)
      continue;
    if (!result.valid) {
      std::fprintf(stderr, "%s: no intensity at n=%d\n", spec.id, n);
      return false;
    }
    Record rec{};
    rec.n = n;
    rec.intensityFinite = std::isfinite(result.intensity);
    rec.intensity = result.intensity;
    std::snprintf(rec.cls, sizeof(rec.cls), "%s", result.intensityClass);
    rec.a = result.a;
    if (!classOk(rec.cls)) {
      std::fprintf(stderr, "%s: unexpected class at n=%d\n", spec.id, n);
      return false;
    }
    out.push_back(rec);
  }
  if (filled != 0) {
    std::fprintf(stderr, "%s: %d samples left in the last packet\n", spec.id, filled);
    return false;
  }
  const int expected = (sampleCount - MAX_SAMPLES) / RECORD_EVERY + 1;
  if (static_cast<int>(out.size()) != expected) {
    std::fprintf(stderr, "%s: %zu records, expected %d\n", spec.id, out.size(), expected);
    return false;
  }
  return true;
}

static void writeNumber(std::FILE *fp, double value, bool finite) {
  if (!finite || !std::isfinite(value)) {
    std::fputs("null", fp);
    return;
  }
  std::fprintf(fp, "%.9g", value);
}

static bool writeJson(const char *path, const Spec *specs, size_t specCount,
                      const std::vector<std::vector<Record>> &records,
                      const std::vector<double> &bpf, int sampleCount) {
  std::FILE *fp = std::fopen(path, "w");
  if (fp == nullptr) {
    std::perror(path);
    return false;
  }
  std::fputs("{\n", fp);
  std::fprintf(fp, "  \"sample_rate_hz\": %d,\n", SAMPLING_RATE);
  std::fprintf(fp, "  \"duration_sec\": %d,\n", DURATION_SEC);
  std::fprintf(fp, "  \"sample_count\": %d,\n", sampleCount);
  std::fprintf(fp, "  \"record_every\": %d,\n", RECORD_EVERY);
  std::fprintf(fp, "  \"window_samples\": %d,\n", MAX_SAMPLES);
  std::fprintf(fp, "  \"lcg_a\": %d,\n", LCG_A);
  std::fprintf(fp, "  \"lcg_c\": %d,\n", LCG_C);
  std::fprintf(fp, "  \"lcg_seed\": %d,\n", LCG_SEED);
  std::fprintf(fp, "  \"lcg_amplitude_gal\": %d,\n", LCG_AMP_GAL);
  std::fprintf(fp, "  \"burst_start_sec\": %d,\n", BURST_START_SEC);
  std::fprintf(fp, "  \"burst_end_sec\": %d,\n", BURST_END_SEC);
  std::fprintf(fp, "  \"burst_hz\": %d,\n", BURST_HZ);
  std::fprintf(fp, "  \"burst_gal\": %d,\n", BURST_GAL);
  std::fputs("  \"signals\": [\n", fp);
  for (size_t s = 0; s < specCount; ++s) {
    std::fprintf(fp, "    {\"id\": \"%s\", \"records\": [\n", specs[s].id);
    const std::vector<Record> &recs = records[s];
    for (size_t i = 0; i < recs.size(); ++i) {
      const Record &rec = recs[i];
      std::fprintf(fp, "      {\"n\": %d, \"intensity\": ", rec.n);
      writeNumber(fp, rec.intensity, rec.intensityFinite);
      std::fprintf(fp, ", \"class\": \"%s\", \"a\": ", rec.cls);
      writeNumber(fp, rec.a, true);
      std::fputs(i + 1 == recs.size() ? "}\n" : "},\n", fp);
    }
    std::fputs(s + 1 == specCount ? "    ]}\n" : "    ]},\n", fp);
  }
  std::fputs("  ],\n", fp);
  std::fputs("  \"bpf_h1_first_300\": [\n", fp);
  for (size_t i = 0; i < bpf.size(); ++i) {
    std::fprintf(fp, "    %.9g%s\n", bpf[i], i + 1 == bpf.size() ? "" : ",");
  }
  std::fputs("  ]\n}\n", fp);
  if (std::fclose(fp) != 0) {
    std::perror(path);
    return false;
  }
  return true;
}

// First 300 outputs of high-pass then low-pass on axes-sine h1.
static void bandPassH1(std::vector<double> &out) {
  BPFFilter highPass;
  BPFFilter lowPass;
  highPass.init(NUM_HPF, DEN_HPF);
  lowPass.init(NUM_LPF, DEN_LPF);
  out.clear();
  out.reserve(300);
  for (int i = 0; i < 300; ++i) {
    const double t = static_cast<double>(i) / static_cast<double>(SAMPLING_RATE);
    const double x = 50.0 * std::sin(2.0 * kPi * 2.0 * t);
    const float y = lowPass.apply(highPass.apply(static_cast<float>(x)));
    out.push_back(static_cast<double>(y));
  }
}

int main(int argc, char **argv) {
  if (argc != 2) {
    std::fprintf(stderr, "usage: jma_reference <out.json>\n");
    return 2;
  }
  std::setlocale(LC_NUMERIC, "C");

  if (SAMPLING_RATE != 50 || MAX_SAMPLES != 3000 || N_PAD != 4096 || TOP_N_SAMPLES != 15) {
    std::fprintf(stderr, "unexpected constants in intensity.h\n");
    return 1;
  }
  const int sampleCount = DURATION_SEC * SAMPLING_RATE;
  if (sampleCount % SAMPLES_PER_PACKET != 0 || MAX_SAMPLES % SAMPLES_PER_PACKET != 0 ||
      RECORD_EVERY % SAMPLES_PER_PACKET != 0 || MAX_SAMPLES % RECORD_EVERY != 0 ||
      sampleCount % RECORD_EVERY != 0 || sampleCount < MAX_SAMPLES) {
    std::fprintf(stderr, "recording grid is not aligned to the packet size\n");
    return 1;
  }

  static const Spec kSpecs[] = {
      {"zeros", Kind::kZeros},
      {"h1_sine_1hz_10gal", Kind::kH1Sine},
      {"axes_sine_2hz_50gal", Kind::kAxesSine},
      {"h2_sine_5hz_200gal", Kind::kH2Sine},
      {"lcg_noise_2gal", Kind::kNoise},
      {"lcg_noise_burst_3hz_300gal", Kind::kNoiseBurst},
  };
  const size_t specCount = sizeof(kSpecs) / sizeof(kSpecs[0]);

  JMAIntensityCalculator calc;
  calc.begin();
  if (!calc.isInitialized()) {
    std::fprintf(stderr, "intensity buffers were not allocated\n");
    return 1;
  }

  std::vector<std::vector<Record>> records(specCount);
  for (size_t s = 0; s < specCount; ++s) {
    if (!runSignal(calc, kSpecs[s], sampleCount, records[s]))
      return 1;
  }

  std::vector<double> bpf;
  bandPassH1(bpf);
  if (bpf.size() != 300) {
    std::fprintf(stderr, "bpf produced %zu samples\n", bpf.size());
    return 1;
  }

  if (!writeJson(argv[1], kSpecs, specCount, records, bpf, sampleCount))
    return 1;

  std::fprintf(stderr, "jma_reference: %zu signals x %zu records, %zu bpf -> %s\n", specCount,
               records[0].size(), bpf.size(), argv[1]);
  calc.end();
  calc.releaseBuffers();
  return 0;
}
