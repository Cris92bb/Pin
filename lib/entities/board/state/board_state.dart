import '../model/board.dart';

/// Immutable state containing the collection of user boards and active selection.
class BoardState {
  /// All boards currently available to the user.
  final List<Board> boards;

  /// Identifier of the currently active board.
  final String activeBoardId;

  /// Whether boards are currently being loaded from persistent storage.
  final bool isLoading;

  /// Whether the multi-board workspaces feature toggle is active.
  final bool isMultiBoardEnabled;

  const BoardState({
    this.boards = const [],
    this.activeBoardId = Board.defaultPersonalId,
    this.isLoading = false,
    this.isMultiBoardEnabled = false,
  });

  /// The currently active [Board] entity.
  Board get activeBoard {
    for (final board in boards) {
      if (board.id == activeBoardId) return board;
    }
    return boards.isNotEmpty ? boards.first : Board.personal;
  }

  /// Creates a copy of this state with updated fields.
  BoardState copyWith({
    List<Board>? boards,
    String? activeBoardId,
    bool? isLoading,
    bool? isMultiBoardEnabled,
  }) {
    return BoardState(
      boards: boards ?? this.boards,
      activeBoardId: activeBoardId ?? this.activeBoardId,
      isLoading: isLoading ?? this.isLoading,
      isMultiBoardEnabled: isMultiBoardEnabled ?? this.isMultiBoardEnabled,
    );
  }
}
