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
          if (index == 0) {
            setState(() => _currentIndex = index);
            return;
          }

          final ok = await _ensureUnlocked(context);
          if (!ok || !mounted) return;

          setState(() => _currentIndex = index);
        },
        selectedItemColor: const Color(0xFFF0A160),
        unselectedItemColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF4C5D70),
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
      MaterialPageRoute(builder: (_) => const LockScreen(setupMode: false)),
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
  // HOME PAGE (RESPONSIVE)
  // -----------------------------------------------------------
  Widget _buildHomePage(BuildContext context) {
    final theme = Theme.of(context);

    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    final isSmallPhone = w < 360 || h < 700;

    // Scale down gently on small devices; keep normal on larger devices.
    double s(double v) => isSmallPhone ? v * 0.88 : v;

    // BottomSheet height estimate (so content never hides behind it)
    final bottomSheetHeight = isSmallPhone ? 240.0 : 280.0;

    return Scaffold(
      appBar: AppBar(title: const Text('SOS Identity')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, bottomSheetHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: s(8)),

                      Icon(
                        Icons.shield,
                        size: s(56),
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(height: s(12)),

                      Text(
                        'Your Safety',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontSize: isSmallPhone ? 24 : 30,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF4C5D70),
                          height: 1.1,
                        ),
                      ),

                      SizedBox(height: s(10)),

                      Text(
                        'Tap SOS to send your emergency message to your trusted contacts.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: isSmallPhone ? 15.5 : 18,
                          height: 1.3,
                        ),
                      ),

                      SizedBox(height: s(18)),

                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(s(14)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: theme.colorScheme.primary,
                                    size: s(22),
                                  ),
                                  SizedBox(width: s(8)),
                                  Text(
                                    'Quick check',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: isSmallPhone ? 16 : null,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: s(10)),
                              Text(
                                '• Make sure your Profile has your name + phone.\n'
                                '• Add at least one emergency contact.\n'
                                '• Turn on App Lock to protect IDs & settings.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.35,
                                  fontSize: isSmallPhone ? 13.5 : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: s(12)),

                      OutlinedButton.icon(
                        onPressed: () => _goShowId(context),
                        icon: const Icon(Icons.badge),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallPhone ? 10 : 12,
                            horizontal: 12,
                          ),
                        ),
                        label: Text(
                          'Show Emergency ID',
                          style: TextStyle(
                            fontSize: isSmallPhone ? 15.5 : 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    final isSmallPhone = w < 360 || h < 700;

    double s(double v) => isSmallPhone ? v * 0.88 : v;

    final buttonSize = isSmallPhone ? 120.0 : 155.0;
    final iconSize = isSmallPhone ? 42.0 : 54.0;
    final sosTextSize = isSmallPhone ? 20.0 : 24.0;

    return SafeArea(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: s(14)),
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
            Text(
              'Start Safety',
              style: TextStyle(
                fontSize: isSmallPhone ? 14 : 16,
                fontWeight: FontWeight.w300,
              ),
            ),
            SizedBox(height: s(10)),
            Center(
              child: GestureDetector(
                onTap: onPressed,
                child: Container(
                  width: buttonSize,
                  height: buttonSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF4C5D70),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4C5D70).withOpacity(0.35),
                        blurRadius: isSmallPhone ? 14 : 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: iconSize,
                        color: Colors.white,
                      ),
                      SizedBox(height: s(6)),
                      Text(
                        'SOS',
                        style: TextStyle(
                          fontSize: sosTextSize,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: s(6)),
            Text(
              'Tap to review and send your SOS message',
              style: TextStyle(
                fontSize: isSmallPhone ? 12 : 13,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
