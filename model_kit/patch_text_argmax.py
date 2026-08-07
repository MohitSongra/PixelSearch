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
import os
import onnx
from onnx import helper, TensorProto


def _elem_type(graph, name):
    for coll in (graph.input, graph.output, graph.value_info):
        for v in coll:
            if v.name == name:
                return v.type.tensor_type.elem_type
    return TensorProto.INT64  # the CLIP case: argmax reads input_ids directly


def patch(path):
    model = onnx.load(path)
    g = model.graph
    changed = 0
    for node in g.node:
        if node.op_type != 'ArgMax' or not node.input:
            continue
        src = node.input[0]
        if _elem_type(g, src) != TensorProto.INT64:
            continue
        cast_out = src + '_i32'
        if any(n.op_type == 'Cast' and n.output and n.output[0] == cast_out
               for n in g.node):
            node.input[0] = cast_out
            continue
        cast = helper.make_node('Cast', [src], [cast_out],
                                to=TensorProto.INT32,
                                name=(node.name or 'argmax') + '_casti32')
        node.input[0] = cast_out
        g.node.insert(0, cast)  # input_ids is a graph input → valid at front
        changed += 1
    if changed:
        onnx.checker.check_model(model)
        onnx.save(model, path)
    print(f'{os.path.basename(path)}: patched {changed} ArgMax node(s)')
    return changed


if __name__ == '__main__':
    here = os.path.dirname(os.path.abspath(__file__))
    out = os.path.join(here, 'out')
    for f in ['mobileclip_text.onnx', 'mobileclip_text_fp16.onnx']:
        p = os.path.join(out, f)
        if os.path.exists(p):
            patch(p)
