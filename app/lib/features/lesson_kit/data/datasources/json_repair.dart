/// Best-effort cleanup of LLM output before JSON parsing. Gemma 4 will
/// sometimes wrap JSON in ```` ```json ``` ```` fences, prepend a sentence
/// of prose, or trail off with extra commentary. Strip those before
/// passing to `jsonDecode`.
class JsonRepair {
  const JsonRepair._();

  /// Returns a substring that is the first balanced JSON object found in
  /// [raw], or [raw] itself if no braces are detected. The result is not
  /// guaranteed to parse — callers must still try/catch.
  static String extractObject(String raw) {
    final stripped = _stripCodeFences(raw).trim();

    final start = stripped.indexOf('{');
    if (start == -1) return stripped;

    var depth = 0;
    var inString = false;
    var escape = false;

    for (var i = start; i < stripped.length; i++) {
      final ch = stripped[i];

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
          return stripped.substring(start, i + 1);
        }
      }
    }

    // Unbalanced — return the slice from the first { onward and let the
    // parser report a useful error.
    return stripped.substring(start);
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
}
