import 'package:flutter_test/flutter_test.dart';
import 'package:pin/entities/task/model/atomic_step.dart';
import 'package:pin/entities/task/model/pin_task.dart';
import 'package:pin/features/task_export_import/services/task_text_formatter.dart';

void main() {
  group('TaskTextFormatter', () {
    final sampleTask = PinTask(
      id: 'task_1',
      title: 'Implement OAuth redirect',
      description: 'Handle deep link on Linux and Android',
      status: TaskStatus.today,
      energyTag: 'deep-focus',
      estimatedMinutes: 45,
      tags: ['#auth', '#oauth'],
      subtasks: const [
        AtomicStep(id: 's1', title: 'Register custom scheme', isCompleted: true),
        AtomicStep(id: 's2', title: 'Verify token exchange', isCompleted: false),
      ],
      createdAt: DateTime(2026, 9, 20, 10, 0),
      updatedAt: DateTime(2026, 9, 20, 10, 0),
    );

    test('formatSingleTask formats markdown correctly with tags and subtasks', () {
      final formatted = TaskTextFormatter.formatSingleTask(sampleTask);

      expect(formatted, contains('📌 Implement OAuth redirect'));
      expect(formatted, contains('Status: Today'));
      expect(formatted, contains('45m'));
      expect(formatted, contains('🏷️ #auth #oauth'));
      expect(formatted, contains('Handle deep link on Linux and Android'));
      expect(formatted, contains('- [x] Register custom scheme'));
      expect(formatted, contains('- [ ] Verify token exchange'));
    });

    test('formatTaskList groups tasks by status with markdown headers', () {
      final backlogTask = sampleTask.copyWith(
        id: 'task_2',
        title: 'Review pull requests',
        status: TaskStatus.backlog,
      );

      final formatted = TaskTextFormatter.formatTaskList([sampleTask, backlogTask]);

      expect(formatted, contains('## ⚡ Today (1)'));
      expect(formatted, contains('- [ ] Implement OAuth redirect (45m)'));
      expect(formatted, contains('## 📋 Backlog (1)'));
      expect(formatted, contains('- [ ] Review pull requests (45m)'));
    });

    test('parseTextToTasks parses bullet points, subtasks, tags, and durations', () {
      const markdown = '''
# My Meeting Notes
- [ ] Implement responsive sheet (30m) #ui #mobile
  - [x] Test small screen
  - [ ] Add animation
- [x] Fix crash on startup (15 min) #bug
* Simple backlog task without tags
''';

      final tasks = TaskTextFormatter.parseTextToTasks(markdown);

      expect(tasks.length, 3);

      final t1 = tasks[0];
      expect(t1.title, 'Implement responsive sheet');
      expect(t1.estimatedMinutes, 30);
      expect(t1.tags, containsAll(['#ui', '#mobile']));
      expect(t1.subtasks.length, 2);
      expect(t1.subtasks[0].title, 'Test small screen');
      expect(t1.subtasks[0].isCompleted, isTrue);
      expect(t1.subtasks[1].title, 'Add animation');
      expect(t1.subtasks[1].isCompleted, isFalse);

      final t2 = tasks[1];
      expect(t2.title, 'Fix crash on startup');
      expect(t2.estimatedMinutes, 15);
      expect(t2.status, TaskStatus.done);
      expect(t2.tags, contains('#bug'));

      final t3 = tasks[2];
      expect(t3.title, 'Simple backlog task without tags');
      expect(t3.estimatedMinutes, 15);
    });
  });
}
