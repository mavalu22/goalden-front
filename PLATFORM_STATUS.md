# Goalden — Platform Readiness Report (V1)

> Last evaluated: 2026-04-05

---

## Summary

| Platform | Status                        | V1 Recommendation   |
|----------|-------------------------------|---------------------|
| Linux    | Working                       | Include             |
| Android  | Working with setup caveats    | Include             |
| macOS    | Blocked                       | Exclude (post-V1)   |
| Windows  | Blocked                       | Exclude (post-V1)   |
| iOS      | Blocked                       | Exclude (post-V1)   |

**V1 scope recommendation: Linux + Android only.**

---

## Linux (Desktop)

**Status: Working**

### Verified
- Builds successfully: `flutter build linux --dart-define-from-file=.env`
- Launches and renders correctly
- Login flow reachable (Email + Google OAuth)
- Google OAuth uses Supabase redirect + XDG URL scheme handler registered at runtime
- Apple Sign In button is correctly hidden on Linux
- Local database (`NativeDatabase` + `sqlite3_flutter_libs`) works via `path_provider`
- `app_links` (Linux variant) handles OAuth deep link callbacks via D-Bus

### Caveats
- Google OAuth callback requires `xdg-mime` and `update-desktop-database` to be installed (standard on most Linux desktops). The app registers the scheme at launch — if these tools are missing it logs a warning and continues without deep link support.

---

## Android (Mobile)

**Status: Working with setup caveats**

### Verified
- Builds successfully: `flutter build apk --dart-define-from-file=.env` (58MB release APK)
- Runs on physical device (Samsung Galaxy S20 FE, Android 13)
- Login flow reachable
- App connects to backend and Supabase
- `NativeDatabase` + `sqlite3_flutter_libs` works correctly
- `app_links` handles deep link callbacks

### Caveats / Setup required before release

1. **Google Sign In — `serverClientId` missing**
   - `GoogleSignIn()` is initialized without a `serverClientId`. On Android this works only if the SHA-1 fingerprint of the signing key is registered in the Google Cloud Console OAuth credentials.
   - For a signed release build, add the release SHA-1 to the Google Cloud Console and set `serverClientId` in `GoogleSignIn(serverClientId: '...')`, or add a `google-services.json`.
   - Email sign-in is unaffected and works without any additional config.

2. **Release signing not configured**
   - `android/app/build.gradle.kts` currently falls back to debug signing for release builds.
   - Before distributing, generate a keystore and configure `key.properties` (see `RELEASE.md`).

3. **App ID**
   - Updated from `com.example.goalden` to `com.goalden.app` in TASK-070. Verified in the release APK.

---

## macOS (Desktop)

**Status: Blocked**

### Blockers
1. **No `macos/` platform directory** — platform files have not been generated (`flutter create --platforms=macos .` required).
2. **Requires macOS machine** — cannot build or validate without Xcode.
3. **Entitlements not configured** — macOS sandbox requires explicit entitlements:
   - `com.apple.security.network.client` — for API/Supabase calls
   - `com.apple.security.network.server` — potentially for local server flows
   - `com.apple.developer.appleseed.applattest` — for Apple Sign In (if using native)
4. **`app_links`** — no macOS variant in the lockfile. The `app_links` package supports macOS but requires URL scheme registration in `Info.plist` and the `macos/` entitlements.
5. **Apple Developer account** — required for signing even in development on macOS.

### What will likely work once unblocked
- Auth flows: Google via OAuth redirect (same as Linux), Apple Sign In native (already guarded to iOS/macOS in code), Email — all handled correctly.
- Local database: `path_provider` returns `~/Library/Application Support/` on macOS. `sqlite3_flutter_libs` supports macOS.
- UI: Desktop layout path is already coded for macOS (`_isDesktop` includes `TargetPlatform.macOS`).

---

## Windows (Desktop)

**Status: Blocked**

### Blockers
1. **No `windows/` platform directory** — not generated.
2. **Requires Windows machine** — cannot build without Windows SDK/MSVC.
3. **`app_links`** — no Windows variant in the lockfile. OAuth deep link callback may not work without a custom URI scheme handler.
4. **Google OAuth redirect** — requires a registered redirect URI and a running browser; should work via `supabase.auth.signInWithOAuth` but the callback delivery mechanism (deep link) needs validation.

### What will likely work once unblocked
- Auth: Google + Email via OAuth redirect. Apple Sign In via OAuth redirect (already handled).
- Local database: `path_provider` returns `%APPDATA%` on Windows. `sqlite3_flutter_libs` supports Windows.
- UI: Desktop layout path covers Windows.

---

## iOS (Mobile)

**Status: Blocked**

### Blockers
1. **No `ios/` platform directory** — not generated.
2. **Requires macOS + Xcode** — iOS builds are impossible without Xcode.
3. **Apple Developer account required** — even for development builds on a real device.
4. **`google_sign_in_ios`** — requires `GoogleService-Info.plist` to be added to the Xcode project with the correct OAuth client ID.
5. **URL scheme for Google Sign In** — `Info.plist` must include the reversed client ID as a custom URL scheme.
6. **Apple Sign In** — requires `Sign In with Apple` capability enabled in the Apple Developer portal and Xcode project. Code is already correct (`SignInWithApple.getAppleIDCredential` guarded to iOS/macOS).

### What will likely work once unblocked
- Auth: Google (with `GoogleService-Info.plist`), Apple Sign In native (code already correct), Email.
- Local database: `path_provider` returns the correct iOS path. `sqlite3_flutter_libs` supports iOS.
- UI: The app uses a mobile layout path on iOS.

---

## Platform feature matrix

| Feature                     | Linux | Android | macOS | Windows | iOS  |
|-----------------------------|-------|---------|-------|---------|------|
| Build compiles              | ✓     | ✓       | —     | —       | —    |
| Launches and renders        | ✓     | ✓       | —     | —       | —    |
| Reaches login screen        | ✓     | ✓       | —     | —       | —    |
| Reaches authenticated app   | ✓     | ✓       | —     | —       | —    |
| Email login                 | ✓     | ✓       | ✓*    | ✓*      | ✓*   |
| Google login                | ✓     | ⚠       | ✓*    | ✓*      | ⚠*   |
| Apple login                 | ✓†    | ✓†      | ✓*    | ✓†*     | ✓*   |
| Local SQLite database       | ✓     | ✓       | ✓*    | ✓*      | ✓*   |
| OAuth deep link callback    | ✓     | ✓       | ⚠*    | ⚠*      | ✓*   |
| Desktop layout              | ✓     | —       | ✓*    | ✓*      | —    |
| Mobile layout               | —     | ✓       | —     | —       | ✓*   |

`✓` = verified working  
`⚠` = expected to work, caveat applies  
`✓*` = expected to work once platform files/tools are set up  
`⚠*` = likely works but needs validation  
`✓†` = Apple OAuth redirect flow (not native Apple Sign In — Apple may reject this on iOS)  
`—` = not applicable  

---

## What must be done before claiming V1 support per platform

### Linux — ready now
- No blockers. Distribute via tarball or AppImage.

### Android — ready with one step
- Configure Google Sign In `serverClientId` in `AuthRepositoryImpl` and register the release SHA-1 in Google Cloud Console.
- Set up release keystore (see `RELEASE.md`).

### macOS — post-V1
1. Run `flutter create --platforms=macos .`
2. Configure entitlements (`macos/Runner/DebugProfile.entitlements`, `Release.entitlements`)
3. Register URL scheme in `macos/Runner/Info.plist` for OAuth callback
4. Enroll in Apple Developer Program
5. Validate auth flows and deep link handling

### Windows — post-V1
1. Run `flutter create --platforms=windows .` on a Windows machine
2. Register a custom URI scheme for OAuth callback (registry or Windows app manifest)
3. Validate Google OAuth redirect + callback delivery

### iOS — post-V1
1. Run `flutter create --platforms=ios .` on a macOS machine with Xcode
2. Add `GoogleService-Info.plist` and register reversed client ID in `Info.plist`
3. Enable Sign In with Apple capability in Xcode + Apple Developer portal
4. Validate Apple Sign In and Google Sign In flows on device
