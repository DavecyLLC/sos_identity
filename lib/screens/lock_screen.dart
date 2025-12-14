import 'package:flutter/material.dart';

import '../services/local_storage.dart';

class LockScreen extends StatefulWidget {
  /// If true, we are setting a new PIN (user enters and confirms).
  /// If false, we are verifying PIN to unlock.
  final bool setupMode;

  const LockScreen({super.key, required this.setupMode});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();

  String? _errorText;
  bool _loading = false;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSetup() async {
    if (!_formKey.currentState!.validate()) return;

    final pin = _pinController.text.trim();
    final confirm = _confirmController.text.trim();

    if (pin != confirm) {
      setState(() {
        _errorText = 'PIN codes do not match.';
      });
      return;
    }

    setState(() {
      _errorText = null;
      _loading = true;
    });

    await LocalStorage.setPinCode(pin);
    await LocalStorage.setLastUnlockTime(DateTime.now());

    if (mounted) {
      Navigator.of(context).pop(true); // success
    }
  }

  Future<void> _handleVerify() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorText = null;
    });

    final storedPin = await LocalStorage.getPinCode();
    final entered = _pinController.text.trim();

    if (storedPin == null || storedPin.isEmpty) {
      setState(() {
        _errorText = 'No PIN is set. Disable lock or set a new PIN in Settings.';
        _loading = false;
      });
      return;
    }

    if (storedPin != entered) {
      setState(() {
        _errorText = 'Incorrect PIN. Try again.';
        _loading = false;
      });
      return;
    }

    await LocalStorage.setLastUnlockTime(DateTime.now());

    if (mounted) {
      Navigator.of(context).pop(true); // unlocked
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSetup = widget.setupMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSetup ? 'Set App PIN' : 'Unlock SOS Identity'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isSetup
                        ? 'Choose a 4-digit PIN to protect your IDs and SOS.'
                        : 'Enter your 4-digit PIN to continue.',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _pinController,
                    decoration: const InputDecoration(
                      labelText: 'PIN',
                      hintText: '4 digits',
                    ),
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    validator: (value) {
                      final v = value?.trim() ?? '';
                      if (v.length != 4) {
                        return 'PIN must be 4 digits.';
                      }
                      if (int.tryParse(v) == null) {
                        return 'PIN must be numbers only.';
                      }
                      return null;
                    },
                  ),
                  if (isSetup) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmController,
                      decoration: const InputDecoration(
                        labelText: 'Confirm PIN',
                      ),
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.length != 4) {
                          return 'Confirm your 4-digit PIN.';
                        }
                        return null;
                      },
                    ),
                  ],
                  if (_errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorText!,
                      style: TextStyle(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _loading
                        ? null
                        : () =>
                            isSetup ? _handleSetup() : _handleVerify(),
                    icon: Icon(isSetup ? Icons.check : Icons.lock_open),
                    label: Text(isSetup ? 'Save PIN' : 'Unlock'),
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
