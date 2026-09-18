"""Generate reproducible OpenCV SFace preprocessing fixtures, never identity labels."""
import argparse
import hashlib
import json
from pathlib import Path
import sys

parser = argparse.ArgumentParser()
parser.add_argument('--app', type=Path, required=True)
args = parser.parse_args()
sys.path.insert(0, str(args.app / 'build/face_reference_deps'))
import cv2
import numpy as np
import onnx
import onnxruntime as ort

model = args.app / 'assets/models/face_recognition_sface_2021dec.onnx'
assert hashlib.sha256(model.read_bytes()).hexdigest() == '0ba9fbfa01b5270c96627c4ef784da859931e02f04419c829e83484087c34e79'
graph = onnx.load(str(model))
onnx.checker.check_model(graph)
options = ort.SessionOptions()
options.log_severity_level = 3
session = ort.InferenceSession(str(model), options, providers=['CPUExecutionProvider'])
recognizer = cv2.FaceRecognizerSF.create(str(model), '')
out = args.app / 'test/fixtures/sface'
out.mkdir(parents=True, exist_ok=True)
template = np.array([[38.2946, 51.6963], [73.5318, 51.5014], [56.0252, 71.7366], [41.5493, 92.3655], [70.7299, 92.2041]], dtype=np.float32)
y, x = np.mgrid[:240, :256]
rgb = np.stack([(x * 3 + y) % 256, (y * 2 + x // 3) % 256, (x + y * 5) % 256], axis=-1).astype(np.uint8)
cv2.imwrite(str(out / 'source.png'), rgb[:, :, ::-1])
cases = []
for name, angle, scale, offset in [('identity', 0, 1, (0, 0)), ('scale', 0, 1.7, (12, 9)), ('rotate', 17, 1.25, (15, 14)), ('border', -8, .9, (-28, -25))]:
    theta = np.deg2rad(angle)
    rotation = np.array([[np.cos(theta), -np.sin(theta)], [np.sin(theta), np.cos(theta)]])
    points = (template @ rotation.T * scale + offset).astype(np.float32)
    face = np.concatenate([np.array([0, 0, 200, 200]), points.flatten(), [1]]).astype(np.float32)
    crop_bgr = recognizer.alignCrop(rgb[:, :, ::-1].copy(), face)
    cv2.imwrite(str(out / f'{name}.png'), crop_bgr)
    tensor = crop_bgr[:, :, ::-1].transpose(2, 0, 1)[None].astype(np.float32)
    raw = session.run(['fc1'], {'data': tensor})[0][0]
    normalized = raw / np.linalg.norm(raw)
    opencv_vector = recognizer.feature(crop_bgr).ravel()
    opencv_vector /= np.linalg.norm(opencv_vector)
    cases.append({'name': name, 'landmarks': points.tolist(), 'vector': normalized.tolist(),
                  'raw_norm': float(np.linalg.norm(raw)), 'opencv_ort_cosine': float(normalized @ opencv_vector)})
result = {'opencv': cv2.__version__, 'onnxruntime': ort.__version__, 'model_sha256': hashlib.sha256(model.read_bytes()).hexdigest(),
          'input': {'name': 'data', 'shape': [1, 3, 112, 112], 'dtype': 'float32', 'range': '0..255 RGB'},
          'output': {'name': 'fc1', 'shape': [1, 128]}, 'cases': cases}
(out / 'reference.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
print(json.dumps({'opencv': result['opencv'], 'cases': [{k: v for k, v in c.items() if k not in ['vector', 'landmarks']} for c in cases]}, indent=2))
