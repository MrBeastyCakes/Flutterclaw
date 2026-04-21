import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/chat_provider.dart';
import 'screens/chat_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FlutterclawApp());
}

class FlutterclawApp extends StatelessWidget {
  const FlutterclawApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatProvider()..initialize(),
      child: MaterialApp(
        title: 'Flutterclaw',
        debugShowCheckedModeBanner: false,
        // ---------- Light theme ----------
        theme: _buildTheme(Brightness.light),
        // ---------- Dark theme ----------
        darkTheme: _buildTheme(Brightness.dark),
        themeMode: ThemeMode.system,
        home: const ChatScreen(),
        routes: {
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final seed = const Color(0xFF6366F1);

    // Custom dark palette with better contrast
    final darkScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
      surface: const Color(0xFF121212),
      surfaceContainerHighest: const Color(0xFF1E1E1E),
      onSurface: const Color(0xFFEAEAEA),
      onSurfaceVariant: const Color(0xFFB0B0B0),
      outline: const Color(0xFF444444),
      outlineVariant: const Color(0xFF333333),
      shadow: Colors.black,
    );

    final lightScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );

    final cs = isDark ? darkScheme : lightScheme;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: cs,
      // fontFamily: 'Inter',  // Fonts removed from pubspec — system font fallback
      scaffoldBackgroundColor: cs.surface,
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        titleTextStyle: TextStyle(
          // fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
      ),
      // SnackBar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: isDark ? const Color(0xFF2A2A2A) : cs.inverseSurface,
        contentTextStyle: TextStyle(
          color: isDark ? cs.onSurface : cs.onInverseSurface,
          // fontFamily: 'Inter',
        ),
      ),
      // Bottom sheets
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      // Cards / Containers
      cardTheme: CardThemeData(
        color: cs.surfaceContainerHighest,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(
          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
          // fontFamily: 'Inter',
        ),
      ),
      // Dividers
      dividerTheme: DividerThemeData(
        color: cs.outlineVariant.withValues(alpha: 0.5),
      ),
      // Progress indicators
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: cs.primary,
        linearTrackColor: cs.surfaceContainerHighest,
      ),
    );
  }
}

