import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_auth_service.dart';
import '../services/firebase_config.dart';
import '../services/firestore_sync_service.dart';
import 'sync_controller.dart';

/// Loads persisted FirebaseConfig asynchronously from SharedPreferences.
final firebaseConfigProvider = FutureProvider<FirebaseConfig>((ref) async {
  return await FirebaseConfig.load();
});

/// Supplies FirebaseAuthService with active Firebase credentials.
final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  final config = ref.watch(syncControllerProvider.select((s) => s.config));
  return FirebaseAuthService(config: config);
});

/// Supplies FirestoreSyncService with active Firebase credentials.
final firestoreSyncServiceProvider = Provider<FirestoreSyncService>((ref) {
  final config = ref.watch(syncControllerProvider.select((s) => s.config));
  return FirestoreSyncService(config: config);
});

/// Main SyncController provider governing synchronization and cloud auth.
final syncControllerProvider =
    NotifierProvider<SyncController, SyncState>(SyncController.new);
