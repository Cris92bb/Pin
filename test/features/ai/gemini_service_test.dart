import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pin/features/ai/services/ai_config_service.dart';
import 'package:pin/features/ai/services/gemini_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockHttpClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest request) handler;
  MockHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request);
    final bytes = utf8.encode(response.body);
    return http.StreamedResponse(
      Stream.value(bytes),
      response.statusCode,
      headers: response.headers,
    );
  }
}

void main() {
  group('AiConfigNotifier Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initial state has empty key and default model', () async {
      final prefs = await SharedPreferences.getInstance();
      final notifier = AiConfigNotifier(prefs);

      expect(notifier.state.hasKey, isFalse);
      expect(notifier.state.apiKey, isEmpty);
      expect(notifier.state.selectedModel, 'gemini-3.6-flash');
    });

    test('setApiKey updates state and persists', () async {
      final prefs = await SharedPreferences.getInstance();
      final notifier = AiConfigNotifier(prefs);

      await notifier.setApiKey('AIzaSyTestKey123');
      expect(notifier.state.hasKey, isTrue);
      expect(notifier.state.apiKey, 'AIzaSyTestKey123');
      expect(prefs.getString(AiConfigNotifier.keyPref), 'AIzaSyTestKey123');

      await notifier.clearApiKey();
      expect(notifier.state.hasKey, isFalse);
      expect(prefs.getString(AiConfigNotifier.keyPref), isNull);
    });

    test('setModel updates model selection', () async {
      final prefs = await SharedPreferences.getInstance();
      final notifier = AiConfigNotifier(prefs);

      await notifier.setModel('gemini-3.5-flash');
      expect(notifier.state.selectedModel, 'gemini-3.5-flash');
      expect(prefs.getString(AiConfigNotifier.modelPref), 'gemini-3.5-flash');
    });
  });

  group('GeminiService Tests', () {
    test('testConnection returns true on HTTP 200', () async {
      final client = MockHttpClient((request) async {
        expect(request.url.queryParameters['key'], 'valid-key');
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': '{"status": "ok"}'}
                  ]
                }
              }
            ]
          }),
          200,
        );
      });

      final service = GeminiService(client: client);
      final result = await service.testConnection('valid-key');
      expect(result, isTrue);
    });

    test('testConnection throws GeminiApiException on 401 invalid key', () async {
      final client = MockHttpClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {
              'code': 401,
              'message': 'API_KEY_INVALID: API key not valid',
            }
          }),
          401,
        );
      });

      final service = GeminiService(client: client);
      expect(
        () => service.testConnection('bad-key'),
        throwsA(isA<GeminiApiException>().having(
          (e) => e.message,
          'message',
          contains('Invalid Gemini API key'),
        )),
      );
    });

    test('suggestTaskBreakdown parses structured response and clamps atomic steps to <= 15 min', () async {
      final client = MockHttpClient((request) async {
        final samplePayload = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': jsonEncode({
                      'title': 'Implement OAuth2 Authentication Flow',
                      'description': 'Configure OAuth2 tokens and integrate provider.',
                      'energyTag': 'deep-focus',
                      'estimatedMinutes': 45,
                      'tags': ['dev', '#security', 'oauth'],
                      'atomicSteps': [
                        {'title': 'Register client ID and secret', 'estimatedMinutes': 10},
                        {'title': 'Setup token storage adapter', 'estimatedMinutes': 15},
                        // Intentionally over 15 minutes to verify automatic clamping
                        {'title': 'Write unit tests for refresh token', 'estimatedMinutes': 30},
                      ],
                    })
                  }
                ]
              }
            }
          ]
        };

        return http.Response(jsonEncode(samplePayload), 200);
      });

      final service = GeminiService(client: client);
      final result = await service.suggestTaskBreakdown(
        apiKey: 'test-key',
        prompt: 'OAuth2 login',
      );

      expect(result.title, 'Implement OAuth2 Authentication Flow');
      expect(result.description, contains('Configure OAuth2 tokens'));
      expect(result.energyTag, 'deep-focus');
      expect(result.estimatedMinutes, 45);
      expect(result.tags, containsAll(['#dev', '#security', '#oauth']));

      expect(result.atomicSteps.length, 3);
      expect(result.atomicSteps[0].title, 'Register client ID and secret');
      expect(result.atomicSteps[0].estimatedMinutes, 10);
      expect(result.atomicSteps[1].estimatedMinutes, 15);
      // Clamped to 15!
      expect(result.atomicSteps[2].estimatedMinutes, 15);
    });

    test('suggestTaskBreakdown throws when prompt is empty', () async {
      final service = GeminiService();
      expect(
        () => service.suggestTaskBreakdown(apiKey: 'key', prompt: '   '),
        throwsA(isA<GeminiApiException>().having(
          (e) => e.message,
          'message',
          contains('Please enter a task title'),
        )),
      );
    });

    test('suggestTaskBreakdown handles quota exceeded (HTTP 429)', () async {
      final client = MockHttpClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {
              'code': 429,
              'message': 'Resource has been exhausted (e.g. check quota).',
            }
          }),
          429,
        );
      });

      final service = GeminiService(client: client);
      expect(
        () => service.suggestTaskBreakdown(apiKey: 'key', prompt: 'Fix memory leak'),
        throwsA(isA<GeminiApiException>().having(
          (e) => e.message,
          'message',
          contains('quota exceeded'),
        )),
      );
    });
  });
}
