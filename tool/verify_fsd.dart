import 'dart:io';

/// Feature-Sliced Design (FSD v2.1) Architecture Validator for Pin.
///
/// Usage:
///   dart run tool/verify_fsd.dart [--strict]
///
/// If run with `--strict`, any architectural violation causes an exit code 1.
/// Default mode validates against the known legacy baseline to prevent any new regressions.

const Map<String, int> layerHierarchy = {
  'app': 1,
  'pages': 2,
  'widgets': 3,
  'features': 4,
  'entities': 5,
  'shared': 6,
};

class FsdViolation {
  final String file;
  final int line;
  final String importUri;
  final String sourceLayer;
  final String? sourceSlice;
  final String targetLayer;
  final String? targetSlice;
  final String violationType;
  final String description;

  const FsdViolation({
    required this.file,
    required this.line,
    required this.importUri,
    required this.sourceLayer,
    required this.sourceSlice,
    required this.targetLayer,
    required this.targetSlice,
    required this.violationType,
    required this.description,
  });

  @override
  String toString() {
    return '[$violationType] $file:$line\n'
        '  Source: $sourceLayer${sourceSlice != null ? '/$sourceSlice' : ''}\n'
        '  Target: $targetLayer${targetSlice != null ? '/$targetSlice' : ''} ($importUri)\n'
        '  Reason: $description';
  }
}

class FsdAuditResult {
  final List<FsdViolation> upwardViolations;
  final List<FsdViolation> crossSliceViolations;
  final int totalScannedFiles;
  final int totalScannedImports;

  const FsdAuditResult({
    required this.upwardViolations,
    required this.crossSliceViolations,
    required this.totalScannedFiles,
    required this.totalScannedImports,
  });

  int get totalViolations =>
      upwardViolations.length + crossSliceViolations.length;
}

FsdAuditResult auditDirectory(Directory libDir) {
  final upwardViolations = <FsdViolation>[];
  final crossSliceViolations = <FsdViolation>[];

  final dartFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  final importRegex = RegExp(r'''^\s*import\s+['"]([^'"]+)['"]''');
  int totalImports = 0;

  for (final file in dartFiles) {
    final relSourcePath = file.path.replaceAll(r'\', '/');
    final (sourceLayer, sourceSlice) = _parseLayerAndSlice(relSourcePath);
    if (sourceLayer == null || !layerHierarchy.containsKey(sourceLayer)) {
      continue;
    }

    final lines = file.readAsLinesSync();
    for (int i = 0; i < lines.length; i++) {
      final match = importRegex.firstMatch(lines[i]);
      if (match == null) continue;

      totalImports++;
      final importUri = match.group(1)!;
      final targetResolvedPath = _resolveImport(file, importUri);
      if (targetResolvedPath == null) continue;

      final (targetLayer, targetSlice) =
          _parseLayerAndSlice(targetResolvedPath);
      if (targetLayer == null || !layerHierarchy.containsKey(targetLayer)) {
        continue;
      }

      final sourceRank = layerHierarchy[sourceLayer]!;
      final targetRank = layerHierarchy[targetLayer]!;

      // 1. Upward Layer Violation (Lower layer importing higher layer)
      // Note: lower in hierarchy has higher rank number (shared=6, app=1).
      if (sourceRank > targetRank) {
        upwardViolations.add(
          FsdViolation(
            file: relSourcePath,
            line: i + 1,
            importUri: importUri,
            sourceLayer: sourceLayer,
            sourceSlice: sourceSlice,
            targetLayer: targetLayer,
            targetSlice: targetSlice,
            violationType: 'UPWARD_LAYER_INVERSION',
            description:
                'Layer "$sourceLayer" cannot import from higher layer "$targetLayer".',
          ),
        );
      }
      // 2. Cross-Slice Isolation Violation (Same layer, different slices)
      else if (sourceLayer == targetLayer &&
          sourceSlice != null &&
          targetSlice != null &&
          sourceSlice != targetSlice) {
        crossSliceViolations.add(
          FsdViolation(
            file: relSourcePath,
            line: i + 1,
            importUri: importUri,
            sourceLayer: sourceLayer,
            sourceSlice: sourceSlice,
            targetLayer: targetLayer,
            targetSlice: targetSlice,
            violationType: 'CROSS_SLICE_COUPLING',
            description:
                'Slice "$sourceSlice" cannot import from sibling slice "$targetSlice" within the same layer "$sourceLayer".',
          ),
        );
      }
    }
  }

  return FsdAuditResult(
    upwardViolations: upwardViolations,
    crossSliceViolations: crossSliceViolations,
    totalScannedFiles: dartFiles.length,
    totalScannedImports: totalImports,
  );
}

(String?, String?) _parseLayerAndSlice(String path) {
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

String? _resolveImport(File sourceFile, String uri) {
  if (uri.startsWith('dart:')) return null;
  if (uri.startsWith('package:')) {
    if (!uri.startsWith('package:pin/')) return null;
    return 'lib/${uri.substring('package:pin/'.length)}';
  }

  // Relative import
  final sourceDir = sourceFile.parent;
  final targetFile = File('${sourceDir.path}/$uri');
  final normalized = targetFile.uri.normalizePath().toFilePath();
  final projectRoot = Directory.current.path;
  if (normalized.startsWith(projectRoot)) {
    return normalized.substring(projectRoot.length + 1).replaceAll(r'\', '/');
  }
  return normalized.replaceAll(r'\', '/');
}

void main(List<String> args) {
  final strict = args.contains('--strict');
  final libDir = Directory('lib');

  if (!libDir.existsSync()) {
    stderr.writeln('Error: lib/ directory not found in ${Directory.current.path}');
    exit(1);
  }

  stdout.writeln('🔍 Running Feature-Sliced Design (FSD) Architectural Audit...');
  final result = auditDirectory(libDir);

  stdout.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  stdout.writeln('Total Dart files scanned:   ${result.totalScannedFiles}');
  stdout.writeln('Total imports inspected:    ${result.totalScannedImports}');
  stdout.writeln('Upward Layer Inversions:    ${result.upwardViolations.length}');
  stdout.writeln('Cross-Slice Couplings:      ${result.crossSliceViolations.length}');
  stdout.writeln('Total Architectural Breaches: ${result.totalViolations}');
  stdout.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  if (result.upwardViolations.isNotEmpty) {
    stdout.writeln('🚨 UPWARD LAYER INVERSIONS (Critical Severity):');
    for (final v in result.upwardViolations) {
      stdout.writeln(v);
      stdout.writeln();
    }
  }

  if (result.crossSliceViolations.isNotEmpty) {
    stdout.writeln('⚠️ CROSS-SLICE COUPLINGS (High Severity):');
    for (final v in result.crossSliceViolations) {
      stdout.writeln(v);
      stdout.writeln();
    }
  }

  // Baseline of currently recorded legacy breaches
  const knownUpwardBaseline = 0;
  const knownCrossSliceBaseline = 0;
  const knownTotalBaseline = knownUpwardBaseline + knownCrossSliceBaseline;

  if (strict) {
    if (result.totalViolations > 0) {
      stderr.writeln('❌ Strict Mode Failed: Found ${result.totalViolations} architectural violations.');
      exit(1);
    }
    stdout.writeln('✅ Strict Mode Passed: Zero architectural violations detected.');
  } else {
    if (result.totalViolations > knownTotalBaseline) {
      stderr.writeln(
        '❌ Regression Detected: Total breaches (${result.totalViolations}) '
        'exceeds known baseline ($knownTotalBaseline). New architectural violations were added!',
      );
      exit(1);
    } else if (result.totalViolations < knownTotalBaseline) {
      stdout.writeln(
        '🎉 Architectural Improvement: Breaches decreased from baseline '
        '$knownTotalBaseline to ${result.totalViolations}! Update baseline to lock in progress.',
      );
    } else {
      stdout.writeln('ℹ️ All breaches match the documented baseline. No new architectural regressions.');
    }
  }
}
