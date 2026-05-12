# Gemma 4 Model Strategy

## Goal

Use Gemma 4 in a way that is central to the product, not just a generic chatbot wrapper.

## Gemma 4 Capabilities To Showcase

### 1. Multimodal Understanding

Input:

- Photo of textbook page
- Optional voice prompt
- Teacher context

Output:

- Extracted topic
- Key concepts
- Misconceptions
- Lesson kit

### 2. Native Function Calling

Use structured tool calls for:

- Generating lesson kit
- Creating quiz
- Adapting explanation style
- Saving lesson
- Exporting homework
- Switching difficulty

### 3. Local Inference

This is the core hackathon fit.

We should demonstrate:

- App still works when internet is off.
- Teacher can generate lesson materials locally.
- Private classroom data does not need to leave the device.

### 4. Agentic Retrieval

Gemma should retrieve from a local curriculum and pedagogy pack before answering.

Current implementation starts with a compact local teaching pack that is
selected from grade, subject, student level, and any pasted passage text. It
adds offline guidance for source concepts, likely misconceptions, low-resource
activities, teacher moves, and quick checks before Gemma produces the final
LessonKit JSON.

Example retrieval documents:

- "Class 5 Science: Water Cycle"
- "Simple science glossary"
- "Low-resource classroom activity templates"
- "Pedagogy rules: ask before answer, use practical examples"

### 5. Post-Training / Fine-Tuning

Use Unsloth if time allows.

Fine-tuning target:

- Convert formal textbook content into plain classroom explanations.
- Generate structured LessonKit outputs.
- Produce practical classroom examples.

## Model Routing

Use smaller local model for routine generation:

- Gemma 4 E2B/E4B local mode

Use larger model only for development or optional online mode:

- Gemma 4 26B/31B for dataset generation, teacher-quality review, or fallback.

Routing policy:

```text
If offline:
  Use local Gemma 4 E2B/E4B.
If online and teacher requests higher quality:
  Optionally use larger Gemma 4 model.
If device is slow:
  Use cached lesson templates and shorter generation.
```

## Prompting Pattern

Prompts should be strict and structured.

Example system instruction:

```text
You are ChalkLens, an offline classroom co-pilot for low-resource teachers.
Create practical teaching material that a teacher can use on a blackboard.
Use simple English. Use practical examples. Do not invent textbook facts.
Return valid JSON matching the LessonKit schema.
If information is missing, ask one short teacher question.
```

## Quality Controls

- JSON schema validation.
- Confidence score.
- Teacher approval before using.
- "Regenerate simpler" button.
- "Show source concepts" section.
- Avoid medical/legal/sensitive claims.
- No direct answer-only student cheating mode. Student mode should explain and ask follow-up questions.

## Model Evaluation

Evaluate outputs on:

- Structure validity
- Explanation clarity
- Grade appropriateness
- Hallucination rate
- Teacher usefulness
- Time to generate
- Offline performance
