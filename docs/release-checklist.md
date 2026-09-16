# Release Checklist

Status as of the current state of this repo. This file tracks what's needed to get
PDFly published on the Play Store — update it as steps get completed.

## Done, in this repo

- [x] Core app: Compress / Merge / Split / Images-to-PDF, all verified working via
      [integration tests](testing.md) on a real device
- [x] Release build signing configured (`android/key.properties`, gitignored)
- [x] Release-build crash fixed (WorkManager/R8 — see
      [build-and-release.md](build-and-release.md))
- [x] App icon (launcher + adaptive icon, Android and iOS)
- [x] Dark mode toggle, persisted
- [x] AdMob wired: real App ID + Android ad unit IDs, test IDs used automatically
      in debug builds
- [x] Play Store listing graphics: 512×512 icon, 1024×500 feature graphic
      (`assets/icon/`)
- [x] Phone screenshots (`store_screenshots/`) — Home, Compress, Merge, Split,
      Images-to-PDF
- [x] Privacy policy page (`docs/privacy-policy.html`)
- [x] ASO copy (title, short description, full description) — see below for where
      it's recorded
- [x] Full manual QA pass through every screen/tool on both an emulator and a real
      device (Samsung Galaxy A16, Android 16), driving the actual native file/photo
      pickers rather than just the integration tests. Found and fixed 3 real bugs
      this way — see below.
- [x] Tablet screenshots (7" and 10", `store_screenshots/tablet_7in/`,
      `tablet_10in/`)

## Bugs found during manual QA (all fixed, all covered by tests where practical)

- **Fatal native OOM crash** on PDFs with an unusually large physical page size
  (e.g. a poster/drawing export) at High quality — the native PDF renderer would
  allocate a huge bitmap and crash the whole app before any Dart error handling
  could run. Fixed with a cheap low-DPI probe pass that caps the real render DPI.
  Regression-tested in `integration_test/pdf_flow_test.dart`.
- **Bottom banner ad rendered behind the system navigation bar** on edge-to-edge
  real devices (only visible on real hardware, not the emulator). Fixed by
  wrapping the banner in `SafeArea(top: false)`.
- **Dark-mode toggle showed off when the app was actually dark** — it only
  checked `mode == ThemeMode.dark` literally, missing the case where the default
  `ThemeMode.system` resolves to dark because the OS is in dark mode. Fixed by
  resolving against `MediaQuery.platformBrightnessOf(context)` in that case.

Also found and reverted mid-fix: wrapping the banner in `Center()` (in addition
to `SafeArea`) broke the Home screen's tool-card grid entirely, because `Center`
has no bounded intrinsic size and expands to fill whatever space Scaffold gives
`bottomNavigationBar`. Worth remembering if this area gets touched again.

Also noted, not fixed (cosmetic/accessibility, not blocking): the Settings gear
icon and the per-file remove ("×") buttons have no accessibility label
(`content-desc`) — screen reader users would hear nothing for these controls.

## ASO copy (for pasting into Play Console's store listing)

**Title:** `PDFly - PDF Compress & Merge`

**Short description:**
`Compress, merge, split PDFs & convert images to PDF — fast, free, offline.`

**Full description:** see the git history / conversation this was drafted in, or
regenerate — it's not duplicated into this repo as a separate file to avoid two
sources of truth drifting apart. (Consider pasting the final, as-submitted copy
here once it's live, so this repo has a record of what's actually published.)

## Needs to happen in Play Console (not something this repo can do)

- [ ] Enable GitHub Pages for this repo (`Settings → Pages → Deploy from a branch
      → main /docs`) so the privacy policy has a live URL
      (`https://dilanfdo.github.io/pdfly/privacy-policy.html`) — required before
      Play Console will accept the privacy policy link
- [ ] Store listing: paste in title/descriptions, upload icon + feature graphic +
      screenshots, add the privacy policy URL
- [ ] App content declarations: content rating questionnaire, target audience
      (18+ only — see rationale in the conversation this was set up in, it avoids
      Families Policy obligations), ads declaration (Yes), Advertising ID
      declaration (Yes, "Advertising or marketing" only), Data safety section
      (AdMob collects advertising ID for ad serving; nothing else is collected)
- [ ] App category: **Tools**. Tags: **Tools, Productivity, Privacy & security**
      (there's no dedicated "PDF"/"document converter" tag in Play's list)
- [ ] Internal testing track: upload `build/app/outputs/bundle/release/app-release.aab`
      (rebuild first if any code has changed since — see
      [build-and-release.md](build-and-release.md))
- [ ] Add internal testers, verify the app installs and works from the testing
      track before requesting a production release

## Before requesting production review

- [ ] Confirm the keystore (`android/keystore/pdfly-upload-key.jks`) and its
      password are backed up somewhere durable (password manager / encrypted
      backup) — **not just this machine**. Losing it means going through Play
      Console's upload-key-reset support flow to ship future updates.
- [ ] Re-run the [integration test suite](testing.md) one more time against the
      exact build being submitted
- [ ] Sanity-check the release build actually launches (this repo already hit one
      release-only crash that debug testing never caught — see
      [build-and-release.md](build-and-release.md))
