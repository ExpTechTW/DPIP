#!/usr/bin/env bash
# Sourced by the native build and launch scripts from the DPIP repository root.
eqr_revision=6c2ca6e21c9a50cd386d5c83064a261227a49326
eqr_tree=0d3d04b3d3b3f7ea4fdd9c12ea6653e84271e8a2

eqr_manifest_hash() {
  case "$1" in
    production) printf '%s\n' 78d38cb38e7283e5b0799fcc8f4e050f868269c20cc080d0a69c5d05e35f25ce ;;
    qa) printf '%s\n' 926624600ae90d1ccaab5e9043bf19e9e581a858d8dd9d4ac986e677d0f64ecb ;;
    *) return 2 ;;
  esac
}

eqr_android_llvm() {
  local sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
  printf '%s/ndk/28.2.13676358/toolchains/llvm/prebuilt/darwin-x86_64/bin\n' "$sdk"
}

eqr_stage() {
  local checkout="$1" profile="$2" candidate="$3" trusted="$4" stage="$5"
  local tree manifest_hash
  tree="$(git -C "$checkout" rev-parse "$eqr_revision^{tree}")" || return
  if [[ $tree != "$eqr_tree" ]]; then
    printf 'Wrong report renderer source tree: %s\n' "$tree" >&2
    return 1
  fi
  manifest_hash="$(eqr_manifest_hash "$profile")" || return
  python3 - "$checkout" "$eqr_revision" "$profile" "$candidate" "$trusted" \
    "$manifest_hash" "$(eqr_android_llvm)" "$stage" <<'PY'
import hashlib
import subprocess
import sys
import tempfile
from pathlib import Path

checkout, revision, profile, candidate, trusted, digest, llvm, stage = sys.argv[1:]
manifest = Path(trusted).resolve()
if Path(candidate).resolve() in manifest.parents:
    sys.exit("Trusted report renderer manifest must be outside the package")
contents = manifest.read_bytes()
if hashlib.sha256(contents).hexdigest() != digest:
    sys.exit(f"Unapproved report renderer manifest for {profile}")

script = "scripts/verify-native-artifacts.py"
source = subprocess.check_output(["git", "-C", checkout, "show", f"{revision}:{script}"])
path = str(Path(checkout, script))
# Give the pinned verifier the same bytes whose digest was checked above.
with tempfile.TemporaryDirectory(prefix="dpip-eqr-trust-") as directory:
    verified_manifest = Path(directory, "manifest.json")
    verified_manifest.write_bytes(contents)
    sys.argv = [path, "stage", "--revision", revision, "--profile", profile,
                "--package", candidate, "--trusted-manifest", str(verified_manifest),
                "--android-llvm", llvm, "--stage-root", stage]
    exec(compile(source, path, "exec"), {"__file__": path, "__name__": "__main__"})
PY
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
