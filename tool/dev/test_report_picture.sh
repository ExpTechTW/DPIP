#!/usr/bin/env bash
# Host-side ABI and lifecycle tests with deterministic C fixtures (no Rust).
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
cd "$(repo_root)"

case "$(uname -s)" in
  Darwin) extension=dylib ;;
  Linux) extension=so ;;
  *) printf 'The report-picture ABI tests require macOS or Linux.\n' >&2; exit 2 ;;
esac
if [[ $(getconf LONG_BIT) != 64 ]]; then
  printf 'The report-picture ABI tests require a 64-bit host.\n' >&2
  exit 2
fi
fixtures="$(mktemp -d "${TMPDIR:-/tmp}/dpip-eqr-ffi.XXXXXX")"
trap 'rm -rf "$fixtures"' EXIT

build_fixture() {
  local name="$1"
  shift
  cc -shared -fPIC "$@" test/shared/seismic/report_picture_ffi_fixture.c \
    -o "$fixtures/$name.$extension"
}
build_fixture supported
build_fixture abi-1-3 -DABI=0x00010003 -DCAPS=0x310 -DWITH_OPTIONS
build_fixture story-qa -DABI=0x00010003 -DCAPS=0x31f -DWITH_OPTIONS -DWITH_STORY
build_fixture missing-4-5-symbol -DABI=0x00010003 -DCAPS=0x310
build_fixture missing-4-5-capability -DABI=0x00010003 -DWITH_OPTIONS
build_fixture missing-abi -DOMIT_ABI
build_fixture old-abi -DABI=0x00010001
build_fixture incompatible-major -DABI=0x00020002
build_fixture missing-v2-capability -DCAPS=0x100
build_fixture missing-16-9-capability -DCAPS=0x010
build_fixture missing-render -DOMIT_RENDER

pinned flutter test --flavor storyqa \
  --dart-define=DPIP_EQR_STORY_SYMBOL=eqr_qa_render_story_png_v1 --dart-define="DPIP_EQR_FFI_FIXTURES=$fixtures" \
  test/core/platform/native_library_test.dart \
  test/shared/seismic/report_picture_test.dart \
  test/shared/seismic/eq_report_pic_bindings_test.dart "$@"
