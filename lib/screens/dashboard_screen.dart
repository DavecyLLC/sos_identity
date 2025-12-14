import 'package:flutter/material.dart';

import '../services/local_storage.dart';
import 'ids_screen.dart';
import 'contacts_screen.dart';
import 'settings_screen.dart';
import 'sos_preview_screen.dart';
import 'emergency_id_screen.dart';
import 'lock_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  // Lock timeout in minutes (after this delay the app asks for PIN again)
  static const int _lockTimeoutMinutes = 2;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _buildHomePage(context),
      const IdsScreen(),
      const ContactsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },

        // 🔶 ORANGE selected icons + text
        selectedItemColor: Colors.orange,

        // 🔵 Grey/Blue for unselected icons
        unselectedItemColor: Colors.blueGrey,

        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(),

        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.badge),
            label: 'IDs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  /// -----------------------------------------------------------
  /// SECURITY CHECKS — ask for PIN if lock enabled + timed out
  /// -----------------------------------------------------------
  Future<bool> _needUnlock() async {
    final lockEnabled = await LocalStorage.getLockEnabled();
    if (!lockEnabled) return false;

    final last = await LocalStorage.getLastUnlockTime();
    if (last == null) return true;

    final elapsed = DateTime.now().difference(last);
    return elapsed.inMinutes >= _lockTimeoutMinutes;
  }

  Future<bool> _ensureUnlocked(BuildContext context) async {
    final mustUnlock = await _needUnlock();
    if (!mustUnlock) return true;

    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const LockScreen(setupMode: false),
      ),
    );

    if (ok == true) {
      await LocalStorage.setLastUnlockTime(DateTime.now());
      return true;
    }

    return false;
  }

  /// -----------------------------------------------------------
  /// HOME PAGE
  /// -----------------------------------------------------------
  Widget _buildHomePage(BuildContext context) {
    final theme = Theme.of(context);
    const double circleSize = 120; // ✅ define the size OUTSIDE the widget tree

    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Identity'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shield,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),

                const SizedBox(height: 16),
                Text(
                  'Your safety identity hub',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),
                Text(
                  'Store your IDs, manage emergency contacts, and send an SOS with key information and GPS.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // --- NEW CENTERED ROUND BUTTONS ---
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🔶 ROUND "Show ID" button
                    GestureDetector(
                      onTap: () async {
                        final ok = await _ensureUnlocked(context);
                        if (!ok) return;
                        if (!mounted) return;

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const EmergencyIdScreen(),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Container(
                            width: circleSize,
                            height: circleSize,
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.badge,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Show ID',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // 🔶 ROUND "Start Safety" button
                    GestureDetector(
                      onTap: () async {
                        final ok = await _ensureUnlocked(context);
                        if (!ok) return;
                        if (!mounted) return;

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SosPreviewScreen(),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Container(
                            width: circleSize,
                            height: circleSize,
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.warning_amber_rounded,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Start Safety',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                Text(
                  'Enable App Lock in Settings to protect your ID and SOS features.',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
