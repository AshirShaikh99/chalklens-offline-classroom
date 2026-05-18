# ChalkLens

Offline lesson kits for teachers, powered by local Gemma 4 inference.

ChalkLens is a Flutter app for classrooms where teachers have textbook pages, PDFs, or scanned material, but cannot count on reliable internet during planning or teaching. It turns source lesson content into practical classroom material that a teacher can use from a laptop: teaching flow, blackboard notes, oral checks, homework, activities, and student follow-up help.

The Kaggle demo focuses on a laptop-first macOS workflow because many teachers prepare and present from laptops, while phones can be too small for reading a full lesson or teaching from the screen.

## Why This Exists

Many education AI tools assume cloud access, fast internet, and comfortable devices. ChalkLens is built around a more constrained classroom reality:

> The textbook is available. The teacher is ready. The internet may not be.

The goal is not to replace teachers. ChalkLens helps with the heavy preparation work so the teacher can spend more time explaining, adapting examples, and checking student understanding.

## What It Does

- Imports textbook PDFs and image files.
- Extracts PDF text locally on macOS.
- Runs local OCR for image-based pages.
- Uses Gemma 4 through LiteRT / Google AI Edge via `flutter_gemma`.
- Generates a classroom-ready Lesson Kit:
  - simple explanation
  - step-by-step teacher moves
  - blackboard notes
  - misconceptions to check
  - oral quiz questions
  - group activity
  - homework
  - glossary
  - easier explanation
- Saves generated lessons locally.
- Provides Student Help grounded in the selected lesson.
- Includes Present mode for teaching directly from the laptop.
- Exports a plain-text lesson file for sharing or archiving.

## Demo Flow

1. Open ChalkLens on macOS.
2. Import a short textbook PDF from `test_assets/`.
3. Review the extracted lesson text.
4. Generate the Lesson Kit using local Gemma 4 inference.
5. Show the teaching sequence, board notes, oral quiz, and homework.
6. Open Present mode to demonstrate laptop-based teaching.
7. Use Student Help to answer a follow-up question from the lesson context.

## Technical Overview

- **App framework:** Flutter
- **Demo platform:** macOS desktop
- **Model runtime:** Gemma 4 E2B `.litertlm` through `flutter_gemma`
- **Inference path:** LiteRT / Google AI Edge local inference
- **PDF text extraction:** native macOS `PDFKit`
- **Image OCR:** native platform OCR bridge
- **State management:** Riverpod
- **Persistence:** local saved lessons and local model registration
- **Robustness:** JSON repair, tool-call extraction, lesson depth guard, and recovery builder for imperfect model output

The model file is not committed to this repository because it is large. The app supports importing or downloading the `.litertlm` file during Model Setup.

## Run Locally

The Flutter app lives in [`app/`](app/).

```bash
cd app
flutter pub get
flutter analyze
flutter test
flutter run -d macos
```

For model setup details, see [`app/README.md`](app/README.md).

## Test Assets

The repository includes small sample classroom files for demos and testing:

- [`test_assets/class1_english_short_a_test_page.pdf`](test_assets/class1_english_short_a_test_page.pdf)
- [`test_assets/class1_english_short_a_test_page.txt`](test_assets/class1_english_short_a_test_page.txt)
- [`test_assets/class7_matter_test_page.txt`](test_assets/class7_matter_test_page.txt)

## Repository Layout

```text
app/          Flutter application
docs/         product, architecture, model, and submission notes
test_assets/  small demo PDFs and source text
```

## Hackathon Positioning

ChalkLens is built for the Gemma 4 Good Hackathon as an education and digital equity project:

- **Main Track:** a working teacher-facing classroom assistant
- **Impact Track:** Future of Education
- **Special Technology Track:** LiteRT / Google AI Edge local Gemma 4 inference

The core idea is simple: bring useful AI closer to classrooms where cloud AI is hardest to depend on.
