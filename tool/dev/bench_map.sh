#!/usr/bin/env bash
# Measures one map surface on an Android device or emulator, the same way for
# every build, so two builds can be compared number for number.
#
#     tool/dev/build.sh android-profile --dart-define=DPIP_FRAME_BENCH=true
#     adb install -r build/app/outputs/flutter-apk/app-profile.apk
#     tool/dev/bench_map.sh <label> [--surface map|home] [--out DIR]
#
# Needs a rooted adb (an emulator's `adb root`): the gestures are raw
# multi-touch events written to the touchscreen, so a pinch is a real two-finger
# pinch with the same timing on every run, through the app's real gesture
# handling. `input swipe` cannot pinch, and a double tap made of two `input`
# processes arrives too far apart to count as one.
#
# What it reports, for an idle window and then for the gesture script:
#   - Flutter frames (build and raster times, from `lib/core/diagnostics/frame_bench.dart`)
#   - CPU seconds the process used — every thread, the map's native ones too,
#     which no Flutter frame timing can see
#   - memory from `dumpsys meminfo` after the run
#
# The app has to be past onboarding already. Taps are for a 1080x1920 screen.
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
cd "$(repo_root)"

label="${1:?usage: tool/dev/bench_map.sh <label> [--surface map|home] [--out DIR]}"
shift
surface=map
out="build/bench"
idle_seconds=10
while (($#)); do
  case "$1" in
    --surface) surface="$2"; shift 2 ;;
    --out) out="$2"; shift 2 ;;
    --idle) idle_seconds="$2"; shift 2 ;;
    *) printf 'unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
done

pkg=com.exptech.dpip
command -v adb >/dev/null || { printf 'adb is not on PATH\n' >&2; exit 1; }
adb get-state >/dev/null 2>&1 || { printf 'no device\n' >&2; exit 1; }
adb root >/dev/null 2>&1 || true
adb wait-for-device
mkdir -p "$out"

# The touchscreen: the first device that reports multi-touch positions.
touch_dev="$(adb shell getevent -pl 2>/dev/null | awk '
  /^add device/ { dev = $4 }
  /ABS_MT_POSITION_X/ && dev != "" { print dev; exit }' | tr -d '\r')"
[[ -n $touch_dev ]] || { printf 'no multi-touch device found\n' >&2; exit 1; }
read -r screen_w screen_h < <(adb shell wm size | awk -F'[ x]' '/Physical/ {print $3, $4}' | tr -d '\r')

step "Generating the gesture script for ${screen_w}x${screen_h} on $touch_dev"
gestures="$(mktemp -d)"
trap 'rm -rf "$gestures"' EXIT
python3 -I - "$gestures" "$screen_w" "$screen_h" "$surface" <<'PY'
import os, struct, sys

out, w, h, surface = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), sys.argv[4]
EV_SYN, EV_KEY, EV_ABS = 0, 1, 3
SLOT, TRACK, X, Y, BTN_TOUCH = 0x2F, 0x39, 0x35, 0x36, 0x14A
# The emulator's touchscreen reports pressure, and Android treats a contact
# with none as a hover rather than a touch.
TOUCH_MAJOR, PRESSURE = 0x30, 0x3A
frames = []  # (events, seconds to wait after)

def ev(t, c, v):
    return struct.pack('<qqHHi', 0, 0, t, c, v)

def sx(px): return int(px * 32767 / w)
def sy(py): return int(py * 32767 / h)

state = {}  # slot -> tracking id currently down
next_id = [100]

def frame(points, wait=1 / 60):
    """points: {slot: (x, y)} still down after this frame."""
    b = b''
    for slot in sorted(set(state) - set(points)):
        b += ev(EV_ABS, SLOT, slot) + ev(EV_ABS, TRACK, -1)
        del state[slot]
    for slot, (x, y) in sorted(points.items()):
        b += ev(EV_ABS, SLOT, slot)
        if slot not in state:
            state[slot] = next_id[0]; next_id[0] += 1
            b += ev(EV_ABS, TRACK, state[slot])
        b += ev(EV_ABS, X, sx(x)) + ev(EV_ABS, Y, sy(y))
        b += ev(EV_ABS, TOUCH_MAJOR, 6) + ev(EV_ABS, PRESSURE, 64)
    touching = 1 if points else 0
    b += ev(EV_KEY, BTN_TOUCH, touching) + ev(EV_SYN, 0, 0)
    frames.append((b, wait))

def pause(seconds):
    b, _ = frames[-1]
    frames[-1] = (b, seconds)

def drag(x0, y0, x1, y1, ms=400):
    n = max(2, round(ms / 1000 * 60))
    for i in range(n + 1):
        f = i / n
        frame({0: (x0 + (x1 - x0) * f, y0 + (y1 - y0) * f)})
    frame({})
    pause(0.35)

def pinch(cx, cy, d0, d1, ms=600):
    n = max(2, round(ms / 1000 * 60))
    for i in range(n + 1):
        d = d0 + (d1 - d0) * i / n
        frame({0: (cx - d / 2, cy), 1: (cx + d / 2, cy)})
    frame({})
    pause(0.8)

cx, cy = w / 2, h * 0.45
for _ in range(2):
    drag(cx + 250, cy, cx - 250, cy)
    drag(cx, cy - 300, cx, cy + 300)
    drag(cx - 250, cy, cx + 250, cy)
    drag(cx, cy + 300, cx, cy - 300)
pinch(cx, cy, 200, 700)
pinch(cx, cy, 200, 700)
for _ in range(2):
    drag(cx + 300, cy + 200, cx - 300, cy - 200)
    drag(cx - 300, cy - 200, cx + 300, cy + 200)
pinch(cx, cy, 700, 200)
pinch(cx, cy, 700, 200)
drag(cx + 250, cy, cx - 250, cy, ms=200)  # a fling
pause(2.0)

with open(os.path.join(out, 'plan.bin'), 'wb') as plan:
    for b, wait in frames:
        plan.write(struct.pack('>ii', int(wait * 1_000_000), len(b)) + b)
print(f'{len(frames)} frames, {sum(w for _, w in frames):.1f} s')
PY
# The replayer: one Java process for the whole window (see Inject.java).
build_tools="$(ls -d "${ANDROID_HOME:-$(dirname "$(dirname "$(command -v adb)")")}"/build-tools/* | sort -V | tail -1)"
command -v javac >/dev/null || { printf 'javac is not on PATH\n' >&2; exit 1; }
javac --release 8 -d "$gestures" tool/dev/bench_inject/Inject.java 2>/dev/null
"$build_tools/d8" --min-api 26 --output "$gestures" "$gestures/Inject.class"
adb shell rm -rf /data/local/tmp/dpip-bench >/dev/null
adb shell mkdir -p /data/local/tmp/dpip-bench
adb push "$gestures/plan.bin" "$gestures/classes.dex" /data/local/tmp/dpip-bench/ >/dev/null

now_ms() { adb shell date +%s%3N | tr -d '\r'; }
cpu_ticks() { adb shell cat "/proc/$1/stat" | awk '{print $14 + $15, $20}'; }

step "Starting $pkg"
adb shell am force-stop "$pkg"
adb shell run-as "$pkg" rm -f files/frame_bench.csv 2>/dev/null || true
activity="$(adb shell cmd package resolve-activity --brief -c android.intent.category.LAUNCHER "$pkg" | tail -1 | tr -d '\r')"
adb shell am start -W -n "$activity" >/dev/null
sleep 8
pid="$(adb shell pidof "$pkg" | tr -d '\r')"
[[ -n $pid ]] || { printf 'the app did not start\n' >&2; exit 1; }

if [[ $surface == map ]]; then
  # The map tab: the middle of five destinations in the bottom bar.
  adb shell input tap $((screen_w / 2)) $((screen_h - 120))
  sleep 6
fi

step "Idle window: ${idle_seconds}s"
idle_t0="$(now_ms)"; read -r idle_c0 _ < <(cpu_ticks "$pid")
sleep "$idle_seconds"
idle_t1="$(now_ms)"; read -r idle_c1 _ < <(cpu_ticks "$pid")

step "Gesture window"
gest_t0="$(now_ms)"; read -r gest_c0 _ < <(cpu_ticks "$pid")
adb shell CLASSPATH=/data/local/tmp/dpip-bench/classes.dex app_process /data/local/tmp/dpip-bench Inject \
  /data/local/tmp/dpip-bench/plan.bin "$touch_dev"
gest_t1="$(now_ms)"; read -r gest_c1 threads < <(cpu_ticks "$pid")

adb shell dumpsys meminfo "$pkg" > "$out/$label.meminfo.txt"
adb shell run-as "$pkg" cat files/frame_bench.csv > "$out/$label.frames.csv" 2>/dev/null || true
adb exec-out screencap -p > "$out/$label.png"

python3 -I - "$out" "$label" "$surface" \
  "$idle_t0" "$idle_t1" "$idle_c0" "$idle_c1" \
  "$gest_t0" "$gest_t1" "$gest_c0" "$gest_c1" "$threads" <<'PY'
import json, re, sys

out, label, surface = sys.argv[1:4]
it0, it1, ic0, ic1, gt0, gt1, gc0, gc1, threads = map(int, sys.argv[4:13])
rows = []
with open(f'{out}/{label}.frames.csv') as f:
    for line in f:
        p = line.strip().split(',')
        if len(p) == 4:
            rows.append(tuple(int(x) for x in p))

def pct(xs, q):
    if not xs: return None
    xs = sorted(xs)
    return round(xs[min(len(xs) - 1, int(q * len(xs)))] / 1000, 2)

def window(t0, t1, c0, c1):
    fr = [r for r in rows if t0 <= r[0] <= t1]
    build = [r[1] for r in fr]; raster = [r[2] for r in fr]; total = [r[3] for r in fr]
    secs = (t1 - t0) / 1000
    return {
        'seconds': round(secs, 2),
        'frames': len(fr),
        'build_ms': {'p50': pct(build, .5), 'p90': pct(build, .9), 'p99': pct(build, .99), 'max': pct(build, 1)},
        'raster_ms': {'p50': pct(raster, .5), 'p90': pct(raster, .9), 'p99': pct(raster, .99), 'max': pct(raster, 1)},
        'janky_over_16ms': sum(1 for t in total if t > 16_667),
        'cpu_seconds': round((c1 - c0) / 100, 2),
        'cpu_percent_of_one_core': round((c1 - c0) / 100 / secs * 100, 1),
    }

mem = open(f'{out}/{label}.meminfo.txt').read()
def kb(name):
    m = re.search(rf'^\s*{name}:\s+(\d+)', mem, re.M)
    return int(m.group(1)) if m else None
result = {
    'label': label, 'surface': surface, 'threads': threads,
    'idle': window(it0, it1, ic0, ic1),
    'gestures': window(gt0, gt1, gc0, gc1),
    'memory_kb': {'total_pss': kb('TOTAL PSS'), 'graphics': kb('Graphics'),
                  'native_heap': kb('Native Heap'), 'java_heap': kb('Java Heap')},
}
json.dump(result, open(f'{out}/{label}.json', 'w'), indent=2)
print(json.dumps(result, indent=2))
PY
