import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/dashboard_screen.dart';
import 'screens/terms_accept_screen.dart';
import 'services/local_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences early (helps avoid plugin init issues on iOS)
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
      home: const TermsGate(),
    );
  }
}

/// ---------------------------------------------------------
///  APP THEME: Orange primary, Blue secondary
/// ---------------------------------------------------------
ThemeData _buildTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Color(0xFF4C5D70),
      primary: Color(0xFF4C5D70),
      secondary: Colors.blue,
      brightness: Brightness.light,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Color(0xFF4C5D70),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Color(0xFF4C5D70),
        side: const BorderSide(color: Colors.orange, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF4C5D70),
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
///  TERMS GATE (reliable):
///  - checks terms accepted
///  - if not accepted, shows TermsAcceptScreen
///  - after accept, refreshes and shows Dashboard
/// ---------------------------------------------------------
class TermsGate extends StatefulWidget {
  const TermsGate({super.key});

  @override
  State<TermsGate> createState() => _TermsGateState();
}

class _TermsGateState extends State<TermsGate> {
  bool _loading = true;
  bool _accepted = false;

  @override
  void initState() {
    super.initState();
    _loadAccepted();
  }

  Future<void> _loadAccepted() async {
    final accepted = await LocalStorage.getTermsAccepted();
    if (!mounted) return;
    setState(() {
      _accepted = accepted;
      _loading = false;
    });
  }

  Future<void> _handleAccepted() async {
    // Mark accepted + switch screen in the same widget
    await LocalStorage.setTermsAccepted(true);
    if (!mounted) return;
    setState(() {
      _accepted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
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

    if (_accepted) {
      return const DashboardScreen();
    }

    // IMPORTANT: We pass the callback the screen calls after saving
    return TermsAcceptScreen(
      onAccepted: () {
        // safest: replace screen so no black screen back-stack issues
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      },
    );
  }
}
