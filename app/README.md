# ChalkLens Flutter App

This is the Flutter implementation of ChalkLens, an offline-first classroom assistant powered by local Gemma 4 inference.

The current hackathon demo is optimized for macOS: teachers can import a PDF or image, extract the lesson text locally, generate a structured Lesson Kit with Gemma 4, save the lesson, present it from the laptop, and ask follow-up student questions from the active lesson context.

## Prerequisites

- macOS with Xcode and CocoaPods installed
- Flutter 3.41+ (`flutter --version`)
- A Gemma 4 E2B `.litertlm` model file
- Enough local disk space for the model file

Mobile targets still exist in the project, but the most polished demo path is macOS.

## Get the Gemma 4 E2B Model

The model file is not bundled in this repository because it is large.

1. Download the Gemma 4 E2B LiteRT-LM `.litertlm` file after accepting the model terms from the official provider.
2. Rename it to:

   ```text
   gemma-4-E2B-it.litertlm
   ```

3. Keep a local copy so it can be re-imported after app reinstalls.

Expected file metadata used by the app:

```text
Name:   gemma-4-E2B-it.litertlm
Size:   2,583,085,056 bytes
SHA256: ab7838cdfc8f77e54d8ca45eadceb20452d9f01e4bfade03e5dce27911b27e42
```

## Run

```bash
flutter pub get
flutter run -d macos
```

For a local debug run, you can also pass the model path directly:

```bash
flutter run -d macos --dart-define=GEMMA_MODEL_PATH=/path/to/gemma-4-E2B-it.litertlm
```

Production or test builds can provide a model download URL:

```bash
flutter run -d macos --dart-define=GEMMA_MODEL_URL=<model-download-url>
```

If no URL is configured, the Model Setup screen still supports manual import.

## Demo Workflow

1. Launch the app on macOS.
2. Complete Model Setup by importing or downloading the `.litertlm` file.
3. Open New Lesson.
4. Import a PDF or image.
5. Review the extracted source text.
6. Generate the Lesson Kit.
7. Save the lesson.
8. Use Present mode for classroom display.
9. Open Student Help and ask a follow-up question from the generated lesson.

## Input Handling

- PDF text extraction on macOS uses native `PDFKit`.
- Image text extraction uses the local platform text-recognition bridge.
- Pasted text is supported and is the most stable path for repeatable demos.
- The lesson generator prefers clean source text for stable local model output.

## Model and Inference

- Runtime package: `flutter_gemma`
- Model format: Gemma 4 E2B instruction-tuned `.litertlm`
- Local inference path: LiteRT / Google AI Edge
- Generation layer: `GemmaLessonKitDatasource`
- Student Q&A layer: `GemmaStudentHelpService`

The app serializes Gemma model access so lesson generation and student help do not compete for the same native runtime session.

## Reliability Features

Small local models can produce useful text with imperfect structure. ChalkLens includes defensive handling so the teacher experience does not fail immediately:

- JSON repair
- Gemma tool-call JSON extraction
- lesson JSON normalization
- lesson depth guard
- recovery builder for malformed model output
- quieter demo logs for noisy token streams

## Current Scope

Working:

- macOS PDF import
- image import and local OCR
- local model setup/import
- local Gemma lesson generation
- saved lessons
- Present mode
- Student Help grounded in lesson context
- plain-text export

Intentionally reduced for the hackathon demo:

- direct printing is removed for now
- desktop microphone input is hidden
- desktop reasoning trace controls are hidden to keep the demo focused

## Verification

Use these checks before pushing code:

```bash
flutter analyze
flutter test
```

The README intentionally avoids asking for a release build because the macOS demo can be run directly during development.
