import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'voice_aloud/voice_aloud_root.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VoxlyApp());
}

class VoxlyApp extends StatelessWidget {
  const VoxlyApp({super.key});

  static const _seedBlue = Color(0xFF2563EB);
  static const _surfaceTint = Color(0xFFF3F6FB);
  static const _foreground = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    final baseText = GoogleFonts.manropeTextTheme();
    final textTheme = baseText.copyWith(
      displayLarge: GoogleFonts.sora(
        fontSize: 52,
        fontWeight: FontWeight.w800,
        color: _foreground,
      ),
      headlineLarge: GoogleFonts.sora(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: _foreground,
      ),
      titleLarge: GoogleFonts.sora(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: _foreground,
      ),
      bodyLarge: baseText.bodyLarge?.copyWith(height: 1.45, color: _foreground),
      bodyMedium: baseText.bodyMedium?.copyWith(height: 1.5, color: _foreground),
      labelLarge: baseText.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedBlue,
      brightness: Brightness.light,
      primary: _seedBlue,
      surface: Colors.white,
      onSurface: _foreground,
      onPrimary: Colors.white,
      secondary: const Color(0xFF0EA5E9),
    );

    return ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Voice Aloud Reader',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: colorScheme,
          scaffoldBackgroundColor: _surfaceTint,
          textTheme: textTheme,
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
            color: Colors.white,
            shadowColor: const Color(0x220F172A),
            surfaceTintColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0x1A1D4ED8)),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: _seedBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: textTheme.labelLarge,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: _seedBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: textTheme.labelLarge,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: _foreground,
              side: const BorderSide(color: Color(0x331E40AF)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: textTheme.labelLarge,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: _seedBlue,
              textStyle: textTheme.labelLarge,
            ),
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
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
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
