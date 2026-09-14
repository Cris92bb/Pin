import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Feature-Sliced Design (FSD v2.1) Architecture Boundary Audit', () {
    const layerHierarchy = {
      'app': 1,
      'pages': 2,
      'widgets': 3,
      'features': 4,
      'entities': 5,
      'shared': 6,
    };

    final importRegex = RegExp(r'''^\s*import\s+['"]([^'"]+)['"]''');

    (String?, String?) parseLayerAndSlice(String path) {
      final normalized = path.replaceAll(r'\', '/');
      final parts = normalized.split('/');
      final libIndex = parts.indexOf('lib');
      if (libIndex == -1 || libIndex + 1 >= parts.length) {
        return (null, null);
      }

      final layer = parts[libIndex + 1];
      String? slice;
      if (libIndex + 2 < parts.length && !parts[libIndex + 2].endsWith('.dart')) {
        slice = parts[libIndex + 2];
      }
      return (layer, slice);
    }

    String? resolveImport(File sourceFile, String uri) {
      if (uri.startsWith('dart:')) return null;
      if (uri.startsWith('package:')) {
        if (!uri.startsWith('package:pin/')) return null;
        return 'lib/${uri.substring('package:pin/'.length)}';
      }

      final sourceDir = sourceFile.parent;
      final targetFile = File('${sourceDir.path}/$uri');
      final normalized = targetFile.uri.normalizePath().toFilePath();
      final projectRoot = Directory.current.path;
      if (normalized.startsWith(projectRoot)) {
        return normalized.substring(projectRoot.length + 1).replaceAll(r'\', '/');
      }
      return normalized.replaceAll(r'\', '/');
    }

    test('verifies architectural breaches do not exceed documented baseline', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue, reason: 'lib/ directory must exist');

      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();

      final upwardViolations = <String>[];
      final crossSliceViolations = <String>[];

      for (final file in dartFiles) {
        final relSourcePath = file.path.replaceAll(r'\', '/');
        final (sourceLayer, sourceSlice) = parseLayerAndSlice(relSourcePath);
        if (sourceLayer == null || !layerHierarchy.containsKey(sourceLayer)) {
          continue;
        }

        final lines = file.readAsLinesSync();
        for (int i = 0; i < lines.length; i++) {
          final match = importRegex.firstMatch(lines[i]);
          if (match == null) continue;

          final importUri = match.group(1)!;
          final targetResolvedPath = resolveImport(file, importUri);
          if (targetResolvedPath == null) continue;

          final (targetLayer, targetSlice) =
              parseLayerAndSlice(targetResolvedPath);
          if (targetLayer == null || !layerHierarchy.containsKey(targetLayer)) {
            continue;
          }

          final sourceRank = layerHierarchy[sourceLayer]!;
          final targetRank = layerHierarchy[targetLayer]!;

          if (sourceRank > targetRank) {
            upwardViolations.add(
              '$relSourcePath:${i + 1} ($sourceLayer -> $targetLayer via $importUri)',
            );
          } else if (sourceLayer == targetLayer &&
              sourceSlice != null &&
              targetSlice != null &&
              sourceSlice != targetSlice) {
            crossSliceViolations.add(
              '$relSourcePath:${i + 1} (slice $sourceSlice -> $targetSlice via $importUri)',
            );
          }
        }
      }

      // Documented baseline of legacy breaches from Phase 1 audit:
      // Upward: lib/shared/ui/pin_breakpoints.dart -> features/wearable/wearable_utils.dart
      const expectedUpwardBreaches = 1;
      // Cross-slice: wearable->sync (2), ai->task_crud (1), task_crud->ai (3),
      // focus_mode->ai/task_crud (3), task->atomic_step (2)
      const expectedCrossSliceBreaches = 11;

      expect(
        upwardViolations.length,
        lessThanOrEqualTo(expectedUpwardBreaches),
        reason: 'New upward layer inversions were introduced!\n${upwardViolations.join('\n')}',
      );

      expect(
        crossSliceViolations.length,
        lessThanOrEqualTo(expectedCrossSliceBreaches),
        reason: 'New cross-slice couplings were introduced!\n${crossSliceViolations.join('\n')}',
      );
    });

    test('shared layer must never import from higher layers (excluding baseline)', () {
      final sharedDir = Directory('lib/shared');
      if (!sharedDir.existsSync()) return;

      final sharedFiles = sharedDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();

      final forbiddenImports = <String>[];

      for (final file in sharedFiles) {
        final relSourcePath = file.path.replaceAll(r'\', '/');
        // Known legacy violation: pin_breakpoints.dart imports wearable_utils.dart
        if (relSourcePath.endsWith('pin_breakpoints.dart')) continue;

        final lines = file.readAsLinesSync();
        for (int i = 0; i < lines.length; i++) {
          final match = importRegex.firstMatch(lines[i]);
          if (match == null) continue;
          final importUri = match.group(1)!;
          final resolved = resolveImport(file, importUri);
          if (resolved == null) continue;

          final (layer, _) = parseLayerAndSlice(resolved);
          if (layer != null && layer != 'shared') {
            forbiddenImports.add('$relSourcePath:${i + 1} imports $importUri');
          }
        }
      }

      expect(
        forbiddenImports,
        isEmpty,
        reason: 'Clean files in shared must not import from higher layers:\n${forbiddenImports.join('\n')}',
      );
    });
  });
}
