#!/usr/bin/env python3
"""M4 Phase 1 preflight: introspect the REAL MobileCLIP-S1 transform + tokenizer
and compare against the documented INTERFACE_CONTRACT. Source of truth = open_clip."""
import json, numpy as np, torch, open_clip

MODEL, PRE = "MobileCLIP-S1", "datacompdr"
print(f"Loading {MODEL} ({PRE}) ...", flush=True)
model, _, preprocess = open_clip.create_model_and_transforms(MODEL, pretrained=PRE)
tokenizer = open_clip.get_tokenizer(MODEL)
model.eval()

def describe(tr):
    comps = tr.transforms if hasattr(tr, "transforms") else [tr]
    out = []
    for t in comps:
        d = {"type": type(t).__name__}
        for a in ["size","interpolation","mean","std","max_size","antialias"]:
            if hasattr(t, a):
                d[a] = str(getattr(t, a))
        out.append(d)
    return out

img_desc = describe(preprocess)

pcfg = {}
try:
    raw = open_clip.get_model_preprocess_cfg(model)
    pcfg = {k: str(v) for k, v in dict(raw).items()}
except Exception as e:
    pcfg = {"error": repr(e)}

# Actually run the transform on a solid-color image to observe output range/mean.
from PIL import Image
probe = Image.new("RGB", (400, 300), (128, 64, 200))
tens = preprocess(probe)  # CHW float tensor
tens_np = tens.numpy()
obs = {
    "shape": list(tens_np.shape),
    "dtype": str(tens_np.dtype),
    "min": float(tens_np.min()),
    "max": float(tens_np.max()),
    "per_channel_mean": [round(float(tens_np[c].mean()), 5) for c in range(tens_np.shape[0])],
}
# What a pure [0,1] scaling (no mean/std) would give for (128,64,200):
expected_01 = [round(128/255, 5), round(64/255, 5), round(200/255, 5)]

ctx = getattr(tokenizer, "context_length", None)
samples = ["a photo of a cat", "a cup of coffee",
           "sunset over the beach in goa", "two dogs playing in snow", ""]
tok = tokenizer(samples)
tok_list = tok.tolist()
arr = np.array(tok_list)

report = {
    "model": MODEL, "pretrained": PRE,
    "image_transform_components": img_desc,
    "preprocess_cfg": pcfg,
    "observed_tensor_on_rgb(128,64,200)": obs,
    "expected_if_pure_0_1_scaling": expected_01,
    "tokenizer": {
        "class": type(tokenizer).__name__,
        "context_length": ctx,
        "first_token(sot)": int(arr[0][0]),
        "max_token_id(eot)": int(arr.max()),
        "samples": samples,
        "token_ids": tok_list,
    },
}
with open("/home/claude/PixelSearch_ModelKit/preflight/PREFLIGHT_REPORT.json", "w") as f:
    json.dump(report, f, indent=2)

print(json.dumps({k: report[k] for k in
      ["image_transform_components","preprocess_cfg",
       "observed_tensor_on_rgb(128,64,200)","expected_if_pure_0_1_scaling"]}, indent=2))
print("\nTokenizer:", json.dumps(report["tokenizer"], indent=2)[:900])
