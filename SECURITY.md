# Security Policy

## Reporting a vulnerability

Please do **not** open a public issue for security problems.

Report privately through GitHub's *Report a vulnerability* button on the
repository's **Security** tab (private vulnerability reporting), or contact
the maintainer through [sagnikbhattacharya.com](https://sagnikbhattacharya.com).
Include steps to reproduce and the platform (Android, iOS or web) affected.
You will get an acknowledgement within a few days.

## Supported versions

| Version | Supported |
| ------- | --------- |
| 2.x     | Yes       |
| 1.x     | No        |

## What this app does with data

This is a teaching sample. It keeps hotel inventory and bookings **in memory
only**: nothing is written to disk, sent over the network, or shared with any
third party. Guest details entered at checkout live for the lifetime of the
process and are discarded when the app closes.

## Hardening in place

### Dart / application code

- Every free-text input is passed through `InputSanitizer` (strips control
  characters, zero-width and bidirectional-override characters, collapses
  whitespace, caps length) before it is validated, searched or displayed.
- Text fields enforce hard limits with `LengthLimitingTextInputFormatter`
  and reject control characters at the keyboard with
  `FilteringTextInputFormatter`.
- Guest name, e-mail and phone are validated twice: in the form for feedback,
  and again by `BookingPolicy` inside the repository, so the domain never
  trusts the UI.
- Booking references come from `Random.secure()` using an alphabet without
  look-alike characters; 32^8 possibilities make guessing another guest's
  reference impractical.
- `GuestDetails.toString()` deliberately omits personal data so accidental
  logging is harmless, and `avoid_print` is promoted to an error in
  `analysis_options.yaml`.
- Strict analyzer settings (`strict-casts`, `strict-inference`,
  `strict-raw-types`) and an extended lint set run in CI with
  `--fatal-infos`.
- No third-party runtime packages, which keeps the supply-chain surface at
  the Flutter SDK itself. Dependabot watches `pub` and GitHub Actions weekly.

### Android

- `android:allowBackup="false"` and `fullBackupContent="false"`: app data is
  never copied into device or cloud backups.
- `android:usesCleartextTraffic="false"` plus a `network_security_config`
  that permits HTTPS only and trusts the **system** certificate store, not
  user-installed CAs.
- Release builds are shrunk and obfuscated (`minifyEnabled`,
  `shrinkResources`, R8 with `proguard-android-optimize.txt`).
- Release signing reads `android/key.properties`, which is git-ignored along
  with `*.jks`, `*.keystore` and `.env*`. Without the file the build falls
  back to the debug key so `flutter run --release` still works locally.
- No permissions are requested. `taskAffinity=""` keeps the activity out of
  other apps' tasks.

### iOS

- App Transport Security stays at its strict default
  (`NSAllowsArbitraryLoads=false`); no exceptions are declared.
- `ITSAppUsesNonExemptEncryption=false` documents that only standard OS
  encryption is used.
- Deployment target 13.0, matching current Flutter requirements.
- Per-machine `ios/Flutter/ephemeral/` files are git-ignored.

### Web

- `web/index.html` ships a Content Security Policy:
  `default-src 'self'`, scripts limited to the origin (plus
  `'wasm-unsafe-eval'` for the CanvasKit renderer), `object-src 'none'`,
  `base-uri 'self'`, `form-action 'self'`.
- `referrer` is set to `strict-origin-when-cross-origin`.
- CI builds with `--no-web-resources-cdn` so CanvasKit is served from the
  same origin; the policy still allows Google's CDN for local builds that use
  it, and Google Fonts for Flutter's fallback fonts.
- `tool/verify_web.cjs` loads the built app in headless Chromium and fails on
  CSP violations, page errors or failed requests.

### CI

- Workflow permissions are `contents: read`; nothing in CI can write to the
  repository.
- Formatting, analysis (infos fatal) and the full test suite gate every
  build; Android, web and iOS builds run on every push.

## Known limitations

- There is no authentication, payment or server. A production app would move
  `BookingPolicy` checks, pricing and confirmation-code generation to a
  backend, add TLS pinning where appropriate, and store any persisted
  personal data in platform secure storage.
