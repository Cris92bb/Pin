import '../../../entities/task/model/atomic_step.dart';
import 'gemini_service.dart';

/// Offline heuristic breakdown service that decomposes tasks into actionable
/// atomic subtasks based on keyword patterns, intent analysis, and structured templates.
///
/// Serves as a zero-configuration, instant fallback when neither On-Device Gemini Nano
/// nor Cloud Gemini API key is configured or ready.
class LocalHeuristicBreakdownService {
  const LocalHeuristicBreakdownService();

  /// Decomposes [prompt] and optional [currentDescription] into an [AiTaskBreakdown].
  AiTaskBreakdown decompose({
    required String prompt,
    String? currentDescription,
  }) {
    final cleanPrompt = prompt.trim();
    final lower = cleanPrompt.toLowerCase();
    final now = DateTime.now().microsecondsSinceEpoch;

    // Detect domain category
    if (_matches(lower, _codingKeywords)) {
      return _buildCodingBreakdown(cleanPrompt, currentDescription, now);
    } else if (_matches(lower, _designKeywords)) {
      return _buildDesignBreakdown(cleanPrompt, currentDescription, now);
    } else if (_matches(lower, _writingKeywords)) {
      return _buildWritingBreakdown(cleanPrompt, currentDescription, now);
    } else if (_matches(lower, _researchKeywords)) {
      return _buildResearchBreakdown(cleanPrompt, currentDescription, now);
    } else if (_matches(lower, _adminKeywords)) {
      return _buildAdminBreakdown(cleanPrompt, currentDescription, now);
    }

    return _buildGeneralBreakdown(cleanPrompt, currentDescription, now);
  }

  bool _matches(String text, List<String> keywords) {
    return keywords.any((kw) => text.contains(kw));
  }

  static const _codingKeywords = [
    'bug', 'fix', 'code', 'refactor', 'api', 'endpoint', 'database', 'query',
    'deploy', 'ci', 'docker', 'test', 'build', 'frontend', 'backend', 'git',
    'flutter', 'react', 'dart', 'python', 'service', 'impl', 'repo', 'leak',
    'crash', 'error', 'model', 'auth', 'logic', 'component', 'script',
  ];

  static const _designKeywords = [
    'design', 'ui', 'ux', 'landing', 'mockup', 'figma', 'layout', 'theme',
    'palette', 'screen', 'wireframe', 'animation', 'style', 'responsive',
    'button', 'modal', 'card', 'typography', 'dark mode', 'icon', 'asset',
  ];

  static const _writingKeywords = [
    'write', 'draft', 'article', 'blog', 'post', 'email', 'newsletter',
    'copy', 'doc', 'readme', 'spec', 'proposal', 'content', 'script',
    'summary', 'release note',
  ];

  static const _researchKeywords = [
    'research', 'study', 'learn', 'investigate', 'compare', 'read',
    'explore', 'evaluate', 'benchmark', 'audit', 'find', 'review doc',
  ];

  static const _adminKeywords = [
    'plan', 'organize', 'schedule', 'meeting', 'call', 'prep', 'sync',
    'invoice', 'tax', 'finance', 'budget', 'clean', 'file', 'admin',
    'roadmap', 'ticket', 'sprint',
  ];

  AtomicStep _step(int ts, int idx, String title, int mins) => AtomicStep(
        id: 'step_${ts}_$idx',
        title: title,
        isCompleted: false,
        estimatedMinutes: mins.clamp(1, 15),
      );

  AiTaskBreakdown _buildCodingBreakdown(String title, String? desc, int ts) {
    return AiTaskBreakdown(
      title: title,
      description: desc?.isNotEmpty == true
          ? desc!
          : 'Systematic implementation, testing, and verification for "$title".',
      energyTag: 'deep-focus',
      estimatedMinutes: 45,
      tags: ['#dev', '#engineering', '#code'],
      atomicSteps: [
        _step(ts, 1, 'Reproduce context and define technical requirements', 10),
        _step(ts, 2, 'Implement core logic and handle edge cases', 15),
        _step(ts, 3, 'Write automated unit/widget tests and verify coverage', 10),
        _step(ts, 4, 'Perform code review and stage clean git commit', 5),
      ],
    );
  }

  AiTaskBreakdown _buildDesignBreakdown(String title, String? desc, int ts) {
    return AiTaskBreakdown(
      title: title,
      description: desc?.isNotEmpty == true
          ? desc!
          : 'Visual hierarchy, design token integration, and responsive layout for "$title".',
      energyTag: 'creative',
      estimatedMinutes: 30,
      tags: ['#design', '#ui', '#visual'],
      atomicSteps: [
        _step(ts, 1, 'Review layout specifications and design tokens', 5),
        _step(ts, 2, 'Draft component structure and responsive breakpoints', 15),
        _step(ts, 3, 'Audit typography, color contrast, and spacing', 10),
      ],
    );
  }

  AiTaskBreakdown _buildWritingBreakdown(String title, String? desc, int ts) {
    return AiTaskBreakdown(
      title: title,
      description: desc?.isNotEmpty == true
          ? desc!
          : 'Outline, draft, and polish content for "$title".',
      energyTag: 'creative',
      estimatedMinutes: 30,
      tags: ['#writing', '#content'],
      atomicSteps: [
        _step(ts, 1, 'Outline main sections and core takeaways', 10),
        _step(ts, 2, 'Write first complete draft without editing', 15),
        _step(ts, 3, 'Proofread for clarity, tone, and conciseness', 5),
      ],
    );
  }

  AiTaskBreakdown _buildResearchBreakdown(String title, String? desc, int ts) {
    return AiTaskBreakdown(
      title: title,
      description: desc?.isNotEmpty == true
          ? desc!
          : 'Structured research, synthesis, and takeaways for "$title".',
      energyTag: 'deep-focus',
      estimatedMinutes: 30,
      tags: ['#research', '#learning'],
      atomicSteps: [
        _step(ts, 1, 'Define 2-3 specific questions to answer', 5),
        _step(ts, 2, 'Gather references and review documentation', 15),
        _step(ts, 3, 'Synthesize insights into concrete action items', 10),
      ],
    );
  }

  AiTaskBreakdown _buildAdminBreakdown(String title, String? desc, int ts) {
    return AiTaskBreakdown(
      title: title,
      description: desc?.isNotEmpty == true
          ? desc!
          : 'Preparation, execution, and follow-through for "$title".',
      energyTag: 'administrative',
      estimatedMinutes: 15,
      tags: ['#admin', '#organization'],
      atomicSteps: [
        _step(ts, 1, 'Assemble required documents, links, and agenda', 5),
        _step(ts, 2, 'Execute core administrative actions', 5),
        _step(ts, 3, 'Document outcomes and archive records', 5),
      ],
    );
  }

  AiTaskBreakdown _buildGeneralBreakdown(String title, String? desc, int ts) {
    return AiTaskBreakdown(
      title: title,
      description: desc?.isNotEmpty == true
          ? desc!
          : 'Actionable step-by-step breakdown for "$title".',
      energyTag: 'medium-flow',
      estimatedMinutes: 30,
      tags: ['#action', '#focus'],
      atomicSteps: [
        _step(ts, 1, 'Clarify goal and prepare working environment', 5),
        _step(ts, 2, 'Execute primary milestone for $title', 15),
        _step(ts, 3, 'Review results and mark completed', 10),
      ],
    );
  }
}
