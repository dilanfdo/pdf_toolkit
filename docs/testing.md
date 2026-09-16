# Testing

## Static analysis

```bash
flutter analyze
```

## Widget smoke test

```bash
flutter test test/widget_test.dart
```
Just confirms the Home screen renders all four tool cards.

## Integration tests (the ones that actually matter here)

```bash
flutter test integration_test/pdf_flow_test.dart -d <device-id>
```

These run **on a real device/emulator**, not in a headless Dart VM, because the
whole PDF pipeline depends on `Printing.raster()`, which is a platform channel
binding to the OS's native PDF renderer — it doesn't work in a plain `flutter
test` unit-test environment.

Every fixture is generated in-process (via the `pdf` and `image` packages) rather
than depending on a pushed file or a real device path. This was a deliberate
choice after hitting a `PathAccessException` trying to read from
`/sdcard/Download/` — Android's scoped storage means an app can't read arbitrary
paths outside its own sandbox without going through the system file picker (which
is exactly why the real app uses `file_picker`/`image_picker` rather than raw
file paths). Keeping fixtures self-contained means the tests also don't depend on
any pre-existing device state, so they'll run the same way in CI as on a dev
machine.

What's covered:
- `getPageCount` returns the correct count for a known fixture
- `compressPdf` never returns a file larger than the original (regression test —
  see below)
- `splitPdf` extracts the correct number of pages for a given range
- `mergePdfs` produces a page count equal to the sum of its inputs
- `compressPdf` meaningfully shrinks a synthetic photo-heavy PDF (proves the
  compression pipeline actually works for the use case it's meant for)
- `imagesToPdf` produces one page per input image

## A bug this suite actually caught

The "never returns a file larger than the original" test exists because it failed
before `compressPdf` had a fallback: compressing a 2-page text-only fixture
produced a file **13x larger** than the input (2535 → 34503 bytes), because
rasterizing near-empty text pages to JPEG is far less space-efficient than the
original vector text. `PdfService.compressPdf` now checks the rasterized output's
size against the original and falls back to a copy of the original file if
compression didn't actually help. This is real behavior a real user would have
hit — compress a small text PDF and get a bigger file back — not a hypothetical
edge case.

Run the integration tests after any change to `pdf_service.dart` — this is the
part of the app most likely to have silent correctness regressions, since the
"happy path" (does it produce *a* PDF) can pass while the actual size/quality
tradeoffs silently break.
