"""Validated FP16 conversion for PixelSearch MobileCLIP ONNX artifacts.

`onnxconverter_common.float16` can leave a Cast node declaring float16 while its
`to` attribute still requests float. ONNX Runtime rejects that graph during
session creation. This module uses ONNX Runtime's converter, puts its generated
I/O casts in topological order, and checks every declared Cast output type.
"""

from __future__ import annotations

import json
import os
from pathlib import Path

import onnx
from onnx import TensorProto, helper
from onnxruntime.transformers.float16 import convert_float_to_float16
from onnxruntime.transformers.onnx_model import OnnxModel

ARTIFACT_VERSION = '3'


def _value_types(graph: onnx.GraphProto) -> dict[str, int]:
    return {
        value.name: value.type.tensor_type.elem_type
        for values in (graph.input, graph.output, graph.value_info)
        for value in values
        if value.type.HasField('tensor_type')
    }


def _cast_target(node: onnx.NodeProto) -> int | None:
    for attribute in node.attribute:
        if attribute.name == 'to':
            return attribute.i
    return None


def _validate_model(model: onnx.ModelProto, path: Path) -> None:
    OnnxModel(model).topological_sort()
    onnx.checker.check_model(model)

    types = _value_types(model.graph)
    mismatches = []
    for node in model.graph.node:
        if node.op_type != 'Cast' or not node.output:
            continue
        expected = types.get(node.output[0])
        actual = _cast_target(node)
        if expected is not None and actual is not None and expected != actual:
            mismatches.append(
                f'{node.name or "<unnamed>"}: declared {expected}, Cast.to {actual}',
            )
    if mismatches:
        details = '\n'.join(mismatches)
        raise RuntimeError(f'Invalid Cast output type(s) in {path}:\n{details}')


def _save_atomically(model: onnx.ModelProto, path: Path) -> None:
    temporary = path.with_suffix(f'{path.suffix}.tmp')
    try:
        onnx.save(model, temporary)
        os.replace(temporary, path)
    finally:
        if temporary.exists():
            temporary.unlink()


def _sync_artifact_version(output: Path) -> None:
    for path in (output / 'preprocess_config.json', output.parent / 'preprocess_config.json'):
        if not path.is_file():
            continue
        with path.open(encoding='utf-8') as config_file:
            config = json.load(config_file)
        config['artifact_version'] = ARTIFACT_VERSION
        temporary = path.with_suffix(f'{path.suffix}.tmp')
        try:
            with temporary.open('w', encoding='utf-8', newline='\n') as config_file:
                json.dump(config, config_file, indent=2)
                config_file.write('\n')
            os.replace(temporary, path)
        finally:
            if temporary.exists():
                temporary.unlink()


def patch_text_argmax(path: Path) -> int:
    """Cast CLIP token ids to int32 before internal ArgMax when necessary."""
    model = onnx.load(path)
    graph = model.graph
    types = _value_types(graph)
    producers = {
        output: node
        for node in graph.node
        for output in node.output
        if output
    }
    changed = 0
    redundant_outputs = set()

    for node in graph.node:
        if node.op_type != 'ArgMax' or not node.input:
            continue
        source = node.input[0]
        cast_chain = []
        root = source
        while (
            (producer := producers.get(root)) is not None
            and producer.op_type == 'Cast'
            and producer.input
        ):
            cast_chain.append(producer)
            root = producer.input[0]
        if types.get(root) != TensorProto.INT64:
            continue
        cast_output = f'{root}_i32'
        cast = producers.get(cast_output)
        if cast is None:
            cast = helper.make_node(
                'Cast',
                [root],
                [cast_output],
                to=TensorProto.INT32,
                name=f'{node.name or "argmax"}_casti32',
            )
            graph.node.insert(0, cast)
            producers[cast_output] = cast
            types[cast_output] = TensorProto.INT32
            changed += 1
        elif (
            cast.op_type != 'Cast'
            or list(cast.input) != [root]
            or _cast_target(cast) != TensorProto.INT32
        ):
            raise RuntimeError(
                f'Cannot normalize ArgMax input in {path}: {cast_output} is occupied',
            )
        if node.input[0] != cast_output:
            node.input[0] = cast_output
            changed += 1
        redundant_outputs.update(
            candidate.output[0]
            for candidate in cast_chain
            if candidate.output and candidate.output[0] != cast_output
        )

    # A prior interrupted repair can leave a chain of no-op int32 casts. Remove
    # only nodes that no remaining graph node or graph output consumes.
    while redundant_outputs:
        consumers = {
            value
            for node in graph.node
            for value in node.input
            if value
        }
        graph_outputs = {value.name for value in graph.output}
        removable = redundant_outputs - consumers - graph_outputs
        if not removable:
            break
        kept = [
            node
            for node in graph.node
            if not (node.op_type == 'Cast' and any(output in removable for output in node.output))
        ]
        del graph.node[:]
        graph.node.extend(kept)
        redundant_outputs -= removable
        changed += len(removable)

    _validate_model(model, path)
    _save_atomically(model, path)
    return changed


def convert_fp32_to_fp16(source: Path, destination: Path) -> None:
    """Convert one fp32 artifact while preserving its public float32 I/O."""
    model = convert_float_to_float16(
        onnx.load(source),
        keep_io_types=True,
    )
    _validate_model(model, destination)
    _save_atomically(model, destination)


def rebuild_fp16_artifacts(output_dir: str | Path) -> None:
    """Rebuild the shipping artifacts from existing fp32 exports."""
    output = Path(output_dir)
    image_fp32 = output / 'mobileclip_image.onnx'
    text_fp32 = output / 'mobileclip_text.onnx'
    if not image_fp32.is_file() or not text_fp32.is_file():
        raise FileNotFoundError(
            'Expected fp32 exports in '
            f'{output}: mobileclip_image.onnx and mobileclip_text.onnx',
        )

    text_changes = patch_text_argmax(text_fp32)
    print(f'{text_fp32.name}: patched {text_changes} int64 ArgMax node(s)')

    for source, destination in (
        (image_fp32, output / 'mobileclip_image_fp16.onnx'),
        (text_fp32, output / 'mobileclip_text_fp16.onnx'),
    ):
        convert_fp32_to_fp16(source, destination)
        print(f'{destination.name}: ONNX checker and Cast types validated')
    _sync_artifact_version(output)
