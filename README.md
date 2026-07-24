# PixelSearch — Project Handoff

Privacy-first, AI-powered **semantic photo retrieval** for mobile (Flutter, Android-first).
This package contains everything to understand the project **and** run a working demo.

## What's in this folder

```
PixelSearch_Handoff/
├── README.md                     ← you are here
├── SETUP_AND_DEMO.md             ← install Flutter from scratch, run the app, 3-min demo script
├── app/                          ← the runnable Flutter demo (M0 + M1 + M3 + mock search)
└── handbook/
    ├── PixelSearch_Mobile_Implementation_Handbook.md    ← full 12-phase plan (renders diagrams)
    ├── PixelSearch_Mobile_Implementation_Handbook.docx  ← same, formatted for printing/submission
    └── diagrams/                 ← the 7 architecture/DB/flow diagrams as PNGs
```

## Quick start (browser, no Android needed)
```bash
cd app
flutter pub get
flutter run -d chrome
```
Then tap **“Explore with sample photos.”** Full steps (including running on a real Android phone) are in **SETUP_AND_DEMO.md**.

## What works today (verified)
- Premium **Material 3** UI with light/dark, onboarding, bottom-nav shell.
- **Real device gallery access** (Android) via `photo_manager`, with a **web sample-photo fallback**.
- **Search** with live results + suggestions (keyword/tag ranking — a stand-in for CLIP).
- **Full-screen viewer** (zoom, swipe, details) and a **consent-gated mock cloud caption**.
- **Timeline** auto-grouping photos into events, and a **Map** grouping by location.
- **Privacy mode** that disables all cloud features.
- Verified: `flutter analyze` clean, widget test passes, `flutter build web` succeeds (Flutter 3.44 / Dart 3.12).

## What's mocked (be upfront at the review)
The **search ranking** is keyword/tag matching, standing in for the real **on-device CLIP** semantic search.
Everything else (gallery, timeline, map, privacy model, UI) is real. The CLIP indexing pipeline is the next
milestone — the app's layered structure (data / state / features) is built so it drops straight in.

## The plan behind the app
`handbook/` is the complete technical plan: critical review of the original desktop design, the mobile-first
tech stack (Flutter, on-device CLIP via ONNX, ML Kit, SQLite/drift, optional FastAPI backend), full system
architecture, database schema, milestone-by-milestone build plan, API design, UI plan, and testing strategy.
This demo is milestones **M0, M1, M3** (plus a mock of the M8 search UI) from that plan.
