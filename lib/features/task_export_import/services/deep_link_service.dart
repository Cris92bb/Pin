import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../../../entities/task/model/pin_task.dart';
import 'package:pin/shared/lib/blueprint_codec.dart';

/// Service responsible for generating and handling cross-platform deep links
/// to share and import Pin tasks seamlessly.
///
/// Supported URI patterns:
/// - `pin://import?blueprint=PIN_BP_...`
/// - `https://pin.app/#/import?blueprint=PIN_BP_...` (Web universal link)
class DeepLinkService {
  static const String customScheme = 'pin';
  static const String defaultHost = 'import';
  static const String channelName = 'com.example.pin/deep_link';

  static final DeepLinkService instance = DeepLinkService._internal();

  DeepLinkService._internal();

  factory DeepLinkService({MethodChannel? channel}) {
    if (channel != null) {
      instance._channel = channel;
    }
    return instance;
  }

  MethodChannel _channel = const MethodChannel(channelName);
  void Function(Uri uri)? _onLinkReceived;
  bool _isInitialized = false;

  /// Visible for testing to override the platform channel.
  @visibleForTesting
  set channel(MethodChannel ch) => _channel = ch;

  /// Generates a deep link string for a single pin task.
  static String generateShareLink(PinTask task) {
    final blueprint = BlueprintCodec.encodeSingleTask(task.toJson());
    return '$customScheme://$defaultHost?blueprint=$blueprint';
  }

  /// Generates a deep link string for an entire collection of tasks.
  static String generateBoardShareLink(List<PinTask> tasks) {
    final taskJsonList = tasks.map((t) => t.toJson()).toList();
    final blueprint = BlueprintCodec.encodeTasks(taskJsonList);
    return '$customScheme://$defaultHost?blueprint=$blueprint';
  }

  /// Parses a deep link URI and returns the contained [PinTask] list.
  ///
  /// Extracts the `blueprint` query parameter and decodes it via [BlueprintCodec].
  /// Returns an empty list if the URI does not contain a valid blueprint.
  static List<PinTask> parseSharedTasks(Uri uri) {
    String? blueprint = uri.queryParameters['blueprint'];

    // Fallback: check fragment query params for web hashes (e.g. /#/import?blueprint=...)
    if (blueprint == null && uri.fragment.isNotEmpty) {
      final fragmentUri = Uri.tryParse(uri.fragment);
      blueprint = fragmentUri?.queryParameters['blueprint'];
    }

    if (blueprint == null || blueprint.trim().isEmpty) {
      return const [];
    }

    final result = BlueprintCodec.decode(blueprint);
    if (!result.isSuccess || result.tasks.isEmpty) {
      return const [];
    }

    final tasks = <PinTask>[];
    for (final json in result.tasks) {
      try {
        tasks.add(PinTask.fromJson(json));
      } catch (_) {
        // Skip malformed individual tasks gracefully
      }
    }
    return tasks;
  }

  /// Initializes deep link listening from the native host and web environment.
  Future<void> init({
    required void Function(Uri uri) onLinkReceived,
    Uri? webUriOverride,
  }) async {
    _onLinkReceived = onLinkReceived;
    if (_isInitialized) return;
    _isInitialized = true;

    // 1. Listen for runtime incoming deep links via platform channel
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onLinkReceived') {
        final linkStr = call.arguments as String?;
        if (linkStr != null && linkStr.isNotEmpty) {
          final uri = Uri.tryParse(linkStr);
          if (uri != null) {
            _onLinkReceived?.call(uri);
          }
        }
      }
    });

    // 2. Check initial launch deep link (cold start)
    try {
      final initialLink = await _channel.invokeMethod<String>('getInitialLink');
      if (initialLink != null && initialLink.isNotEmpty) {
        final uri = Uri.tryParse(initialLink);
        if (uri != null) {
          _onLinkReceived?.call(uri);
        }
      }
    } catch (_) {
      // Platform channels not supported on pure desktop/test runtimes
    }

    // 3. Check web URL query parameters upon launch
    if (kIsWeb || webUriOverride != null) {
      final baseUri = webUriOverride ?? Uri.base;
      if (baseUri.queryParameters.containsKey('blueprint') ||
          (baseUri.fragment.isNotEmpty && baseUri.fragment.contains('blueprint='))) {
        _onLinkReceived?.call(baseUri);
      }
    }
  }

  /// Disposes active listeners and resets initialization flag.
  void dispose() {
    _channel.setMethodCallHandler(null);
    _onLinkReceived = null;
    _isInitialized = false;
  }
}
