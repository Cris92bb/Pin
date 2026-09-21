import 'package:flutter_test/flutter_test.dart';
import 'package:pin/features/ai/services/local_heuristic_breakdown_service.dart';

void main() {
  const service = LocalHeuristicBreakdownService();

  test('LocalHeuristicBreakdownService decomposes coding task with deep-focus and steps', () {
    final result = service.decompose(
      prompt: 'Fix memory leak in method channel',
      currentDescription: 'Investigate native bridge lifecycle',
    );

    expect(result.title, 'Fix memory leak in method channel');
    expect(result.energyTag, 'deep-focus');
    expect(result.estimatedMinutes, 45);
    expect(result.tags, contains('#dev'));
    expect(result.atomicSteps.length, 4);
    expect(result.atomicSteps.first.title, contains('Reproduce context'));
  });

  test('LocalHeuristicBreakdownService decomposes design task with creative energy', () {
    final result = service.decompose(
      prompt: 'Design modern dark mode palette',
    );

    expect(result.energyTag, 'creative');
    expect(result.tags, contains('#design'));
    expect(result.atomicSteps.length, 3);
  });

  test('LocalHeuristicBreakdownService decomposes writing task', () {
    final result = service.decompose(
      prompt: 'Write release notes for v1.2',
    );

    expect(result.energyTag, 'creative');
    expect(result.tags, contains('#writing'));
    expect(result.atomicSteps.length, 3);
  });

  test('LocalHeuristicBreakdownService decomposes research task', () {
    final result = service.decompose(
      prompt: 'Research best practices for on-device AI',
    );

    expect(result.energyTag, 'deep-focus');
    expect(result.tags, contains('#research'));
    expect(result.atomicSteps.length, 3);
  });

  test('LocalHeuristicBreakdownService decomposes administrative task', () {
    final result = service.decompose(
      prompt: 'Schedule quarterly planning meeting',
    );

    expect(result.energyTag, 'administrative');
    expect(result.tags, contains('#admin'));
    expect(result.atomicSteps.length, 3);
  });

  test('LocalHeuristicBreakdownService decomposes generic task', () {
    final result = service.decompose(
      prompt: 'Organize personal bookshelf and files',
    );

    expect(result.atomicSteps.isNotEmpty, isTrue);
    expect(result.atomicSteps.every((s) => !s.isCompleted), isTrue);
  });
}
