#!/usr/bin/env python3
"""Reference CLIP-BPE tokenizations from open_clip, for Dart token-id parity.
No fabrication — these are the exact ids open_clip produces."""
import json, os
import open_clip

HERE = os.path.dirname(os.path.abspath(__file__))
tok = open_clip.get_tokenizer("MobileCLIP-S1")
enc = tok if hasattr(tok, "encode") else None
if enc is None:
    from open_clip.tokenizer import SimpleTokenizer
    enc = SimpleTokenizer()

strings = [
    "a photo of a cat", "a cup of coffee", "a rocket",
    "an astronaut in a spacesuit", "a person holding a camera", "a horse",
    "sunset over the beach in Goa", "two dogs playing in snow",
    "HELLO World", "  extra   whitespace \t here ",
    "don't stop, it's 100% real!", "2023-08-06 12:30",
    "email@example.com", "C++ & Python", "New York City skyline at night",
    "café résumé naïve", "single", "",
    "a very long and rambling description of a scene " * 8,
]

cases = []
for s in strings:
    ids = enc.encode(s)
    toks = tok([s])[0].tolist()
    cases.append({"text": s, "ids": ids, "tokens77": toks})

json.dump({"context_length": 77, "sot": 49406, "eot": 49407, "cases": cases},
          open(os.path.join(HERE, "reference_tokens.json"), "w"))
print("wrote", len(cases), "tokenization cases; sample ids[0]:", cases[0]["ids"])
