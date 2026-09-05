import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pin/shared/api/storage/local_file_storage_adapter.dart';

void main() {
  group('LocalFileStorageAdapter', () {
    late Directory tempDir;
    late File testFile;
    late LocalFileStorageAdapter adapter;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('pin_test_storage_');
      testFile = File('${tempDir.path}/test_tasks.json');
      adapter = LocalFileStorageAdapter(customFile: testFile);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('returns empty list when file does not exist', () async {
      final tasks = await adapter.loadTasks();
      expect(tasks, isEmpty);
    });

    test('saves and loads tasks atomically', () async {
      final sampleTasks = [
        {
          'id': 't1',
          'title': 'Local First Task',
          'status': 'today',
          'estimatedMinutes': 15,
        }
      ];

      await adapter.saveTasks(sampleTasks);
      expect(await testFile.exists(), isTrue);

      final loaded = await adapter.loadTasks();
      expect(loaded.length, 1);
      expect(loaded.first['title'], 'Local First Task');
    });

    test('clears saved tasks', () async {
      final sampleTasks = [
        {'id': 't1', 'title': 'To Be Cleared'}
      ];
      await adapter.saveTasks(sampleTasks);
      expect(await testFile.exists(), isTrue);

      await adapter.clear();
      expect(await testFile.exists(), isFalse);
    });
  });
}
