import 'package:flutter/material.dart';
import '../services/local_storage.dart';

class TermsAcceptScreen extends StatefulWidget {
  final Future<void> Function() onAccepted;

  const TermsAcceptScreen({
    super.key,
    required this.onAccepted,
  });

  @override
  State<TermsAcceptScreen> createState() => _TermsAcceptScreenState();
}

class _TermsAcceptScreenState extends State<TermsAcceptScreen> {
  bool _acceptChecked = false;
  bool _saving = false;

  Future<void> _accept() async {
    if (!_acceptChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please check the box to accept the terms.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await LocalStorage.setTermsAccepted(true);
      await widget.onAccepted();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SOS Identity – Terms & Conditions',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Please read these terms carefully before using SOS Identity.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),

                      _h(theme, '1. Purpose of the App'),
                      const Text(
                        'SOS Identity helps you store ID information, profile details, and trusted contacts, and prepare an SOS message you can send. It does not replace emergency services.',
                      ),
                      const SizedBox(height: 12),

                      _h(theme, '2. No Emergency Service or Guarantee'),
                      const Text(
                        'SOS Identity does not contact emergency services and does not guarantee delivery or response from contacts. Call local emergency services when needed.',
                      ),
                      const SizedBox(height: 12),

                      _h(theme, '3. Data Storage and Security'),
                      const Text(
                        'Your data is stored locally on your device. The app does not upload to Davecy LLC or external servers. Protect your device using OS security features.',
                      ),
                      const SizedBox(height: 12),

                      _h(theme, '4. Phone Security'),
                      const Text(
                        'If someone has access to your unlocked phone, they may view data in this app. Use device PIN/password/biometrics.',
                      ),
                      const SizedBox(height: 12),

                      _h(theme, '5. No Liability – Davecy LLC'),
                      const Text(
                        'You use the app at your own risk. Davecy LLC is not responsible for damages arising from use or inability to use the app, including missed/unsent/unseen SOS messages.',
                      ),
                      const SizedBox(height: 12),

                      _h(theme, '6. Accuracy of Information'),
                      const Text(
                        'You are responsible for keeping stored information accurate and up to date.',
                      ),
                      const SizedBox(height: 12),

                      _h(theme, '7. Changes to the App and Terms'),
                      const Text(
                        'The app and these terms may change over time. Continued use means you accept updated terms.',
                      ),
                      const SizedBox(height: 12),

                      _h(theme, '8. Acceptance'),
                      const Text(
                        'By accepting, you confirm you have read and agree to these terms.',
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Checkbox(
                    value: _acceptChecked,
                    onChanged: _saving ? null : (v) => setState(() => _acceptChecked = v ?? false),
                  ),
                  const Expanded(
                    child: Text('I have read and agree to the Terms & Conditions.'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _accept,
                  child: _saving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('I Accept'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _h(ThemeData theme, String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        t,
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
