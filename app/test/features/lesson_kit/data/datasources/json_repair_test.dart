import 'dart:convert';

import 'package:chalk_lens/features/lesson_kit/data/datasources/json_repair.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JsonRepair.extractObjects', () {
    test('returns later JSON object when thinking echoes a schema first', () {
      const raw = '''
<think>
JSON schema:
{
  "lesson_title": string,
  "oral_quiz": [{"question": string}]
}
</think>
```json
{"lesson_title":"Plants","simple_explanation":"Plants need water."}
```
''';

      final objects = JsonRepair.extractObjects(raw);

      expect(objects, hasLength(greaterThanOrEqualTo(2)));
      expect(
        objects.last,
        '{"lesson_title":"Plants","simple_explanation":"Plants need water."}',
      );
    });

    test('recovers final JSON after an unbalanced prompt echo', () {
      const raw = '''
The model started echoing the prompt:
{
  "lesson_title": string,
  "grade": string

{"lesson_title":"Water Cycle","simple_explanation":"Water moves."}
''';

      final objects = JsonRepair.extractObjects(raw);

      expect(
        objects,
        contains(
          '{"lesson_title":"Water Cycle","simple_explanation":"Water moves."}',
        ),
      );
    });
  });

  group('JsonRepair.repair', () {
    test('is idempotent on already-valid JSON', () {
      const valid = '{"a":1,"b":["x","y"],"c":{"d":2}}';

      expect(JsonRepair.repair(valid), valid);
      expect(jsonDecode(JsonRepair.repair(valid)), jsonDecode(valid));
    });

    test('strips leftover Gemma escape tokens', () {
      const raw = '{"lesson_title":<|"|>Plants<|"|>}';

      final repaired = JsonRepair.repair(raw);

      expect(jsonDecode(repaired), {'lesson_title': 'Plants'});
    });

    test('drops trailing commas before } and ]', () {
      const raw = '{"a":[1,2,3,],"b":2,}';

      final repaired = JsonRepair.repair(raw);

      expect(jsonDecode(repaired), {
        'a': [1, 2, 3],
        'b': 2,
      });
    });

    test('strips // line and /* block */ comments outside strings', () {
      const raw = '''
{
  // top-level comment
  "a": 1, /* inline block */
  "b": "value with // not a comment"
}
''';

      final repaired = JsonRepair.repair(raw);

      expect(jsonDecode(repaired), {
        'a': 1,
        'b': 'value with // not a comment',
      });
    });

    test('escapes raw newlines and tabs inside string values', () {
      final raw = '{"a":"first line\nsecond\tline"}';

      final repaired = JsonRepair.repair(raw);

      expect(jsonDecode(repaired), {'a': 'first line\nsecond\tline'});
    });

    test('closes a string truncated mid-value', () {
      const raw = '{"lesson_title":"Plants","simple_explanation":"Plants need';

      final repaired = JsonRepair.repair(raw);

      expect(jsonDecode(repaired), {
        'lesson_title': 'Plants',
        'simple_explanation': 'Plants need',
      });
    });

    test('closes nested array and object truncated mid-stream', () {
      const raw =
          '{"lesson_title":"Photosynthesis","oral_quiz":[{"question":"What do plants need';

      final repaired = JsonRepair.repair(raw);

      expect(jsonDecode(repaired), {
        'lesson_title': 'Photosynthesis',
        'oral_quiz': [
          {'question': 'What do plants need'},
        ],
      });
    });

    test('drops a dangling key with no value', () {
      const raw = '{"a":1,"b":"ok","c"';

      final repaired = JsonRepair.repair(raw);

      expect(jsonDecode(repaired), {'a': 1, 'b': 'ok'});
    });

    test('pads a dangling colon with null', () {
      const raw = '{"a":1,"b":';

      final repaired = JsonRepair.repair(raw);

      expect(jsonDecode(repaired), {'a': 1, 'b': null});
    });

    test('drops a trailing partial backslash escape inside a string', () {
      // Truncation happened right after a `\` — there is no way to know
      // what character was about to be escaped, so dropping it is safest.
      final raw = '{"a":"hello\\';

      final repaired = JsonRepair.repair(raw);

      expect(jsonDecode(repaired), {'a': 'hello'});
    });

    test('repairs combined comment + trailing comma + truncation', () {
      const raw = '''
```json
{
  // header
  "title": "Water Cycle",
  "items": ["evaporation", "condensation",
''';

      final repaired = JsonRepair.repair(raw);

      expect(jsonDecode(repaired), {
        'title': 'Water Cycle',
        'items': ['evaporation', 'condensation'],
      });
    });
  });
}
