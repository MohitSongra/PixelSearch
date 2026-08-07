# Evaluation (PixelSearch ModelKit)

`metrics.py` implements **Precision@K**, **Recall@K**, **Average Precision**, and **mAP** over ranked
ids. `test_metrics.py` verifies the math on synthetic inputs — no model results are fabricated.

## Protocol
1. Build a labeled probe set: each query maps to a set of relevant image ids (ground truth).
2. For each query, run the retrieval (on-device app, or the ModelKit reference) to get a **ranked** id list.
3. Feed `(ranked, relevant)` into `metrics.py`; aggregate P@K, R@K, mAP across queries.

## Data format
```json
// queries.json
[ {"query": "a dog on the beach", "relevant": ["img_003", "img_017"]}, ... ]
```
Runs (ranked id lists) are produced by the app/ModelKit; this module only **scores** them.

## Run the tests
```bash
cd eval && python test_metrics.py
```

## Rule
These functions score measured retrievals only. Result tables live in
`PixelSearch/docs/BENCHMARK_RESULTS.md` and stay empty until real runs exist.
