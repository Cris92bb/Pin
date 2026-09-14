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

      // Strict zero-tolerance FSD baseline:
      expect(
        upwardViolations,
        isEmpty,
        reason: 'Upward layer inversions detected!\n${upwardViolations.join('\n')}',
      );

      expect(
        crossSliceViolations,
        isEmpty,
        reason: 'Cross-slice couplings detected!\n${crossSliceViolations.join('\n')}',
      );
    });

    test('shared layer must never import from higher layers', () {
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
