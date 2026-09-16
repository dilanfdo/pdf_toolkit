# Tech Stack

## Framework

**Flutter** — chosen for fast iteration and a mature file-handling/PDF ecosystem,
with a real path to iOS later from the same codebase even though Android is the
primary target for now.

## Dependencies and why each is there

| Package | Purpose |
|---|---|
| `file_picker` | Native file picker for selecting PDFs from device storage |
| `image_picker` | Native photo picker for the Images→PDF tool |
| `pdf` | Generates PDF files from scratch (pages, images, layout) |
| `printing` | Rasterizes existing PDF pages to bitmaps via the platform's native renderer — this is the load-bearing package for the whole PDF pipeline, see [architecture.md](architecture.md) |
| `image` | Decodes/encodes image bytes (PNG↔JPEG, raw RGBA), used to re-encode rasterized pages as JPEG for real compression |
| `share_plus` | System share sheet for sending the finished PDF to another app |
| `path_provider` | Finds the app's documents directory to save output files |
| `shared_preferences` | Persists the dark-mode setting and the interstitial-ad export counter |
| `google_mobile_ads` | AdMob SDK — banner + interstitial |
| `flutter_launcher_icons` (dev) | Generates all platform icon sizes from one source image |
| `integration_test` (dev, Flutter SDK) | On-device test framework used for the PDF pipeline test suite |

## Why not X

- **No Syncfusion / other paid PDF SDK**: would give true vector-preserving
  merge/split, but the free `pdf`+`printing` stack covers the actual use case
  (scan/photo-style documents) well enough, and avoids a licensing cost for a
  solo/indie project. Documented explicitly as a tradeoff in
  [architecture.md](architecture.md) in case this needs revisiting.
- **No state management package** (Provider/Riverpod/Bloc): the app's state is
  small and local to each screen, plus two singleton services
  (`AdService`, `ThemeController`). Not enough complexity to justify the
  dependency and the indirection it brings.
- **No backend/API**: everything is on-device by design — this is a privacy
  selling point (see the privacy policy and ASO copy) as much as it is a cost
  and complexity saver.
