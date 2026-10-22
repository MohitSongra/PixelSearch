<!--
Privacy first: this repository is public. Never include gallery photos, face crops, person names,
GPS coordinates, device serial numbers, local paths, backend URLs or tokens in the description,
screenshots, test fixtures or committed files. Use placeholders such as <name> and synthetic images.
-->

## Summary

<!-- What does this change do, and why? Link the issue if there is one. -->

## Type of change

- [ ] Bug fix
- [ ] Feature
- [ ] Refactor or cleanup
- [ ] Tests or CI
- [ ] Documentation

## How was it verified?

<!-- Commands run, host or device, and results. Label every number with its date, host or device,
precision and sample size. Never run a bare `flutter test integration_test/... -d <device>`. -->

## Checklist

- [ ] `flutter analyze` reports no issues (in `pixelsearch_app/`).
- [ ] `flutter test test/` passes (in `pixelsearch_app/`).
- [ ] `python tool/check_repository.py` passes.
- [ ] Docs are updated where facts changed, and new measurements are recorded with their date, host or device,
      precision and sample size (`docs/EVIDENCE_LEDGER.md`).
- [ ] No model contract change (preprocessing, tokenizer, embedding size, image size, normalization, ONNX names,
      dtypes or opset, face pipeline) without the matching version bump and re-verification.
- [ ] Schema changes include an additive migration step, both schema version bumps, a `MIGRATIONS.md` row and a
      migration test.
- [ ] Ranking changes (gate, weights, lexical policy) come with judged, held-out evidence.
- [ ] No personal data, secrets, model exports, APKs or device databases are added. Files were staged by explicit
      path.
