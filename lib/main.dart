import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// ✅ iPad-safe Flutter startup:
/// - Ensures Flutter binding is initialized
/// - Catches async errors (prevents hard crash when possible)
/// - Does NOT call plugins (geolocator / secure storage / image picker) before runApp()
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kReleaseMode) {
      // In release, you could log to a service later (Crashlytics etc.)
    }
  };

  // Catch async errors outside Flutter
  runZonedGuarded(() {
    runApp(const MyApp());
  }, (Object error, StackTrace stack) {
    if (kDebugMode) {
      // This helps a lot during local runs
      // ignore: avoid_print
      print('UNCAUGHT ZONE ERROR: $error\n$stack');
    }
  });
}

/// Replace this with your existing App widget if you already have one.
/// Keep this structure: show a lightweight splash, then navigate after init.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOS Identity',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const AppBootstrap(),
    );
  }
}

/// ✅ Boots the app safely:
/// - First paints UI (prevents "crash on launch" from heavy startup)
/// - Then runs initialization AFTER first frame
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  bool _ready = false;
  Object? _initError;

  @override
  void initState() {
    super.initState();

    // ✅ Defer any setup until AFTER the first frame is rendered.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _initializeAppSafely();
        if (!mounted) return;
        setState(() => _ready = true);
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _initError = e;
          _ready = false;
        });
      }
    });
  }

  /// ✅ Put ALL plugin calls here (NOT in main()).
  /// If one plugin is crashing on iPad, it will crash here instead of "on launch",
  /// and Apple reviewers can at least see the app open (or you'll get a visible error screen).
  Future<void> _initializeAppSafely() async {
    // IMPORTANT RULE:
    // Do not request permissions here automatically.
    // Only request permissions after a user taps a button (Apple prefers this).

    // Examples of things that are safe:
    // - Read SharedPreferences
    // - Load local JSON/assets
    //
    // Avoid calling these here automatically:
    // - Geolocator.getCurrentPosition()
    // - requestPermission() at startup
    // - flutter_secure_storage read/write at startup (if it causes native crash)
    //
    // If you NEED secure storage on startup, do it later in a screen after UI loads.
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }

  @override
  Widget build(BuildContext context) {
    if (_initError != null) {
      return _StartupErrorScreen(error: _initError.toString());
    }

    if (!_ready) {
      return const _SplashScreen();
    }

    // ✅ Replace this with your real first screen / dashboard / home route.
    // Example:
    // return const DashboardScreen();
    return const _HomePlaceholder();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: 220,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield, size: 56),
                SizedBox(height: 12),
                Text(
                  'SOS Identity',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 10),
                CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StartupErrorScreen extends StatelessWidget {
  final String error;
  const _StartupErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 52),
                  const SizedBox(height: 12),
                  const Text(
                    'Startup Error',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    error,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Just restart app manually
                    },
                    child: const Text('Close and reopen the app'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Temporary placeholder home.
/// Replace with your actual first screen.
class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SOS Identity')),
      body: const SafeArea(
        child: Center(
          child: Text(
            'App launched successfully.\nReplace this with your dashboard screen.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
