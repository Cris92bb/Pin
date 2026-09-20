import '../../../entities/task/model/pin_task.dart';
import '../../../entities/task/state/task_state_notifier.dart';
import '../model/daily_checkin.dart';
import '../services/firestore_sync_service.dart';

/// Encapsulates the output of reconciling local and cloud Kanban board state.
class SyncMergeResult {
  final List<PinTask> mergedTasks;
  final Map<String, int> mergedDeletedMap;
  final DailyCheckin? checkin;

  const SyncMergeResult({
    required this.mergedTasks,
    required this.mergedDeletedMap,
    this.checkin,
  });
}

/// Algorithmic reconciler performing CRDT and Last-Write-Wins (LWW) conflict resolution
/// between local SQLite/SharedPreferences state and Cloud Firestore snapshots.
class SyncMerger {
  /// Merges local tasks and tombstones with cloud snapshot.
  static SyncMergeResult reconcile({
    required List<PinTask> localTasks,
    required Map<String, int> localDeletedMap,
    required CloudBoardData cloudBoard,
    required DailyCheckin? currentCheckin,
    required int? lastSyncedAt,
  }) {
    // 1. Combine deletion tombstones from cloud and local
    final mergedDeletedMap = Map<String, int>.from(cloudBoard.deletedTaskIds);
    for (final entry in localDeletedMap.entries) {
      final existing = mergedDeletedMap[entry.key];
      if (existing == null || entry.value > existing) {
        mergedDeletedMap[entry.key] = entry.value;
      }
    }

    // 2. Parse cloud tasks
    final cloudTasks = cloudBoard.tasks.map((m) => PinTask.fromJson(m)).toList();

    final cloudHasRealTasks =
        cloudTasks.any((t) => !TaskStateNotifier.isUntouchedSamplePin(t));
    final localHasRealTasks =
        localTasks.any((t) => !TaskStateNotifier.isUntouchedSamplePin(t));

    // 3. Merge tasks using CRDT / LWW (Last-Write-Wins)
    final Map<String, PinTask> merged = {};

    // Filter local tasks
    final effectiveLocalTasks = localTasks.where((t) {
      if (cloudHasRealTasks && TaskStateNotifier.isUntouchedSamplePin(t)) {
        return false;
      }
      final deletedAt = mergedDeletedMap[t.id];
      if (deletedAt != null &&
          deletedAt >= t.updatedAt.millisecondsSinceEpoch) {
        return false;
      }
      return true;
    });

    for (final t in effectiveLocalTasks) {
      merged[t.id] = t;
    }

    // Filter cloud tasks
    final effectiveCloudTasks = cloudTasks.where((t) {
      if (localHasRealTasks && TaskStateNotifier.isUntouchedSamplePin(t)) {
        return false;
      }
      final deletedAt = mergedDeletedMap[t.id];
      if (deletedAt != null &&
          deletedAt >= t.updatedAt.millisecondsSinceEpoch) {
        return false;
      }
      return true;
    });

    for (final cloudTask in effectiveCloudTasks) {
      final local = merged[cloudTask.id];
      if (local == null) {
        // Task only in cloud (created on another device) → add it
        merged[cloudTask.id] = cloudTask;
      } else if (cloudTask.updatedAt.isAfter(local.updatedAt)) {
        // Cloud version is newer → prefer cloud
        merged[cloudTask.id] = cloudTask;
      }
    }

    final mergedList = merged.values.toList();

    // 4. Merge daily check-in
    DailyCheckin? checkin = currentCheckin;
    if (cloudBoard.dailyCheckin != null && cloudBoard.dailyCheckin!.isNotEmpty) {
      final cloudCheckin = DailyCheckin.fromJson(cloudBoard.dailyCheckin!);
      if (checkin == null || cloudBoard.lastSyncedAt > (lastSyncedAt ?? 0)) {
        checkin = cloudCheckin;
      }
    }

    return SyncMergeResult(
      mergedTasks: mergedList,
      mergedDeletedMap: mergedDeletedMap,
      checkin: checkin,
    );
  }

  /// Determines if task contents or order changed between two lists.
  static bool hasListChanged(List<PinTask> a, List<PinTask> b) {
    if (a.length != b.length) return true;
    final mapA = {for (final t in a) t.id: t};
    for (final tb in b) {
      final ta = mapA[tb.id];
      if (ta == null) return true;
      if (ta.updatedAt.millisecondsSinceEpoch !=
          tb.updatedAt.millisecondsSinceEpoch) {
        return true;
      }
      if (ta.status != tb.status) return true;
      if (ta.title != tb.title) return true;
    }
    return false;
  }
}
