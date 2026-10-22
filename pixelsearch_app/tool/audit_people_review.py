"""Audit a private app backup locally without exposing faces or changing ratings."""
import argparse
from collections import Counter
from contextlib import closing
import json
import math
from pathlib import Path
import sqlite3
import struct
import tarfile
from tempfile import TemporaryDirectory


def audit(path):
    with tarfile.open(path) as archive, TemporaryDirectory() as directory:
        members = {m.name.removeprefix("./"): m for m in archive.getmembers()}
        for suffix in ("", "-wal", "-shm"):
            name = "app_flutter/pixelsearch.sqlite" + suffix
            if name in members:
                with archive.extractfile(members[name]) as stream:
                    (Path(directory) / ("pixelsearch.sqlite" + suffix)).write_bytes(stream.read())
        database = Path(directory) / "pixelsearch.sqlite"
        with closing(sqlite3.connect(f"{database.as_uri()}?mode=ro", uri=True)) as db:
            db.row_factory = sqlite3.Row
            state = dict(db.execute("SELECT * FROM people_state WHERE id=0").fetchone())
            faces = {r["id"]: dict(r) for r in db.execute("SELECT * FROM people_faces")}
            pairs = [dict(r) for r in db.execute(
                "SELECT * FROM people_reviews WHERE subset IN ('calibration','validation') ORDER BY rowid"
            )]
            vectors = {}
            invalid = 0
            for face_id, face in faces.items():
                blob = face["vector"]
                if blob is None:
                    continue
                if len(blob) != 512:
                    invalid += 1
                    continue
                vector = struct.unpack("<128f", blob)
                if not all(map(math.isfinite, vector)) or abs(sum(x*x for x in vector)-1) > .002:
                    invalid += 1
                    continue
                vectors[face_id] = vector
            report = {
                "schema": db.execute("PRAGMA user_version").fetchone()[0],
                "integrity": db.execute("PRAGMA integrity_check").fetchone()[0],
                "indexed_photos": db.execute("SELECT count(*) FROM photo_rows").fetchone()[0],
                "state": {k: state[k] for k in ("enabled", "paused", "threshold")},
                "saved_calibration": {k: v for k, v in json.loads(state["calibration_json"]).items()
                                      if not k.endswith("_pair_ids")},
                "faces": len(faces), "valid_vectors": len(vectors), "invalid_vectors": invalid,
                "quality": dict(Counter(f["quality"] for f in faces.values())),
                "assignments": dict(Counter(f["assignment"] for f in faces.values())),
                "scans": dict(db.execute("SELECT status,count(*) FROM people_scans GROUP BY status").fetchall()),
                "reviews": len(pairs),
                "judgments": {s: dict(Counter(p["judgment"] for p in pairs if p["subset"] == s))
                              for s in ("calibration", "validation")},
            }
            cal = [p for p in pairs if p["subset"] == "calibration"]
            thresholds = sorted({p["cosine"] for p in cal if p["judgment"] == "same"}, reverse=True)
            threshold, best_true = None, 0
            for candidate in thresholds:
                if any(p["judgment"] == "different" and p["cosine"] >= candidate for p in cal):
                    continue
                true = sum(p["judgment"] == "same" and p["cosine"] >= candidate for p in cal)
                if true > best_true:
                    threshold, best_true = candidate, true
            report["candidate_threshold"] = threshold
            report["calibration_true_joins"] = best_true
            errors, detail, photos = [], [], {"calibration": set(), "validation": set()}
            for number, pair in enumerate(pairs, 1):
                left, right = faces.get(pair["left_face_id"]), faces.get(pair["right_face_id"])
                if left and right:
                    photos[pair["subset"]].update((left["photo_id"], right["photo_id"]))
                a, b = vectors.get(pair["left_face_id"]), vectors.get(pair["right_face_id"])
                recalculated = max(-1, min(1, sum(x*y for x, y in zip(a, b)))) if a and b else None
                if recalculated is not None:
                    errors.append(abs(recalculated-pair["cosine"]))
                joins = pair["cosine"] >= threshold if threshold is not None else None
                detail.append({"pair": number, "subset": pair["subset"], "judgment": pair["judgment"],
                               "cosine": pair["cosine"], "would_join": joins,
                               "false_join": joins is True and pair["judgment"] == "different",
                               "missed_same": joins is False and pair["judgment"] == "same"})
            report["max_saved_cosine_error"] = max(errors, default=None)
            report["overlapping_photos"] = len(photos["calibration"] & photos["validation"])
            report["pairs"] = detail
            return report


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("backup", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    output = json.dumps(audit(args.backup), indent=2)
    if args.output:
        args.output.write_text(output + "\n", encoding="utf-8")
    print(output)
