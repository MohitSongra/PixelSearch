import tempfile
import unittest
from pathlib import Path

import onnx
import onnxruntime as ort
from onnx import TensorProto, helper

from fp16_conversion import convert_fp32_to_fp16, patch_text_argmax


class Fp16ConversionTest(unittest.TestCase):
    def test_fp16_conversion_is_checker_valid_and_session_loadable(self):
        with tempfile.TemporaryDirectory() as temporary:
            source = Path(temporary) / 'source.onnx'
            destination = Path(temporary) / 'converted.onnx'
            graph = helper.make_graph(
                [
                    helper.make_node('Cast', ['input'], ['internal'], to=TensorProto.FLOAT),
                    helper.make_node('Identity', ['internal'], ['output']),
                ],
                'cast_graph',
                [helper.make_tensor_value_info('input', TensorProto.FLOAT, [1])],
                [helper.make_tensor_value_info('output', TensorProto.FLOAT, [1])],
            )
            onnx.save(
                helper.make_model(graph, opset_imports=[helper.make_opsetid('', 17)]),
                source,
            )

            convert_fp32_to_fp16(source, destination)

            model = onnx.load(destination)
            onnx.checker.check_model(model)
            session = ort.InferenceSession(
                destination,
                providers=['CPUExecutionProvider'],
            )
            self.assertEqual(session.get_inputs()[0].type, 'tensor(float)')
            self.assertEqual(session.get_outputs()[0].type, 'tensor(float)')

    def test_argmax_patch_is_idempotent(self):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / 'text.onnx'
            graph = helper.make_graph(
                [
                    helper.make_node(
                        'ArgMax',
                        ['input_ids'],
                        ['indices'],
                        axis=1,
                        keepdims=0,
                    ),
                ],
                'text_graph',
                [helper.make_tensor_value_info('input_ids', TensorProto.INT64, [1, 77])],
                [helper.make_tensor_value_info('indices', TensorProto.INT64, [1])],
            )
            onnx.save(
                helper.make_model(graph, opset_imports=[helper.make_opsetid('', 17)]),
                path,
            )

            self.assertGreater(patch_text_argmax(path), 0)
            self.assertEqual(patch_text_argmax(path), 0)

            model = onnx.load(path)
            onnx.checker.check_model(model)
            argmax = next(node for node in model.graph.node if node.op_type == 'ArgMax')
            self.assertEqual(list(argmax.input), ['input_ids_i32'])
            input_casts = [
                node
                for node in model.graph.node
                if node.op_type == 'Cast' and list(node.output) == ['input_ids_i32']
            ]
            self.assertEqual(len(input_casts), 1)
            self.assertEqual(list(input_casts[0].input), ['input_ids'])
            self.assertEqual(
                next(attr.i for attr in input_casts[0].attribute if attr.name == 'to'),
                TensorProto.INT32,
            )


if __name__ == '__main__':
    unittest.main()
