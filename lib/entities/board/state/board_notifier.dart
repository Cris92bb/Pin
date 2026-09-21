import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/api/storage/prefs_storage_adapter.dart';
import '../../../shared/api/storage/storage_adapter.dart';
import '../model/board.dart';
import 'board_state.dart';

/// State notifier managing board collections, selection, creation, and persistence.
class BoardStateNotifier extends Notifier<BoardState> {
  final StorageAdapter? _configuredStorage;
  StorageAdapter? _storage;
  BoardState? _standaloneState;

  BoardStateNotifier({StorageAdapter? storage})
      : _configuredStorage = storage {
    _standaloneState = BoardState(
      boards: Board.defaultBoards,
      isLoading: false,
    );
  }

  /// Active storage adapter.
  StorageAdapter get storage =>
      _storage ?? _configuredStorage ?? PrefsStorageAdapter();

  /// Future tracking board loading from storage.
  Future<void> loadFuture = Future.value();

  @override
  BoardState build() {
    StorageAdapter? watchedStorage;
    try {
      watchedStorage = ref.watch(storageAdapterProvider);
    } catch (_) {
      watchedStorage = null;
    }
    _storage = _configuredStorage ?? watchedStorage ?? PrefsStorageAdapter();
    final initialState = BoardState(
      boards: Board.defaultBoards,
      isLoading: true,
    );
    _standaloneState = initialState;
    loadFuture = Future.microtask(() => loadBoards());
    return initialState;
  }

  @override
  BoardState get state {
    try {
      return super.state;
    } catch (_) {
      return _standaloneState ??= BoardState(
        boards: Board.defaultBoards,
        isLoading: false,
      );
    }
  }

  @override
  set state(BoardState value) {
    try {
      super.state = value;
    } catch (_) {
      _standaloneState = value;
    }
  }

  /// Loads boards from persistent storage, falling back to default Personal.
  Future<void> loadBoards() async {
    state = state.copyWith(isLoading: true);
    try {
      final isEnabled = await storage.isMultiBoardEnabled();
      final boardMaps = await storage.loadBoards();
      if (boardMaps.isEmpty) {
        final initial = Board.defaultBoards;
        state = state.copyWith(
          boards: initial,
          activeBoardId: Board.defaultPersonalId,
          isMultiBoardEnabled: isEnabled,
          isLoading: false,
        );
        await storage.saveBoards(initial.map((b) => b.toJson()).toList());
      } else {
        final parsed = boardMaps.map((m) => Board.fromJson(m)).toList();
        final hasActive = parsed.any((b) => b.id == state.activeBoardId);
        final activeId = hasActive
            ? state.activeBoardId
            : (parsed.isNotEmpty ? parsed.first.id : Board.defaultPersonalId);
        state = state.copyWith(
          boards: parsed,
          activeBoardId: activeId,
          isMultiBoardEnabled: isEnabled,
          isLoading: false,
        );
      }
    } catch (_) {
      state = state.copyWith(
        boards: Board.defaultBoards,
        activeBoardId: Board.defaultPersonalId,
        isLoading: false,
      );
    }
  }

  /// Updates whether multi-board workspaces feature is enabled.
  Future<void> setMultiBoardEnabled(bool enabled) async {
    state = state.copyWith(isMultiBoardEnabled: enabled);
    await storage.setMultiBoardEnabled(enabled);
  }

  /// Changes the active board selection.
  void selectBoard(String boardId) {
    if (state.boards.any((b) => b.id == boardId)) {
      state = state.copyWith(activeBoardId: boardId);
    }
  }

  /// Creates a new workspace board and switches to it.
  Future<Board> createBoard(
    String name, {
    String icon = 'folder',
    int wipLimit = 3,
  }) async {
    final cleanName = name.trim().isEmpty ? 'New Board' : name.trim();
    final newId = 'board-${DateTime.now().millisecondsSinceEpoch}';
    final newBoard = Board(
      id: newId,
      name: cleanName,
      icon: icon,
      wipLimit: wipLimit,
      isDefault: false,
      createdAt: DateTime.now(),
    );

    final updated = [...state.boards, newBoard];
    state = state.copyWith(
      boards: updated,
      activeBoardId: newId,
      isMultiBoardEnabled: true,
    );
    await storage.saveBoards(updated.map((b) => b.toJson()).toList());
    await storage.setMultiBoardEnabled(true);
    return newBoard;
  }

  /// Renames an existing board.
  Future<void> renameBoard(String boardId, String newName) async {
    final cleanName = newName.trim();
    if (cleanName.isEmpty) return;

    final updated = state.boards.map((b) {
      if (b.id == boardId) {
        return b.copyWith(name: cleanName);
      }
      return b;
    }).toList();

    state = state.copyWith(boards: updated);
    await storage.saveBoards(updated.map((b) => b.toJson()).toList());
  }

  /// Updates the WIP limit for a specific board.
  Future<void> updateWipLimit(String boardId, int newLimit) async {
    if (newLimit < 1) return;

    final updated = state.boards.map((b) {
      if (b.id == boardId) {
        return b.copyWith(wipLimit: newLimit);
      }
      return b;
    }).toList();

    state = state.copyWith(boards: updated);
    await storage.saveBoards(updated.map((b) => b.toJson()).toList());
  }

  /// Deletes a board if more than one board exists.
  /// Switches active board if the active board is being deleted.
  Future<bool> deleteBoard(String boardId) async {
    if (state.boards.length <= 1) return false;

    final updated = state.boards.where((b) => b.id != boardId).toList();
    var nextActiveId = state.activeBoardId;
    if (nextActiveId == boardId) {
      nextActiveId = updated.first.id;
    }

    state = state.copyWith(boards: updated, activeBoardId: nextActiveId);
    await storage.saveBoards(updated.map((b) => b.toJson()).toList());
    return true;
  }

  /// Merges cloud board records into local state.
  Future<void> hydrateBoards(List<Board> cloudBoards) async {
    if (cloudBoards.isEmpty) return;

    final map = <String, Board>{};
    for (final b in state.boards) {
      map[b.id] = b;
    }
    for (final b in cloudBoards) {
      map[b.id] = b;
    }

    final merged = map.values.toList();
    final activeId = merged.any((b) => b.id == state.activeBoardId)
        ? state.activeBoardId
        : merged.first.id;

    state = state.copyWith(boards: merged, activeBoardId: activeId);
    await storage.saveBoards(merged.map((b) => b.toJson()).toList());
  }
}
