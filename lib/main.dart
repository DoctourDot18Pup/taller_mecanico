import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'screens/home_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_MX');
  tz.initializeTimeZones();
  final String timezoneName = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timezoneName));
  await NotificationService().init();
  runApp(const TallerApp());
}

class TallerApp extends StatefulWidget {
  const TallerApp({super.key});
  static TallerAppState of(BuildContext context) =>
      context.findAncestorStateOfType<TallerAppState>()!;
  @override
  State<TallerApp> createState() => TallerAppState();
}

class TallerAppState extends State<TallerApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme() => setState(() {
        _themeMode =
            _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
      });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taller Mecánico',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      home: const HomeScreen(),
    );
  }
}

// ─────────────────────────── LIGHT THEME ───────────────────────────
ThemeData _buildLightTheme() {
  const primary = Color(0xFF0D1B2A);
  const secondary = Color(0xFF1565C0);
  const surface = Color(0xFFF5F7FA);
  const card = Colors.white;

  final scheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFD6E4FF),
    onPrimaryContainer: primary,
    secondary: secondary,
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFFDCEAFF),
    onSecondaryContainer: secondary,
    surface: surface,
    onSurface: const Color(0xFF1A1C1E),
    surfaceContainerHighest: const Color(0xFFE8ECF0),
    outline: const Color(0xFFBDC5CD),
    error: const Color(0xFFBA1A1A),
    onError: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE8ECF0)),
      ),
      margin: EdgeInsets.zero,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: StadiumBorder(),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      elevation: 0,
      indicatorColor: const Color(0xFFD6E4FF),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: primary);
        }
        return const IconThemeData(color: Color(0xFF8A929A));
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
              color: primary, fontSize: 12, fontWeight: FontWeight.w600);
        }
        return const TextStyle(color: Color(0xFF8A929A), fontSize: 12);
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF0F3F7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E5EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(color: Color(0xFF5A6370)),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE8ECF0),
      thickness: 1,
      space: 1,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
          color: primary, fontWeight: FontWeight.w700, fontSize: 28),
      headlineMedium: TextStyle(
          color: primary, fontWeight: FontWeight.w700, fontSize: 24),
      titleLarge: TextStyle(
          color: Color(0xFF1A1C1E),
          fontWeight: FontWeight.w700,
          fontSize: 20),
      titleMedium: TextStyle(
          color: Color(0xFF1A1C1E),
          fontWeight: FontWeight.w600,
          fontSize: 16),
      titleSmall: TextStyle(
          color: Color(0xFF3D4450),
          fontWeight: FontWeight.w600,
          fontSize: 14),
      bodyLarge: TextStyle(color: Color(0xFF1A1C1E), fontSize: 16),
      bodyMedium: TextStyle(color: Color(0xFF3D4450), fontSize: 14),
      bodySmall: TextStyle(color: Color(0xFF6B7380), fontSize: 12),
      labelSmall: TextStyle(
          color: Color(0xFF8A929A),
          fontSize: 11,
          letterSpacing: 0.5),
    ),
  );
}

// ─────────────────────────── DARK THEME ───────────────────────────
ThemeData _buildDarkTheme() {
  const primary = Color(0xFF90C8F8);
  const background = Color(0xFF0E1117);
  const surface = Color(0xFF161B26);
  const card = Color(0xFF1E2535);
  const border = Color(0xFF2A3245);

  final scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: primary,
    onPrimary: Color(0xFF001E36),
    primaryContainer: Color(0xFF00344F),
    onPrimaryContainer: Color(0xFFCDE5FF),
    secondary: Color(0xFF9ECAFF),
    onSecondary: Color(0xFF00315C),
    secondaryContainer: Color(0xFF004880),
    onSecondaryContainer: Color(0xFFD4E3FF),
    surface: surface,
    onSurface: Color(0xFFE2E8F0),
    surfaceContainerHighest: Color(0xFF252D3D),
    outline: border,
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      foregroundColor: Color(0xFFE2E8F0),
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      titleTextStyle: TextStyle(
        color: Color(0xFFE2E8F0),
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: border),
      ),
      margin: EdgeInsets.zero,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Color(0xFF001E36),
      elevation: 4,
      shape: StadiumBorder(),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      elevation: 0,
      indicatorColor: const Color(0xFF00344F),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: primary);
        }
        return const IconThemeData(color: Color(0xFF6B7A99));
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
              color: primary, fontSize: 12, fontWeight: FontWeight.w600);
        }
        return const TextStyle(color: Color(0xFF6B7A99), fontSize: 12);
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E2535),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFFB4AB)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(color: Color(0xFF8A99B8)),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dividerTheme: const DividerThemeData(
      color: border,
      thickness: 1,
      space: 1,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
          color: Color(0xFFE2E8F0), fontWeight: FontWeight.w700, fontSize: 28),
      headlineMedium: TextStyle(
          color: Color(0xFFE2E8F0), fontWeight: FontWeight.w700, fontSize: 24),
      titleLarge: TextStyle(
          color: Color(0xFFE2E8F0),
          fontWeight: FontWeight.w700,
          fontSize: 20),
      titleMedium: TextStyle(
          color: Color(0xFFE2E8F0),
          fontWeight: FontWeight.w600,
          fontSize: 16),
      titleSmall: TextStyle(
          color: Color(0xFFB8C4D8),
          fontWeight: FontWeight.w600,
          fontSize: 14),
      bodyLarge: TextStyle(color: Color(0xFFE2E8F0), fontSize: 16),
      bodyMedium: TextStyle(color: Color(0xFFB8C4D8), fontSize: 14),
      bodySmall: TextStyle(color: Color(0xFF8A99B8), fontSize: 12),
      labelSmall: TextStyle(
          color: Color(0xFF6B7A99),
          fontSize: 11,
          letterSpacing: 0.5),
    ),
  );
}
