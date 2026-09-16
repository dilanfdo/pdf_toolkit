# Architecture

## High-level shape

PDFly is a single Flutter app with no backend. There's no state-management library
(no Provider/Riverpod/Bloc) — the app is small enough that plain `StatefulWidget`s
plus a couple of singleton services are enough, and adding a state-management
dependency would be complexity without a matching benefit at this size.

```
lib/
  main.dart               # App entry point, theme wiring, AdMob init
  models/
    pdf_tool.dart          # PdfTool enum + display metadata (title/icon/subtitle)
  screens/
    home_screen.dart        # 4 tool cards + banner ad
    file_picker_screen.dart # Pick files/images, tool-specific options (quality/page range)
    processing_screen.dart  # Runs the PdfService call, shows progress/error
    result_screen.dart      # Shows output file, Share / Back to home
    settings_screen.dart    # Dark mode toggle, "Remove ads" placeholder
  services/
    pdf_service.dart        # All PDF manipulation logic (see below)
    ad_service.dart         # AdMob wiring, interstitial frequency capping
    theme_controller.dart   # ValueNotifier<ThemeMode>, persisted via SharedPreferences
  widgets/
    tool_card.dart          # The Home screen's tool cards
```

## Navigation

Plain `Navigator.push` / `MaterialPageRoute` — no named routes, no router package.
The flow is linear: `Home → FilePickerScreen → ProcessingScreen → ResultScreen`, and
`ResultScreen`'s "Back to home" uses `pushAndRemoveUntil` to clear the stack back to
Home rather than popping through every intermediate screen.

## The PDF pipeline — the most important design decision in the app

This is worth understanding before touching `pdf_service.dart`.

The free package stack (`pdf` + `printing`) can only **generate** PDFs — neither
package can parse or edit the bytes of an arbitrary existing PDF. That rules out
"real" merge/split (splicing pages between documents while preserving vector
content, fonts, embedded text) without a paid library like Syncfusion.

So every operation in `PdfService` works the same way:

1. Rasterize each source PDF page to a bitmap, using `Printing.raster()` (the
   `printing` package's binding to the platform's native PDF renderer) at a
   quality-dependent DPI.
2. Re-encode that bitmap as a JPEG (via the `image` package — `Printing.raster`
   only gives you `.toPng()`, and PNG doesn't compress well for anything
   photo-like, so we decode the raw RGBA and re-encode as JPEG ourselves at a
   quality-dependent level).
3. Build a brand new PDF (`pw.Document` from the `pdf` package) with one full-page
   image per rasterized page.

This means:
- **Merge/split/images-to-PDF** work correctly and visually match the source, but
  output pages are images — no selectable/searchable text in the output.
- **Compress** works by combining lower DPI (fewer pixels to render) with a lower
  JPEG quality. This is genuinely effective for scanned/photographed documents
  (verified in testing: a 12MB photo-heavy PDF compressed to ~70KB, 0.6% of
  original) but is *actively harmful* for small text-only PDFs, where rasterizing
  a near-empty page to JPEG can produce a bigger file than the vector original.
  `compressPdf` guards against this explicitly: if the rasterized output isn't
  smaller than the input, it discards the rasterized version and returns a copy
  of the original file instead. This was a real bug caught by the integration
  tests, not a hypothetical — see [testing.md](testing.md).

If a future version needs true vector-preserving merge/split (keeping selectable
text), that requires swapping this layer for a proper PDF-editing library — it is
not a small tweak to the current approach.

## Ads

`AdService` centralizes both the ad unit IDs and the interstitial frequency cap.
Two things worth knowing:

- **Debug vs release ad units**: real ad unit IDs are only used in release builds
  (`kReleaseMode`). Debug/profile builds always use Google's test ad units,
  because serving real ads repeatedly from the same dev device risks AdMob's
  invalid-traffic detection flagging the account. The AdMob **App ID** (used only
  for SDK init, not per-ad serving) is safe to use for real in any build mode and
  is not gated this way.
- **iOS has no real ad units yet** — no iOS app is registered in AdMob, so iOS
  stays on test IDs regardless of build mode until that's set up.
- **Interstitial capping**: a `SharedPreferences`-backed counter shows an
  interstitial after every 3rd successful export, never on the first.

## Theming

`ThemeController` is a `ValueNotifier<ThemeMode>` wrapped around
`SharedPreferences`. `main.dart` wraps `MaterialApp` in a
`ValueListenableBuilder` on it, so toggling dark mode in Settings updates the
whole app immediately and persists across restarts. There's no dependency
injection framework — it's a plain singleton (`ThemeController.instance`), same
pattern as `AdService` and `PdfService`.

## What isn't here

No backend, no analytics SDK beyond what AdMob itself collects for ad serving, no
crash reporting SDK (Play Console's own native-crash reporting is relied on
instead, which is why release builds are configured to include debug symbols —
see [build-and-release.md](build-and-release.md)).
