#!/usr/bin/env bash
# Measures the home weather animation on an Android emulator, the same way for
# every scene, so a build can be compared number for number with another.
#
#     tool/dev/build.sh android-profile --dart-define=DPIP_FRAME_BENCH=true
#     adb install -r build/app/outputs/flutter-apk/app-profile.apk
#     tool/dev/bench_sky.sh [--out DIR] [--runs N] [--scene weather:sky]
#
# One profile APK covers every scene. With DPIP_FRAME_BENCH the home backdrop
# reads files/bench_sky.txt ("<weather> <skyTime>", WeatherMode / SkyTimeMode
# names) before the experimental settings — see lib/core/diagnostics/bench_sky.dart.
# DPIP_BENCH_WEATHER and DPIP_BENCH_SKY_TIME are the compile-time fallback and
# do nothing unless DPIP_FRAME_BENCH is set. Both are off in a normal build.
#
# Default scenes, two runs each: clear/noon, clear/night, overcast/noon,
# rain/noon, thunderstorm/noon, snow/noon. Noon is pinned on the scenes that
# do not name a time so a run does not follow the wall clock. The app has to
# be past onboarding already. The sheet is dragged open past the 85 % weather
# gate, held for the warmup, then measured.
#
# What one run reports, for the measure window only:
#   - Flutter frames (build and raster times, from frame_bench.dart)
#   - CPU percent of one core, every thread
#   - TOTAL PSS and native heap from dumpsys meminfo
#   - a screenshot
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
cd "$(repo_root)"

out="build/bench/sky"
runs=2
warmup=10
measure=20
startup=90
custom=0
scenes=()
while (($#)); do
  case "$1" in
    --out) out="$2"; shift 2 ;;
    --runs) runs="$2"; shift 2 ;;
    --warmup) warmup="$2"; shift 2 ;;
    --measure) measure="$2"; shift 2 ;;
    --startup) startup="$2"; shift 2 ;;
    --scene)
      if ((custom == 0)); then scenes=(); custom=1; fi
      scenes+=("$2")
      shift 2
      ;;
    *) printf 'unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
done
if ((custom == 0)); then
  scenes=(
    "clear:noon"
    "clear:night"
    "overcast:noon"
    "rain:noon"
    "thunderstorm:noon"
    "snow:noon"
  )
fi

ADB="${ADB:-/Users/yuyu1015/.local/share/mise/installs/android-sdk/1.0/platform-tools/adb}"
if [[ ! -x $ADB ]]; then
  ADB="$(command -v adb || true)"
fi
[[ -n ${ADB:-} && -x $ADB ]] || { printf 'adb is not available\n' >&2; exit 1; }
serial="${ANDROID_SERIAL:-emulator-5554}"
pkg=com.exptech.dpip

"$ADB" -s "$serial" get-state >/dev/null 2>&1 || {
  printf 'device %s is not online\n' "$serial" >&2
  exit 1
}
mkdir -p "$out"

now_ms() { "$ADB" -s "$serial" shell date +%s%3N | tr -d '\r'; }
cpu_ticks() { "$ADB" -s "$serial" shell cat "/proc/$1/stat" | awk '{print $14 + $15}'; }

# The system ANR dialog steals the drag and then the measure window. It is a
# focus window, not part of the app, so a pixel probe of the map cannot see it.
anr_focused() {
  "$ADB" -s "$serial" shell dumpsys window | grep -F "mCurrentFocus=" | grep -q "Application Not Responding: $pkg"
}

dismiss_anr() {
  anr_focused || return 0
  printf 'ANR dialog is up; closing it\n' >&2
  "$ADB" -s "$serial" shell uiautomator dump /sdcard/dpip_uidump.xml >/dev/null || true
  local tap
  tap="$("$ADB" -s "$serial" shell cat /sdcard/dpip_uidump.xml | python3 -I -c '
import re, sys
xml = sys.stdin.read()
m = re.search(
    r"resource-id=.android:id/aerr_close.[^>]*bounds=.\[(\d+),(\d+)\]\[(\d+),(\d+)\]",
    xml,
)
if not m:
    sys.exit(1)
x1, y1, x2, y2 = (int(v) for v in m.groups())
print((x1 + x2) // 2, (y1 + y2) // 2)
')" || true
  if [[ -n $tap ]]; then
    # shellcheck disable=SC2086
    "$ADB" -s "$serial" shell input tap $tap
  fi
  sleep 1
}

read -r screen_w screen_h < <("$ADB" -s "$serial" shell wm size | awk -F'[ x]' '/Physical/ {print $3, $4}' | tr -d '\r')
[[ -n ${screen_w:-} && -n ${screen_h:-} ]] || { printf 'could not read the screen size\n' >&2; exit 1; }

# Rest extent is 1/3, so the snap midpoint on the way to full is a drag of
# about a third of the screen. Start on the sheet (below that top edge) and
# stop short of full travel so the list itself does not scroll — a scrolled
# list freezes the sky.
swipe_x=$((screen_w / 2))
swipe_y0=$((screen_h * 80 / 100))
swipe_y1=$((screen_h * 42 / 100))

measure_one() {
  local weather="$1" sky="$2" run="$3"
  local label="${weather}-${sky}-${run}"
  step "Scene ${weather} / ${sky}, run ${run}"

  dismiss_anr
  "$ADB" -s "$serial" shell am force-stop "$pkg" >/dev/null
  "$ADB" -s "$serial" shell run-as "$pkg" mkdir -p files >/dev/null
  # stdin, not a redirected `sh -c` argument: the device shell would otherwise
  # eat the `>` and write the file outside the app directory.
  printf '%s\n' "${weather} ${sky}" | "$ADB" -s "$serial" shell "run-as $pkg sh -c 'cat > files/bench_sky.txt'"
  "$ADB" -s "$serial" shell run-as "$pkg" rm -f files/frame_bench.csv >/dev/null 2>&1 || true

  "$ADB" -s "$serial" shell input keyevent KEYCODE_WAKEUP >/dev/null
  "$ADB" -s "$serial" shell wm dismiss-keyguard >/dev/null 2>&1 || true
  local activity
  activity="$("$ADB" -s "$serial" shell cmd package resolve-activity --brief -c android.intent.category.LAUNCHER "$pkg" | tail -1 | tr -d '\r')"
  # -W often times out while the splash is still up; the poll below is the
  # real "home is on screen" signal. A swipe during the splash hits nothing
  # and the sheet stays at rest, so the sky ticker never starts.
  "$ADB" -s "$serial" shell am start -W -n "$activity" >/dev/null || true

  python3 -I - "$ADB" "$serial" "$startup" <<'PY' || exit 1
import struct, subprocess, sys, time
adb, serial, budget = sys.argv[1], sys.argv[2], float(sys.argv[3])
deadline = time.time() + budget

def pixel(x, y):
    data = subprocess.check_output([adb, "-s", serial, "exec-out", "screencap"])
    w, h, _fmt = struct.unpack_from("<III", data, 0)
    off = 12 + (y * w + x) * 4
    return struct.unpack_from("<BBB", data, off)

# The splash is white behind the mark. Home at rest shows the map there.
while time.time() < deadline:
    r, g, b = pixel(200, 400)
    if not (r > 245 and g > 245 and b > 245):
        print(f"home is up ({r},{g},{b})", flush=True)
        break
    time.sleep(2)
else:
    sys.exit("the splash never left")
PY
  # The sheet attaches a moment after the first non-splash frame.
  sleep 2

  local pid
  pid="$("$ADB" -s "$serial" shell pidof "$pkg" | awk '{print $1}' | tr -d '\r')"
  [[ -n $pid ]] || { printf 'the app did not start\n' >&2; exit 1; }

  "$ADB" -s "$serial" shell input swipe "$swipe_x" "$swipe_y0" "$swipe_x" "$swipe_y1" 800
  sleep 1.5
  # (540, 900) is the flat map grey (~174) while the sheet rests, and the sky
  # once it has snapped open. One retry if the first drag missed the sheet.
  if ! python3 -I - "$ADB" "$serial" <<'PY'
import struct, subprocess, sys
adb, serial = sys.argv[1], sys.argv[2]
data = subprocess.check_output([adb, "-s", serial, "exec-out", "screencap"])
w, h, _fmt = struct.unpack_from("<III", data, 0)
off = 12 + (900 * w + 540) * 4
r, g, b = struct.unpack_from("<BBB", data, off)
closed = (
    165 <= r <= 185
    and 165 <= g <= 185
    and 165 <= b <= 185
    and max(r, g, b) - min(r, g, b) < 8
)
print(f"sheet probe ({r},{g},{b}) closed={closed}", flush=True)
sys.exit(1 if closed else 0)
PY
  then
    "$ADB" -s "$serial" shell input swipe "$swipe_x" "$swipe_y0" "$swipe_x" "$swipe_y1" 800
    sleep 1.5
  fi
  if anr_focused; then
    "$ADB" -s "$serial" exec-out screencap -p > "$out/$label.png" || true
    printf 'ANR dialog is up after the drag\n' >&2
    return 86
  fi
  step "Warmup ${warmup}s, then measure ${measure}s"
  sleep "$warmup"

  local t0 c0 t1 c1
  t0="$(now_ms)"
  c0="$(cpu_ticks "$pid")"
  sleep "$measure"
  t1="$(now_ms)"
  c1="$(cpu_ticks "$pid")"

  "$ADB" -s "$serial" shell dumpsys meminfo "$pkg" > "$out/$label.meminfo.txt"
  "$ADB" -s "$serial" exec-out screencap -p > "$out/$label.png"
  if anr_focused; then
    printf 'ANR dialog covered the measure window\n' >&2
    return 86
  fi
  if ! "$ADB" -s "$serial" shell run-as "$pkg" cat files/frame_bench.csv > "$out/$label.frames.csv"; then
    printf 'frame_bench.csv missing — rebuild with --dart-define=DPIP_FRAME_BENCH=true\n' >&2
    : > "$out/$label.frames.csv"
  fi

  python3 -I - "$out" "$label" "$weather" "$sky" "$run" "$t0" "$t1" "$c0" "$c1" <<'PY'
import json, re, sys
out, label, weather, sky, run = sys.argv[1:6]
t0, t1, c0, c1 = map(int, sys.argv[6:10])
rows = []
with open(f'{out}/{label}.frames.csv') as f:
    for line in f:
        p = line.strip().split(',')
        if len(p) == 4:
            rows.append(tuple(int(x) for x in p))

def pct(xs, q):
    if not xs:
        return None
    xs = sorted(xs)
    return round(xs[min(len(xs) - 1, int(q * len(xs)))] / 1000, 2)

fr = [r for r in rows if t0 <= r[0] <= t1]
build = [r[1] for r in fr]
raster = [r[2] for r in fr]
secs = (t1 - t0) / 1000
mem = open(f'{out}/{label}.meminfo.txt').read()

def kb(name):
    m = re.search(rf'^\s*{re.escape(name)}:\s+(\d+)', mem, re.M)
    return int(m.group(1)) if m else None

result = {
    'label': label,
    'weather': weather,
    'sky': sky,
    'run': int(run),
    'seconds': round(secs, 2),
    'frames': len(fr),
    'build_ms': {'p50': pct(build, .5), 'p90': pct(build, .9), 'p99': pct(build, .99)},
    'raster_ms': {'p50': pct(raster, .5), 'p90': pct(raster, .9), 'p99': pct(raster, .99)},
    'cpu_percent': round((c1 - c0) / 100 / secs * 100, 1) if secs else None,
    'memory_kb': {'total_pss': kb('TOTAL PSS'), 'native_heap': kb('Native Heap')},
}
json.dump(result, open(f'{out}/{label}.json', 'w'), indent=2)
print(json.dumps(result, indent=2))
if not fr:
    print('no frames in the measure window', file=sys.stderr)
    sys.exit(86)
PY
}

for spec in "${scenes[@]}"; do
  weather="${spec%%:*}"
  sky="${spec##*:}"
  [[ $weather != "$spec" && -n $sky ]] || {
    printf 'scene must be weather:sky, got %s\n' "$spec" >&2
    exit 2
  }
  for ((run = 1; run <= runs; run++)); do
    # A wedged UI thread (the ANR dialog) records zero frames. One retry,
    # after the dialog is closed, keeps a single stall from ending the suite.
    if ! measure_one "$weather" "$sky" "$run"; then
      dismiss_anr
      measure_one "$weather" "$sky" "$run" || exit 1
    fi
  done
done

python3 -I - "$out" <<'PY'
import json, pathlib, sys
out = pathlib.Path(sys.argv[1])
rows = []
for path in sorted(out.glob('*.json')):
    if path.name == 'summary.json':
        continue
    rows.append(json.loads(path.read_text()))
json.dump(rows, open(out / 'summary.json', 'w'), indent=2)

def cell(v):
    return '-' if v is None else str(v)

print()
print(f'{"scene":<22} {"run":>3} {"frames":>7} {"cpu%":>6} {"build p50":>9} {"build p90":>9} {"build p99":>9} {"rast p50":>9} {"rast p90":>9} {"rast p99":>9} {"pss":>8} {"native":>8}')
for r in rows:
    b, a = r['build_ms'], r['raster_ms']
    mem = r['memory_kb']
    print(
        f'{r["weather"] + "/" + r["sky"]:<22} {r["run"]:>3} {r["frames"]:>7} '
        f'{cell(r["cpu_percent"]):>6} {cell(b["p50"]):>9} {cell(b["p90"]):>9} {cell(b["p99"]):>9} '
        f'{cell(a["p50"]):>9} {cell(a["p90"]):>9} {cell(a["p99"]):>9} '
        f'{cell(mem["total_pss"]):>8} {cell(mem["native_heap"]):>8}'
    )
PY
