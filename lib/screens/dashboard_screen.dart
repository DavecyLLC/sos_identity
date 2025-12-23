import 'package:flutter/material.dart';

import '../services/local_storage.dart';
import 'contacts_screen.dart';
import 'emergency_id_screen.dart';
import 'ids_screen.dart';
import 'lock_screen.dart';
import 'settings_screen.dart';
import 'sos_preview_screen.dart';

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

      // ✅ Big round SOS button in its own space (Home only)
      bottomSheet: _currentIndex == 0
          ? _StartSafetyBottomButton(
              onPressed: () => _goStartSafety(context),
            )
          : null,

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) async {
          // Home is always allowed
          if (index == 0) {
            setState(() => _currentIndex = index);
            return;
          }

          // IDs / Contacts / Settings require unlock (if enabled)
          final ok = await _ensureUnlocked(context);
          if (!ok || !mounted) return;

          setState(() => _currentIndex = index);
        },
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.blueGrey,
        selectedLabelStyle: const TextStyle(),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.badge), label: 'IDs'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Contacts'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  // -----------------------------------------------------------
  // SECURITY CHECKS — ask for PIN if lock enabled + timed out
  // -----------------------------------------------------------
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

  // -----------------------------------------------------------
  // ACTIONS
  // -----------------------------------------------------------
  Future<void> _goStartSafety(BuildContext context) async {
    final ok = await _ensureUnlocked(context);
    if (!ok || !mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SosPreviewScreen()),
    );
  }

  Future<void> _goShowId(BuildContext context) async {
    final ok = await _ensureUnlocked(context);
    if (!ok || !mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EmergencyIdScreen()),
    );
  }

  // -----------------------------------------------------------
  // HOME PAGE
  // -----------------------------------------------------------
  Widget _buildHomePage(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Identity'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),

                  Icon(
                    Icons.shield,
                    size: 56,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'Your Safety',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: 30,
                      color: Colors.orange,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'Tap SOS to send your emergency message to your trusted contacts.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 18,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 18),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Quick check',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '• Make sure your Profile has your name + phone.\n'
                            '• Add at least one emergency contact.\n'
                            '• Turn on App Lock to protect IDs & settings.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: () => _goShowId(context),
                    icon: const Icon(Icons.badge),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'Show Emergency ID',
                        style: TextStyle(fontSize: 17),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // ✅ clearance so content never hides under the bottom SOS space
                  const SizedBox(height: 200),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StartSafetyBottomButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _StartSafetyBottomButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Start Safety',
              style: TextStyle(
                fontSize: 16,
                
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: GestureDetector(
                onTap: onPressed,
                child: Container(
                  width: 155,
                  height: 155,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.orange,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.4),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 54,
                        color: Colors.white,
                      ),
                      SizedBox(height: 6),
                      Text(
                        'SOS',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap to review and send your SOS message',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
