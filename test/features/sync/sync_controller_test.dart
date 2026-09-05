import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pin/entities/task/model/pin_task.dart';
import 'package:pin/entities/task/state/task_state_notifier.dart';
import 'package:pin/features/sync/model/app_user.dart';
import 'package:pin/features/sync/model/sync_status.dart';
import 'package:pin/features/sync/services/firebase_auth_service.dart';
import 'package:pin/features/sync/services/firebase_config.dart';
import 'package:pin/features/sync/services/firestore_rest_codec.dart';
import 'package:pin/features/sync/services/firestore_sync_service.dart';
import 'package:pin/features/sync/state/sync_controller.dart';
import 'package:pin/shared/api/storage/memory_storage_adapter.dart';

class MockHttpClient extends http.BaseClient {
  int patchCallCount = 0;
  int getCallCount = 0;
  Map<String, dynamic>? lastPatchedBody;
  Map<String, dynamic>? getResponseBody;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.method == 'PATCH') {
      patchCallCount++;
      if (request is http.Request) {
        lastPatchedBody = jsonDecode(request.body) as Map<String, dynamic>;
      }
      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode({'name': 'doc-path'}))),
        200,
      );
    } else if (request.method == 'GET') {
      getCallCount++;
      if (getResponseBody != null) {
        return http.StreamedResponse(
          Stream.value(utf8.encode(jsonEncode(getResponseBody!))),
          200,
        );
      }
      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode({'error': 'Not found'}))),
        404,
      );
    } else if (request.method == 'POST') {
      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode({
          'localId': 'user-mock-123',
          'idToken': 'token-mock-xyz',
          'email': 'mock@example.com',
        }))),
        200,
      );
    }
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode({'status': 'ok'}))),
      200,
    );
  }
}

void main() {
  group('Dual-Layer Persistence & Debounced Cloud Firestore Sync', () {
    late MemoryStorageAdapter memoryStorage;
    late MockHttpClient mockHttp;
    late FirebaseConfig testConfig;
    late FirebaseAuthService authService;
    late FirestoreSyncService firestoreService;

    setUp(() {
      memoryStorage = MemoryStorageAdapter();
      mockHttp = MockHttpClient();
      testConfig = const FirebaseConfig(
        apiKey: 'test-api-key',
        projectId: 'test-project-id',
      );
      authService = FirebaseAuthService(client: mockHttp, config: testConfig);
      firestoreService = FirestoreSyncService(client: mockHttp, config: testConfig);
    });

    test('immediate local storage write occurs without delay in guest mode', () async {
      final container = ProviderContainer(
        overrides: [
          storageAdapterProvider.overrideWithValue(memoryStorage),
          taskStateProvider.overrideWith((ref) => TaskStateNotifier(
                storage: memoryStorage,
                seedInitialSample: false,
              )),
        ],
      );

      final taskNotifier = container.read(taskStateProvider.notifier);
      final syncState = container.read(syncControllerProvider);

      expect(syncState.status, equals(SyncStatus.guest));

      final newTask = PinTask(
        id: 'task-guest-1',
        title: 'Instant Local Write Task',
        status: TaskStatus.today,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Create task
      await taskNotifier.createTask(newTask);

      // Local storage must have the task immediately
      final loadedLocal = await memoryStorage.loadTasks();
      expect(loadedLocal.any((t) => t['id'] == 'task-guest-1'), isTrue);

      // Zero HTTP patch calls in guest mode
      expect(mockHttp.patchCallCount, equals(0));
    });

    test('debounces rapid task modifications by 1,000ms when signed in', () async {
      const testUser = AppUser(
        uid: 'user-abc',
        email: 'test@example.com',
        idToken: 'token-123',
      );

      final container = ProviderContainer(
        overrides: [
          storageAdapterProvider.overrideWithValue(memoryStorage),
          taskStateProvider.overrideWith((ref) => TaskStateNotifier(
                storage: memoryStorage,
                seedInitialSample: false,
              )),
          syncControllerProvider.overrideWith((ref) {
            return SyncController(
              ref: ref,
              authService: authService,
              firestoreService: firestoreService,
              initialConfig: testConfig,
              initialUser: testUser,
            );
          }),
        ],
      );

      final taskNotifier = container.read(taskStateProvider.notifier);
      final syncController = container.read(syncControllerProvider.notifier);

      // Initial state is signed in
      expect(container.read(syncControllerProvider).isSignedIn, isTrue);

      // Wait for initial loadTasks to settle
      await Future.delayed(Duration.zero);

      // 1. Rapidly create 3 tasks within 300ms
      await taskNotifier.createTask(PinTask(
        id: 'rapid-1',
        title: 'Step 1',
        status: TaskStatus.today,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await taskNotifier.createTask(PinTask(
        id: 'rapid-2',
        title: 'Step 2',
        status: TaskStatus.today,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await taskNotifier.createTask(PinTask(
        id: 'rapid-3',
        title: 'Step 3',
        status: TaskStatus.today,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      // Immediate local write has all 3 tasks
      final localTasks = await memoryStorage.loadTasks();
      expect(localTasks.length, greaterThanOrEqualTo(3));

      // Because of 1,000ms debounce, no HTTP patch call has completed yet
      expect(mockHttp.patchCallCount, equals(0));
      expect(container.read(syncControllerProvider).isDebouncing, isTrue);

      // Manual syncNow cancels debounce and forces immediate cloud write
      await syncController.syncNow();

      expect(mockHttp.patchCallCount, equals(1));
      expect(container.read(syncControllerProvider).status, equals(SyncStatus.synced));
      expect(container.read(syncControllerProvider).syncedTaskCount, greaterThanOrEqualTo(3));
    });

    test('hydrates local board from cloud when signed in with existing cloud tasks', () async {
      final cloudTaskPayload = {
        'id': 'cloud-task-999',
        'title': 'Hydrated from Firestore',
        'status': 'today',
        'energyTag': 'deep-focus',
        'estimatedMinutes': 45,
        'trackedSeconds': 120,
        'isPinned': true,
        'tags': ['#cloud'],
        'subtasks': [],
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final encodedDoc = {
        'fields': FirestoreRestCodec.encodeFields({
          'tasks': [cloudTaskPayload],
          'dailyCheckin': {
            'energyScore': 85,
            'cognitiveCapacity': 'peak_focus',
          },
          'lastSyncedAt': 1725555000000,
          'count': 1,
        }),
      };

      mockHttp.getResponseBody = encodedDoc;

      final container = ProviderContainer(
        overrides: [
          storageAdapterProvider.overrideWithValue(memoryStorage),
          taskStateProvider.overrideWith((ref) => TaskStateNotifier(
                storage: memoryStorage,
                seedInitialSample: false,
              )),
          syncControllerProvider.overrideWith((ref) {
            return SyncController(
              ref: ref,
              authService: authService,
              firestoreService: firestoreService,
              initialConfig: testConfig,
            );
          }),
        ],
      );

      // Trigger user login
      final syncController = container.read(syncControllerProvider.notifier);
      await syncController.signInAnonymously();

      // Cloud document was loaded
      final state = container.read(taskStateProvider);
      expect(state.tasks.isNotEmpty, isTrue);
    });

    test('1-click passwordless Google sign in authenticates and establishes cloud session', () async {
      final container = ProviderContainer(
        overrides: [
          storageAdapterProvider.overrideWithValue(memoryStorage),
          taskStateProvider.overrideWith((ref) => TaskStateNotifier(
                storage: memoryStorage,
                seedInitialSample: false,
              )),
          syncControllerProvider.overrideWith((ref) {
            return SyncController(
              ref: ref,
              authService: authService,
              firestoreService: firestoreService,
              initialConfig: testConfig,
            );
          }),
        ],
      );

      final syncController = container.read(syncControllerProvider.notifier);
      final success = await syncController.signInWithGoogle(
        email: 'testuser@gmail.com',
        displayName: 'Test User',
      );

      expect(success, isTrue);
      final syncState = container.read(syncControllerProvider);
      expect(syncState.isSignedIn, isTrue);
      expect(syncState.user?.email, equals('testuser@gmail.com'));
      expect(syncState.user?.displayName, equals('Test User'));
      expect(syncState.user?.photoURL, contains('googleusercontent.com'));
    });
  });
}
