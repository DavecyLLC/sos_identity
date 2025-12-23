import 'package:flutter/material.dart';
import '../services/local_storage.dart';

class LockScreen extends StatefulWidget {
  final bool setupMode; // true = set PIN, false = unlock

  const LockScreen({super.key, required this.setupMode});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _pinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _pinCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool _isValidPin(String pin) {
    final p = pin.trim();
    return RegExp(r'^\d{4,8}$').hasMatch(p); // 4–8 digits
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _busy = true;
    });

    try {
      if (widget.setupMode) {
        final pin = _pinCtrl.text.trim();
        final confirm = _confirmCtrl.text.trim();

        if (!_isValidPin(pin)) {
          setState(() => _error = 'PIN must be 4–8 digits.');
          return;
        }
        if (pin != confirm) {
          setState(() => _error = 'PINs do not match.');
          return;
        }

        await LocalStorage.setPinCode(pin);
        await LocalStorage.setLockEnabled(true);
        await LocalStorage.setLastUnlockTime(DateTime.now());

        if (!mounted) return;
        Navigator.of(context).pop(true);
      } else {
        final entered = _pinCtrl.text.trim();
        final saved = await LocalStorage.getPinCode();

        if (saved == null || saved.isEmpty) {
          setState(() => _error = 'No PIN is set. Turn on App Lock in Settings.');
          return;
        }

        if (entered != saved) {
          setState(() => _error = 'Incorrect PIN.');
          return;
        }

        await LocalStorage.setLastUnlockTime(DateTime.now());

        if (!mounted) return;
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgotPinReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Forgot PIN?'),
        content: const Text(
          'For your security, resetting the PIN will erase saved IDs, contacts, and profile data on this device.\n\nDo you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await LocalStorage.resetPinAndWipeData();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PIN reset. Data cleared for security.')),
    );
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.setupMode ? 'Set App PIN' : 'Enter PIN';
    final subtitle = widget.setupMode
        ? 'Create a PIN to protect IDs, Contacts, and Settings.'
        : 'Enter your PIN to continue.';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(subtitle, textAlign: TextAlign.center),
                const SizedBox(height: 16),

                TextField(
                  controller: _pinCtrl,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 8,
                  decoration: const InputDecoration(
                    labelText: 'PIN (4–8 digits)',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                ),

                if (widget.setupMode) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmCtrl,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 8,
                    decoration: const InputDecoration(
                      labelText: 'Confirm PIN',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                  ),
                ],

                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],

                const SizedBox(height: 16),

                FilledButton.icon(
                  onPressed: _busy ? null : _submit,
                  icon: const Icon(Icons.lock),
                  label: Text(widget.setupMode ? 'Save PIN' : 'Unlock'),
                ),

                if (!widget.setupMode) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _busy ? null : _forgotPinReset,
                    child: const Text('Forgot PIN? Reset'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
