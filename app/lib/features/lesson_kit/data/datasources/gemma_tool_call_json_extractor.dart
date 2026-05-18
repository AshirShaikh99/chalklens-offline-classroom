import 'dart:convert';

import 'json_repair.dart';

class GemmaToolCallJsonExtractor {
  const GemmaToolCallJsonExtractor({required this.toolName});

  final String toolName;

  String? fromText(String raw) {
    final sdk = fromSdkRawResponse(raw);
    if (sdk != null) return sdk;
    return fromNativeToolCall(raw);
  }

  String? fromFunctionArgs(Map<String, dynamic> args) {
    final normalizedArgs = _normalizeMap(args);
    if (normalizedArgs.isEmpty) return null;

    final nestedArguments =
        normalizedArgs['arguments'] ??
        normalizedArgs['parameters'] ??
        normalizedArgs['args'];
    if (nestedArguments != null && normalizedArgs.length <= 2) {
      final nested = _fromRawArguments(nestedArguments);
      if (nested != null) return nested;
    }

    final directJson = normalizedArgs['lesson_kit_json'];
    if (directJson is String && directJson.trim().isNotEmpty) {
      return _cleanString(directJson);
    }
    if (directJson is Map<String, dynamic>) {
      return jsonEncode(directJson);
    }

    final nestedKit = normalizedArgs['lesson_kit'] ?? normalizedArgs['kit'];
    if (nestedKit is Map<String, dynamic>) {
      return jsonEncode(nestedKit);
    }

    return jsonEncode(normalizedArgs);
  }

  String? fromSdkRawResponse(String raw) {
    final candidates = JsonRepair.extractObjects(raw);
    for (final candidate in candidates) {
      final decoded = _decodeMap(candidate);
      if (decoded == null) continue;

      final extracted = _fromToolContainer(decoded);
      if (extracted != null) return extracted;
    }
    return null;
  }

  String? fromNativeToolCall(String raw) {
    const prefix = 'call:';
    var searchFrom = 0;
    while (true) {
      final callStart = raw.indexOf(prefix, searchFrom);
      if (callStart == -1) return null;
      final nameStart = callStart + prefix.length;
      final braceStart = raw.indexOf('{', nameStart);
      if (braceStart == -1) return null;

      final name = raw.substring(nameStart, braceStart).trim();
      if (name != toolName) {
        searchFrom = braceStart + 1;
        continue;
      }

      try {
        final parser = _GemmaNativeValueParser(raw, braceStart);
        final parsed = parser.parseValue();
        if (parsed is Map<String, dynamic>) {
          return fromFunctionArgs(parsed);
        }
      } on FormatException {
        searchFrom = braceStart + 1;
        continue;
      }

      searchFrom = braceStart + 1;
    }
  }

  String? _fromToolContainer(Map<String, dynamic> value) {
    final direct = _fromToolCallObject(value);
    if (direct != null) return direct;

    final topLevelCalls = value['tool_calls'];
    if (topLevelCalls is List) {
      for (final call in topLevelCalls) {
        final extracted = _fromToolCallObject(call);
        if (extracted != null) return extracted;
      }
    }

    final content = value['content'];
    if (content is List) {
      for (final item in content) {
        if (item is! Map) continue;
        if (item['type'] != 'tool_call') continue;
        final extracted = _fromToolCallObject(item['tool_call']);
        if (extracted != null) return extracted;
      }
    }

    return null;
  }

  String? _fromToolCallObject(Object? raw) {
    if (raw is! Map) return null;
    final call = _normalizeMap(raw);

    Map<String, dynamic>? function;
    final rawFunction = call['function'];
    if (rawFunction is Map) {
      function = _normalizeMap(rawFunction);
    } else if (call['name'] is String || call.containsKey('arguments')) {
      function = call;
    }
    if (function == null) return null;

    final name = function['name'];
    if (name is String && name != toolName) return null;

    final rawArguments =
        function['arguments'] ?? function['parameters'] ?? function['args'];
    return _fromRawArguments(rawArguments);
  }

  String? _fromRawArguments(Object? rawArguments) {
    if (rawArguments == null) return null;

    if (rawArguments is Map) {
      return fromFunctionArgs(_normalizeMap(rawArguments));
    }

    if (rawArguments is! String) return null;
    final cleaned = _cleanString(rawArguments);
    if (cleaned.isEmpty) return null;

    try {
      final decoded = jsonDecode(cleaned);
      if (decoded is Map) {
        return fromFunctionArgs(_normalizeMap(decoded));
      }
      if (decoded is String && decoded.trim().isNotEmpty) {
        return _cleanString(decoded);
      }
    } on FormatException {
      // The raw string may already be the lesson JSON object with imperfect
      // escaping. Return it and let the normal repair/parser path decide.
    }

    return cleaned;
  }

  Map<String, dynamic>? _decodeMap(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) return _normalizeMap(decoded);
    } on FormatException {
      return null;
    }
    return null;
  }

  Map<String, dynamic> _normalizeMap(Map<dynamic, dynamic> value) {
    return value.map(
      (key, value) =>
          MapEntry(_cleanString(key.toString()), _normalizeValue(value)),
    );
  }

  dynamic _normalizeValue(Object? value) {
    if (value is String) return _cleanString(value);
    if (value is Map) return _normalizeMap(value);
    if (value is List) return value.map(_normalizeValue).toList();
    return value;
  }

  String _cleanString(String value) => value.replaceAll('<|"|>', '').trim();
}

class _GemmaNativeValueParser {
  _GemmaNativeValueParser(this.source, this.index);

  final String source;
  int index;

  static const _stringToken = '<|"|>';

  Object? parseValue() {
    _skipSpaceAndSeparators();
    if (_atEnd) throw const FormatException('Unexpected end of tool call.');
    if (_startsWith(_stringToken)) return _parseGemmaString();
    final char = source[index];
    if (char == '{') return _parseObject();
    if (char == '[') return _parseArray();
    if (char == '"') return _parseQuotedString();
    return _parseBareValue();
  }

  Map<String, dynamic> _parseObject() {
    _expect('{');
    final map = <String, dynamic>{};

    while (true) {
      _skipSpaceAndSeparators();
      if (_atEnd) throw const FormatException('Unclosed object.');
      if (source[index] == '}') {
        index++;
        return map;
      }

      final key = _parseKey();
      _skipWhitespace();
      _expect(':');
      final value = parseValue();
      map[key] = value;

      _skipWhitespace();
      if (!_atEnd && source[index] == ',') index++;
    }
  }

  List<Object?> _parseArray() {
    _expect('[');
    final list = <Object?>[];

    while (true) {
      _skipSpaceAndSeparators();
      if (_atEnd) throw const FormatException('Unclosed array.');
      if (source[index] == ']') {
        index++;
        return list;
      }
      list.add(parseValue());
      _skipWhitespace();
      if (!_atEnd && source[index] == ',') index++;
    }
  }

  String _parseKey() {
    _skipWhitespace();
    if (_startsWith(_stringToken)) return _parseGemmaString();
    if (!_atEnd && source[index] == '"') return _parseQuotedString();

    final start = index;
    while (!_atEnd && source[index] != ':') {
      index++;
    }
    if (_atEnd) throw const FormatException('Object key missing colon.');
    final key = source.substring(start, index).trim();
    if (key.isEmpty) throw const FormatException('Object key was empty.');
    return key.replaceAll(_stringToken, '').trim();
  }

  String _parseGemmaString() {
    if (!_startsWith(_stringToken)) {
      throw const FormatException('Expected Gemma string token.');
    }
    index += _stringToken.length;
    final end = source.indexOf(_stringToken, index);
    if (end == -1) throw const FormatException('Unclosed Gemma string.');
    final value = source.substring(index, end);
    index = end + _stringToken.length;
    return value.trim();
  }

  String _parseQuotedString() {
    _expect('"');
    final buffer = StringBuffer();
    var escaped = false;

    while (!_atEnd) {
      final char = source[index++];
      if (escaped) {
        buffer.write(char);
        escaped = false;
        continue;
      }
      if (char == r'\') {
        escaped = true;
        continue;
      }
      if (char == '"') return buffer.toString();
      buffer.write(char);
    }

    throw const FormatException('Unclosed quoted string.');
  }

  Object? _parseBareValue() {
    final start = index;
    while (!_atEnd) {
      final char = source[index];
      if (char == ',' || char == '}' || char == ']') break;
      index++;
    }
    final raw = source.substring(start, index).trim();
    if (raw.isEmpty) return '';

    final lower = raw.toLowerCase();
    if (lower == 'null' || lower == 'n/a') return null;
    if (lower == 'true') return true;
    if (lower == 'false') return false;
    final number = num.tryParse(raw);
    if (number != null) return number;
    return raw.replaceAll(_stringToken, '').trim();
  }

  void _skipSpaceAndSeparators() {
    _skipWhitespace();
    while (!_atEnd && source[index] == ',') {
      index++;
      _skipWhitespace();
    }
  }

  void _skipWhitespace() {
    while (!_atEnd && source.codeUnitAt(index) <= 32) {
      index++;
    }
  }

  void _expect(String value) {
    if (_atEnd || source[index] != value) {
      throw FormatException('Expected $value.');
    }
    index++;
  }

  bool _startsWith(String value) => source.startsWith(value, index);

  bool get _atEnd => index >= source.length;
}
