import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/pin_task.dart';
import 'task_list_state.dart';
import 'task_notifier.dart';

export '../../../shared/api/storage/storage_adapter.dart' show storageAdapterProvider;

/// A versatile [Notifier] holding mutable state [T] with both [state] getter and setter,
/// serving as a clean Riverpod 3 replacement for legacy [StateProvider].
class StateValueNotifier<T> extends Notifier<T> {
  final T Function() _init;
  T? _standaloneState;

  StateValueNotifier(this._init);

  @override
  T build() => _init();

  @override
  T get state {
    try {
      return super.state;
    } catch (_) {
      return _standaloneState ??= _init();
    }
  }

  @override
  set state(T value) {
    try {
      super.state = value;
    } catch (_) {
      _standaloneState = value;
    }
  }
}

/// Task state notifier provider managing Kanban boards and enforcing WIP limits.
final taskStateProvider =
    NotifierProvider<TaskStateNotifier, TaskListState>(() {
  return TaskStateNotifier(seedInitialSample: true);
});

/// Holds currently focused pin task (null if idle).
final activeFocusTaskProvider =
    NotifierProvider<StateValueNotifier<PinTask?>, PinTask?>(
  () => StateValueNotifier(() => null),
);

/// Active deck tab in the layered companion view (Today, Backlog, or Done).
final activeDeckProvider =
    NotifierProvider<StateValueNotifier<TaskStatus>, TaskStatus>(
  () => StateValueNotifier(() => TaskStatus.today),
);

/// Theme mode provider: toggles between Light and Dark mode.
final themeModeProvider =
    NotifierProvider<StateValueNotifier<ThemeMode>, ThemeMode>(
  () => StateValueNotifier(() => ThemeMode.system),
);
