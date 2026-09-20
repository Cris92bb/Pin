import 'package:http/http.dart' as http;
import '../google_sso_result.dart';

/// Contract for platform-specific Google SSO runners (desktop loopback, web popup).
abstract class GoogleSsoPlatformRunner {
  /// Initiates Google SSO authorization on the active platform.
  Future<GoogleSsoResult> signIn({
    required String clientId,
    String? clientSecret,
    Duration timeout = const Duration(minutes: 3),
  });

  /// Cancels in-flight Google SSO operation and releases underlying resources.
  void cancel();
}

/// Type signature for factory instantiation of a [GoogleSsoPlatformRunner].
typedef PlatformRunnerFactory = GoogleSsoPlatformRunner Function({
  http.Client? httpClient,
});
