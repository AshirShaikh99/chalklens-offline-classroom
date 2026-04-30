# ChalkLens — Flutter App

Offline classroom co-pilot powered by Gemma 4 on-device. This testing build generates structured LessonKit output using Gemma 4 E2B LiteRT-LM.

## Prerequisites

- macOS with Xcode 26+ and CocoaPods installed
- Flutter 3.41+ (`flutter --version`)
- Physical iPhone (iPhone 13 Pro / 14 Pro / 15 Pro recommended — 6GB+ RAM)
- Apple ID signed in to Xcode (free Personal Team is fine for testing)
- HuggingFace account (free)

## One-time iOS setup in Xcode

The Flutter project is already configured for Gemma's iOS runtime. Only signing may need a one-time click in Xcode:

1. Open the workspace:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Signing**: Select the `Runner` target → `Signing & Capabilities` tab → set `Team` to your Personal Team. Bundle ID is `com.chalklens.app`.

The debug build is set up for Personal Team signing. If you later use a paid Apple Developer account, large-model memory entitlements can be re-enabled for more headroom.

## Get the Gemma 4 E2B model

The model file is **not bundled in this repo** (~2.4GB on disk).

1. Visit https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm
2. Sign in to HuggingFace and accept the Gemma license terms.
3. Download the `.litertlm` file. Filename varies — usually `gemma-4-E2B-it.litertlm` or similar.
4. Rename it to exactly **`gemma-4-E2B-it.litertlm`** to match the app's expected model filename.

## Prepare the offline model

The APK/IPA does **not** bundle the 2.4GB model. On first launch after a fresh install, the app opens **Model setup**:

1. Tap **Download offline model** and paste a direct `.litertlm` download URL, or use **Import** for a pre-provisioned file.
2. Wait for the download to finish.
3. The app verifies exact file size, SHA-256 checksum, and runtime registration.
4. Tap **Continue** once the status says **Offline model ready**.

If the model was provisioned separately, use the compact **Import** fallback on the same screen and select `gemma-4-E2B-it.litertlm` from Files/storage.

Deleting the app deletes the installed model copy because iOS and Android remove the app documents directory on uninstall. Keep the original `.litertlm` file in Files/Downloads for quick re-import after reinstall, or use **Offload App** on iOS when you want to remove the app binary but keep documents.

Expected file:

```text
Name:   gemma-4-E2B-it.litertlm
Size:   2,583,085,056 bytes
SHA256: ab7838cdfc8f77e54d8ca45eadceb20452d9f01e4bfade03e5dce27911b27e42
```

For a desktop/local debug run, you can also pass the file directly:

```bash
flutter run --dart-define=GEMMA_MODEL_PATH=/Users/ashirshaikh/Downloads/gemma-4-E2B-it.litertlm
```

Production/test builds can override the default hosted model URL:

```bash
flutter run --dart-define=GEMMA_MODEL_URL=<model-download-url>
```

File sharing is still enabled via `UIFileSharingEnabled` and `LSSupportsOpeningDocumentsInPlace` in `Info.plist`, so Finder/Files manual copy also works.

## Run on iPhone

```bash
flutter run -d <device-id>
```

Find your iPhone's device ID with `flutter devices`. Or open the workspace in Xcode and click Run.

## What to expect on first successful run

- The first screen is **Model setup** if the model is missing. Download the model once per app install, or use **Import** for a pre-provisioned file.
- Open **New lesson**.
- Capture a textbook page with the camera or import one from the gallery.
- Choose grade, subject, duration, and student level.
- Tap **Generate lesson kit**.
- The Lesson Kit screen shows structured sections: explanation, notes, quiz, activity, homework, glossary, and easier explanation.
- Save stores the kit locally on the device. Copy places a plain-text version on the clipboard.

The app sends captured page images directly to Gemma 4 vision through `flutter_gemma` 0.14.

## Troubleshooting

- **Model incomplete**: the previous copy was interrupted. Import/download the model again from Model setup.
- **Model needs replacement**: the file size is right, but checksum failed. Delete/re-import the model.
- **Model setup appears after reinstall**: this is expected after deleting the app. App documents are removed with the app, so import the saved `.litertlm` file or download it again.
- **App crashes on model load**: likely out-of-memory. A paid Apple Developer account may be needed to re-enable larger memory entitlements for production iOS testing.
- **Build fails on `pod install`**: run `cd ios && pod deintegrate && pod install` to reset.
- **Signing error**: free Personal Team needs Apple ID added in Xcode → Settings → Accounts.

## Current testing scope

- Camera/gallery capture is available for the teacher workflow.
- Captured image input flows directly into Gemma multimodal generation.
- English is exposed in the testing UI for the global demo.
- Saved lessons persist locally in the app documents directory.
- Student Help uses Gemma with the active generated lesson as context.
- iPhone Gemma 4 vision support is currently treated as experimental because upstream docs and public Gallery allowlists are not fully aligned.

## Architecture notes

- **Model runtime**: `flutter_gemma` v0.14.0, which wraps LiteRT-LM under the hood (also satisfies the LiteRT prize track).
- **Model file**: Gemma 4 E2B instruction-tuned, INT4 quantized, `.litertlm` format.
- **System prompt**: pinned in `GemmaLessonKitDatasource` with a strict JSON schema and "use only info from the passage" anti-hallucination instruction.
- **Backend abstraction**: generation goes through the clean-architecture datasource/repository/use-case path.
