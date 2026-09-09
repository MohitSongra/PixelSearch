#!/usr/bin/env python3
"""Make the MobileCLIP text ONNX runnable on onnxruntime 1.15 (the version the
Flutter plugin bundles, on device and in CI).

CLIP's text encoder selects the EOT position with `argmax` over `input_ids`
(int64). ORT 1.15 has no int64 ArgMax CPU kernel, so we insert a
Cast(int64 -> int32) before each such ArgMax. External I/O is unchanged
(`input_ids` stays int64); the argmax indices — and therefore the embeddings —
are identical (token ids < 49408 << 2^31). This is an artifact_version bump, not
an embedding_version change: no re-index is required.
"""
from pathlib import Path

from fp16_conversion import patch_text_argmax


if __name__ == '__main__':
    out = Path(__file__).resolve().parent / 'out'
    for f in ['mobileclip_text.onnx', 'mobileclip_text_fp16.onnx']:
        path = out / f
        if path.exists():
            changed = patch_text_argmax(path)
            print(f'{path.name}: patched {changed} ArgMax node(s)')
