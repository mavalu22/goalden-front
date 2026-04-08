# Goalden — Release Guide

## Prerequisites

- Flutter SDK (stable channel)
- Java 17+ (`jdk17-openjdk` on Arch/Manjaro)
- Android SDK at `~/Android/Sdk` (configured via `flutter config --android-sdk`)
- `.env` file with required environment variables (see `.env.example`)

## Environment setup

```fish
set -x JAVA_HOME /usr/lib/jvm/java-17-openjdk
set -x ANDROID_HOME ~/Android/Sdk
fish_add_path $ANDROID_HOME/cmdline-tools/latest/bin
fish_add_path $ANDROID_HOME/platform-tools
```

---

## Android (Mobile)

### Debug build (run on connected device)

```bash
flutter run -d <device-id> --dart-define-from-file=.env
```

### Release APK

```bash
flutter build apk --dart-define-from-file=.env
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Signing (required for Play Store)

1. Generate a keystore (one-time):
   ```
   keytool -genkey -v -keystore android/app/goalden-release.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias goalden
   ```
2. Create `android/key.properties` (already gitignored):
   ```
   storePassword=<your-store-password>
   keyPassword=<your-key-password>
   keyAlias=goalden
   storeFile=goalden-release.jks
   ```
3. Reference `key.properties` in `android/app/build.gradle.kts` under `signingConfigs`.

> The keystore and `key.properties` are gitignored — never commit them.

---

## Linux (Desktop)

### Debug run

```bash
flutter run -d linux --dart-define-from-file=.env
```

### Release build

```bash
flutter build linux --dart-define-from-file=.env
# Output: build/linux/x64/release/bundle/goalden
```

### Launch built binary

```bash
./build/linux/x64/release/bundle/goalden &
```

---

## App metadata

| Field         | Value             |
|---------------|-------------------|
| App ID        | `com.goalden.app` |
| Version       | `1.0.0+1`         |
| Min Android   | API 21 (Android 5.0) |
| Target Android| API 35            |
