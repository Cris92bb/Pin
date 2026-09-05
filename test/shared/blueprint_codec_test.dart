import 'package:flutter_test/flutter_test.dart';
import 'package:pin/shared/lib/blueprint_codec.dart';

void main() {
  group('BlueprintCodec', () {
    test('encodes and decodes task blueprint successfully', () {
      final sampleTasks = [
        {
          'id': 'task_1',
          'title': 'Build FSD architecture',
          'description': 'Feature-sliced design for Pin',
          'status': 'today',
          'energyTag': 'deep-focus',
          'estimatedMinutes': 30,
          'trackedSeconds': 120,
          'subtasks': [
            {
              'id': 'sub_1',
              'title': 'Write entities',
              'isCompleted': true,
              'estimatedMinutes': 15,
            }
          ],
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        }
      ];

      final encoded = BlueprintCodec.encodeTasks(sampleTasks);
      expect(encoded.startsWith('PIN_BP_'), isTrue);

      final result = BlueprintCodec.decode(encoded);
      expect(result.isSuccess, isTrue);
      expect(result.count, 1);
      expect(result.tasks.first['title'], 'Build FSD architecture');
      expect(result.tasks.first['subtasks'].length, 1);
    });

    test('handles empty input gracefully', () {
      final result = BlueprintCodec.decode('');
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, isNotNull);
    });

    test('handles malformed string gracefully', () {
      final result = BlueprintCodec.decode('invalid_corrupted_data_not_base64!!!');
      expect(result.isSuccess, isFalse);
    });
  });
}
