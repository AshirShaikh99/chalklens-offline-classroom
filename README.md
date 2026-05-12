# ChalkLens Offline Classroom

Textbook page to blackboard kit, offline.

ChalkLens is a Flutter app for low-resource classrooms where a teacher may have one phone, one textbook, and unreliable internet. It uses on-device Gemma 4 E2B LiteRT-LM to turn a textbook page into teacher-ready classroom material without sending the page to a cloud service.

## What It Does

- Captures or imports a textbook page image.
- Runs Gemma locally through `flutter_gemma` and LiteRT-LM.
- Generates a structured classroom kit:
  - simple explanation
  - blackboard notes
  - oral quiz
  - no-materials classroom activity
  - homework
  - key-terms glossary
  - easier version for struggling students
- Saves lessons locally on the device.
- Lets students ask follow-up questions from the active lesson context.

## Why It Is Different

Most AI teaching tools assume reliable internet, laptops, or student-owned devices. ChalkLens is built around a narrower classroom reality:

> one teacher phone, one textbook page, one blackboard, no reliable internet.

The product is not trying to be a full LMS. The core proof is that a teacher can scan a page and get a blackboard-ready kit while offline.

## App

The Flutter app lives in [`app/`](app/).

```bash
cd app
flutter pub get
flutter analyze
flutter run
```

The Gemma model file is not bundled in this repository. See [`app/README.md`](app/README.md) for model import/download instructions.

### Model URL (build-time)

The app downloads the model from a URL supplied at build time. Set it in
a local `.env` file (gitignored) and use the helper scripts:

```bash
cp app/.env.example app/.env
# edit app/.env and set GEMMA_MODEL_URL=...

./app/scripts/run.sh                  # development run
./app/scripts/build-release-apk.sh    # release APK with the URL baked in
```

Without a URL configured, the Model Setup screen falls back to a manual
input field so the app still works for source-builders without a `.env`.

## Demo Story

1. Turn on airplane mode.
2. Open ChalkLens.
3. Capture a Class 5 science textbook page.
4. Choose class duration and student level.
5. Generate the classroom kit locally.
6. Show the teacher using board notes, oral questions, and the no-materials activity.

## Repository Layout

```text
app/      Flutter application
docs/     product, architecture, model, and submission notes
demo/     demo assets and screenshots
eval/     benchmark samples and results
```

## Hackathon Focus

Primary angle:

> Offline Gemma classroom intelligence for teachers in underserved schools.

Technical proof points:

- Gemma 4 image/text input
- on-device LiteRT-LM inference
- structured JSON generation
- offline teaching pack retrieval before generation
- local model install/import flow
- local lesson persistence
- English-first, globally understandable demo
