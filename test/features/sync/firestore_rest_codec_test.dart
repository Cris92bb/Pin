import 'package:flutter_test/flutter_test.dart';
import 'package:pin/features/sync/services/firestore_rest_codec.dart';

void main() {
  group('FirestoreRestCodec', () {
    test('correctly encodes primitive types into Firestore REST value maps', () {
      final input = {
        'title': 'ADHD Focus Task',
        'estimatedMinutes': 25,
        'rating': 4.5,
        'isPinned': true,
        'notes': null,
      };

      final encoded = FirestoreRestCodec.encodeFields(input);

      expect(encoded['title'], equals({'stringValue': 'ADHD Focus Task'}));
      expect(encoded['estimatedMinutes'], equals({'integerValue': '25'}));
      expect(encoded['rating'], equals({'doubleValue': 4.5}));
      expect(encoded['isPinned'], equals({'booleanValue': true}));
      expect(encoded['notes'], equals({'nullValue': null}));
    });

    test('correctly encodes and decodes nested maps and arrays', () {
      final input = {
        'id': 'task-101',
        'tags': ['#adhd', '#deepwork'],
        'metadata': {
          'version': 1,
          'category': 'deep_work',
        },
        'subtasks': [
          {'id': 's1', 'title': 'Step 1', 'isCompleted': true},
          {'id': 's2', 'title': 'Step 2', 'isCompleted': false},
        ],
      };

      final encoded = FirestoreRestCodec.encodeFields(input);
      final decoded = FirestoreRestCodec.decodeFields(encoded);

      expect(decoded['id'], equals('task-101'));
      expect(decoded['tags'], equals(['#adhd', '#deepwork']));
      expect(decoded['metadata']['version'], equals(1));
      expect(decoded['metadata']['category'], equals('deep_work'));
      expect((decoded['subtasks'] as List).length, equals(2));
      expect(decoded['subtasks'][0]['title'], equals('Step 1'));
      expect(decoded['subtasks'][0]['isCompleted'], equals(true));
      expect(decoded['subtasks'][1]['isCompleted'], equals(false));
    });

    test('handles empty arrays and empty maps', () {
      final input = {
        'emptyList': [],
        'emptyDict': <String, dynamic>{},
      };

      final encoded = FirestoreRestCodec.encodeFields(input);
      final decoded = FirestoreRestCodec.decodeFields(encoded);

      expect(decoded['emptyList'], equals([]));
      expect(decoded['emptyDict'], equals(<String, dynamic>{}));
    });
  });
}
