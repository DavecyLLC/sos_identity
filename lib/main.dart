import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/dashboard_screen.dart';
import 'screens/terms_accept_screen.dart';
import 'services/local_storage.dart';

void main() async {
  // ✅ CRITICAL: Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ CRITICAL: Initialize SharedPreferences BEFORE runApp with retry logic
  try {
    await SharedPreferences.getInstance();
  } catch (e) {
    debugPrint('SharedPreferences init failed: $e');
    // Try one more time after a small delay
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
///  Styled buttons: Filled = Orange, Outlined = Orange border/text
/// ---------------------------------------------------------
ThemeData _buildTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.orange,
      primary: Colors.orange,
      secondary: Colors.blue,
      brightness: Brightness.light,
    ),

    // 🔶 FILLED BUTTONS (Accept, Start Safety, etc.)
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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