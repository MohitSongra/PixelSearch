"""Read an app backup without touching the phone; hash data across schema upgrades."""
import hashlib
import json
import sqlite3
import sys
import tarfile
from contextlib import closing
from pathlib import Path
from tempfile import TemporaryDirectory


def audit(path):
    result = {"archive": str(path), "files": {}}
    with path.open("rb") as stream:
        result["archive_sha256"] = hashlib.file_digest(stream, "sha256").hexdigest()
    with tarfile.open(path) as archive, TemporaryDirectory() as directory:
        members = {m.name.removeprefix("./"): m for m in archive.getmembers()}
        required = [
            "app_flutter/pixelsearch.sqlite",
            "files/models/mobileclip_image.onnx",
            "files/models/mobileclip_text.onnx",
            "files/search_evaluation/queries.json",
            "files/search_evaluation/latest_report.json",
            "files/user_preferences.json",
        ]
        for name in required:
            member = members[name]
            with archive.extractfile(member) as stream:
                result["files"][name] = {
                    "bytes": member.size,
                    "sha256": hashlib.file_digest(stream, "sha256").hexdigest(),
                }
        # Only these fixed SQLite names are materialized, never arbitrary tar paths.
        for suffix in ("", "-wal", "-shm"):
            name = "app_flutter/pixelsearch.sqlite" + suffix
            if name in members:
                with archive.extractfile(members[name]) as stream:
                    (Path(directory) / ("pixelsearch.sqlite" + suffix)).write_bytes(stream.read())
        database = Path(directory) / "pixelsearch.sqlite"
        with closing(sqlite3.connect(f"{database.as_uri()}?mode=ro", uri=True)) as db:
            result["integrity"] = db.execute("PRAGMA integrity_check").fetchone()[0]
            assert result["integrity"] == "ok", result["integrity"]
            result["schema"] = db.execute("PRAGMA user_version").fetchone()[0]
            tables = [r[0] for r in db.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")]
            result["tables"] = {}
            for table in tables:
                quoted = '"' + table.replace('"', '""') + '"'
                rows = db.execute(f"SELECT * FROM {quoted}").fetchall()
                encoded = sorted(json.dumps([{"blob": v.hex()} if isinstance(v, bytes) else v for v in row],
                                            ensure_ascii=True, separators=(",", ":")) for row in rows)
                digest = hashlib.sha256("\n".join(encoded).encode()).hexdigest()
                result["tables"][table] = {"count": len(rows), "sha256": digest}
            result["folder_preferences"] = db.execute("SELECT * FROM indexing_preferences_rows").fetchall()
            result["embedding_versions"] = db.execute(
                "SELECT model_id, embedding_version, dim, count(*) FROM embedding_rows GROUP BY model_id,embedding_version,dim"
            ).fetchall()
            if "photo_locations" in tables:
                result["location_status_counts"] = db.execute(
                    "SELECT status, count(*) FROM photo_locations GROUP BY status ORDER BY status"
                ).fetchall()
                result["located_photos"] = db.execute(
                    "SELECT count(*) FROM photo_locations WHERE latitude IS NOT NULL AND longitude IS NOT NULL"
                ).fetchone()[0]
            if "memory_events" in tables:
                result["named_memories"] = db.execute(
                    "SELECT count(*) FROM memory_events WHERE title != ''"
                ).fetchone()[0]
                result["invalid_memory_covers"] = db.execute(
                    "SELECT count(*) FROM memory_events e WHERE NOT EXISTS "
                    "(SELECT 1 FROM memory_members m WHERE m.event_id=e.id AND m.photo_id=e.cover_id)"
                ).fetchone()[0]
    return result


if __name__ == "__main__":
    print(json.dumps(audit(Path(sys.argv[1]).resolve()), indent=2))
