import 'package:flutter/material.dart';
import '../services/local_storage.dart';

class TermsAcceptScreen extends StatefulWidget {
  /// Called after terms are successfully accepted & saved.
  /// Use this to route to Dashboard (or refresh your gate).
  final VoidCallback onAccepted;

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

  Future<void> _onAccept() async {
    if (_saving) return;

    if (!_acceptChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please check the box to confirm you accept the terms.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await LocalStorage.setTermsAccepted(true);

      if (!mounted) return;

      // Fire callback so parent decides how to navigate
      widget.onAccepted();
    } catch (e) {
      if (!mounted) return;

      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save acceptance. Please try again.'),
        ),
      );
    }
  }

  void _onCancel() {
    if (_saving) return;
    Navigator.of(context).pop(false);
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
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Scrollbar(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SOS Identity – Terms & Conditions',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Please read these terms carefully before using SOS Identity.',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),

                            _sectionTitle(theme, '1. Purpose of the App'),
                            const Text(
                              'SOS Identity helps you store ID information, personal profile details, and emergency contacts, '
                              'and quickly prepare an SOS message you can send to people you trust. '
                              'It does not replace emergency services.',
                            ),
                            const SizedBox(height: 12),

                            _sectionTitle(theme, '2. No Emergency Service or Guarantee'),
                            const Text(
                              'SOS Identity does not contact emergency services automatically and does not guarantee that your '
                              'contacts will respond, be available, or be able to help you. You remain responsible for calling '
                              'local emergency services directly when needed.',
                            ),
                            const SizedBox(height: 12),

                            _sectionTitle(theme, '3. Data Storage and Security'),
                            const Text(
                              'Your data (IDs, contacts, profile information) is stored locally on your device. '
                              'The app does not send this information to Davecy LLC or any external server. '
                              'You are responsible for securing your device (screen lock, device password, etc.).',
                            ),
                            const SizedBox(height: 12),

                            _sectionTitle(theme, '4. Phone Security'),
                            const Text(
                              'The security of your information depends heavily on the security of your phone. '
                              'If someone has access to your unlocked device, they may be able to view information stored in the app. '
                              'Using device-level security (PIN, password, biometrics) is strongly recommended.',
                            ),
                            const SizedBox(height: 12),

                            _sectionTitle(theme, '5. No Liability – Davecy LLC'),
                            const Text(
                              'SOS Identity and Davecy LLC are not responsible for any direct, indirect, incidental, or consequential '
                              'damages arising from use, inability to use, or misuse of the app. This includes cases where an SOS '
                              'message is not sent, not received, or not acted on. You use the app at your own risk.',
                            ),
                            const SizedBox(height: 12),

                            _sectionTitle(theme, '6. Accuracy of Information'),
                            const Text(
                              'You are responsible for ensuring the information you store (IDs, contact numbers, notes, etc.) '
                              'is accurate, up to date, and appropriate to share with trusted contacts.',
                            ),
                            const SizedBox(height: 12),

                            _sectionTitle(theme, '7. Changes to the App and Terms'),
                            const Text(
                              'Davecy LLC may update the app or these terms at any time. Continued use after changes are published '
                              'means you accept the updated terms.',
                            ),
                            const SizedBox(height: 12),

                            _sectionTitle(theme, '8. Acceptance'),
                            const Text(
                              'By tapping "I Accept", you confirm that you have read, understood, and agree to these terms.',
                            ),

                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _acceptChecked,
                    onChanged: _saving
                        ? null
                        : (v) => setState(() => _acceptChecked = v ?? false),
                  ),
                  const Expanded(
                    child: Text('I have read and agree to the Terms & Conditions.'),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : _onCancel,
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

  Widget _sectionTitle(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
