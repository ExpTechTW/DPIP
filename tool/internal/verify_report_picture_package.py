"""Check the selected EQR implementation in the final mobile application."""
import hashlib
import json
import plistlib
import re
import subprocess
import sys
import zipfile
from pathlib import Path

FONTS = ("mplus-2p-bold.ttf", "GenShinGothic-Bold.ttf", "NotoSansTC-Black.ttf")


def check(condition, message):
    if not condition:
        raise ValueError(message)


def run(*args):
    return subprocess.check_output(args, text=True)


def check_fonts(read, expected):
    for font in FONTS:
        check(
            hashlib.sha256(read(font)).hexdigest() == expected[f"fonts/{font}"],
            f"Packaged font differs from stage: {font}",
        )


def check_ios(app, link_map, stage, manifest):
    metadata = plistlib.loads((app / "Info.plist").read_bytes())
    executable = app / metadata["CFBundleExecutable"]
    subprocess.run(["codesign", "--verify", "--strict", str(app)], check=True)
    expected = set(manifest["symbols"])
    exports = run("xcrun", "dyld_info", "-exports", executable)
    check(set(re.findall(r"\b_(eqr_\w+)\b", exports)) == expected, "Wrong Mach-O exports")
    stem = "libeq_report_pic_story_qa" if manifest["profile"] == "qa" else "libeq_report_pic"
    roots = set(re.findall(r"\s(/[^\n]+libeq_report_pic\w*\.a)\(", link_map.read_text(errors="replace")))
    check(len(roots) == 1, f"Expected one renderer archive in link map, found {roots}")
    archive = Path(roots.pop())
    check(archive.name == stem + ".a", f"Wrong linked archive: {archive}")
    relative = archive.relative_to(stage)
    check(
        hashlib.sha256(archive.read_bytes()).hexdigest() == manifest["files_sha256"][str(relative)],
        "Linked archive differs from its verified stage",
    )
    fonts = app / "Frameworks/App.framework/flutter_assets/assets/fonts/report"
    check_fonts(lambda name: (fonts / name).read_bytes(), manifest["files_sha256"])
    return f"{executable}, {len(expected)} exports, {relative}"


def check_android(apk, zipalign, manifest):
    stem = "libeq_report_pic_story_qa" if manifest["profile"] == "qa" else "libeq_report_pic"
    with zipfile.ZipFile(apk) as package:
        libraries = [name for name in package.namelist() if re.fullmatch(r"lib/[^/]+/libeq_report_pic\w*\.so", name)]
        check(bool(libraries), "The APK contains no EQR runtime")
        check(len(libraries) == len(set(libraries)), "Duplicate EQR ZIP entries")
        for library in libraries:
            _, abi, name = library.split("/")
            expected = manifest["files_sha256"].get(f"android/{abi}/{stem}.so")
            actual = hashlib.sha256(package.read(library)).hexdigest()
            check(name == stem + ".so" and actual == expected, f"Unexpected ELF: {library}")
            # The stage verifier has already checked the SONAME, exports, ABI,
            # embedded assets and PT_LOAD alignment of these exact ELF bytes.
            check(package.getinfo(library).compress_type == zipfile.ZIP_STORED, f"Compressed ELF: {library}")
        prefix = "assets/flutter_assets/assets/fonts/report/"
        check_fonts(lambda name: package.read(prefix + name), manifest["files_sha256"])
    subprocess.run([zipalign, "-c", "-P", "16", "4", apk], check=True)
    return f"{apk}, {', '.join(libraries)}, zipalign -P 16 OK"


if __name__ == "__main__":
    platform, artifact, directory, inspection, revision = sys.argv[1:]
    stage = Path(directory).resolve()
    manifest = json.loads((stage / "manifest.json").read_text())
    check(manifest["source_commit"] == revision, "The stage uses a different source revision")
    check(manifest["profile"] == stage.name in {"production", "qa"}, "Invalid staged profile")
    check(manifest["abi_version"] == "0x00010003", "Wrong renderer ABI")
    check(manifest["capability_mask"] == "0x31f", "Wrong capability mask")
    if platform == "ios":
        result = check_ios(Path(artifact), Path(inspection), stage, manifest)
    else:
        result = check_android(Path(artifact), Path(inspection), manifest)
    print(f'{platform} {stage.name} {revision}: {result}')
