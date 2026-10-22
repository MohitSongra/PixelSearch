# PixelSearch

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users

Everyday users finding memories in a large personal photo library, confirmed by the user on 18 September 2026.

## Product Purpose

Find personal photos by describing their content, then browse and revisit them through search results, photo details, timeline memories, and recorded places.

## Positioning

On-device AI photo search. The Flutter Android app computes labels and embeddings locally and searches the local photo index. Optional online enhancements have separate consent controls.

## Capabilities and Constraints

- Existing Flutter implementation: `pixelsearch_app/`, Riverpod state, GoRouter navigation, Material 3 light and dark themes.
- Preserve indexed gallery browsing, semantic and keyword search, people identification, voice/conversation entry points, folder selection, local indexing, and label corrections.
- Preserve timeline year/month navigation, event groups, memory stories, and cover editing.
- Map pins use verified photo locations. Online map tiles require consent; offline states must remain usable and truthful.
- Privacy controls include offline-only mode and separate permissions for captions, the search assistant, online speech transcription, and map tiles.
- Do not imply encryption, cloud backup, sharing, favorites, or other capabilities the current implementation does not provide.
- Requested redesign covers Home/Search, Results Grid, Photo Detail, Timeline, Map View, and Privacy Centre.

## Brand Commitments

Keep the name PixelSearch. The user requested a premium Android gallery experience inspired by Google Photos and other gallery apps. Familiar native navigation, legible controls, and prominent photo content take priority over ornamental presentation.

## Evidence on Hand

Existing Dart code, Android implementation, domain and widget tests, and four bundled sample photos are available. Documentation at the repository root includes older demo claims; current source code is authoritative for implemented capabilities.

Mockup photos, counts, dates, and place names are illustrative design content, not the user's actual library or measured product claims.

## Product Principles

- Make finding a remembered photo the easiest action.
- Preserve the user's photos and the behavior of existing features.
- Explain online permissions at the point they matter.
- Give photographs priority while keeping controls readable and reachable.

## Open Decisions

No additional audiences, monetization requirements, or new product features were requested.
