#!/usr/bin/env bash
# Sourced by the native build and launch scripts from the DPIP repository root.
eqr_revision=76662bb9710eafa2a77a694605513163db7c5967

eqr_android_llvm() {
  local sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
  printf '%s/ndk/28.2.13676358/toolchains/llvm/prebuilt/darwin-x86_64/bin\n' "$sdk"
}

eqr_stage() {
  local checkout="$1" profile="$2" candidate="$3" trusted="$4" stage="$5"
  local verifier
  verifier="$(git -C "$checkout" show "$eqr_revision:scripts/verify-native-artifacts.py")"
  python3 -c 'import sys
source = sys.stdin.read()
sys.argv = sys.argv[1:]
exec(compile(source, sys.argv[0], "exec"), {"__file__": sys.argv[0], "__name__": "__main__"})
' "$checkout/scripts/verify-native-artifacts.py" stage \
    --revision "$eqr_revision" --profile "$profile" --package "$candidate" \
    --trusted-manifest "$trusted" --android-llvm "$(eqr_android_llvm)" --stage-root "$stage" <<< "$verifier"
}

eqr_stage_fonts() {
  # Both profiles use the same three verified fonts. Replace individual assets
  # atomically so another build cannot read a partial file.
  python3 - "$1" <<'PY'
import os
import shutil
import sys
import tempfile
from pathlib import Path

package = Path(sys.argv[1])
assets = Path("assets/fonts/report")
files = {p.name: p for p in (package / "fonts").glob("*.ttf")}
files["third-party-notices.txt"] = package / "third-party-notices.txt"
files["rust-library-copyright.html"] = package / "COPYRIGHT-library.html"
for name, source in files.items():
    destination = assets / name
    if destination.is_file() and destination.read_bytes() == source.read_bytes():
        continue
    with tempfile.NamedTemporaryFile(dir=assets, prefix=".eqr-", delete=False) as temporary:
        with source.open("rb") as stream:
            shutil.copyfileobj(stream, temporary)
    os.replace(temporary.name, destination)
PY
}
