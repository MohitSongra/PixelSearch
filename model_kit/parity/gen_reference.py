#!/usr/bin/env python3
"""Generate the parity reference for the M4 numerical gate.

Canonical source of truth = open_clip preprocessing + the exported fp32 ONNX
encoders. Saves the EXACT PNGs the Flutter side will load, plus reference image
embeddings, text embeddings, and the retrieval sanity check. No fabrication.
"""
import json, os
import numpy as np
import onnxruntime as ort
from PIL import Image
from skimage import data
import open_clip, torch

HERE = os.path.dirname(os.path.abspath(__file__))
IMG_DIR = os.path.join(HERE, "images")
os.makedirs(IMG_DIR, exist_ok=True)
MODELKIT = os.path.dirname(HERE)
IMG_ONNX = os.path.join(MODELKIT, "out", "mobileclip_image.onnx")
TXT_ONNX = os.path.join(MODELKIT, "out", "mobileclip_text.onnx")

print("Loading open_clip MobileCLIP-S1 (source of truth) ...", flush=True)
model, _, preprocess = open_clip.create_model_and_transforms(
    "MobileCLIP-S1", pretrained="datacompdr")
tokenizer = open_clip.get_tokenizer("MobileCLIP-S1")

imgs = {"cat": data.chelsea(), "coffee": data.coffee(), "rocket": data.rocket(),
        "astronaut": data.astronaut(), "camera_person": data.camera(),
        "horse": data.horse()}
queries = ["a photo of a cat", "a cup of coffee", "a rocket",
           "an astronaut in a spacesuit", "a person holding a camera", "a horse"]
names = list(imgs)


def to_pil(a):
    a = np.asarray(a)
    if a.dtype == bool:
        a = a.astype(np.uint8) * 255
    if a.ndim == 2:
        a = np.stack([a] * 3, -1)
    if a.dtype != np.uint8:
        lo, hi = float(a.min()), float(a.max())
        a = (255 * (a.astype(np.float32) - lo) / ((hi - lo) + 1e-9)).astype(np.uint8)
    return Image.fromarray(a).convert("RGB")


pils = {}
for n in names:
    p = to_pil(imgs[n])
    p.save(os.path.join(IMG_DIR, f"{n}.png"))  # exact bytes Flutter loads
    pils[n] = p

si = ort.InferenceSession(IMG_ONNX)
st = ort.InferenceSession(TXT_ONNX)

img_embeds = {}
for n in names:
    x = preprocess(pils[n]).unsqueeze(0).numpy().astype(np.float32)
    img_embeds[n] = si.run(None, {"pixel_values": x})[0][0].astype(np.float32)

tk = tokenizer(queries).to(torch.int64).numpy()
txt = st.run(None, {"input_ids": tk})[0].astype(np.float32)  # [6,512]

IE = np.stack([img_embeds[n] for n in names])  # [6,512]
sim = txt @ IE.T
argmax = sim.argmax(1).tolist()
ok = argmax == list(range(len(names)))
print("retrieval argmax:", argmax, "->", f"{sum(int(argmax[i]==i) for i in range(len(names)))}/{len(names)}")

json.dump({
    "image_names": names,
    "queries": queries,
    "image_embeds": {n: img_embeds[n].tolist() for n in names},
    "text_embeds": [row.tolist() for row in txt],
    "note": "image_embeds: open_clip preprocess -> fp32 image ONNX. "
            "text_embeds: tokenizer -> fp32 text ONNX. All model-L2-normalized.",
}, open(os.path.join(HERE, "reference_embeddings.json"), "w"))
print("wrote reference_embeddings.json +", len(names), "PNGs; retrieval",
      "6/6 OK" if ok else "MISMATCH")
