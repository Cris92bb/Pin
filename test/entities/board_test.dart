import 'package:flutter_test/flutter_test.dart';
import 'package:pin/entities/board/model/board.dart';
import 'package:pin/entities/board/state/board_notifier.dart';
import 'package:pin/entities/task/model/pin_task.dart';
import 'package:pin/entities/task/state/task_state_notifier.dart';
import 'package:pin/shared/api/storage/memory_storage_adapter.dart';

void main() {
  group('Board Domain Model', () {
    test('defaultBoards contains only single personal board by default', () {
      final defaults = Board.defaultBoards;
      expect(defaults.length, 1);
      expect(defaults[0].id, 'personal');
      expect(defaults[0].name, 'Personal');
    });

    test('serializes to and from JSON', () {
      final now = DateTime(2026, 9, 21, 12, 0, 0);
      final board = Board(
        id: 'work',
        name: 'Work Board',
        icon: 'briefcase',
        wipLimit: 4,
        isDefault: false,
        createdAt: now,
      );

      final json = board.toJson();
      final recovered = Board.fromJson(json);

      expect(recovered.id, 'work');
      expect(recovered.name, 'Work Board');
      expect(recovered.icon, 'briefcase');
      expect(recovered.wipLimit, 4);
      expect(recovered.isDefault, isFalse);
      expect(recovered.createdAt, now);
    });

    test('copyWith updates properties correctly', () {
      final board = Board.personal;
      final updated = board.copyWith(name: 'My Life', wipLimit: 5);
      expect(updated.id, 'personal');
      expect(updated.name, 'My Life');
      expect(updated.wipLimit, 5);
    });
  });

  group('BoardStateNotifier', () {
    late MemoryStorageAdapter storage;
    late BoardStateNotifier notifier;

    setUp(() {
      storage = MemoryStorageAdapter();
      notifier = BoardStateNotifier(storage: storage);
    });

    test('initializes with default single board and active personal board', () {
      expect(notifier.state.boards.length, 1);
      expect(notifier.state.activeBoardId, 'personal');
      expect(notifier.state.activeBoard.name, 'Personal');
      expect(notifier.state.isMultiBoardEnabled, isFalse);
    });

    test('setMultiBoardEnabled toggles feature state and persists', () async {
      expect(notifier.state.isMultiBoardEnabled, isFalse);
      await notifier.setMultiBoardEnabled(true);
      expect(notifier.state.isMultiBoardEnabled, isTrue);

      final persisted = await storage.isMultiBoardEnabled();
      expect(persisted, isTrue);
    });

    test('createBoard adds new board, enables multi-board, selects it, and saves', () async {
      final newBoard = await notifier.createBoard('Projects', icon: 'briefcase');
      expect(newBoard.name, 'Projects');
      expect(notifier.state.boards.length, 2);
      expect(notifier.state.activeBoardId, newBoard.id);
      expect(notifier.state.activeBoard.name, 'Projects');
      expect(notifier.state.isMultiBoardEnabled, isTrue);

      final saved = await storage.loadBoards();
      expect(saved.length, 2);
      expect(saved.any((b) => b['id'] == newBoard.id), isTrue);
    });

    test('selectBoard switches the active board when multiple exist', () async {
      await notifier.createBoard('Projects');
      notifier.selectBoard('personal');
      expect(notifier.state.activeBoardId, 'personal');
      notifier.selectBoard(notifier.state.boards.last.id);
      expect(notifier.state.activeBoardId, notifier.state.boards.last.id);
    });

    test('renameBoard updates board name', () async {
      await notifier.renameBoard('personal', 'Private Tasks');
      expect(notifier.state.boards.firstWhere((b) => b.id == 'personal').name, 'Private Tasks');
    });

    test('deleteBoard deletes board and adjusts activeBoard if necessary', () async {
      final custom = await notifier.createBoard('Temporary');
      expect(notifier.state.activeBoardId, custom.id);
      expect(notifier.state.boards.length, 2);

      final success = await notifier.deleteBoard(custom.id);
      expect(success, isTrue);
      expect(notifier.state.boards.length, 1);
      // Active board falls back
      expect(notifier.state.activeBoardId, 'personal');
    });

    test('deleteBoard cannot delete when only one board remains', () async {
      final delete = await notifier.deleteBoard('personal');
      expect(delete, isFalse);
      expect(notifier.state.boards.length, 1);
    });
  });

  group('TaskStateNotifier Board Isolation & Scoping', () {
    late MemoryStorageAdapter storage;
    late TaskStateNotifier notifier;

    setUp(() {
      storage = MemoryStorageAdapter();
      notifier = TaskStateNotifier(storage: storage);
    });

    test('tasks are isolated by activeBoardId', () async {
      final taskPersonal = PinTask(
        id: 't_personal',
        title: 'Buy Groceries',
        boardId: 'personal',
        status: TaskStatus.today,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final taskProjects = PinTask(
        id: 't_projects',
        title: 'Launch MVP',
        boardId: 'projects',
        status: TaskStatus.today,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await notifier.createTask(taskPersonal);
      await notifier.createTask(taskProjects);

      // On 'personal' board (default)
      expect(notifier.state.activeBoardId, 'personal');
      expect(notifier.state.todayTasks.length, 1);
      expect(notifier.state.todayTasks.first.title, 'Buy Groceries');

      // Switch active board to 'projects'
      notifier.setActiveBoard('projects');
      expect(notifier.state.activeBoardId, 'projects');
      expect(notifier.state.todayTasks.length, 1);
      expect(notifier.state.todayTasks.first.title, 'Launch MVP');
    });

    test('moveTaskToBoard moves task to target board', () async {
      final task = PinTask(
        id: 'task_to_move',
        title: 'Migrate Code',
        boardId: 'personal',
        status: TaskStatus.today,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await notifier.createTask(task);
      expect(notifier.state.todayTasks.length, 1);

      await notifier.moveTaskToBoard('task_to_move', 'projects');

      // On personal board, it is no longer visible
      expect(notifier.state.todayTasks.isEmpty, isTrue);

      // On projects board, it is visible
      notifier.setActiveBoard('projects');
      expect(notifier.state.todayTasks.length, 1);
      expect(notifier.state.todayTasks.first.title, 'Migrate Code');
      expect(notifier.state.todayTasks.first.boardId, 'projects');
    });
  });
}
