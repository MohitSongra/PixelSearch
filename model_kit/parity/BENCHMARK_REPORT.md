# PixelSearch AI — Benchmark Report

Platform: **build host — x86-64 CPU, fp32, onnxruntime 1.15** via real Flutter ONNX Runtime. These are real measurements but **not** target-device numbers; Android NNAPI/XNNPACK fp16 is measured on device (still pending).

## Model loading & memory
| metric | value |
|---|---|
| Image encoder load (fp32, 87 MB) | 588 ms |
| Text encoder load (fp32, 254 MB) | 961 ms |
| Process RSS increase after loading both | 612 MB |
| Session reuse | loaded once; every embed below reuses the session (no reload) |

## Embedding latency (session reused, 30 iterations)
| op | mean | median | p95 | min | max |
|---|---|---|---|---|---|
| image embed | 175.3 ms | 165.8 ms | 259.0 ms | 127.1 ms | 282.5 ms |
| text embed | 41.7 ms | 40.2 ms | 46.7 ms | 38.8 ms | 47.3 ms |

## Throughput & single-thread indexing projection (image encoder)
Measured image throughput: **6.1 img/s** over 60 embeds. Query (text) embed ≈ 41.7 ms.

Projected full-index time = N × mean image latency (175.3 ms), single isolate:
| gallery size | projected index time (1 isolate) |
|---|---|
|    100 | 17.5 s |
|   1000 | 2.9 min |
|   5000 | 14.6 min |
|  10000 | 29.2 min |
|  50000 | 146.1 min |

_Note: M5 runs indexing in a background isolate with batching; multi-core devices reduce wall-clock roughly linearly. Search latency (M6) is added when the search path exists._
