import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'voice_aloud/voice_aloud_root.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VoiceAloudReaderApp());
}

class VoiceAloudReaderApp extends StatelessWidget {
  const VoiceAloudReaderApp({super.key});

  static const _obsidian = Color(0xFF07070F);
  static const _gold = Color(0xFFC9A84C);
  static const _cream = Color(0xFFEDE8DC);
  static const _muted = Color(0xFF7B7A8E);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _gold,
      brightness: Brightness.dark,
      primary: _gold,
      secondary: _gold,
      surface: const Color(0xFF0D0D1A),
      onSurface: _cream,
      onPrimary: _obsidian,
    );

    return ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'VoiceAloud Reader',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: colorScheme,
          scaffoldBackgroundColor: _obsidian,
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: _FadeSlideTransitionBuilder(),
              TargetPlatform.iOS: _FadeSlideTransitionBuilder(),
              TargetPlatform.macOS: _FadeSlideTransitionBuilder(),
              TargetPlatform.windows: _FadeSlideTransitionBuilder(),
              TargetPlatform.linux: _FadeSlideTransitionBuilder(),
            },
          ),
          cardTheme: CardThemeData(
            color: const Color(0xFF1A1A2E),
            shadowColor: Colors.black54,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: _gold.withValues(alpha: 0.15)),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: _obsidian,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: _obsidian,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: _cream,
              side: BorderSide(color: _gold.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: _gold),
          ),
          snackBarTheme: const SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
          ),
        ),
        home: const VoiceAloudRoot(),
      ),
    );
  }
}

class _FadeSlideTransitionBuilder extends PageTransitionsBuilder {
  const _FadeSlideTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.02, 0.0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
