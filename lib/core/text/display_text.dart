import 'package:characters/characters.dart';

/// Display-only transformations. Never pass profile names without protecting them.
/// Unknown uppercase words and camelCase/snake_case identifiers are conservative
/// exceptions: their significant casing is retained, not guessed.
String formatUiTitle(
  String value, {
  Iterable<String> protectedTerms = const [],
}) => _format(value, title: true, protectedTerms: protectedTerms);
String formatUiLabel(
  String value, {
  Iterable<String> protectedTerms = const [],
}) => formatUiTitle(value, protectedTerms: protectedTerms);
String formatSentence(
  String value, {
  Iterable<String> protectedTerms = const [],
}) => _format(value, title: false, protectedTerms: protectedTerms);

final _words = RegExp(r'[\p{L}\p{M}][\p{L}\p{M}\p{N}_]*', unicode: true);
final _protected = RegExp(
  r'(?:https?://|www\.)\S+|[^\s@]+@[^\s@]+\.[^\s@]+|[\p{L}\p{N}_-]+(?:[./_][\p{L}\p{N}_-]+)+',
  unicode: true,
  caseSensitive: false,
);
final _boundary = RegExp(r'[.!?…][\x27"”’»)]*\s+$|\n\s*$', unicode: true);
final _camelCase = RegExp(r'[a-z][A-Z]');
const _special = <String, String>{
  'pilogy': 'PILOGY',
  'api': 'API',
  'json': 'JSON',
  'ui': 'UI',
  'sdk': 'SDK',
  'http': 'HTTP',
  'https': 'HTTPS',
  'sql': 'SQL',
  'uuid': 'UUID',
  'utc': 'UTC',
  'gmt': 'GMT',
  'id': 'ID',
  'url': 'URL',
  'utf': 'UTF',
  'faq': 'FAQ',
  'firebase': 'Firebase',
  'admob': 'AdMob',
  'sqlite': 'SQLite',
  'riverpod': 'Riverpod',
  'pythagoras': 'Pythagoras',
};

String _upperFirstGrapheme(String value) {
  final chars = value.characters;
  return chars.isEmpty
      ? value
      : chars.first.toUpperCase() + chars.skip(1).join();
}

String _format(
  String value, {
  required bool title,
  required Iterable<String> protectedTerms,
}) {
  final spans = <({int start, int end})>[
    for (final match in _protected.allMatches(value))
      (start: match.start, end: match.end),
  ];
  for (final term in protectedTerms) {
    if (term.isEmpty) continue;
    var position = 0;
    while (position <= value.length) {
      final start = value.indexOf(term, position);
      if (start < 0) break;
      spans.add((start: start, end: start + term.length));
      position = start + term.length;
    }
  }
  final output = StringBuffer();
  var end = 0;
  var sentenceStart = true;
  for (final match in _words.allMatches(value)) {
    final prefix = value.substring(end, match.start);
    output.write(prefix);
    if (_boundary.hasMatch(prefix)) sentenceStart = true;
    final word = match.group(0)!;
    final preserve = spans.any(
      (span) => match.start < span.end && match.end > span.start,
    );
    if (preserve) {
      output.write(word);
    } else if (_special.containsKey(word.toLowerCase())) {
      output.write(_special[word.toLowerCase()]);
    } else if (_camelCase.hasMatch(word) ||
        word.contains('_') ||
        (word.characters.length > 1 &&
            word == word.toUpperCase() &&
            word != word.toLowerCase())) {
      output.write(word);
    } else if (title) {
      output.write(_upperFirstGrapheme(word.toLowerCase()));
    } else {
      output.write(sentenceStart ? _upperFirstGrapheme(word) : word);
    }
    sentenceStart = false;
    end = match.end;
  }
  output.write(value.substring(end));
  return output.toString();
}

/// A presentation projection; inputs and the DTO/raw JSON are never modified.
/// Only repeated complete paragraphs within the supplied group are removed.
Map<String, String> distinctDisplayParagraphs(Map<String, String> fields) {
  final seen = <String>{};
  final result = <String, String>{};
  for (final entry in fields.entries) {
    final display = formatSentence(entry.value).trim();
    final key = display.replaceAll(RegExp(r'\s+'), ' ');
    if (key.isNotEmpty && seen.add(key)) result[entry.key] = display;
  }
  return Map.unmodifiable(result);
}
