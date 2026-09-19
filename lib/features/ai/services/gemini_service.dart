import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../../../entities/task/model/atomic_step.dart';
import '../../../entities/task/model/pin_task.dart';

class GeminiApiException implements Exception {
  final String message;
  final int? statusCode;

  const GeminiApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class AiTaskBreakdown {
  final String title;
  final String description;
  final TaskStatus status;
  final String energyTag;
  final int estimatedMinutes;
  final List<String> tags;
  final List<AtomicStep> atomicSteps;

  const AiTaskBreakdown({
    required this.title,
    required this.description,
    this.status = TaskStatus.today,
    required this.energyTag,
    required this.estimatedMinutes,
    required this.tags,
    required this.atomicSteps,
  });
}

class GeminiService {
  final http.Client _client;

  GeminiService({http.Client? client}) : _client = client ?? http.Client();

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  static const List<String> validEnergyTags = [
    'low-friction',
    'medium-flow',
    'deep-focus',
    'creative',
    'administrative',
  ];

  static const List<int> validEstimateOptions = [5, 15, 30, 45, 60, 120];

  /// Tests whether the provided Gemini API key and model are valid.
  Future<bool> testConnection(
    String apiKey, {
    String model = 'gemini-3.6-flash',
  }) async {
    final key = apiKey.trim();
    if (key.isEmpty) {
      throw const GeminiApiException('API key cannot be empty');
    }

    final resolvedModel = (model == 'gemini-2.5-flash' ||
            model == 'gemini-1.5-flash' ||
            model == 'gemini-2.0-flash' ||
            model.trim().isEmpty)
        ? 'gemini-3.6-flash'
        : model.trim();

    final url = Uri.parse('$_baseUrl/$resolvedModel:generateContent?key=$key');
    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': 'Ping. Reply with {"status": "ok"}'}
              ]
            }
          ],
          'generationConfig': {
            'responseMimeType': 'application/json',
          }
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return true;
      }

      final errorMsg = _extractErrorMessage(response);
      throw GeminiApiException(errorMsg, response.statusCode);
    } catch (e) {
      if (e is GeminiApiException) rethrow;
      throw GeminiApiException('Connection failed: ${e.toString()}');
    }
  }

  /// Suggests a task breakdown and sets pin properties via Gemini structured output.
  Future<AiTaskBreakdown> suggestTaskBreakdown({
    required String apiKey,
    required String prompt,
    String? currentDescription,
    String model = 'gemini-3.6-flash',
  }) async {
    final key = apiKey.trim();
    if (key.isEmpty) {
      throw const GeminiApiException('Gemini API key is required');
    }

    final cleanPrompt = prompt.trim();
    if (cleanPrompt.isEmpty) {
      throw const GeminiApiException('Please enter a task title or description to analyze');
    }

    final resolvedModel = (model == 'gemini-2.5-flash' ||
            model == 'gemini-1.5-flash' ||
            model == 'gemini-2.0-flash' ||
            model.trim().isEmpty)
        ? 'gemini-3.6-flash'
        : model.trim();

    final url = Uri.parse('$_baseUrl/$resolvedModel:generateContent?key=$key');

    const systemInstruction =
        'You are an expert productivity companion for Pin, a minimalist desktop Kanban app. '
        'Your job is to analyze the user\'s task prompt, refine the title to be crisp and actionable, '
        'generate a clear concise objective description, assess appropriate energy level and duration, '
        'suggest 1-4 relevant hashtags (#dev, #design, #bug, #docs, etc.), and break down the task '
        'into 2-6 bite-sized atomic subtasks. '
        'CRITICAL RULE: Each atomic step must take 15 minutes or less (estimatedMinutes <= 15).';

    final requestBody = {
      'contents': [
        {
          'parts': [
            {
              'text': '$systemInstruction\n\n'
                  'TASK INPUT: $cleanPrompt\n'
                  'EXISTING DETAILS: ${currentDescription?.trim() ?? "None"}'
            }
          ]
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'responseSchema': {
          'type': 'OBJECT',
          'properties': {
            'title': {
              'type': 'STRING',
              'description': 'Refined, actionable task title',
            },
            'description': {
              'type': 'STRING',
              'description': 'Short objective explaining the scope and definition of done',
            },
            'energyTag': {
              'type': 'STRING',
              'enum': validEnergyTags,
              'description': 'Cognitive energy profile required',
            },
            'estimatedMinutes': {
              'type': 'INTEGER',
              'description': 'Estimated total task duration in minutes',
            },
            'tags': {
              'type': 'ARRAY',
              'items': {'type': 'STRING'},
              'description': 'Tags prefixed with # (e.g. #dev, #ui, #fix)',
            },
            'atomicSteps': {
              'type': 'ARRAY',
              'items': {
                'type': 'OBJECT',
                'properties': {
                  'title': {
                    'type': 'STRING',
                    'description': 'Action-oriented micro step',
                  },
                  'estimatedMinutes': {
                    'type': 'INTEGER',
                    'description': 'Estimated minutes (maximum 15)',
                  },
                },
                'required': ['title', 'estimatedMinutes'],
              },
              'description': 'Atomic breakdown steps, each <= 15 minutes',
            },
          },
          'required': [
            'title',
            'energyTag',
            'estimatedMinutes',
            'atomicSteps',
          ],
        },
      },
    };

    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode != 200) {
        final errorMsg = _extractErrorMessage(response);
        throw GeminiApiException(errorMsg, response.statusCode);
      }

      final dynamic decoded = jsonDecode(response.body);
      final candidates = decoded['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw const GeminiApiException('Gemini returned an empty response');
      }

      final firstCandidate = candidates.first as Map<String, dynamic>;
      final content = firstCandidate['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        throw const GeminiApiException('No content parts returned by Gemini');
      }

      final text = parts.first['text'] as String?;
      if (text == null || text.trim().isEmpty) {
        throw const GeminiApiException('No text output in Gemini response');
      }

      final Map<String, dynamic> jsonResult = jsonDecode(text);
      return _parseBreakdownResult(jsonResult, cleanPrompt);
    } catch (e) {
      if (e is GeminiApiException) rethrow;
      throw GeminiApiException('Failed to analyze task with Gemini: ${e.toString()}');
    }
  }

  AiTaskBreakdown _parseBreakdownResult(
    Map<String, dynamic> data,
    String fallbackTitle,
  ) {
    final title = (data['title'] as String?)?.trim().isNotEmpty == true
        ? (data['title'] as String).trim()
        : fallbackTitle;

    final description = (data['description'] as String?)?.trim() ?? '';

    String energyTag = (data['energyTag'] as String?)?.toLowerCase().trim() ?? 'medium-flow';
    if (!validEnergyTags.contains(energyTag)) {
      energyTag = 'medium-flow';
    }

    final rawMinutes = (data['estimatedMinutes'] as num?)?.toInt() ?? 30;
    // Map to the closest valid option in Pin's standard presets
    final estimatedMinutes = validEstimateOptions.reduce(
      (curr, next) => (curr - rawMinutes).abs() < (next - rawMinutes).abs() ? curr : next,
    );

    // Tags
    final rawTags = data['tags'];
    final List<String> tags = [];
    if (rawTags is List) {
      for (final t in rawTags) {
        if (t is String && t.trim().isNotEmpty) {
          final clean = t.trim().startsWith('#') ? t.trim() : '#${t.trim()}';
          if (!tags.contains(clean)) {
            tags.add(clean);
          }
        }
      }
    }
    if (tags.isEmpty) {
      tags.add('#dev');
    }

    // Atomic steps
    final rawSteps = data['atomicSteps'];
    final List<AtomicStep> atomicSteps = [];
    if (rawSteps is List) {
      int stepIdx = 0;
      for (final s in rawSteps) {
        if (s is Map<String, dynamic>) {
          final stepTitle = (s['title'] as String?)?.trim() ?? '';
          if (stepTitle.isEmpty) continue;

          final rawStepMin = (s['estimatedMinutes'] as num?)?.toInt() ?? 10;
          // Constrain strictly to <= 15 minutes as asserted by AtomicStep
          final clampedMinutes = max(1, min(15, rawStepMin));

          atomicSteps.add(
            AtomicStep(
              id: 'ai_step_${DateTime.now().millisecondsSinceEpoch}_${stepIdx++}',
              title: stepTitle,
              estimatedMinutes: clampedMinutes,
              isCompleted: false,
            ),
          );
        }
      }
    }

    return AiTaskBreakdown(
      title: title,
      description: description,
      status: TaskStatus.today,
      energyTag: energyTag,
      estimatedMinutes: estimatedMinutes,
      tags: tags,
      atomicSteps: atomicSteps,
    );
  }

  String _extractErrorMessage(http.Response response) {
    try {
      final dynamic body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body['error'] != null) {
        final error = body['error'];
        if (error is Map && error['message'] != null) {
          final msg = error['message'] as String;
          if (msg.contains('API_KEY_INVALID') || msg.contains('API key not valid')) {
            return 'Invalid Gemini API key. Please verify in AI Settings.';
          }
          if (msg.contains('Resource has been exhausted') || response.statusCode == 429) {
            return 'Gemini API quota exceeded. Please wait a moment or check your limits.';
          }
          return msg;
        }
      }
    } catch (_) {}

    switch (response.statusCode) {
      case 400:
        return 'Invalid request to Gemini API (HTTP 400).';
      case 401:
      case 403:
        return 'Authentication failed. Please verify your Gemini API key.';
      case 429:
        return 'Rate limit reached. Please try again shortly.';
      case 500:
      case 503:
        return 'Gemini API server is temporarily unavailable.';
      default:
        return 'Gemini API error (HTTP ${response.statusCode}).';
    }
  }
}
