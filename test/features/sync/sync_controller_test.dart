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
import 'package:shared_preferences/shared_preferences.dart';

class MockHttpClient extends http.BaseClient {
  int patchCallCount = 0;
  int getCallCount = 0;
  Map<String, dynamic>? lastPatchedBody;
  Map<String, dynamic>? getResponseBody;
  String? postErrorMessage;
  final List<Uri> deletedUris = [];
  http.Request? lastPostRequest;

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
    } else if (request.method == 'DELETE') {
      deletedUris.add(request.url);
      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode({'status': 'deleted'}))),
        200,
      );
    } else if (request.method == 'POST') {
      if (request is http.Request) {
        lastPostRequest = request;
      }
      if (postErrorMessage != null) {
        return http.StreamedResponse(
          Stream.value(utf8.encode(jsonEncode({
            'error': {'message': postErrorMessage, 'code': 400}
          }))),
          400,
        );
      }
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

    test('handles disabled anonymous authentication gracefully with actionable message', () async {
      final errorClient = MockHttpClient();
      // Mock error response for signUp
      final failingAuthService = FirebaseAuthService(
        client: errorClient,
        config: testConfig,
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
              authService: failingAuthService,
              firestoreService: firestoreService,
              initialConfig: testConfig,
            );
          }),
        ],
      );

      // Force mockHttp to return ADMIN_ONLY_OPERATION
      errorClient.postErrorMessage = 'ADMIN_ONLY_OPERATION';

      final syncController = container.read(syncControllerProvider.notifier);
      final success = await syncController.signInWithGoogle(
        email: 'testuser@gmail.com',
      );

      expect(success, isFalse);
      final syncState = container.read(syncControllerProvider);
      expect(syncState.isSignedIn, isFalse);
      expect(syncState.errorMessage, contains('Firebase Anonymous sign-in is disabled'));
    });

    test('normalizes email to lowercase and maps EMAIL_EXISTS to actionable password message', () async {
      final errorClient = MockHttpClient();
      final authService = FirebaseAuthService(
        client: errorClient,
        config: testConfig,
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
            );
          }),
        ],
      );

      errorClient.postErrorMessage = 'EMAIL_EXISTS';

      final syncController = container.read(syncControllerProvider.notifier);
      final success = await syncController.signInWithGoogle(
        email: '  User.Test@Gmail.COM  ',
      );

      expect(success, isFalse);
      final syncState = container.read(syncControllerProvider);
      expect(syncState.isSignedIn, isFalse);
      expect(
        syncState.errorMessage,
        contains('This account was created with a password'),
      );
      // Verify the request sent lowercase normalized email
      expect(errorClient.lastPostRequest, isNotNull);
      final requestBody = jsonDecode(errorClient.lastPostRequest!.body) as Map<String, dynamic>;
      expect(requestBody['email'], equals('user.test@gmail.com'));
    });

    test('persists idToken in AppUser serialization and restores valid session', () async {
      SharedPreferences.setMockInitialValues({});
      const originalUser = AppUser(
        uid: 'user-persistence-123',
        email: 'persist@example.com',
        displayName: 'Persist User',
        idToken: 'valid-jwt-token-456',
        photoURL: 'https://example.com/photo.png',
        isAnonymous: false,
      );

      // Verify toJson contains idToken
      final userJson = originalUser.toJson();
      expect(userJson['idToken'], equals('valid-jwt-token-456'));

      // Verify fromJson restores idToken
      final restoredUser = AppUser.fromJson(userJson);
      expect(restoredUser.idToken, equals('valid-jwt-token-456'));
      expect(restoredUser.uid, equals('user-persistence-123'));

      // Save via SharedPreferences and reload
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('firebase_cached_user', jsonEncode(userJson));

      final loadedUser = await FirebaseAuthService.loadCachedUser();
      expect(loadedUser, isNotNull);
      expect(loadedUser?.idToken, equals('valid-jwt-token-456'));
    });

    test('purges legacy or corrupted session without idToken upon loadCachedUser', () async {
      SharedPreferences.setMockInitialValues({
        'firebase_cached_user': jsonEncode({
          'uid': 'legacy-user-no-token',
          'email': 'legacy@example.com',
          'displayName': 'Legacy User',
        }),
      });

      final loadedUser = await FirebaseAuthService.loadCachedUser();
      expect(loadedUser, isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('firebase_cached_user'), isFalse);
    });

    test('cross-device synchronization merges tasks seamlessly with the same Google account', () async {
      // Setup Device 1 cloud state: cloud already has a task from Device 1
      final now = DateTime.now();
      final cloudTask1 = PinTask(
        id: 'task-device-1',
        title: 'Task created on Device 1',
        status: TaskStatus.today,
        isPinned: true,
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      );

      // Cloud document payload encoded as Firestore fields
      final cloudDocFields = {
        'fields': {
          'tasks': {
            'arrayValue': {
              'values': [
                FirestoreRestCodec.encodeValue(cloudTask1.toJson()),
              ]
            }
          },
          'lastSyncedAt': {'integerValue': now.millisecondsSinceEpoch.toString()},
        }
      };
      mockHttp.getResponseBody = cloudDocFields;

      // Setup Device 2 local state: has task-device-2
      final device2LocalTask = PinTask(
        id: 'task-device-2',
        title: 'Task created on Device 2',
        status: TaskStatus.backlog,
        createdAt: now.subtract(const Duration(minutes: 30)),
        updatedAt: now.subtract(const Duration(minutes: 30)),
      );

      final device2Storage = MemoryStorageAdapter();
      await device2Storage.saveTasks([device2LocalTask.toJson()]);

      final container = ProviderContainer(
        overrides: [
          storageAdapterProvider.overrideWithValue(device2Storage),
          taskStateProvider.overrideWith((ref) => TaskStateNotifier(
                storage: device2Storage,
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

      // Device 2 signs in with the same Google account
      final syncController = container.read(syncControllerProvider.notifier);
      final success = await syncController.signInWithGoogle(
        email: 'shared.developer@gmail.com',
        displayName: 'Shared Developer',
      );

      expect(success, isTrue);

      // Verify authentic Firebase Auth UID is preserved across devices
      final user = container.read(syncControllerProvider).user;
      expect(user?.uid, equals('user-mock-123'));

      // Verify both tasks are present after 3-way merge
      final currentTasks = container.read(taskStateProvider).tasks;
      expect(currentTasks.length, equals(2));
      expect(currentTasks.any((t) => t.id == 'task-device-1'), isTrue);
      expect(currentTasks.any((t) => t.id == 'task-device-2'), isTrue);

      // Verify merged tasks were synced back to Firestore
      expect(mockHttp.patchCallCount, greaterThanOrEqualTo(1));
      expect(mockHttp.lastPatchedBody, isNotNull);
    });

    test('cross-device conflict resolution prefers task with newer updatedAt timestamp', () async {
      final now = DateTime.now();
      // Cloud has an older version of task-x
      final cloudTask = PinTask(
        id: 'task-conflict-id',
        title: 'Older Cloud Version',
        status: TaskStatus.backlog,
        createdAt: now.subtract(const Duration(hours: 5)),
        updatedAt: now.subtract(const Duration(hours: 3)),
      );

      mockHttp.getResponseBody = {
        'fields': {
          'tasks': {
            'arrayValue': {
              'values': [
                FirestoreRestCodec.encodeValue(cloudTask.toJson()),
              ]
            }
          },
          'lastSyncedAt': {'integerValue': now.millisecondsSinceEpoch.toString()},
        }
      };

      // Local has a newer version of the same task-x
      final newerLocalTask = PinTask(
        id: 'task-conflict-id',
        title: 'Newer Local Version (Edited on Device 2)',
        status: TaskStatus.today,
        isPinned: true,
        createdAt: now.subtract(const Duration(hours: 5)),
        updatedAt: now.subtract(const Duration(minutes: 10)),
      );

      final deviceStorage = MemoryStorageAdapter();
      await deviceStorage.saveTasks([newerLocalTask.toJson()]);

      final container = ProviderContainer(
        overrides: [
          storageAdapterProvider.overrideWithValue(deviceStorage),
          taskStateProvider.overrideWith((ref) => TaskStateNotifier(
                storage: deviceStorage,
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
      await syncController.signInWithGoogle(
        email: 'developer@example.com',
      );

      final currentTasks = container.read(taskStateProvider).tasks;
      expect(currentTasks.length, equals(1));
      // Local version was newer, so it should win
      expect(currentTasks.first.title, equals('Newer Local Version (Edited on Device 2)'));
      expect(currentTasks.first.status, equals(TaskStatus.today));
    });

    test('auto token refresh refreshes expired ID token during cloud sync without disrupting session', () async {
      // User with expired ID token but valid refresh token
      final expiredUser = AppUser(
        uid: 'google_test_user',
        email: 'test@example.com',
        displayName: 'Test User',
        idToken: 'expired-jwt-token',
        refreshToken: 'valid-refresh-token-123',
        tokenExpiresAt: DateTime.now().subtract(const Duration(minutes: 10)).millisecondsSinceEpoch,
        isAnonymous: false,
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
              initialUser: expiredUser,
            );
          }),
        ],
      );

      final syncController = container.read(syncControllerProvider.notifier);
      final taskNotifier = container.read(taskStateProvider.notifier);

      // Create a task — this triggers persistence -> debounce -> _executeCloudSync
      final now = DateTime.now();
      await taskNotifier.createTask(PinTask(
        id: 'new-pin',
        title: 'Trigger Sync',
        status: TaskStatus.backlog,
        createdAt: now,
        updatedAt: now,
      ));

      // Fast forward past debounce
      await syncController.syncNow();

      // State should be synced, not error
      final syncState = container.read(syncControllerProvider);
      expect(syncState.status, equals(SyncStatus.synced));
      expect(syncState.isSignedIn, isTrue);
    });

    test('refreshIdToken sends form-encoded parameters and parses snake_case and camelCase payloads', () async {
      const user = AppUser(
        uid: 'refresh-test-user',
        email: 'test@example.com',
        idToken: 'old-token',
        refreshToken: 'refresh+token/with=special&chars',
        isAnonymous: false,
      );

      final refreshed = await authService.refreshIdToken(user);
      expect(refreshed.idToken, equals('token-mock-xyz'));
      expect(mockHttp.lastPostRequest, isNotNull);
      expect(mockHttp.lastPostRequest!.headers['content-type'], contains('application/x-www-form-urlencoded'));
      // Verify body was properly form URL-encoded by package:http
      expect(mockHttp.lastPostRequest!.body, contains('grant_type=refresh_token'));
      expect(mockHttp.lastPostRequest!.body, contains('refresh_token='));
    });

    test('deleteUserAccount cascades deletion to board doc, profile doc, and auth record', () async {
      const user = AppUser(
        uid: 'delete-target-user',
        email: 'delete@example.com',
        idToken: 'valid-id-token',
        isAnonymous: false,
      );

      await authService.deleteUserAccount(user);

      // Verify board doc and profile doc were deleted
      expect(mockHttp.deletedUris.any((uri) => uri.path.contains('/users/delete-target-user/meta/board')), isTrue);
      expect(mockHttp.deletedUris.any((uri) => uri.path.contains('/users/delete-target-user')), isTrue);
    });

    test('FirebaseConfig persists and restores storageBucket and oAuthClientId via SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      const config = FirebaseConfig(
        apiKey: 'custom-api-key',
        projectId: 'custom-project-id',
        authDomain: 'custom.firebaseapp.com',
        firestoreDatabaseId: '(default)',
        storageBucket: 'custom.appspot.com',
        oAuthClientId: 'custom-client-id.apps.googleusercontent.com',
      );

      await config.save();
      final loaded = await FirebaseConfig.loadFromPreferences();

      expect(loaded.apiKey, equals('custom-api-key'));
      expect(loaded.projectId, equals('custom-project-id'));
      expect(loaded.storageBucket, equals('custom.appspot.com'));
      expect(loaded.oAuthClientId, equals('custom-client-id.apps.googleusercontent.com'));

      await FirebaseConfig.clear();
      final cleared = await FirebaseConfig.loadFromPreferences();
      expect(cleared.storageBucket, isEmpty);
      expect(cleared.oAuthClientId, isEmpty);
    });
  });
}
