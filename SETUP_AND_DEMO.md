# PixelSearch — Setup & Demo Guide

This is a runnable **Flutter** demo of PixelSearch (privacy-first semantic photo search).
It implements the first milestones of the plan (**M0 project setup, M1 gallery access, M3 grid, plus a mock M8 search UI**) and is deliberately built to **run in two ways**:

1. **In a web browser (Chrome)** — easiest, no Android needed. Uses bundled **sample photos**.
2. **On an Android phone/emulator** — shows your **real gallery** via on-device access.

> What's real vs. mocked (say this at the review): the **UI, gallery access, timeline clustering, map locations, and privacy/consent model are real**. The **search is a keyword/tag stand-in** for now — the real CLIP semantic search is the next milestone (M4–M7 in the handbook). Everything is honest and on-device.

---

## Part A — Fastest path for the demo (web, ~15 min from scratch)

### 1. Install Flutter
- **Windows:** download the Flutter SDK zip from https://docs.flutter.dev/get-started/install/windows , extract to `C:\src\flutter`, and add `C:\src\flutter\bin` to your PATH. Then open a **new** terminal.
- **macOS:** `brew install --cask flutter` (or follow https://docs.flutter.dev/get-started/install/macos ).
- **Linux:** follow https://docs.flutter.dev/get-started/install/linux (or `sudo snap install flutter --classic`).

Verify:
```bash
flutter --version
```

### 2. Enable web + get dependencies
```bash
cd app
flutter config --enable-web
flutter pub get
```

### 3. Run it in Chrome
```bash
flutter run -d chrome
```
The app opens with the onboarding screen → tap **“Explore with sample photos”** → search, timeline, map, and settings all work on the 18 bundled sample photos.

> No Chrome? `flutter devices` to see options, or use `flutter run -d edge`. On a headless machine you can `flutter build web` and serve `build/web` with any static server.

---

## Part B — Show it on a real Android phone (real gallery)

This is the more impressive version because it indexes **actual photos**.

### 1. One-time tooling
- Install **Android Studio** (https://developer.android.com/studio) — it brings the Android SDK + platform tools.
- Open Android Studio once → let it finish “SDK components setup”.
- Accept licenses:
  ```bash
  flutter doctor --android-licenses
  ```
- Check everything is green:
  ```bash
  flutter doctor
  ```

### 2a. Easiest: a real phone over USB
- On the phone: **Settings → About phone → tap “Build number” 7 times** to unlock Developer options.
- **Settings → Developer options → enable “USB debugging.”**
- Plug the phone in, accept the “Allow USB debugging?” prompt.
- Confirm it's detected:
  ```bash
  flutter devices
  ```
- Run:
  ```bash
  cd app
  flutter run
  ```
- On first launch tap **“Use my photos”** and **grant photo access** when Android asks. Your real photos appear in the grid; timeline/map use their real dates/locations.

### 2b. Or an emulator
- Android Studio → **Device Manager → Create device** (e.g., Pixel 7, a recent system image) → start it.
- `flutter run` with the emulator running.
- Emulators start with an empty gallery — add a few photos to the emulator (drag-drop onto the window, or use its browser) so the grid isn't empty, or just use the sample set.

### 3. Build an APK to share (optional)
```bash
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```
Send that APK to a phone and install it (allow “install from unknown sources”).

---

## Part C — 3-minute review demo script

1. **Open with the story (10s).** “PixelSearch lets you search your own photo gallery in plain language — and unlike Google Photos, everything runs **on your device**. Nothing is uploaded.”
2. **Onboarding (10s).** Point out the three promises: private by design, fast semantic search, optional cloud extras with consent.
3. **Load photos (20s).**
   - On phone: tap **Use my photos**, grant access → “these are my real photos, indexed on the device.”
   - On web: **Explore with sample photos** → “a sample library so you can see the full flow.”
4. **Search (40s).** Type **“beach at sunset”**, then **“snow in the mountains”**, then **“my dog”**. Show results updating and the result count. Tap the suggestion chips too.
   - Be honest: “Search today matches tags/labels as a placeholder — the next milestone wires the on-device CLIP model so it understands the *image content*.”
5. **Viewer (20s).** Tap a photo → pinch-zoom, swipe between results, open details (date, place, tags).
6. **Privacy model (25s).** Tap **Generate caption (cloud)** → the **consent sheet** appears (“this ONE photo will be sent… your gallery is never uploaded”). Cancel it, go to **Settings → Privacy mode**, show that it disables cloud features. “This is the core of our design: a visible, trustworthy privacy boundary.”
7. **Timeline (20s).** Show photos auto-grouped into **events/trips** by date — “done on-device, no cloud.”
8. **Map (15s).** Show photos grouped by location. “Interactive OpenStreetMap is the next map milestone.”
9. **Close (20s).** “So today we have the full app shell, real on-device gallery access, the search/timeline/map experience, and the privacy model working. The next milestone drops in the CLIP model so search understands the actual image content — the architecture and database for that are fully specified in our handbook.”

**If asked “what's left?”** → point to the handbook's milestone plan: M4 CLIP image embeddings → M5 indexing engine → M6 text encoder → M7 search engine. The app is structured (data/domain/features layers) so those slot straight in behind the existing repositories.

---

## Troubleshooting

- **`flutter: command not found`** → PATH not set / terminal not reopened. Re-check step A.1.
- **`flutter pub get` fails** → check internet; run `flutter pub get` again; ensure you're inside the `app/` folder.
- **Chrome doesn't launch** → `flutter config --enable-web` then `flutter devices`; try `-d web-server` and open the printed URL.
- **Android build issues** → `flutter doctor` and fix any red items; run `flutter doctor --android-licenses`.
- **Gradle first build is slow** → the first Android build downloads Gradle/deps; give it a few minutes.
- **Photos don't show on Android 13/14** → make sure you granted “Photos and videos” (or “Selected photos”) when prompted; you can re-grant in the phone's App info → Permissions.
- **Emulator gallery empty** → add images to the emulator, or just demo with the sample set.

## Project structure (where things live)
```
app/lib/
  models/photo.dart            # the Photo model (platform-neutral)
  data/
    sample_data.dart           # 18 bundled sample photos + metadata
    device_gallery*.dart       # real gallery via photo_manager (mobile) + web stub
    search_engine.dart         # the mock ranking (replace with CLIP in M4–M7)
  state/providers.dart         # Riverpod state
  core/{theme,router}.dart     # Material 3 theme + go_router navigation
  features/                    # onboarding, search, viewer, timeline, map, settings
  widgets/                     # reusable grid/tile/empty-state
```
See `handbook/` for the full 12-phase implementation plan this app is built from.
