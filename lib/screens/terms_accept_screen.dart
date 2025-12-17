import 'package:flutter/material.dart';
import '../services/local_storage.dart';

class TermsAcceptScreen extends StatefulWidget {
  const TermsAcceptScreen({super.key});

  @override
  State<TermsAcceptScreen> createState() => _TermsAcceptScreenState();
}

class _TermsAcceptScreenState extends State<TermsAcceptScreen> {
  bool _acceptChecked = false;
  bool _saving = false;

  Future<void> _onAccept() async {
    if (!_acceptChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please check the box to confirm you accept the terms.'),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    await LocalStorage.setTermsAccepted(true);

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 🔹 Scrollable area for the long text
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SOS Identity – Terms & Conditions',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Please read these terms carefully before using SOS Identity.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),

                      Text(
                        '1. Purpose of the App',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'SOS Identity is designed to help you store ID information, personal profile details, and '
                        'emergency contacts, and to quickly prepare an SOS message that you can send to people you trust. '
                        'It is a supportive tool and does not replace emergency services.',
                      ),
                      const SizedBox(height: 12),

                      Text(
                        '2. No Emergency Service or Guarantee',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'SOS Identity does not contact emergency services automatically and does not guarantee that your '
                        'contacts will respond, be available, or be able to help you. You remain responsible for calling '
                        'local emergency services directly when needed.',
                      ),
                      const SizedBox(height: 12),

                      Text(
                        '3. Data Storage and Security',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Your data (IDs, contacts, profile information) is stored locally on your device. '
                        'The app does not send this information to Davecy LLC or any external server. '
                        'You are responsible for securing your device (using screen lock, device password, etc.).',
                      ),
                      const SizedBox(height: 12),

                      Text(
                        '4. Phone Security',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'The security of your information depends heavily on the security of your phone. '
                        'If someone has access to your unlocked device, they may be able to view information stored in the app. '
                        'Using device-level security (PIN, password, biometrics) is strongly recommended.',
                      ),
                      const SizedBox(height: 12),

                      Text(
                        '5. No Liability – Davecy LLC',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'SOS Identity and Davecy LLC are not responsible for any direct, indirect, incidental, or consequential '
                        'damages that arise from the use of, inability to use, or misuse of the app. This includes, but is not '
                        'limited to, situations where an SOS message is not sent, not received, or not acted upon by your contacts. '
                        'You use the app at your own risk and remain fully responsible for your own safety decisions.',
                      ),
                      const SizedBox(height: 12),

                      Text(
                        '6. Accuracy of Information',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'You are responsible for making sure that all information you store in the app (IDs, contact numbers, '
                        'medical notes, etc.) is accurate, up to date, and appropriate to share with your trusted contacts.',
                      ),
                      const SizedBox(height: 12),

                      Text(
                        '7. Changes to the App and Terms',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Davecy LLC may update or change the app or these terms at any time. Continued use of the app after changes '
                        'have been published means you accept the updated terms.',
                      ),
                      const SizedBox(height: 12),

                      Text(
                        '8. Acceptance',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'By tapping "I Accept" and using SOS Identity, you confirm that you have read, understood, and agree to these terms.',
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // 🔹 Checkbox row
              Row(
                children: [
                  Checkbox(
                    value: _acceptChecked,
                    onChanged: (v) {
                      setState(() {
                        _acceptChecked = v ?? false;
                      });
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'I have read and agree to the Terms & Conditions.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 🔹 Buttons at the bottom
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () {
                              Navigator.of(context).pop(false);
                            },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _onAccept,
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
            ],
          ),
        ),
      ),
    );
  }
}
