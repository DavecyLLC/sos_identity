import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/dashboard_screen.dart';
import 'screens/terms_accept_screen.dart';
import 'services/local_storage.dart';

void main() async {
  // ✅ Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize SharedPreferences BEFORE runApp (with retry)
  try {
    await SharedPreferences.getInstance();
  } catch (e) {
    debugPrint('SharedPreferences init failed: $e');
    await Future.delayed(const Duration(milliseconds: 100));
    await SharedPreferences.getInstance();
  }

  runApp(const SafeIdApp());
}

class SafeIdApp extends StatelessWidget {
  const SafeIdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOS Identity',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const _TermsGate(),
    );
  }
}

/// ---------------------------------------------------------
///  APP THEME: Orange primary, Blue secondary
///  ✅ Remove bold globally (text + buttons)
/// ---------------------------------------------------------
ThemeData _buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.orange,
      primary: Colors.orange,
      secondary: Colors.blue,
      brightness: Brightness.light,
    ),
  );

  // ✅ Force ALL text styles to normal weight (removes bold everywhere)
  final noBoldTextTheme = base.textTheme.copyWith(
    displayLarge: base.textTheme.displayLarge?.copyWith(fontWeight: FontWeight.normal),
    displayMedium: base.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.normal),
    displaySmall: base.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.normal),
    headlineLarge: base.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.normal),
    headlineMedium: base.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.normal),
    headlineSmall: base.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.normal),
    titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.normal),
    titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.normal),
    titleSmall: base.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.normal),
    bodyLarge: base.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.normal),
    bodyMedium: base.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.normal),
    bodySmall: base.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.normal),
    labelLarge: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.normal),
    labelMedium: base.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.normal),
    labelSmall: base.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.normal),
  );

  // ✅ Apply no-bold to BOTH textTheme and primaryTextTheme
  return base.copyWith(
    textTheme: noBoldTextTheme,
    primaryTextTheme: noBoldTextTheme,

    // 🔶 FILLED BUTTONS (Accept, Start Safety, etc.)
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        // ✅ Remove bold on button labels
        textStyle: const TextStyle(fontWeight: FontWeight.normal),
      ),
    ),

    // 🟠 OUTLINED BUTTONS (View Terms, Add optional items)
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.orange,
        side: const BorderSide(color: Colors.orange, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        // ✅ Remove bold on button labels
        textStyle: const TextStyle(fontWeight: FontWeight.normal),
      ),
    ),

    // 🟠 ELEVATED BUTTONS (Legacy buttons)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        // ✅ Remove bold on button labels
        textStyle: const TextStyle(fontWeight: FontWeight.normal),
      ),
    ),

    // ✅ Also remove bold from TextButton labels (just in case)
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: const TextStyle(fontWeight: FontWeight.normal),
      ),
    ),
  );
}

/// ---------------------------------------------------------
///  TERMS GATE:
///  If user has not accepted Terms → show the TermsAcceptScreen.
///  If accepted → show Dashboard.
/// ---------------------------------------------------------
class _TermsGate extends StatelessWidget {
  const _TermsGate();

  Future<bool> _checkAccepted() async {
    return LocalStorage.getTermsAccepted();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkAccepted(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          );
        }

        final accepted = snapshot.data ?? false;

        if (!accepted) {
          return const TermsAcceptScreen();
        }

        return const DashboardScreen();
      },
    );
  }
}
