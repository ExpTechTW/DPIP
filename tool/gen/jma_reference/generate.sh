#!/usr/bin/env bash
# Builds the ES-Net intensity sources and writes
# test/fixtures/seismometer/jma_reference.json.
#
# Every signal is 70 s at 50 Hz. Sample index i runs from 0 through 3499 and
# t = i / 50. The sine on an axis is amp * sin(2 * pi * hz * t):
#   zeros                          h1 = h2 = v = 0
#   h1_sine_1hz_10gal              h1 = 10 * sin(2 * pi * 1 * t)
#   axes_sine_2hz_50gal            h1 = h2 = v = 50 * sin(2 * pi * 2 * t)
#   h2_sine_5hz_200gal             h2 = 200 * sin(2 * pi * 5 * t)
#   lcg_noise_2gal                 h1, then h2, then v, each drawn from the LCG
#   lcg_noise_burst_3hz_300gal     that same noise, plus
#                                  300 * sin(2 * pi * 3 * t) on every axis
#                                  while 40 <= t < 43
#
# LCG, seed 1:
#   state = (1664525 * state + 1013904223) mod 2^32
#   uniform = (state + 0.5) / 2^32
#   sample = (uniform * 2 - 1) * 2          # gal
#
# Once 3000 samples are stored, n = 3000, 3050, ..., 3500 records intensity,
# class, and a. bpf_h1_first_300 is the first 300 outputs of high-pass then
# low-pass on axes_sine_2hz_50gal's h1.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../../.." && pwd)"
es_net="${ES_NET_DIR:-$HOME/Documents/GitHub/ES-Net}"
src="$es_net/src/sensor/intensity.cpp"
out="$root/test/fixtures/seismometer/jma_reference.json"

if [[ ! -f $src ]]; then
  printf 'ES-Net intensity.cpp not found: %s\n' "$src" >&2
  exit 1
fi

mkdir -p "$(dirname "$out")"

bin="$(mktemp "${TMPDIR:-/tmp}/jma_reference.XXXXXX")"
trap 'rm -f "$bin"' EXIT

clang++ -O2 -std=c++17 \
  -I "$here/stubs" \
  -I "$es_net/src/sensor" \
  -DDURATION_SEC=70 \
  -DRECORD_EVERY=50 \
  -DLCG_A=1664525 \
  -DLCG_C=1013904223 \
  -DLCG_SEED=1 \
  -DLCG_AMP_GAL=2 \
  -DBURST_START_SEC=40 \
  -DBURST_END_SEC=43 \
  -DBURST_HZ=3 \
  -DBURST_GAL=300 \
  -o "$bin" \
  "$here/harness.cpp" \
  "$src"

"$bin" "$out"
