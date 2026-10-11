"""Run a real extension load in the canonical build/bin package directory."""
import argparse
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
PLATFORMS = {
    "windows": ("windows", ".dll", {"x64": "x86_64", "x86": "x86_32", "arm64": "arm64"}),
    "linux": ("linux", ".so", {"x86_64": "x86_64", "i386": "x86_32", "arm64": "arm64", "armv7": "arm32", "riscv64": "rv64", "ppc64": "ppc64"}),
    "macosx": ("macos", ".dylib", {"x86_64": "x86_64", "arm64": "arm64"}),
    "android": ("android", ".so", {"arm64-v8a": "arm64", "armeabi-v7a": "arm32", "x86": "x86_32", "x86_64": "x86_64"}),
    "iphoneos": ("ios", ".dylib", {"arm64": "arm64", "x86_64": "x86_64"}),
    "wasm": ("web", ".wasm", {"wasm32": "wasm32"}),
}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", required=True)
    parser.add_argument("--platform", choices=PLATFORMS, default="windows")
    parser.add_argument("--arch", default="x64")
    parser.add_argument("--mode", choices=("debug", "release", "releasedbg"), default="debug")
    parser.add_argument("--prepare-only", action="store_true")
    args = parser.parse_args()
    plat, extension, arches = PLATFORMS[args.platform]
    arch = arches[args.arch]
    package = ROOT / "build" / "bin" / args.platform / args.arch / args.mode
    binary = package / ("gdx_loader" + extension)
    if not binary.is_file():
        parser.error(f"Build the extension first: {binary}")
    for filename in ("project.godot", "smoke.gd"):
        (package / filename).write_bytes((ROOT / "tests" / "smoke" / filename).read_bytes())
    (package / "gdx_loader.gdextension").write_text(
        '[configuration]\nentry_symbol = "gdx_loader_init"\ncompatibility_minimum = "4.8"\n'
        'reloadable = false\n\n[libraries]\n'
        f'{plat}.{arch} = "res://{binary.name}"\n', encoding="utf-8")
    if args.prepare_only:
        print(f"Prepared smoke project: {package}")
        return
    if args.platform not in ("windows", "linux", "macosx"):
        parser.error("Device/browser platforms require their target runtime; use --prepare-only")
    for flags in (("--editor", "--import"), ("--script", "res://smoke.gd")):
        result = subprocess.run([args.godot, "--headless", "--path", str(package), *flags],
                                capture_output=True, text=True, timeout=120)
        print(result.stdout, end="")
        print(result.stderr, end="")
        if result.returncode or "ERROR:" in result.stderr:
            raise SystemExit(result.returncode or 1)
        if flags[0] == "--script" and "GDX_LOADER_SMOKE_OK" not in result.stdout:
            raise SystemExit("Smoke confirmation missing")


if __name__ == "__main__":
    main()
