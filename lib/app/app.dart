import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../entities/task/state/task_state_notifier.dart';
import '../pages/home/home_page.dart';
import 'theme/pin_theme.dart';

import 'package:pin/shared/lib/platform_theme_service.dart';

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
      theme: PinTheme.lightTheme,
      darkTheme: PinTheme.darkTheme,
      themeMode: themeMode,
      home: const HomePage(),
    );
  }
}
