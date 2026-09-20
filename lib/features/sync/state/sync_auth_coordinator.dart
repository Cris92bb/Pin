import 'dart:async';
import '../model/app_user.dart';
import '../model/sync_status.dart';
import '../services/google_sso_service.dart';
import '../services/watch_auth_bridge.dart';
import 'sync_controller.dart';

/// Extension encapsulating Firebase and Watch authentication workflows for [SyncController].
extension SyncAuthCoordinator on SyncController {
  /// Signs in using cross-device credentials received from companion phone.
  Future<bool> signInWithCrossDeviceCredentials(AppUser user) async {
    state = state.copyWith(status: SyncStatus.syncing, clearError: true);
    try {
      await onUserAuthenticated(user);
      return true;
    } catch (e) {
      state = state.copyWith(status: SyncStatus.error, errorMessage: formatError(e));
      return false;
    }
  }

  /// Requests companion phone to authenticate or provide existing session.
  Future<PhoneAuthRequestResult> signInWithCompanionPhone({
    Duration timeout = const Duration(seconds: 45),
  }) async {
    state = state.copyWith(status: SyncStatus.syncing, clearError: true);
    final bridge = WatchAuthBridge();
    final result = await bridge.requestPhoneAuth(timeout: timeout);
    if (result.success && result.user != null) {
      await onUserAuthenticated(result.user!);
      return result;
    } else {
      state = state.copyWith(
        status: state.user != null ? SyncStatus.synced : SyncStatus.guest,
        errorMessage: result.errorMessage != null ? formatError(result.errorMessage!) : null,
      );
      return result;
    }
  }

  /// Signs in with email and password.
  Future<bool> signInWithEmail(String email, String password, {String? twoFactorCode}) async {
    if (!guardConfigLoaded()) return false;
    state = state.copyWith(status: SyncStatus.syncing, clearError: true);
    try {
      final user = await authService.signInWithEmail(email, password, twoFactorCode: twoFactorCode);
      await onUserAuthenticated(user);
      return true;
    } catch (e) {
      state = state.copyWith(status: SyncStatus.error, errorMessage: formatError(e));
      return false;
    }
  }

  /// Signs up with email and password.
  Future<bool> signUpWithEmail(
    String email,
    String password, {
    String? displayName,
    String? twoFactorCode,
  }) async {
    if (!guardConfigLoaded()) return false;
    state = state.copyWith(status: SyncStatus.syncing, clearError: true);
    try {
      final user = await authService.signUpWithEmail(
        email,
        password,
        displayName: displayName,
        twoFactorCode: twoFactorCode,
      );
      await onUserAuthenticated(user);
      return true;
    } catch (e) {
      state = state.copyWith(status: SyncStatus.error, errorMessage: formatError(e));
      return false;
    }
  }

  /// Cancels in-flight Google SSO operation.
  void cancelGoogleSso() {
    activeSsoService?.cancel();
    activeSsoService = null;
    state = state.copyWith(
      status: state.user != null ? SyncStatus.synced : SyncStatus.guest,
      clearError: true,
    );
  }

  /// Real Google SSO authentication via direct Google OAuth consent screen.
  Future<bool> signInWithGoogleSso() async {
    if (!guardConfigLoaded()) return false;
    state = state.copyWith(status: SyncStatus.syncing, clearError: true);
    try {
      final ssoService = GoogleSsoService();
      activeSsoService = ssoService;
      final result = await ssoService.signIn(
        clientId: state.config.oAuthClientId,
        clientSecret: state.config.oAuthClientSecret,
      );
      activeSsoService = null;
      if (result.isCancelled) {
        state = state.copyWith(
          status: state.user != null ? SyncStatus.synced : SyncStatus.guest,
          clearError: true,
        );
        return false;
      }
      if (!result.isSuccess) {
        state = state.copyWith(
          status: SyncStatus.error,
          errorMessage: result.errorMessage != null ? formatError(result.errorMessage!) : 'Google SSO failed.',
        );
        return false;
      }
      final user = await authService.signInWithGoogleSso(
        idToken: result.idToken,
        accessToken: result.accessToken,
      );
      await onUserAuthenticated(user);
      return true;
    } catch (e) {
      activeSsoService = null;
      state = state.copyWith(status: SyncStatus.error, errorMessage: formatError(e));
      return false;
    }
  }

  /// 1-Click Google Sign-In.
  Future<bool> signInWithGoogle({String? email, String? displayName, String? idToken}) async {
    if (!guardConfigLoaded()) return false;
    state = state.copyWith(status: SyncStatus.syncing, clearError: true);
    try {
      final user = await authService.signInWithGoogle(
        googleEmail: email,
        displayName: displayName,
        idToken: idToken,
      );
      await onUserAuthenticated(user);
      return true;
    } catch (e) {
      state = state.copyWith(status: SyncStatus.error, errorMessage: formatError(e));
      return false;
    }
  }

  /// Anonymous guest sign in.
  Future<bool> signInAnonymously() async {
    if (!state.config.isConfigured) {
      final mockUser = AppUser(
        uid: 'demo-guest-${DateTime.now().millisecondsSinceEpoch}',
        displayName: 'Guest Explorer',
        isAnonymous: true,
      );
      state = state.copyWith(
        user: mockUser,
        status: SyncStatus.synced,
        lastSyncedAt: DateTime.now().millisecondsSinceEpoch,
      );
      return true;
    }

    state = state.copyWith(status: SyncStatus.syncing, clearError: true);
    try {
      final user = await authService.signInAnonymously();
      await onUserAuthenticated(user);
      return true;
    } catch (e) {
      state = state.copyWith(status: SyncStatus.error, errorMessage: formatError(e));
      return false;
    }
  }

  /// Signs out user and switches back to guest mode.
  Future<void> signOut() async {
    cancelDebounce();
    stopPeriodicSync();
    await authService.signOut();
    state = state.copyWith(clearUser: true, status: SyncStatus.guest, clearError: true);
  }

  /// Updates display name across session and cloud.
  Future<void> updateDisplayName(String newName) async {
    final user = state.user;
    if (user == null) return;
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    final updated = user.copyWith(displayName: trimmed);
    await authService.updateUserProfile(updated);
    state = state.copyWith(user: updated);
  }

  /// Deletes user board from Firestore, user profile, and auth account.
  Future<bool> deleteAccountAndCloudData() async {
    final user = state.user;
    if (user == null) return false;

    state = state.copyWith(status: SyncStatus.syncing);
    try {
      stopPeriodicSync();
      await firestoreService.deleteBoard(userId: user.uid, idToken: user.idToken);
      await authService.deleteUserAccount(user);
      state = state.copyWith(
        clearUser: true,
        status: SyncStatus.guest,
        syncedTaskCount: 0,
        lastSyncedAt: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: 'Failed to delete account data: ${e.toString()}',
      );
      return false;
    }
  }

  /// Guards against triggering authentication before configuration credentials are loaded.
  bool guardConfigLoaded() {
    if (state.configLoaded || state.config.isConfigured) return true;
    state = state.copyWith(
      errorMessage: 'Connecting to Firebase… please try again in a moment.',
    );
    return false;
  }

  /// Formats raw exception objects into user-friendly error strings.
  String formatError(Object e) {
    final str = e.toString().replaceAll('Exception: ', '');
    if (str.contains('Failed host lookup') ||
        str.contains('SocketException') ||
        str.contains('ClientException')) {
      return 'Network connection error. Please verify your device has an active internet connection and try again.';
    }
    return str;
  }
}

