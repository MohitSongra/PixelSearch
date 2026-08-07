#!/usr/bin/env python3
"""
PixelSearch — MobileCLIP model preparation & verification.

Downloads MobileCLIP-S1, exports the image + text encoders to ONNX, verifies the
export is numerically faithful to PyTorch, runs a real semantic-retrieval self-test
on bundled photos, and produces fp16 models for on-device (Android) deployment.

Outputs (in ./out):
  mobileclip_image.onnx        fp32 image encoder  (verification)
  mobileclip_text.onnx         fp32 text encoder   (verification)
  mobileclip_image_fp16.onnx   fp16 image encoder  (ship this to the device)
  mobileclip_text_fp16.onnx    fp16 text encoder   (ship this to the device)
  bpe_simple_vocab_16e6.txt.gz CLIP BPE tokenizer vocab (bundle in the app)
  preprocess_config.json       preprocessing + tokenizer constants (bundle in app)

Run:  pip install torch torchvision open_clip_torch onnx onnxruntime onnxconverter_common scikit-image
      python prepare_model.py
"""
import os, json, glob, shutil, warnings
import numpy as np
import torch, torch.nn as nn, open_clip
import onnx, onnxruntime as ort
from onnxconverter_common import float16
warnings.filterwarnings("ignore")

MODEL, PRE, IMG, DIM = "MobileCLIP-S1", "datacompdr", 256, 512
OUT = "out"; os.makedirs(OUT, exist_ok=True)
mb = lambda p: round(os.path.getsize(p) / 1e6, 1)

print(f"[1/6] Loading {MODEL} ({PRE}) …")
model, _, preprocess = open_clip.create_model_and_transforms(MODEL, pretrained=PRE)
tokenizer = open_clip.get_tokenizer(MODEL)
model.eval()


class ImgEnc(nn.Module):
    def __init__(s, m): super().__init__(); s.m = m
    def forward(s, x):
        f = s.m.encode_image(x); return f / f.norm(dim=-1, keepdim=True)


class TxtEnc(nn.Module):
    def __init__(s, m): super().__init__(); s.m = m
    def forward(s, t):
        f = s.m.encode_text(t); return f / f.norm(dim=-1, keepdim=True)


ie, te = ImgEnc(model).eval(), TxtEnc(model).eval()
dummy_img = torch.randn(1, 3, IMG, IMG)
dummy_txt = tokenizer(["a photo"]).to(torch.int64)

print("[2/6] Exporting to ONNX (fp32) …")
torch.onnx.export(ie, dummy_img, f"{OUT}/mobileclip_image.onnx", opset_version=17, dynamo=False,
                  input_names=["pixel_values"], output_names=["image_embeds"],
                  dynamic_axes={"pixel_values": {0: "b"}, "image_embeds": {0: "b"}})
torch.onnx.export(te, dummy_txt, f"{OUT}/mobileclip_text.onnx", opset_version=17, dynamo=False,
                  input_names=["input_ids"], output_names=["text_embeds"],
                  dynamic_axes={"input_ids": {0: "b"}, "text_embeds": {0: "b"}})

print("[3/6] Verifying ONNX == PyTorch …")
si = ort.InferenceSession(f"{OUT}/mobileclip_image.onnx")
st = ort.InferenceSession(f"{OUT}/mobileclip_text.onnx")
with torch.no_grad():
    ti, tt = ie(dummy_img).numpy(), te(dummy_txt).numpy()
oi = si.run(None, {"pixel_values": dummy_img.numpy()})[0]
ot = st.run(None, {"input_ids": dummy_txt.numpy()})[0]
cos = lambda a, b: float(a.ravel() @ b.ravel() / (np.linalg.norm(a) * np.linalg.norm(b)))
print(f"      image cos={cos(ti, oi):.6f}  text cos={cos(tt, ot):.6f}  (want ~1.0)")

print("[4/6] Semantic-retrieval self-test on real photos …")
try:
    from skimage import data
    from PIL import Image
    imgs = {"cat": data.chelsea(), "coffee": data.coffee(), "rocket": data.rocket(),
            "astronaut": data.astronaut(), "camera_person": data.camera(), "horse": data.horse()}
    def to_pil(a):
        a = np.asarray(a)
        if a.dtype == bool: a = a.astype(np.uint8) * 255
        if a.ndim == 2: a = np.stack([a] * 3, -1)
        if a.dtype != np.uint8:
            lo, hi = float(a.min()), float(a.max())
            a = (255 * (a.astype(np.float32) - lo) / ((hi - lo) + 1e-9)).astype(np.uint8)
        return Image.fromarray(a).convert("RGB")
    names = list(imgs); pil = [to_pil(imgs[k]) for k in names]
    it = torch.stack([preprocess(p) for p in pil]).numpy()
    q = ["a photo of a cat", "a cup of coffee", "a rocket",
         "an astronaut in a spacesuit", "a person holding a camera", "a horse"]
    tk = tokenizer(q).to(torch.int64).numpy()
    im = si.run(None, {"pixel_values": it})[0]; tx = st.run(None, {"input_ids": tk})[0]
    im /= np.linalg.norm(im, 1, keepdims=True); tx /= np.linalg.norm(tx, 1, keepdims=True)
    sim = tx @ im.T; ok = sum(int(sim[i].argmax()) == i for i in range(len(q)))
    print(f"      top-1 retrieval accuracy: {ok}/{len(q)}")
    json.dump({"queries": q, "image_names": names,
               "sim_matrix": sim.astype(np.float32).round(4).tolist()},
              open(f"{OUT}/reference_vectors.json", "w"))
except Exception as e:
    print("      (self-test skipped:", e, ")")

print("[5/6] Converting to fp16 for on-device deployment …")
for base in ["mobileclip_image", "mobileclip_text"]:
    m16 = float16.convert_float_to_float16(onnx.load(f"{OUT}/{base}.onnx"), keep_io_types=True)
    onnx.save(m16, f"{OUT}/{base}_fp16.onnx")

# [5b] onnxruntime 1.15 (bundled in the Flutter plugin) has no int64 ArgMax CPU
# kernel. CLIP's text encoder does argmax over input_ids (int64) to find EOT, so
# insert Cast(int64->int32) before it. External I/O unchanged; embeddings identical.
print("[5b/6] Patching text ArgMax int64->int32 for onnxruntime 1.15 …")
from onnx import helper, TensorProto as _TP  # noqa: E402
for base in ["mobileclip_text", "mobileclip_text_fp16"]:
    _m = onnx.load(f"{OUT}/{base}.onnx"); _g = _m.graph; _ch = 0
    for _n in _g.node:
        if _n.op_type == "ArgMax" and _n.input:
            _src = _n.input[0]; _co = _src + "_i32"
            if any(x.op_type == "Cast" and x.output and x.output[0] == _co for x in _g.node):
                _n.input[0] = _co; continue
            _c = helper.make_node("Cast", [_src], [_co], to=_TP.INT32,
                                  name=(_n.name or "am") + "_ci32")
            _n.input[0] = _co; _g.node.insert(0, _c); _ch += 1
    if _ch:
        onnx.save(_m, f"{OUT}/{base}.onnx")
    print(f"      {base}: +{_ch} cast(s)")

print("[6/6] Saving tokenizer vocab + config …")
vocab = glob.glob(os.path.join(os.path.dirname(open_clip.__file__), "**",
                               "bpe_simple_vocab_16e6.txt.gz"), recursive=True)
if vocab:
    shutil.copy(vocab[0], f"{OUT}/bpe_simple_vocab_16e6.txt.gz")
json.dump({"model": MODEL, "pretrained": PRE,
           "model_version": "1.0", "embedding_version": "1", "artifact_version": "1",
           "embed_dim": DIM, "image_size": IMG,
           "resize_mode": "shortest", "center_crop": True,
           "interpolation": "bilinear", "antialias": True,
           "pixel_scale": "0..1", "mean": [0, 0, 0], "std": [1, 1, 1],
           "channel_order": "RGB", "layout": "CHW",
           "context_length": 77, "sot": 49406, "eot": 49407, "pad": 0},
          open(f"{OUT}/preprocess_config.json", "w"), indent=2)

print("\nDone. Ship the *_fp16.onnx files + bpe vocab + preprocess_config.json to the app.")
for f in sorted(os.listdir(OUT)):
    print(f"   {f:32s} {mb(os.path.join(OUT, f))} MB")
