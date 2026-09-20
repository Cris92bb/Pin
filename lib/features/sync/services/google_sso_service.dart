import 'package:http/http.dart' as http;
import 'google_sso_result.dart';
import 'platform/google_sso_runner.dart';
import 'platform/google_sso_runner_stub.dart'
    if (dart.library.io) 'platform/google_sso_runner_io.dart'
    if (dart.library.js_interop) 'platform/google_sso_runner_web.dart';

export 'google_sso_result.dart';

/// Single Sign-On (SSO) service for authenticating with Google accounts
/// across native desktop (RFC 8252 loopback) and web (Google Identity Services).
class GoogleSsoService {
  final GoogleSsoPlatformRunner _runner;

  /// Creates a [GoogleSsoService] instance.
  ///
  /// Optionally accepts a custom [http.Client] or a mock [GoogleSsoPlatformRunner].
  GoogleSsoService({
    http.Client? httpClient,
    GoogleSsoPlatformRunner? runner,
  }) : _runner = runner ?? createPlatformRunner(httpClient: httpClient);

  /// Launches the Google SSO authentication workflow.
  ///
  /// On Desktop, starts a loopback HTTP listener and opens Google's OAuth consent
  /// screen in the system browser.
  /// On Web, initiates Google Identity Services (GIS) authorization popup.
  Future<GoogleSsoResult> signIn({
    required String clientId,
    String? clientSecret,
    Duration timeout = const Duration(minutes: 3),
  }) {
    return _runner.signIn(
      clientId: clientId,
      clientSecret: clientSecret,
      timeout: timeout,
    );
  }

  /// Cancels in-flight sign-in operation and cleans up active resources.
  void cancel() {
    _runner.cancel();
  }
}
