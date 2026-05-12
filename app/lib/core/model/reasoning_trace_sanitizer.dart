class ReasoningTraceFilter {
  ReasoningTraceFilter({
    Iterable<String> promptEchoes = const [],
    this.maxLength = 1800,
    this.rawBufferLimit = 32 * 1024,
  }) : _promptEchoes = _preparePromptEchoes(promptEchoes);

  final List<_PromptEcho> _promptEchoes;
  final int maxLength;

  /// Cap on the rolling unprocessed-input buffer. Without this, long
  /// generations cause `_raw` to grow without bound — visible as climbing
  /// memory across a multi-minute session.
  final int rawBufferLimit;

  String _raw = '';
  String _visible = '';

  String get visibleText => _visible;

  String add(String chunk) {
    if (chunk.isEmpty) return '';

    _raw = '$_raw$chunk';
    if (_raw.length > rawBufferLimit) {
      _raw = _raw.substring(_raw.length - rawBufferLimit);
    }
    final next = _cleanWithPreparedPromptEchoes(
      _raw,
      _promptEchoes,
      maxLength: maxLength,
    );

    if (next.length <= _visible.length) {
      _visible = next;
      return '';
    }

    final delta = next.substring(_visible.length);
    _visible = next;
    return delta;
  }

  static String clean(
    String input, {
    Iterable<String> promptEchoes = const [],
    int? maxLength,
  }) {
    return _cleanWithPreparedPromptEchoes(
      input,
      _preparePromptEchoes(promptEchoes),
      maxLength: maxLength,
    );
  }
}

List<_PromptEcho> _preparePromptEchoes(Iterable<String> promptEchoes) {
  final echoes =
      promptEchoes
          .map((text) => text.trim())
          .where((text) => text.isNotEmpty)
          .map(_PromptEcho.new)
          .where((echo) => echo.normalized.isNotEmpty)
          .toList()
        ..sort((a, b) => b.normalized.length.compareTo(a.normalized.length));
  return echoes;
}

String _cleanWithPreparedPromptEchoes(
  String input,
  List<_PromptEcho> promptEchoes, {
  int? maxLength,
}) {
  var value = _stripThinkingMarkers(input).trimLeft();

  for (var i = 0; i < 4; i++) {
    final before = value;
    value = _stripPromptEcho(value, promptEchoes).trimLeft();
    value = _stripLeadingTurnMarkers(value).trimLeft();
    if (value == before) break;
  }

  value = _stripThinkingMarkers(value).trimLeft();
  if (_looksLikeUnresolvedPromptEcho(value)) return '';

  if (maxLength != null && value.length > maxLength) {
    value = '...${value.substring(value.length - maxLength).trimLeft()}';
  }
  return value;
}

String _stripPromptEcho(String value, List<_PromptEcho> promptEchoes) {
  if (value.trim().isEmpty || promptEchoes.isEmpty) return value;

  final normalizedValue = _normalizeWithOffsets(value);
  if (normalizedValue.text.isEmpty) return '';

  for (final prompt in promptEchoes) {
    if (prompt.normalized.startsWith(normalizedValue.text)) {
      return '';
    }

    if (normalizedValue.text.startsWith(prompt.normalized)) {
      return _dropNormalizedPrefix(value, normalizedValue, prompt.normalized);
    }
  }

  return value;
}

String _dropNormalizedPrefix(
  String value,
  _NormalizedText normalizedValue,
  String normalizedPrefix,
) {
  if (normalizedPrefix.isEmpty) return value;
  final lastOffset = normalizedValue.offsets[normalizedPrefix.length - 1];
  if (lastOffset + 1 >= value.length) return '';
  return value.substring(lastOffset + 1);
}

String _stripThinkingMarkers(String value) {
  return value
      .replaceAll('<|channel>thought\n', '')
      .replaceAll('<channel|>', '')
      .replaceAll('<think>', '')
      .replaceAll('</think>', '');
}

String _stripLeadingTurnMarkers(String value) {
  return value.replaceFirst(
    RegExp(
      r'^\s*(?:<start_of_turn>\s*(?:user|model)\s*|<end_of_turn>\s*)+',
      caseSensitive: false,
    ),
    '',
  );
}

bool _looksLikeUnresolvedPromptEcho(String value) {
  final normalized = _normalizeWithOffsets(value).text;
  if (normalized.isEmpty) return false;

  const promptPrefixes = [
    '[system:',
    'you are chalklens',
    'you are chalklens student help',
    'given a textbook passage',
    'strict json matching',
    'output only the json object',
    'target language for all textual fields',
    'required teaching strategy fields:',
    'json schema:',
    'offline teaching pack',
    'student question:',
    'active lesson:',
    'generate the classroom kit',
    'here is a page from a',
    'read the page carefully',
    'passage:',
  ];

  return promptPrefixes.any(normalized.startsWith);
}

_NormalizedText _normalizeWithOffsets(String value) {
  final buffer = StringBuffer();
  final offsets = <int>[];
  var pendingSpace = false;

  for (var i = 0; i < value.length; i++) {
    final codeUnit = value.codeUnitAt(i);
    final isWhitespace =
        codeUnit == 0x20 ||
        codeUnit == 0x09 ||
        codeUnit == 0x0a ||
        codeUnit == 0x0d ||
        codeUnit == 0x0c;

    if (isWhitespace) {
      if (buffer.isNotEmpty) pendingSpace = true;
      continue;
    }

    if (pendingSpace) {
      buffer.write(' ');
      offsets.add(i);
      pendingSpace = false;
    }

    buffer.write(value[i].toLowerCase());
    offsets.add(i);
  }

  return _NormalizedText(buffer.toString(), offsets);
}

class _PromptEcho {
  _PromptEcho(String text) : normalized = _normalizeWithOffsets(text).text;

  final String normalized;
}

class _NormalizedText {
  const _NormalizedText(this.text, this.offsets);

  final String text;
  final List<int> offsets;
}
