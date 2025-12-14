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

  late final TextEditingController _nameController;
  late final TextEditingController _dobController;
  late final TextEditingController _bloodTypeController;
  late final TextEditingController _medicalNotesController;

  bool _loading = true;
  UserProfile _currentProfile = UserProfile.empty;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _dobController = TextEditingController();
    _bloodTypeController = TextEditingController();
    _medicalNotesController = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await LocalStorage.loadProfile();
    setState(() {
      _currentProfile = profile ?? UserProfile.empty;
      _nameController.text = _currentProfile.fullName;
      _dobController.text = _currentProfile.dateOfBirth;
      _bloodTypeController.text = _currentProfile.bloodType;
      _medicalNotesController.text = _currentProfile.medicalNotes;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _bloodTypeController.dispose();
    _medicalNotesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;

    final updated = UserProfile(
      fullName: _nameController.text.trim(),
      dateOfBirth: _dobController.text.trim(),
      bloodType: _bloodTypeController.text.trim(),
      medicalNotes: _medicalNotesController.text.trim(),
    );

    await LocalStorage.saveProfile(updated);

    setState(() {
      _currentProfile = updated;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile & Medical Info'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Medical Info'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Quick summary card
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text(
                  _currentProfile.fullName.isEmpty
                      ? 'No name set'
                      : _currentProfile.fullName,
                ),
                subtitle: Text(
                  _currentProfile.bloodType.isEmpty
                      ? 'Blood type not set'
                      : 'Blood type: ${_currentProfile.bloodType}',
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Basic information',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Please enter your name'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _dobController,
                    decoration: const InputDecoration(
                      labelText: 'Date of birth',
                      hintText: 'e.g. 1990-05-21',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bloodTypeController,
                    decoration: const InputDecoration(
                      labelText: 'Blood type',
                      hintText: 'e.g. O+, A-, B+',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Medical notes',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _medicalNotesController,
                    decoration: const InputDecoration(
                      labelText: 'Allergies, conditions, medications…',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text('Save profile'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
