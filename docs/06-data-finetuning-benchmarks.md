# Data, Fine-Tuning, and Benchmarks

## Purpose

Fine-tuning is not mandatory for the app to work, but it gives the project stronger technical depth and a better chance at the Unsloth prize.

## Fine-Tuning Target

Train a Gemma 4 variant to produce plain-English classroom teaching kits from textbook-style input.

Input example:

```json
{
  "grade": "Class 5",
  "subject": "Science",
  "textbook_text": "Evaporation is the process by which liquid water changes into water vapor.",
  "target_language": "English",
  "class_context": "Large classroom, no lab equipment"
}
```

Output example:

```json
{
  "simple_explanation": "Evaporation means water slowly becomes vapor because of heat...",
  "blackboard_notes": ["Heat changes water into vapor", "Wet clothes dry because of evaporation"],
  "local_example": "When clothes dry on the roof in sunlight...",
  "quiz": ["What happens to wet clothes in sunlight?", "What is evaporation?"],
  "activity": "Put a small amount of water in two plates..."
}
```

## Dataset Sources

Use only legal, public, or self-created data.

Recommended dataset types:

- Public domain textbook excerpts.
- Open educational resources.
- Self-created textbook-style mini passages.
- Teacher-written examples.
- Synthetic examples generated and manually reviewed.
- Public curriculum outlines.
- Key-term glossaries created by us.

Avoid:

- Copyrighted textbook pages copied directly into training data.
- Private student data.
- Teacher or student personally identifying data.

## Dataset Size For Hackathon

Minimum:

- 150 high-quality examples

Good:

- 500 examples

Strong:

- 1,000+ examples with train/dev/test split

For a hackathon, quality beats size.

## Output Style

Recommended MVP focus:

1. English
2. Simple classroom wording
3. Practical low-resource examples

Stretch:

- Shorter explanations for struggling students
- More advanced explanations for extension work
- Printable worksheet formatting

Do not support many languages badly. Support one globally understandable language convincingly.

## Benchmark Tasks

### Task 1: LessonKit JSON Validity

Metric:

- Percentage of outputs that parse as valid JSON and match required schema.

Target:

- 95%+

### Task 2: Grade-Level Clarity

Method:

- Human rubric or LLM-as-judge with fixed criteria.

Criteria:

- Simple vocabulary
- Age-appropriate length
- Clear examples
- No unnecessary jargon

Target:

- Fine-tuned model beats base model by 20% on rubric score.

### Task 3: Classroom Usefulness

Method:

- Compare base Gemma 4 vs fine-tuned Gemma 4 on classroom explanation quality.

Target:

- Fine-tuned output should be clearer, shorter, and more teacher-ready.

### Task 4: Hallucination Check

Method:

- Use known textbook snippets with expected key facts.
- Check whether output adds false claims.

Target:

- Less than 5% major factual errors on test set.

### Task 5: Offline Performance

Metric:

- Time to first token
- Total generation time
- Memory usage
- Device type

Target:

- Acceptable demo generation under 60-120 seconds on available hardware.

## Model Card Requirements

If publishing fine-tuned weights, include:

- Base model
- Training method
- Dataset description
- License notes
- Intended use
- Limitations
- Evaluation results
- Safety considerations

## Benchmark Table Template

| Model | JSON Validity | Clarity Score | Classroom Usefulness Score | Hallucination Rate | Avg Generation Time |
| --- | ---: | ---: | ---: | ---: | ---: |
| Base Gemma 4 | To measure | To measure | To measure | To measure | To measure |
| ChalkLens Fine-Tuned | To measure | To measure | To measure | To measure | To measure |
