# Sprint 20 — Production Flutter Release

## Overview
Sprint 20 transitioned Back2Kasi from local emulators to a production-ready mobile artifact (`app-release.apk`) configured for direct deployment and testing on physical Android devices against the live cloud backend.

---

## Key Engineering Decisions & Implementations

### 1. Release Configuration & Manifest Permissions
* **Issue**: Android manifests default to scoping `android.permission.INTERNET` only in the `debug` source set. Release builds without explicit permission fail on network calls with `SocketException`.
* **Solution**:
  * Added `<uses-permission android:name="android.permission.INTERNET"/>` to `app/android/app/src/main/AndroidManifest.xml`.
  * Updated `android:label` to `Back2Kasi` so the device launcher displays a clean brand title instead of the default package folder name.
  * Verified package ID `com.back2kasi.back2kasi_app` and semantic release version `1.0.0+1`.

### 2. Cryptographic Release Signing Architecture
* **Keystore Generation**: Created an RSA 2048-bit production release keystore (`upload-keystore.jks`) using Java `keytool` with PKCS12 standard encoding.
* **Gradle Configuration**:
  * Configured `build.gradle.kts` to dynamically read `key.properties` for `storeFile`, `storePassword`, `keyAlias`, and `keyPassword`.
  * Bound the release signing configuration to `buildTypes.getByName("release")`.
  * Verified that `.gitignore` strictly protects `*.keystore`, `*.jks`, and `key.properties` from version control commits.

### 3. Production Environment Injection via `--dart-define`
* Built without modifying Dart source code by leveraging `ApiConfig._apiBaseUrl` with compile-time environment variable:
  ```powershell
  flutter build apk --release --dart-define=API_BASE_URL=https://back2kasi.onrender.com
  ```
* Verified fallback and production URL behavior across auth, business discovery, and booking endpoints.

### 4. Build Toolchain & Android SDK Modernization
* Configured local Android SDK toolchain under `C:\Users\KABELO~1\AppData\Local\Android\Sdk` (resolving Windows space path caveats using 8.3 short paths).
* Installed Android SDK Platform 36, Android Platform 34, Android Build-Tools 34.0.0, Platform Tools, and `cmdline-tools/latest`.
* Compiled multi-architecture native binaries supporting `arm64-v8a`, `armeabi-v7a`, and `x86_64`.

---

## Artifact Verification

* **Output Artifact**: `app/build/app/outputs/flutter-apk/app-release.apk` (50.4 MB)
* **Signature Verification (`apksigner`)**:
  * Verified using APK Signature Scheme v2 (`true`).
  * Signer: `CN=Back2Kasi Developer, OU=Mobile, O=Back2Kasi, L=Johannesburg, ST=Gauteng, C=ZA`
  * SHA-256 Digest: `1df85f0426160bae5e28325e4934b1ad4ea6295bd5ecc14b78ce1c64e4cea971`
* **Package Badging (`aapt`)**:
  * Package Name: `com.back2kasi.back2kasi_app`
  * Version: `versionCode=1`, `versionName=1.0.0`
  * Label: `Back2Kasi`
  * Permission: `android.permission.INTERNET`
* **Client Tests**: 16/16 Flutter tests passing (`flutter test`).

---

## Real-Device Testing & Distribution Guide

1. **Install on Physical Device via ADB**:
   ```powershell
   adb install -r app/build/app/outputs/flutter-apk/app-release.apk
   ```
2. **Direct APK Distribution**:
   * Transfer `app-release.apk` to test users via WhatsApp, Google Drive, or USB.
   * Device prompt: Allow "Install from Unknown Sources" for immediate onboarding.
3. **Smoke Test Sequence on Phone**:
   * Launch `Back2Kasi` from app drawer.
   * Register new account -> Authenticate against Render cloud API.
   * Create listing (Owner) / Book rental unit (Customer) -> Verify end-to-end sync.
   * Toggle Airplane mode -> Verify resilient offline error handling and session restore.
