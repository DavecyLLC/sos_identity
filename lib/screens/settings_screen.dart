import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/local_storage.dart';
import 'lock_screen.dart';
import 'terms_accept_screen.dart';
import 'profile_screen.dart'; // ✅ ADD

// TODO: put your real GitHub Pages URL here:
const String _privacyPolicyUrl = 'https://davecyllc.github.io/SOS-Identity-App/';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _lockEnabled = false;
  bool _termsAccepted = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final lockEnabled = await LocalStorage.getLockEnabled();
    final termsAccepted = await LocalStorage.getTermsAccepted();
    setState(() {
      _lockEnabled = lockEnabled;
      _termsAccepted = termsAccepted;
      _loading = false;
    });
  }

  Future<void> _toggleLock(bool value) async {
    if (value == _lockEnabled) return;

    if (value == true) {
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => const LockScreen(setupMode: true),
        ),
      );
      if (ok == true) {
        await LocalStorage.setLockEnabled(true);
        setState(() => _lockEnabled = true);
      }
    } else {
      await LocalStorage.setLockEnabled(false);
      setState(() => _lockEnabled = false);
    }
  }

  Future<void> _openTerms() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const TermsAcceptScreen(),
      ),
    );
    final accepted = await LocalStorage.getTermsAccepted();
    setState(() => _termsAccepted = accepted);
  }

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse(_privacyPolicyUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open Privacy Policy.'),
        ),
      );
    }
  }

  Future<void> _openProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // PROFILE SECTION ✅ NEW
          Text(
            'Profile',
            style:
                theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Your Profile'),
            subtitle: const Text('Your name + phone are included in SOS alerts'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _openProfile,
          ),

          const SizedBox(height: 24),

          // SECURITY SECTION
          Text(
            'Security',
            style:
                theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          SwitchListTile(
            title: const Text('App Lock (PIN)'),
            subtitle: const Text(
              'Require a PIN to view IDs, contacts, and SOS features.',
            ),
            value: _lockEnabled,
            onChanged: _toggleLock,
          ),

          if (_lockEnabled) ...[
            ListTile(
              leading: const Icon(Icons.lock_reset),
              title: const Text('Change PIN'),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LockScreen(setupMode: true),
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 24),

          // LEGAL SECTION
          Text(
            'Legal & Info',
            style:
                theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          ListTile(
            leading: const Icon(Icons.article),
            title: const Text('Terms & Conditions'),
            subtitle: Text(_termsAccepted ? 'Accepted' : 'Not accepted yet'),
            onTap: _openTerms,
          ),

          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            subtitle: const Text('Opens in your browser'),
            onTap: _openPrivacyPolicy,
          ),

          const SizedBox(height: 24),

          // APP INFO SECTION
          Text(
            'App',
            style:
                theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About SOS Identity'),
            subtitle: Text(
              'SOS Identity is a personal safety and identity tool by Davecy LLC.',
            ),
          ),
        ],
      ),
    );
  }
}
