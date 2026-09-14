import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pin/shared/lib/platform_theme_service.dart';
import '../entities/task/state/task_state_notifier.dart';
import '../features/ai/services/ai_config_service.dart';
import '../features/ai/services/gemini_service.dart';
import '../features/ai/ui/ai_settings_modal.dart';
import '../features/task_crud/ui/task_crud_modal.dart';
import '../pages/home/home_page.dart';
import 'theme/pin_scroll_behavior.dart';
import 'theme/pin_theme.dart';

/// Root Application widget for Pin.
class PinApp extends StatelessWidget {
  const PinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(
      child: _PinAppContent(),
    );
  }
}

class _PinAppContent extends ConsumerStatefulWidget {
  const _PinAppContent();

  @override
  ConsumerState<_PinAppContent> createState() => _PinAppContentState();
}

class _PinAppContentState extends ConsumerState<_PinAppContent>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    TaskCrudModal.defaultAiSettingsHandler = (ctx) => AiSettingsModal.show(ctx);
    TaskCrudModal.defaultAiBreakdownHandler =
        (ctx, ref, {required prompt, currentDescription}) async {
      final aiConfig = ref.read(aiConfigProvider);
      if (!aiConfig.hasKey) {
        final configured = await AiSettingsModal.show(ctx);
        if (configured != true) return null;
        if (!ref.read(aiConfigProvider).hasKey) return null;
      }
      final service = GeminiService();
      final breakdown = await service.suggestTaskBreakdown(
        apiKey: ref.read(aiConfigProvider).apiKey,
        prompt: prompt,
        currentDescription: currentDescription,
        model: ref.read(aiConfigProvider).selectedModel,
      );
      return TaskAiBreakdownPayload(
        title: breakdown.title,
        description: breakdown.description,
        energyTag: breakdown.energyTag,
        estimatedMinutes: breakdown.estimatedMinutes,
        tags: breakdown.tags,
        atomicSteps: breakdown.atomicSteps,
      );
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncTheme();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    if (ref.read(themeModeProvider) == ThemeMode.system) {
      _syncTheme();
    }
  }

  bool _computeIsDark(ThemeMode? mode) {
    if (mode == ThemeMode.dark) return true;
    if (mode == ThemeMode.light) return false;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  void _syncTheme([ThemeMode? mode]) {
    final activeMode = mode ?? ref.read(themeModeProvider);
    final isDark = _computeIsDark(activeMode);
    PlatformThemeService.syncTheme(isDark: isDark);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    ref.listen<ThemeMode>(themeModeProvider, (_, next) {
      _syncTheme(next);
    });

    return MaterialApp(
      title: 'Pin',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const PinScrollBehavior(),
      theme: PinTheme.lightTheme,
      darkTheme: PinTheme.darkTheme,
      themeMode: themeMode,
      home: const HomePage(),
    );
  }
}
