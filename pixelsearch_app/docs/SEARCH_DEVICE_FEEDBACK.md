# Scene Search Feedback

Device: Vivo I2214, Android API 36. Model: existing MobileCLIP-S1 FP32 CPU.

1. Select your desired folders and let indexing finish (or cancel normally after a committed batch).
2. Open Settings > Search diagnostics and compare one complete scene query.
3. Inspect Raw cosine and Final Top 5. Check the full image where a thumbnail is unclear.
4. Mark only your own relevance judgments. Add known expected filenames through the JSON format in
   `SEARCH_EVALUATION.md`, especially when an expected photo is absent from Top 20.
5. Copy queries/judgments and the report after rerunning. Repeat across scene categories, not just nouns.

For each query, return:

```text
Query:
Expected filename(s) or asset ID(s):
Raw cosine Top 5:
Final Top 5:
Correct result:
Correct raw rank:
Correct final rank:
Relevant / Partially relevant / Irrelevant:
Notes:
```

Leave unknown entries blank. Do not choose an expected match solely because the system ranked it highly.
For multi-part scenes, explain which requested details are present or missing. "No matching photo in my indexed
folders" is useful feedback too. No exact filename matches or relevance labels have been supplied in advance.
