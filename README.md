# Neon Drift Mini

A minimalist neon-styled top-down endless car racing mini-game built with pure Flutter.
Designed for Android, offline, lightweight, and Play Store ready.

![Style: Gen Z Neon](https://img.shields.io/badge/style-neon-FF2D95)
![Engine: Flutter](https://img.shields.io/badge/engine-flutter-00F0FF)
![Offline](https://img.shields.io/badge/offline-yes-00FF94)

---

## ✨ Features

- 🎮 Top-down endless racing — dodge obstacles, collect coins
- 🌈 Gen-Z neon aesthetic — drawn entirely with `CustomPainter`, zero image assets
- 📈 Difficulty scaling — speed and spawn rate ramp up over time
- 🏆 Local high score (offline via `shared_preferences`)
- 📱 Touch buttons + swipe controls with haptic feedback
- ⚡ Smooth 60/90/120Hz gameplay (frame-rate independent physics)
- 🔒 Fully offline — no internet, ads, or backend required

---

## 📁 Project Structure

```
neon_drift_mini/
├── pubspec.yaml
├── analysis_options.yaml
├── README.md
└── lib/
    ├── main.dart
    ├── theme/
    │   └── app_theme.dart
    ├── services/
    │   └── storage_service.dart
    ├── game/
    │   ├── game_controller.dart      # State + game loop
    │   ├── game_objects.dart         # Player, obstacles, coins
    │   └── game_painter.dart         # All rendering
    └── screens/
        ├── home_screen.dart
        ├── game_screen.dart
        └── game_over_screen.dart
```

> The `android/`, `ios/`, `web/` and platform folders are **generated locally** by Flutter on first setup (see below). This keeps the zip tiny and avoids stale Gradle versions.

---

## 🚀 Quick Start (5 minutes)

### 1. Prerequisites

- **Flutter SDK** 3.27 or later → https://docs.flutter.dev/get-started/install
- **Android Studio** (for the Android SDK + an emulator) → https://developer.android.com/studio
- **VS Code** (recommended) with the Flutter extension

Verify your install:
```bash
flutter doctor
```
Make sure all checkmarks are green for **Flutter**, **Android toolchain**, and **VS Code** / **Android Studio**.

### 2. Unzip and open

1. Unzip `neon_drift_mini.zip`
2. Open the folder in **VS Code** (`File → Open Folder…`) **or** Android Studio.

### 3. Generate the Android platform files

The zip contains only the **Dart source** to keep things clean. Run this **once** inside the project folder to generate the `android/` folder, Gradle wrapper, manifest, etc.:

```bash
cd neon_drift_mini
flutter create --org com.tharindux --project-name neondriftmini .
```

This command **will not overwrite** your existing `lib/`, `pubspec.yaml`, or `README.md`. It only fills in the missing platform-specific scaffolding.

### 4. Install dependencies

```bash
flutter pub get
```

### 5. Set the display name

Open `android/app/src/main/AndroidManifest.xml` and change:
```xml
android:label="neondriftmini"
```
to:
```xml
android:label="Neon Drift Mini"
```

### 6. Run!

Plug in an Android device (with USB debugging enabled) or start an emulator, then:
```bash
flutter run
```

---

## 🛠️ Building a Release APK

When you're ready to share or publish:

```bash
flutter build apk --release
```

The APK will be at:
```
build/app/outputs/flutter-apk/app-release.apk
```

For a smaller, per-architecture split build:
```bash
flutter build apk --split-per-abi --release
```

For a **Play Store** upload, build an App Bundle instead:
```bash
flutter build appbundle --release
```
The bundle will be at `build/app/outputs/bundle/release/app-release.aab`.

> Before publishing to the Play Store, you must sign the app with your own keystore. See the official guide: https://docs.flutter.dev/deployment/android#signing-the-app

---

## 📦 Creating a Zip for Sharing

Before zipping, clean the build cache so the zip stays small:

```bash
flutter clean
```

Then:

**On Linux / macOS:**
```bash
cd ..
zip -r neon_drift_mini.zip neon_drift_mini -x "neon_drift_mini/.dart_tool/*" "neon_drift_mini/build/*"
```

**On Windows (PowerShell):**
```powershell
Compress-Archive -Path .\neon_drift_mini -DestinationPath .\neon_drift_mini.zip
```

---

## 🎨 Customizing the Game

### Change the game name (visible on the home screen / launcher)

1. **Launcher name (Android):** Edit `android/app/src/main/AndroidManifest.xml`:
   ```xml
   android:label="Your New Name"
   ```
2. **Window title (in code):** Edit `lib/main.dart`:
   ```dart
   title: 'Your New Name',
   ```
3. **In-game logo (home screen):** Edit `lib/screens/home_screen.dart` — search for the strings `'NEON'`, `'DRIFT'`, `'MINI'` and replace.

### Change the package name (application ID)

The current package is `com.tharindux.neondriftmini`. To change it:

1. **Easy way** — use the [`change_app_package_name`](https://pub.dev/packages/change_app_package_name) tool:
   ```bash
   flutter pub run change_app_package_name:main com.yourcompany.yourgame
   ```
2. **Manual way** — edit `android/app/build.gradle` (or `build.gradle.kts`), change `applicationId`, and rename the folder structure under `android/app/src/main/kotlin/`.

> ⚠️ Once you publish to the Play Store, the package name is **permanent**. Choose it carefully before launch.

### Change the app icon

1. Add `flutter_launcher_icons` to `pubspec.yaml`:
   ```yaml
   dev_dependencies:
     flutter_launcher_icons: ^0.13.1

   flutter_launcher_icons:
     android: true
     ios: false
     image_path: "assets/icon.png"
     min_sdk_android: 21
   ```
2. Put a **1024×1024 PNG** at `assets/icon.png`.
3. Run:
   ```bash
   flutter pub get
   dart run flutter_launcher_icons
   ```

### Tweak game balance

All gameplay constants live in `lib/game/game_controller.dart`:

| Constant | Meaning |
| --- | --- |
| `baseSpeed` | Starting scroll speed (px/s) |
| `maxSpeed` | Hard cap for difficulty |
| `acceleration` | How fast speed ramps up over time |
| `laneEaseRate` | Smoothness of lane changes (higher = snappier) |

### Tweak the color palette

All neon colors live in `lib/theme/app_theme.dart`. Want a green/orange theme? Just swap the constants — they propagate everywhere automatically.

---

## 🔄 Publishing Updates

Every Play Store update needs a bumped version. Edit the line in `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

The format is `versionName+versionCode`:
- **versionName** (`1.0.0`) — what users see on the Play Store
- **versionCode** (`+1`) — internal integer, must increase every upload

Example progression:
```
1.0.0+1   → Initial release
1.0.1+2   → Bug fix
1.1.0+3   → New feature
2.0.0+4   → Major redesign
```

Then build the new App Bundle and upload it to the Play Console:
```bash
flutter build appbundle --release
```

---

## 🎮 How to Play

- **Tap left / right buttons** at the bottom to switch lanes
- **Or swipe** left/right anywhere on the screen
- Dodge red hazards and enemy cars
- Collect yellow coins (+50 score) and survive (+1 score per frame)
- Every 500 score = level up = faster, more obstacles

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────┐
│              UI Screens                     │
│  home_screen → game_screen → game_over      │
└──────────────────┬──────────────────────────┘
                   │
       ┌───────────▼────────────┐
       │   GameController       │  ← ChangeNotifier
       │ (state + game loop +   │     drives every frame
       │  spawn + collision)    │
       └───────────┬────────────┘
                   │
       ┌───────────▼────────────┐
       │   GamePainter          │  ← reads controller
       │  (CustomPainter)       │     each frame
       └────────────────────────┘

       ┌─────────────────────────┐
       │  StorageService         │  ← shared_preferences
       │ (high score, stats)     │
       └─────────────────────────┘
```

Key design choices:
- **Frame-rate independent**: physics use real `dt`, not fixed step counts
- **No game engine**: just Flutter's `Ticker` + `CustomPainter`
- **No assets**: every shape is drawn in code, so the APK is tiny
- **ChangeNotifier**: simple, native, no extra state-management dependency

---

## 📜 License

All rights reserved to TharinduX.exe

---


