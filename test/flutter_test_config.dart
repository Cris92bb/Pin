import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global test configuration hook for Pin test suite.
///
/// Ensures mock initial values are configured for SharedPreferences so that
/// unit and widget tests never read host machine credentials or session data.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  await testMain();
}
