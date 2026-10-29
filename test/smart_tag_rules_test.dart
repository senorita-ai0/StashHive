import 'package:flutter_test/flutter_test.dart';
import 'package:stashhive/services/smart_tag_rules.dart';

SmartTagRule rule({
  String id = 'rule-1',
  String matchText = 'design',
  String suggestedTag = 'Design',
}) =>
    SmartTagRule.create(
      id: id,
      matchText: matchText,
      suggestedTag: suggestedTag,
    );

void main() {
  group('SmartTagRule', () {
    test('trims values and round-trips storage', () {
      final original = SmartTagRule.create(
        id: ' rule-1 ',
        matchText: '  Design ',
        suggestedTag: ' Creative ',
      );
      final restored = SmartTagRule.fromMap(original.toMap());

      expect(restored.id, 'rule-1');
      expect(restored.matchText, 'Design');
      expect(restored.suggestedTag, 'Creative');
    });

    test('rejects blank or overlong values', () {
      expect(
        () => SmartTagRule.create(id: ' ', matchText: 'design', suggestedTag: 'Design'),
        throwsFormatException,
      );
      expect(
        () => SmartTagRule.create(id: 'id', matchText: ' ', suggestedTag: 'Design'),
        throwsFormatException,
      );
      expect(
        () => SmartTagRule.create(
          id: 'id',
          matchText: List<String>.filled(maxSmartTagMatchCharacters + 1, 'x').join(),
          suggestedTag: 'Design',
        ),
        throwsFormatException,
      );
      expect(
        () => SmartTagRule.create(
          id: 'id',
          matchText: 'design',
          suggestedTag: List<String>.filled(101, 'x').join(),
        ),
        throwsFormatException,
      );
      expect(
        () => SmartTagRule.fromMap(<String, Object?>{'id': 'x', 'matchText': 'design'}),
        throwsFormatException,
      );
    });
  });

  group('suggestSmartTags', () {
    test('matches title, URL and notes case-insensitively', () {
      final suggestions = suggestSmartTags(
        title: 'A DESIGN systems overview',
        url: 'https://example.com/research',
        content: 'Use local storage for examples.',
        existingTags: const <String>[],
        rules: <SmartTagRule>[
          rule(),
          rule(id: 'rule-2', matchText: 'example.com', suggestedTag: 'Research'),
          rule(id: 'rule-3', matchText: 'local storage', suggestedTag: 'Offline'),
        ],
      );

      expect(suggestions.map((entry) => entry.tag), <String>[
        'Design',
        'Research',
        'Offline',
      ]);
      expect(suggestions.first.matchText, 'design');
    });

    test('does not offer existing tags or duplicate suggested tags', () {
      final suggestions = suggestSmartTags(
        title: 'Design inspiration',
        url: '',
        content: '',
        existingTags: const <String>['DESIGN'],
        rules: <SmartTagRule>[
          rule(),
          rule(id: 'rule-2', matchText: 'inspiration', suggestedTag: 'Design'),
          rule(id: 'rule-3', matchText: 'design', suggestedTag: 'Ideas'),
        ],
      );

      expect(suggestions.map((entry) => entry.tag), <String>['Ideas']);
    });

    test('ignores rules without a text match and caps visible suggestions', () {
      final suggestions = suggestSmartTags(
        title: 'Keep this link',
        url: '',
        content: '',
        existingTags: const <String>[],
        rules: List<SmartTagRule>.generate(
          maxSmartTagRules + 10,
          (index) => rule(
            id: 'rule-$index',
            matchText: 'keep',
            suggestedTag: 'Tag $index',
          ),
        ),
      );

      expect(suggestions, hasLength(maxSmartTagSuggestionsPerItem));
      expect(suggestions.first.tag, 'Tag 0');
    });

    test('returns an immutable suggestion list', () {
      final suggestions = suggestSmartTags(
        title: 'Design',
        url: '',
        content: '',
        existingTags: const <String>[],
        rules: <SmartTagRule>[rule()],
      );

      expect(() => suggestions.clear(), throwsUnsupportedError);
    });
  });
}
