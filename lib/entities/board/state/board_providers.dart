import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/board.dart';
import 'board_notifier.dart';
import 'board_state.dart';

/// Provider exposing the board management state and operations.
final boardStateProvider =
    NotifierProvider<BoardStateNotifier, BoardState>(() {
  return BoardStateNotifier();
});

/// Convenience provider returning the currently active [Board].
final activeBoardProvider = Provider<Board>((ref) {
  return ref.watch(boardStateProvider).activeBoard;
});
