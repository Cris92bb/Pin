import 'package:http/http.dart' as http;
import 'google_sso_runner.dart';

/// Platform runner factory for unsupported execution environments.
GoogleSsoPlatformRunner createPlatformRunner({http.Client? httpClient}) {
  throw UnsupportedError(
    'Google SSO is not supported on this platform runtime.',
  );
}
