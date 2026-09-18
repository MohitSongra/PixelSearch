"""Check the source tree and Git publication boundaries without third-party deps."""

from pathlib import Path, PurePosixPath
import re
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[1]
SFACE = "pixelsearch_app/assets/models/face_recognition_sface_2021dec.onnx"


def main():
    tracked = subprocess.check_output(
        ["git", "ls-files", "-z"], cwd=ROOT
    ).decode("utf-8").split("\0")
    errors = []
    for name in filter(None, tracked):
        path = PurePosixPath(name)
        if path.parts[0] in {"app", "tmp", "output", ".claude", ".codex"}:
            errors.append(f"Local or obsolete directory is tracked: {name}")
        if set(path.parts) & {".venv", "__pycache__", ".pytest_cache", "local_evaluation", ".dart_tool", "build"}:
            errors.append(f"Generated or private data is tracked: {name}")
        if path.name.startswith(".env") and path.name != ".env.example":
            errors.append(f"Local environment file is tracked: {name}")
        if path.suffix in {".db", ".sqlite", ".apk", ".aab", ".jks", ".keystore", ".pem", ".key"}:
            errors.append(f"Private/runtime artifact is tracked: {name}")
        if path.suffix == ".onnx" and name != SFACE:
            errors.append(f"Unapproved model binary is tracked: {name}")
        local = ROOT / name
        if local.is_file() and local.stat().st_size >= 100 * 1024 * 1024:
            errors.append(f"File exceeds normal GitHub file limit: {name}")

    for relative in ("pixelsearch_app/pubspec.yaml", "model_kit/INTERFACE_CONTRACT.md", "enhancement_backend/app.py"):
        if not (ROOT / relative).is_file():
            errors.append(f"Required component missing: {relative}")

    state = ROOT / "pixelsearch_app/lib/state"
    barrel = (state / "providers.dart").read_text(encoding="utf-8")
    for line in barrel.splitlines():
        if line.strip() and not line.startswith(("//", "export ")):
            errors.append("providers.dart must remain an export-only compatibility API")
            break
    for file in state.glob("*.dart"):
        if re.search(r"^import ['\"]providers\.dart['\"]", file.read_text(encoding="utf-8"), re.M):
            errors.append(f"State implementation imports its own barrel: {file.name}")

    # Every retained sample is a deliberate test fixture, never a mock gallery.
    tests = "\n".join(p.read_text(encoding="utf-8") for p in (ROOT / "pixelsearch_app/test").rglob("*.dart"))
    for file in (ROOT / "pixelsearch_app/assets/samples").glob("*.jpg"):
        if file.name not in tests:
            errors.append(f"Unused bundled sample: {file.name}")

    if errors:
        print("\n".join(errors))
        return 1
    print("Repository layout and publication boundaries passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
