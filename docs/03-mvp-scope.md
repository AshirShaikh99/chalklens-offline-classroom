# MVP Scope

## Guiding Rule

Build one workflow extremely well:

> Textbook page + teacher context -> classroom-ready teaching kit

Do not build a full LMS.

## Must-Have Features

### 1. Textbook Scan

Teacher can capture or upload a textbook page image.

Gemma 4 should extract:

- Topic
- Key terms
- Main concept
- Grade difficulty
- Likely misconceptions

### 2. Teacher Context

Teacher can provide:

- Grade
- Subject
- Output style
- Class duration
- Student level

### 3. Lesson Kit Generation

The app generates a structured `LessonKit`:

- Title
- Learning objectives
- 5-minute warm-up
- Simple explanation
- Blackboard notes
- Local example
- 5 oral quiz questions
- Group activity
- Homework
- Key-terms glossary
- Easier version
- Harder version

### 4. Plain-English Teaching Mode

At minimum support:

- English

Stretch output styles:

- Standard classroom explanation
- Easier explanation for struggling students
- More advanced explanation for extension work

The MVP should show one globally understandable language deeply rather than many languages shallowly.

### 5. Offline Save

Teacher can save generated lessons on the device.

### 6. Student Help Mode

Simple mode where a student can ask:

- "Explain again."
- "Give me an example."
- "Ask me a question."

### 7. Demo Dataset

Include 10-20 sample textbook pages or synthetic lesson examples in the repo for repeatable demo and tests.

## Should-Have Features

- Voice input for teacher prompt.
- Text-to-speech for generated explanations.
- Export lesson as image/PDF/text.
- Copy SMS/WhatsApp style homework message.
- Simple progress history.

## Could-Have Features

- Class profile management.
- Parent revision note.
- Multi-student quiz tracking.
- Admin dashboard.
- Cloud sync.
- Printable worksheets.

## Not In MVP

- Full school management system.
- Attendance.
- Fees.
- Marksheets.
- Parent chat.
- Live video class.
- Marketplace.
- Complex student accounts.

## MVP Acceptance Test

Given a textbook page about a Class 5 science topic:

1. The teacher can scan/upload it.
2. The app generates a lesson kit in under two minutes.
3. The lesson kit is structured and editable.
4. The app can explain the topic in simple classroom English.
5. The output works without a cloud dependency in the demo path.
6. The repo includes enough code and instructions for judges to reproduce the flow.
