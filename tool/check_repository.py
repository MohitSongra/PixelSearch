"""Check the source tree and Git publication boundaries without third-party deps."""

from pathlib import Path, PurePosixPath
import re
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[1]
SFACE = "pixelsearch_app/assets/models/face_recognition_sface_2021dec.onnx"

# Generic shapes of personal or deployment data that must never be published.
# Real names live only in a git-ignored denylist (see check_private_content).
PRIVATE_PATTERNS = [
    ("local user path", re.compile(r"(?:\b[A-Za-z]:[\\/]+|/c/)Users[\\/]+[A-Za-z0-9._-]+")),
    ("camera or chat photo filename", re.compile(
        r"\b(?:IMG[-_]\d{8}[-_](?:WA\d{4}|\d{6})|PXL_\d{8}_\d{6,}|VID[-_]\d{8}[-_]\d+|"
        r"Screenshot_\d{8}[-_]\d{6}|WhatsApp Image \d{4}-\d{2}-\d{2})")),
    ("deployment URL", re.compile(r"https?://[\w.-]+\.onrender\.com")),
    ("share link with a token", re.compile(r"eraser\.io/\S*requestId=|storage\.googleapis\.com/[\w.-]+/")),
    ("roll number", re.compile(r"\b\d{5}[A-Z]\d{4}\b")),
    ("device serial", re.compile(r"(?i)\badb serial\b\W{0,3}[A-Za-z0-9]{8,}")),
]
TEXT_SUFFIXES = {
    ".md", ".dart", ".py", ".ps1", ".sh", ".yaml", ".yml", ".json", ".txt", ".toml", ".kts", ".gradle",
    ".xml", ".html", ".cff", ".eraser", ".cfg", ".ini", ".properties", ".example",
}


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

    errors.extend(check_private_content())

    if errors:
        print("\n".join(errors))
        return 1
    print("Repository layout and publication boundaries passed.")
    return 0


def check_private_content():
    """Scans tracked files, and untracked files Git would offer to add, for the
    patterns above. A git-ignored `.privacy-denylist.txt` (one term per line)
    adds whole-word terms such as real names; findings never print the term."""
    listed = subprocess.check_output(
        ["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"], cwd=ROOT
    ).decode("utf-8").split("\0")
    denylist = ROOT / ".privacy-denylist.txt"
    terms = []
    if denylist.is_file():
        terms = [
            t.strip()
            for t in denylist.read_text(encoding="utf-8").splitlines()
            if t.strip() and not t.startswith("#")
        ]
    denied = re.compile(r"(?i)\b(?:" + "|".join(map(re.escape, terms)) + r")\b") if terms else None
    errors = []
    for name in sorted(set(filter(None, listed))):
        path = ROOT / name
        if name == ".privacy-denylist.txt" or path.suffix.lower() not in TEXT_SUFFIXES or not path.is_file():
            continue
        try:
            lines = path.read_text(encoding="utf-8").splitlines()
        except (UnicodeDecodeError, OSError):
            continue
        for number, line in enumerate(lines, 1):
            for label, pattern in PRIVATE_PATTERNS:
                if pattern.search(line):
                    errors.append(f"Possible {label}: {name}:{number}")
            if denied and denied.search(line):
                errors.append(f"Denylisted term: {name}:{number}")
    return errors


if __name__ == "__main__":
    sys.exit(main())
