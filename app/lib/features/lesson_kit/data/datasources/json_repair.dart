/// Best-effort cleanup of LLM output before JSON parsing. Small on-device
/// models routinely emit JSON wrapped in ```` ```json ``` ```` fences,
/// preceded by a sentence of prose, with trailing commas, raw newlines
/// inside string values, JS-style comments, leftover `<|"|>` escape tokens,
/// or simply truncated mid-object when `max_tokens` is hit. Strip and
/// reconstruct as much as we can before handing off to `jsonDecode`.
class JsonRepair {
  const JsonRepair._();

  /// Defense-in-depth bound on the model output size we will scan. The
  /// inference layer's max-tokens setting is the primary guard; this is a
  /// belt-and-braces cap so a runaway generation cannot exhaust memory while
  /// JSON repair walks the string.
  static const int maxInputBytes = 256 * 1024;

  /// Gemma-family tool-call escape token. The native function-call parser
  /// understands it, but small models also leak it into free-form text
  /// output where it confuses strict JSON parsers.
  static const String _gemmaEscapeToken = '<|"|>';

  /// Returns a substring that is the first balanced JSON object found in
  /// [raw], or [raw] itself if no braces are detected. The result is not
  /// guaranteed to parse — callers must still try/catch.
  static String extractObject(String raw) {
    final stripped = _clean(raw);
    final objects = extractObjects(raw);
    if (objects.isNotEmpty) return objects.first;

    final start = stripped.indexOf('{');
    if (start == -1) return stripped;

    // Unbalanced — return the slice from the first { onward and let the
    // parser (or repair pass) take a shot.
    return stripped.substring(start);
  }

  /// Returns every balanced JSON-looking object in [raw], in encounter order.
  ///
  /// Gemma can emit a thinking trace or prompt echo before the final answer.
  /// In that case the first brace block may be an echoed schema, while the
  /// later block is the actual LessonKit JSON. Callers can try each candidate
  /// and keep the first one that matches their schema.
  static List<String> extractObjects(String raw) {
    final stripped = _clean(raw);
    final starts = _objectStarts(stripped);
    final objects = <String>[];
    final seen = <String>{};

    for (final start in starts) {
      final object = _balancedObjectFrom(stripped, start);
      if (object == null) continue;
      if (seen.add(object)) objects.add(object);
    }

    return objects;
  }

  /// Best-effort repair of a JSON object candidate. Idempotent on valid
  /// JSON. Targets the failure modes we have actually observed in on-device
  /// Gemma output:
  ///
  ///   * leftover `<|"|>` escape tokens around strings,
  ///   * `// line` and `/* block */` comments,
  ///   * trailing commas before `}` or `]`,
  ///   * raw control characters (newline, tab, ...) inside string values
  ///     that should have been escaped,
  ///   * truncation mid-string / mid-array / mid-object when the model
  ///     hits its token budget.
  ///
  /// Returns the repaired candidate. Callers must still try `jsonDecode`
  /// and treat a `FormatException` as a real parse failure.
  static String repair(String raw) {
    var value = _clean(raw);
    if (value.isEmpty) return value;
    value = _stripGemmaEscapeTokens(value);
    value = _stripLineAndBlockComments(value);
    value = _escapeRawControlCharsInStrings(value);
    value = _stripTrailingCommas(value);
    value = _completeOpenStructures(value);
    return value;
  }

  static String _stripCodeFences(String raw) {
    var s = raw.trim();
    // ``` or ```json ... ``` — strip leading fence
    final openFence = RegExp(r'^```(?:json)?\s*', caseSensitive: false);
    s = s.replaceFirst(openFence, '');
    // strip trailing ``` if present
    if (s.endsWith('```')) {
      s = s.substring(0, s.length - 3).trim();
    }
    return s;
  }

  static String _clean(String raw) {
    final input = raw.length > maxInputBytes
        ? raw.substring(0, maxInputBytes)
        : raw;
    return _stripCodeFences(input).trim();
  }

  /// Converts Gemma's `<|"|>X<|"|>` string-delimiter pairs into normal
  /// `"X"` quoted strings so a strict JSON parser will accept them. The
  /// SDK-side extractor already strips bare leftover tokens from decoded
  /// values; this pass is for the buffered free-form text path where the
  /// tokens still act as quote markers.
  static String _stripGemmaEscapeTokens(String value) {
    if (!value.contains(_gemmaEscapeToken)) return value;
    return value.replaceAll(_gemmaEscapeToken, '"');
  }

  static String _stripLineAndBlockComments(String value) {
    if (!value.contains('//') && !value.contains('/*')) return value;

    final out = StringBuffer();
    var inString = false;
    var escape = false;
    var i = 0;
    while (i < value.length) {
      final ch = value[i];

      if (!inString && i + 1 < value.length && ch == '/') {
        final next = value[i + 1];
        if (next == '/') {
          // Skip until newline (preserve the newline).
          var j = i + 2;
          while (j < value.length && value[j] != '\n') {
            j++;
          }
          i = j;
          continue;
        }
        if (next == '*') {
          var j = i + 2;
          while (j + 1 < value.length &&
              !(value[j] == '*' && value[j + 1] == '/')) {
            j++;
          }
          i = j + 2 <= value.length ? j + 2 : value.length;
          continue;
        }
      }

      out.write(ch);
      if (escape) {
        escape = false;
      } else if (ch == r'\') {
        escape = true;
      } else if (ch == '"') {
        inString = !inString;
      }
      i++;
    }
    return out.toString();
  }

  static String _stripTrailingCommas(String value) {
    if (!value.contains(',')) return value;

    final out = StringBuffer();
    var inString = false;
    var escape = false;
    for (var i = 0; i < value.length; i++) {
      final ch = value[i];

      if (!inString && ch == ',') {
        var j = i + 1;
        while (j < value.length && _isWhitespace(value.codeUnitAt(j))) {
          j++;
        }
        if (j < value.length && (value[j] == '}' || value[j] == ']')) {
          // Drop the trailing comma; do not emit it.
          continue;
        }
      }

      out.write(ch);
      if (escape) {
        escape = false;
      } else if (ch == r'\') {
        escape = true;
      } else if (ch == '"') {
        inString = !inString;
      }
    }
    return out.toString();
  }

  static String _escapeRawControlCharsInStrings(String value) {
    final out = StringBuffer();
    var inString = false;
    var escape = false;
    for (var i = 0; i < value.length; i++) {
      final code = value.codeUnitAt(i);
      final ch = value[i];

      if (escape) {
        out.write(ch);
        escape = false;
        continue;
      }
      if (ch == r'\') {
        out.write(ch);
        escape = true;
        continue;
      }
      if (ch == '"') {
        out.write(ch);
        inString = !inString;
        continue;
      }
      if (inString && code < 0x20) {
        switch (code) {
          case 0x08:
            out.write(r'\b');
            break;
          case 0x09:
            out.write(r'\t');
            break;
          case 0x0A:
            out.write(r'\n');
            break;
          case 0x0C:
            out.write(r'\f');
            break;
          case 0x0D:
            out.write(r'\r');
            break;
          default:
            out
              ..write(r'\u')
              ..write(code.toRadixString(16).padLeft(4, '0'));
        }
        continue;
      }
      out.write(ch);
    }
    return out.toString();
  }

  /// If [value] ends mid-string or with unclosed `{` / `[`, append the
  /// minimum suffix required to make it well-formed: close the string,
  /// drop dangling separators, pad missing values with `null`, and emit
  /// the matching closers in reverse-open order.
  static String _completeOpenStructures(String value) {
    final stack = <String>[]; // '}' or ']'
    var inString = false;
    var escape = false;

    for (var i = 0; i < value.length; i++) {
      final ch = value[i];
      if (escape) {
        escape = false;
        continue;
      }
      if (inString) {
        if (ch == r'\') {
          escape = true;
        } else if (ch == '"') {
          inString = false;
        }
        continue;
      }
      if (ch == '"') {
        inString = true;
      } else if (ch == '{') {
        stack.add('}');
      } else if (ch == '[') {
        stack.add(']');
      } else if (ch == '}' || ch == ']') {
        if (stack.isNotEmpty && stack.last == ch) stack.removeLast();
      }
    }

    if (!inString && stack.isEmpty) return value;

    var s = value;

    // Drop a trailing partial escape (`...\`) — we cannot guess what was
    // about to be escaped, so the cleanest recovery is to remove it.
    if (inString && escape) {
      s = s.substring(0, s.length - 1);
    }

    if (inString) {
      s = '$s"';
    }

    while (stack.isNotEmpty) {
      final closer = stack.removeLast();
      s = _trimTrailingWhitespace(s);
      while (s.endsWith(',')) {
        s = _trimTrailingWhitespace(s.substring(0, s.length - 1));
      }

      if (s.endsWith(':')) {
        // `"key":` with no value — pad with null so the object is valid.
        s = '$s null';
      } else if (closer == '}' &&
          !s.endsWith('}') &&
          !s.endsWith(']') &&
          _endsWithDanglingKey(s)) {
        // `{"key"` or `..., "key"` — drop the dangling key entirely. We
        // only check this when s does not already end in a closer, so
        // that a `,` inside a freshly-closed inner array/object is not
        // mistaken for a top-level dangling key.
        s = _dropDanglingKey(s);
        s = _trimTrailingWhitespace(s);
        while (s.endsWith(',')) {
          s = _trimTrailingWhitespace(s.substring(0, s.length - 1));
        }
      }

      s = '$s$closer';
    }

    return s;
  }

  static String _trimTrailingWhitespace(String s) {
    var end = s.length;
    while (end > 0 && _isWhitespace(s.codeUnitAt(end - 1))) {
      end--;
    }
    return s.substring(0, end);
  }

  /// True when [s] ends with a JSON string token that is not followed by
  /// a `:` — i.e. an object key whose value never arrived.
  static bool _endsWithDanglingKey(String s) {
    final cutoff = _lastObjectSeparator(s);
    if (cutoff < 0) return false;
    final segment = s.substring(cutoff + 1).trimLeft();
    if (segment.isEmpty || !segment.startsWith('"')) return false;

    var i = 1;
    var escape = false;
    while (i < segment.length) {
      final ch = segment[i];
      if (escape) {
        escape = false;
        i++;
        continue;
      }
      if (ch == r'\') {
        escape = true;
        i++;
        continue;
      }
      if (ch == '"') break;
      i++;
    }
    if (i >= segment.length) return false;

    final tail = segment.substring(i + 1).trimLeft();
    return !tail.startsWith(':');
  }

  static String _dropDanglingKey(String s) {
    final cutoff = _lastObjectSeparator(s);
    if (cutoff < 0) return s;
    // If the separator is `,`, drop it too. If it is `{`, keep it so the
    // empty object is still well-formed.
    if (s[cutoff] == ',') return s.substring(0, cutoff);
    return s.substring(0, cutoff + 1);
  }

  /// Returns the index of the last `{` or `,` in [s] that lives outside a
  /// string literal, scanning from the end.
  static int _lastObjectSeparator(String s) {
    var inString = false;
    var quoteIndex = -1;

    // Forward pass to track quoted regions, then return the highest
    // structural separator that lies outside a string.
    final separators = <int>[];
    var escape = false;
    for (var i = 0; i < s.length; i++) {
      final ch = s[i];
      if (escape) {
        escape = false;
        continue;
      }
      if (inString) {
        if (ch == r'\') {
          escape = true;
        } else if (ch == '"') {
          inString = false;
        }
        continue;
      }
      if (ch == '"') {
        inString = true;
        quoteIndex = i;
      } else if (ch == '{' || ch == ',') {
        separators.add(i);
      }
    }

    // If we ended inside a string, the dangling string starts at quoteIndex.
    // The most recent separator before the dangling string is the cutoff.
    if (inString && quoteIndex >= 0) {
      for (var i = separators.length - 1; i >= 0; i--) {
        if (separators[i] < quoteIndex) return separators[i];
      }
      return -1;
    }

    return separators.isEmpty ? -1 : separators.last;
  }

  static List<int> _objectStarts(String value) {
    final starts = <int>[];
    var inString = false;
    var escape = false;

    for (var i = 0; i < value.length; i++) {
      final ch = value[i];

      if (escape) {
        escape = false;
        continue;
      }
      if (ch == r'\') {
        escape = true;
        continue;
      }
      if (ch == '"') {
        inString = !inString;
        continue;
      }
      if (inString) continue;
      if (ch == '{') starts.add(i);
    }

    return starts;
  }

  static String? _balancedObjectFrom(String value, int start) {
    var depth = 0;
    var inString = false;
    var escape = false;

    for (var i = start; i < value.length; i++) {
      final ch = value[i];

      if (escape) {
        escape = false;
        continue;
      }
      if (ch == r'\') {
        escape = true;
        continue;
      }
      if (ch == '"') {
        inString = !inString;
        continue;
      }
      if (inString) continue;

      if (ch == '{') depth++;
      if (ch == '}') {
        depth--;
        if (depth == 0) {
          return value.substring(start, i + 1);
        }
      }
    }

    return null;
  }

  static bool _isWhitespace(int code) {
    return code == 0x20 ||
        code == 0x09 ||
        code == 0x0A ||
        code == 0x0D ||
        code == 0x0B ||
        code == 0x0C;
  }
}
