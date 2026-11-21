#!/usr/bin/env bash
# Build the optional report-image runtime from a verified local source checkout.
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
root="$(repo_root)"
revision=b135d02bd1ba5103cd3d116a951b1b63a710a312

platform="${1:-}"
source_checkout="${2:-}"
if [[ $# -ne 2 || ! $platform =~ ^(ios|android)$ ]]; then
  printf 'Usage: %s {ios|android} <eq-report-pic checkout>\n' "$0" >&2
  exit 2
fi

if ! git -C "$source_checkout" cat-file -e "$revision^{commit}"; then
  printf 'Fetch pinned eq-report-pic revision %s into the source checkout.\n' "$revision" >&2
  exit 1
fi

# Build a snapshot of the committed inputs, leaving the source checkout alone.
runtime="$root/native/eq_report_pic"
mkdir -p "$runtime"
scratch="$(mktemp -d "$runtime/.build.XXXXXX")"
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/source" "$scratch/fonts"
git -C "$source_checkout" archive "$revision" | tar -xf - -C "$scratch/source"
cd "$scratch/source"
shasum -a 256 -c .github/cargo/Cargo.lock.sha256
tar -xzf .github/cargo/vendor.tar.gz
mkdir -p .cargo
cat > .cargo/config.toml <<'CONFIG'
[source.crates-io]
replace-with = "vendored-sources"

[source.vendored-sources]
directory = "vendor"
CONFIG

toolchain="$(sed -n 's/^channel = "\([^"]*\)"$/\1/p' rust-toolchain.toml)"
unset RUSTFLAGS
export CARGO_ENCODED_RUSTFLAGS="--remap-path-prefix=$scratch=/eq-report-pic"
export CARGO_TARGET_DIR="$scratch/target"
build() {
  rustup run "$toolchain" cargo build --frozen --release --lib --target "$1"
}

symbols="$scratch/symbols"
sed -nE 's/^[[:alnum:]_ *]+[ *](eqr_[[:alnum:]_]+)\(.*/\1/p' \
  include/eq_report_pic.h | LC_ALL=C sort > "$symbols"
[[ "$(wc -l < "$symbols" | tr -d ' ')" == 9 ]]

case "$platform" in
  ios)
    export IPHONEOS_DEPLOYMENT_TARGET=15.0
    mkdir -p "$scratch/ios" "$scratch/simulator"
    build aarch64-apple-ios
    build aarch64-apple-ios-sim
    build x86_64-apple-ios
    xcrun lipo -create \
      "$CARGO_TARGET_DIR/aarch64-apple-ios-sim/release/libeq_report_pic.a" \
      "$CARGO_TARGET_DIR/x86_64-apple-ios/release/libeq_report_pic.a" \
      -output "$scratch/simulator/libeq_report_pic.a"
    xcodebuild -create-xcframework \
      -library "$CARGO_TARGET_DIR/aarch64-apple-ios/release/libeq_report_pic.a" \
      -library "$scratch/simulator/libeq_report_pic.a" \
      -output "$scratch/ios/EqReportPic.xcframework"

    # Only Runner consumes these flags. Keep the linker roots even under dead
    # stripping so symbols with no native caller are still visible to Dart.
    {
      printf 'DPIP_EQR_XCFRAMEWORK = $(SRCROOT)/../native/eq_report_pic/ios/EqReportPic.xcframework\n'
      printf 'DPIP_EQR_SLICE[sdk=iphoneos*] = ios-arm64\n'
      printf 'DPIP_EQR_SLICE[sdk=iphonesimulator*] = ios-arm64_x86_64-simulator\n'
      printf 'DPIP_EQR_LINK = "$(DPIP_EQR_XCFRAMEWORK)/$(DPIP_EQR_SLICE)/libeq_report_pic.a"'
      while IFS= read -r symbol; do
        printf ' -Wl,-u,_%s' "$symbol"
      done < "$symbols"
      printf '\n'
    } > "$scratch/ios/link.xcconfig"
    xcodebuild -version > "$scratch/ios/toolchain.txt"
    ;;
  android)
    ndk_version=28.2.13676358
    sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
    case "$(uname -s)" in
      Darwin) host_tag=darwin-x86_64 ;;
      Linux) host_tag=linux-x86_64 ;;
      *) printf 'The Android report runtime build requires macOS or Linux.\n' >&2; exit 1 ;;
    esac
    llvm="$sdk/ndk/$ndk_version/toolchains/llvm/prebuilt/$host_tag/bin"
    if [[ ! -x $llvm/llvm-readelf ]]; then
      printf 'Install Android NDK %s in %s.\n' "$ndk_version" "$sdk" >&2
      exit 1
    fi
    for abi in arm64-v8a x86_64; do
      case "$abi" in
        arm64-v8a) target=aarch64-linux-android ;;
        x86_64) target=x86_64-linux-android ;;
      esac
      linker_var="CARGO_TARGET_$(printf '%s' "$target" | tr 'a-z-' 'A-Z_')_LINKER"
      env "$linker_var=$llvm/${target}26-clang" \
        rustup run "$toolchain" cargo build --frozen --release --lib --target "$target"
      output="$scratch/android/$abi/libeq_report_pic.so"
      mkdir -p "$(dirname "$output")"
      "$llvm/llvm-strip" --strip-debug "$CARGO_TARGET_DIR/$target/release/libeq_report_pic.so" -o "$output"
      "$llvm/llvm-nm" -D --defined-only "$output" | awk '{print $NF}' \
        | LC_ALL=C sort | diff - "$symbols"
      "$llvm/llvm-readelf" --program-headers --wide "$output" \
        | awk '$1 == "LOAD" {n++; if ($NF != "0x4000") exit 1} END {if (!n) exit 1}'
    done
    "$llvm/clang" --version > "$scratch/android/toolchain.txt"
    printf 'NDK %s, API 26\n' "$ndk_version" >> "$scratch/android/toolchain.txt"
    ;;
esac

# Preserve the fonts' embedded licenses and ship the dependency notices with
# the runtime. The native archive and the basemap are not checked into DPIP.
cp assets/fonts/*.ttf "$scratch/fonts/"
sysroot="$(rustup run "$toolchain" rustc --print sysroot)"
cp "$sysroot/share/doc/rust/COPYRIGHT-library.html" "$scratch/fonts/rust-library-copyright.html"
{
  printf 'eq-report-pic source revision: %s\n' "$revision"
  find vendor -maxdepth 2 -type f \( -iname 'license*' -o -iname 'copying*' -o -iname 'notice*' \) \
    | LC_ALL=C sort | while IFS= read -r notice; do
      printf '\n--- %s ---\n' "$notice"
      cat "$notice"
      printf '\n'
    done
} > "$scratch/fonts/third-party-notices.txt"
rustup run "$toolchain" rustc -Vv >> "$scratch/$platform/toolchain.txt"
printf '%s\n' "$revision" > "$scratch/$platform/source-revision.txt"
mkdir -p "$runtime/$platform"
rsync -a --delete "$scratch/$platform/" "$runtime/$platform/"
cp "$scratch/fonts/"* "$root/assets/fonts/report/"
cd "$root"
{
  find "native/eq_report_pic/$platform" -type f ! -name SHA256SUMS
  printf '%s\n' assets/fonts/report/*.ttf assets/fonts/report/OFL.txt \
    assets/fonts/report/README.md assets/fonts/report/third-party-notices.txt \
    assets/fonts/report/rust-library-copyright.html
} | LC_ALL=C sort | while IFS= read -r artifact; do
  shasum -a 256 "$artifact"
done | tee "$runtime/$platform/SHA256SUMS"
