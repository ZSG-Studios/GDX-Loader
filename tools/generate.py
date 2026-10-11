"""Generate only changed Godot 4.8 bindings, using the upstream generator."""
import argparse
import hashlib
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from binding_generator import generate_bindings
from build_profile import generate_trimmed_api

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--bits", choices=("32", "64"), default="64")
    parser.add_argument("--precision", choices=("single", "double"), default="single")
    parser.add_argument("--profile", type=Path)
    parser.add_argument("--hooks", type=Path)
    parser.add_argument("--api", type=Path, default=ROOT / "gdextension" / "extension_api.json")
    parser.add_argument("--interface", type=Path, default=ROOT / "gdextension" / "gdextension_interface.json")
    args = parser.parse_args()
    output = args.output.resolve()
    # The upstream generator removes output/gen before regeneration.
    if not output.is_relative_to(ROOT / "build"):
        parser.error("Generated bindings must remain inside this checkout's build directory")
    api = args.api.resolve()
    interface = args.interface.resolve()
    header = json.loads(api.read_text(encoding="utf-8"))["header"]
    if (header["version_major"], header["version_minor"]) != (4, 8):
        parser.error("GDX-Loader requires an official Godot 4.8 API")
    if header.get("precision", args.precision) != args.precision:
        parser.error("Precision must match the API dumped by the target Godot 4.8 editor")
    files = [api, interface, Path(__file__), ROOT / "binding_generator.py",
             ROOT / "build_profile.py", ROOT / "make_interface_header.py"]
    files.extend(p for p in (args.profile, args.hooks) if p)
    fingerprint = hashlib.sha256()
    fingerprint.update(f"{args.bits}:{args.precision}:{args.profile}:{args.hooks}".encode())
    for file in files:
        fingerprint.update(file.read_bytes())
    stamp = output / "bindings.sha256"
    digest = fingerprint.hexdigest()
    sentinel = output / "gen" / "include" / "godot_cpp" / "core" / "version.hpp"
    if stamp.exists() and stamp.read_text() == digest and sentinel.exists():
        return
    output.mkdir(parents=True, exist_ok=True)
    if args.profile:
        trimmed = generate_trimmed_api(str(api), str(args.profile))
        api = output / "extension_api.json"
        api.write_text(json.dumps(trimmed), encoding="utf-8")
    generate_bindings(str(api), str(interface), True, args.bits, args.precision, str(output),
                      str(args.hooks) if args.hooks else None)
    stamp.write_text(digest)


if __name__ == "__main__":
    main()
