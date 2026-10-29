import '../models/saved_item.dart';

const int maxSmartTagRules = 50;
const int maxSmartTagMatchCharacters = 120;
const int maxSmartTagSuggestionsPerItem = 12;

/// A user-authored local rule: if text in a saved item's title, URL or notes
/// contains [matchText], offer [suggestedTag]. Rules never fetch content or
/// apply tags automatically.
class SmartTagRule {
  const SmartTagRule({
    required this.id,
    required this.matchText,
    required this.suggestedTag,
  });

  final String id;
  final String matchText;
  final String suggestedTag;

  static SmartTagRule create({
    required String id,
    required String matchText,
    required String suggestedTag,
  }) {
    final cleanId = id.trim();
    final cleanMatch = matchText.trim();
    final cleanTag = suggestedTag.trim();
    if (cleanId.isEmpty || cleanId.length > 128) {
      throw const FormatException('A smart-tag rule has an invalid ID.');
    }
    if (cleanMatch.isEmpty || cleanMatch.length > maxSmartTagMatchCharacters) {
      throw const FormatException(
        'Match text must be between 1 and $maxSmartTagMatchCharacters characters.',
      );
    }
    if (cleanTag.isEmpty || cleanTag.length > 100) {
      throw const FormatException(
        'Suggested tags must be between 1 and 100 characters.',
      );
    }
    return SmartTagRule(
      id: cleanId,
      matchText: cleanMatch,
      suggestedTag: cleanTag,
    );
  }

  Map<String, Object?> toMap() {
    final validated = SmartTagRule.create(
      id: id,
      matchText: matchText,
      suggestedTag: suggestedTag,
    );
    return <String, Object?>{
      'id': validated.id,
      'matchText': validated.matchText,
      'suggestedTag': validated.suggestedTag,
    };
  }

  factory SmartTagRule.fromMap(Map<dynamic, dynamic> raw) {
    final id = raw['id'];
    final matchText = raw['matchText'];
    final suggestedTag = raw['suggestedTag'];
    if (id is! String ||
        matchText is! String ||
        suggestedTag is! String ||
        id.length > 128 ||
        matchText.length > maxSmartTagMatchCharacters ||
        suggestedTag.length > 100) {
      throw const FormatException('The saved smart-tag rule is invalid.');
    }
    return SmartTagRule.create(
      id: id,
      matchText: matchText,
      suggestedTag: suggestedTag,
    );
  }
}

/// Explains why a tag was offered so users can review suggestions before
/// appending them to Quick Save's tags field.
class SmartTagSuggestion {
  const SmartTagSuggestion({
    required this.tag,
    required this.matchText,
    required this.ruleId,
  });

  final String tag;
  final String matchText;
  final String ruleId;
}

/// Suggests tags based only on the text the user has already entered locally.
/// A match against any title, URL or notes field can trigger a rule. Duplicate
/// rule outputs, existing tags, and excess suggestions are omitted.
List<SmartTagSuggestion> suggestSmartTags({
  required String title,
  required String url,
  required String content,
  required Iterable<String> existingTags,
  required Iterable<SmartTagRule> rules,
}) {
  final searchableText = <String>[
    if (title.length <= 500) title.toLowerCase(),
    if (url.length <= maxSavedItemUrlCharacters) url.toLowerCase(),
    if (content.length <= 1000000) content.toLowerCase(),
  ];
  final existing = <String>{};
  for (final tag in existingTags) {
    final normalized = tag.trim().toLowerCase();
    if (normalized.isNotEmpty) existing.add(normalized);
  }

  final emitted = <String>{};
  final suggestions = <SmartTagSuggestion>[];
  for (final rule in rules.take(maxSmartTagRules)) {
    final match = rule.matchText.trim().toLowerCase();
    final tagKey = rule.suggestedTag.trim().toLowerCase();
    if (match.isEmpty ||
        match.length > maxSmartTagMatchCharacters ||
        tagKey.isEmpty ||
        tagKey.length > 100 ||
        existing.contains(tagKey)) {
      continue;
    }
    if (!searchableText.any((field) => field.contains(match))) continue;
    if (!emitted.add(tagKey)) continue;
    suggestions.add(
      SmartTagSuggestion(
        tag: rule.suggestedTag,
        matchText: rule.matchText,
        ruleId: rule.id,
      ),
    );
    if (suggestions.length >= maxSmartTagSuggestionsPerItem) break;
  }
  return List<SmartTagSuggestion>.unmodifiable(suggestions);
}
