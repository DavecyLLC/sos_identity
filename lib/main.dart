import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MinimalBootApp());
}

class MinimalBootApp extends StatelessWidget {
  const MinimalBootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Text(
              'Build 8: Boot OK (no plugins)',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
