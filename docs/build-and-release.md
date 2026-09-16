# Build & Release

## Debug builds

```bash
flutter run -d <device-id>
```

Uses debug signing and Google's test AdMob ad units automatically (see
[architecture.md](architecture.md#ads)).

## Release builds

```bash
flutter build apk --release      # for sideloading/testing a single APK
flutter build appbundle --release  # .aab — what Play Console actually wants
```

Both require `android/key.properties` to exist (gitignored, not in this repo) with:

```properties
storePassword=<password>
keyPassword=<password>
keyAlias=pdfly-upload
storeFile=keystore/pdfly-upload-key.jks
```

`storePassword` and `keyPassword` are the same value — `keytool`'s modern default
(PKCS12) doesn't support different store/key passwords. The actual keystore file
and its password are **not in this repo** and were only ever communicated directly
to the project owner — if you don't have them, they need to be regenerated (which
means going through Play Console's key-reset flow, since Play App Signing is in
use) or recovered from wherever they were backed up.

Without `key.properties` present, `build.gradle.kts` falls back to debug signing
so `flutter run --release` still works for local testing — but that output is
**not** suitable for upload to Play Console.

## Known build gotchas (both were real, both cost real debugging time)

### 1. Release build crashes on launch: `Failed to create an instance of androidx.work.impl.WorkDatabase`

R8 (enabled by default for release builds) strips/renames Room-generated `_Impl`
classes that WorkManager needs via reflection at startup. WorkManager is pulled in
transitively (most likely via `google_mobile_ads`). This **only shows up in release
builds** — debug builds skip minification entirely, so this can silently ship if
you only ever test debug builds.

Fixed by `android/app/proguard-rules.pro`:
```
-keep class * extends androidx.room.RoomDatabase
-keep class androidx.work.impl.** { *; }
-keep class androidx.room.** { *; }
```
wired into `build.gradle.kts`'s release `proguardFiles`. If you add a new
dependency and see a similar `Failed to create an instance of ...` crash on
release only, the fix pattern is the same: figure out what's being reflectively
instantiated and add a targeted `-keep` rule rather than disabling minification.

**Always test an actual signed release build before uploading to Play Console —
debug builds do not catch this class of bug.**

### 2. `flutter build appbundle --release` fails with "failed to strip debug symbols from native libraries"

This is Flutter's own post-build verification step (it runs `apkanalyzer` to
confirm native debug symbols were packaged), not a Gradle/signing failure —
running `./gradlew bundleRelease` directly can succeed while the Flutter wrapper
still reports this error. Two separate things had to be true to fix it on this
machine:

- `android/app/build.gradle.kts`'s release build type needs
  `ndk { debugSymbolLevel = "FULL" }` so AGP actually packages the
  `.so.dbg` sidecar files Flutter's check looks for (this part is in the repo).
- **Machine-local**: if `cmdline-tools/latest` under the Android SDK is a
  *symlink* to a Homebrew-installed location (e.g. from
  `brew install --cask android-commandlinetools`), `apkanalyzer`'s own
  self-path resolution can resolve back to the symlink target, which doesn't
  have `build-tools/` as a sibling directory, causing
  `Cannot locate latest build tools`. Fix: replace the symlink with a real copy
  of `cmdline-tools/latest` inside the actual SDK directory. This is an
  environment setup issue, not something a code change in this repo can fix —
  if a future dev hits the same "failed to strip debug symbols" error, check
  whether `cmdline-tools/latest` is a symlink first.

## Store assets

- App icon source: `assets/icon/` (`icon.png`, `icon_background.png`,
  `icon_foreground.png` — see `flutter_launcher_icons` config in `pubspec.yaml`).
  Regenerate all platform icons after changing any of these with:
  ```bash
  dart run flutter_launcher_icons
  ```
- Play Store listing assets (512×512 icon, 1024×500 feature graphic, phone
  screenshots): `assets/icon/play_store_icon_512.png`,
  `assets/icon/feature_graphic.png`, `store_screenshots/`.
- Privacy policy: `docs/privacy-policy.html`, served via GitHub Pages (Settings →
  Pages → deploy from `main` / `/docs`) at
  `https://dilanfdo.github.io/pdfly/privacy-policy.html`.

## AdMob IDs

Real production App ID and Android ad unit IDs are already wired into
`AndroidManifest.xml` and `ad_service.dart`. See
[architecture.md](architecture.md#ads) for how debug/release and Android/iOS
selection works before changing anything here.
