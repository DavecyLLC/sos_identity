import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/local_storage.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _blood = TextEditingController();
  final _medical = TextEditingController();

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await LocalStorage.loadProfile() ?? UserProfile.empty;

    _name.text = profile.fullName;
    _phone.text = profile.phoneNumber;
    _blood.text = profile.bloodType;
    _medical.text = profile.medicalNotes;

    if (mounted) setState(() => _loading = false);
  }

  String _normalizePhone(String s) {
    // Keep digits and leading + if present
    final trimmed = s.trim();
    final hasPlus = trimmed.startsWith('+');
    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    return hasPlus ? '+$digits' : digits;
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;

    final profile = UserProfile(
      fullName: _name.text.trim(),
      phoneNumber: _normalizePhone(_phone.text),
      bloodType: _blood.text.trim(),
      medicalNotes: _medical.text.trim(),
    );

    await LocalStorage.saveProfile(profile);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved.')),
    );
    Navigator.of(context).pop(profile);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _blood.dispose();
    _medical.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Your Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Your Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Your name and phone number are required and will be included in SOS alerts.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Full name (required)',
                ),
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return 'Please enter your name';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Your phone number (required)',
                  hintText: '+1 555 123 4567',
                ),
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return 'Please enter your phone number';
                  final digits = s.replaceAll(RegExp(r'[^0-9]'), '');
                  if (digits.length < 7) return 'Phone number looks too short';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _blood,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Blood type (optional)',
                  hintText: 'O+, A-, etc.',
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _medical,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Medical notes (optional)',
                  hintText: 'Allergies, conditions, medications…',
                ),
              ),
              const SizedBox(height: 20),

              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Save profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
