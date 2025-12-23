import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

import '../models/contact_model.dart';
import '../models/id_model.dart';
import '../models/user_profile.dart';
import '../services/local_storage.dart';
import 'edit_sos_message_screen.dart';
import 'profile_screen.dart';
import 'package:flutter_sms/flutter_sms.dart';


class SosPreviewScreen extends StatefulWidget {
  const SosPreviewScreen({super.key});

  @override
  State<SosPreviewScreen> createState() => _SosPreviewScreenState();
}

class _SosPreviewScreenState extends State<SosPreviewScreen> {
  List<ContactModel> _allContacts = [];
  List<ContactModel> _targetContacts = [];
  UserProfile _profile = UserProfile.empty;
  IdModel? _emergencyId;

  bool _loading = true;

  // Emergency type selection
  final List<String> _emergencyTypes = const [
    'Medical emergency',
    'Personal safety / threat',
    'Accident or injury',
    'Lost / missing / stranded',
    'Other',
  ];
  String _selectedEmergencyType = 'Personal safety / threat';

  // GPS / location state
  bool _includeLocation = false;
  bool _gettingLocation = false;
  Position? _lastPosition;

  // Optional custom-edited message
  String? _customEditedMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // -----------------------------
  // LOAD
  // -----------------------------
  Future<void> _loadData() async {
    final contacts = await LocalStorage.loadContacts();
    final profile = await LocalStorage.loadProfile() ?? UserProfile.empty;
    final ids = await LocalStorage.loadIds();
    final emergencyRef = await LocalStorage.getEmergencyIdRef();

    IdModel? emergencyId;
    if (emergencyRef != null) {
      emergencyId = ids.cast<IdModel?>().firstWhere(
            (id) =>
                id != null &&
                id.type == emergencyRef['type'] &&
                id.number == emergencyRef['number'],
            orElse: () => null,
          );
    }

    final primary = contacts.where((c) => c.isPrimary).toList();
    final targets = primary.isNotEmpty ? primary : contacts;

    if (!mounted) return;
    setState(() {
      _allContacts = contacts;
      _targetContacts = targets;
      _profile = profile;
      _emergencyId = emergencyId;
      _loading = false;
    });
  }

  // -----------------------------
  // PROFILE REQUIRED
  // -----------------------------
  bool get _profileComplete =>
      _profile.fullName.trim().isNotEmpty &&
      _profile.phoneNumber.trim().isNotEmpty;

  Future<void> _ensureProfileBeforeSending() async {
    if (_profileComplete) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Please complete your Profile (name + phone) before sending SOS.',
        ),
      ),
    );

    final updated = await Navigator.of(context).push<UserProfile>(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );

    if (!mounted) return;

    if (updated != null) {
      setState(() {
        _profile = updated;
        _customEditedMessage = null; // refresh template with new info
      });
      return;
    }

    // Reload in case profile was saved and returned without a value
    final reloaded = await LocalStorage.loadProfile();
    if (reloaded != null && mounted) {
      setState(() {
        _profile = reloaded;
        _customEditedMessage = null;
      });
    }
  }

  // -----------------------------
  // LOCATION TOGGLE
  // -----------------------------
  Future<void> _toggleIncludeLocation(bool value) async {
    if (!value) {
      setState(() {
        _includeLocation = false;
        _lastPosition = null;
      });
      return;
    }

    setState(() {
      _gettingLocation = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location services are disabled on this device.'),
            ),
          );
        }
        setState(() {
          _includeLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission denied. Cannot include GPS link in SOS.',
              ),
            ),
          );
        }
        setState(() {
          _includeLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() {
        _includeLocation = true;
        _lastPosition = position;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location added to SOS message.')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to get location.')),
        );
      }
      setState(() {
        _includeLocation = false;
      });
    } finally {
      if (mounted) {
        setState(() => _gettingLocation = false);
      }
    }
  }

  // -----------------------------
  // MESSAGE TEMPLATE
  // -----------------------------
  String _buildSosMessage() {
    final name = _profile.fullName.trim();
    final senderPhone = _profile.phoneNumber.trim();
    final bloodType = _profile.bloodType.trim();
    final medical = _profile.medicalNotes.trim();
    final emergencyType = _selectedEmergencyType.trim();

    final buffer = StringBuffer();

    // Header
    if (name.isNotEmpty) {
      buffer.write('This is an SOS alert from "$name" via the SOS Identity app. ');
    } else {
      buffer.write('This is an SOS alert via the SOS Identity app. ');
    }

    buffer.write('They indicated they may be in trouble and want you to check on them.');

    // Emergency type
    if (emergencyType.isNotEmpty) {
      buffer.write(' Emergency type: $emergencyType.');
    }

    // Blood type
    if (bloodType.isNotEmpty) {
      buffer.write(' Reported blood type: $bloodType.');
    }

    // Medical notes
    if (medical.isNotEmpty) {
      buffer.write(' Medical notes: $medical');
    }

    // Emergency ID
    if (_emergencyId != null) {
      buffer.write(
        ' Primary ID: ${_emergencyId!.type} '
        '(${_emergencyId!.number}, ${_emergencyId!.country}).',
      );
    }

    // Location
    if (_includeLocation && _lastPosition != null) {
      final lat = _lastPosition!.latitude.toStringAsFixed(6);
      final lng = _lastPosition!.longitude.toStringAsFixed(6);
      buffer.write('\n\nLocation: https://maps.google.com/?q=$lat,$lng');
    } else {
      buffer.write('\n\nLocation: not shared');
    }

    // Placeholder
    buffer.write('\nID image: (not attached yet)');

    // Footer: MUST include sender info
    buffer.write('\n\n— Sender info —');
    buffer.write('\nName: ${name.isNotEmpty ? name : "Not provided"}');
    buffer.write('\nPhone: ${senderPhone.isNotEmpty ? senderPhone : "Not provided"}');

    return buffer.toString();
  }

  // -----------------------------
  // SEND SMS (ALL TRUSTED CONTACTS)
  // -----------------------------
  Future<void> _sendSosViaSms() async {
      await _ensureProfileBeforeSending();
      if (!_profileComplete) return;

      if (_targetContacts.isEmpty) return;

      final phones = _targetContacts
          .map((c) => c.phone.trim())
          .where((p) => p.isNotEmpty)
          .toSet()
          .toList();

      if (phones.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No selected emergency contacts have phone numbers.'),
          ),
        );
        return;
      }

      final message = (_customEditedMessage ?? _buildSosMessage()).trim();

      try {
        // ✅ Opens Messages with ALL recipients filled
        await sendSMS(
          message: message,
          recipients: phones,
          sendDirect: false, // App Store-safe (shows composer)
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open Messages: $e')),
        );
      }
    }


  // -----------------------------
  // EDIT MESSAGE
  // -----------------------------
  Future<void> _openEditor() async {
    await _ensureProfileBeforeSending();
    if (!_profileComplete) return;

    final initialText = _customEditedMessage ?? _buildSosMessage();

    final edited = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => EditSosMessageScreen(initialText: initialText),
      ),
    );

    if (edited != null && mounted) {
      setState(() {
        _customEditedMessage = edited.trim();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SOS message updated.')),
      );
    }
  }

  // -----------------------------
  // UI
  // -----------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('SOS')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final hasContacts = _allContacts.isNotEmpty;

    // ✅ Fixed action bar height so scroll content doesn't hide under it
    const double actionBarHeight = 150;

    return Scaffold(
      appBar: AppBar(title: const Text('SOS')),

      // ✅ FIX: buttons always visible
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton.tonalIcon(
                onPressed: hasContacts ? _openEditor : null,
                icon: const Icon(Icons.edit),
                label: Text(
                  _customEditedMessage == null
                      ? 'Edit message (optional)'
                      : 'Edit message (customized)',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: (!hasContacts || _targetContacts.isEmpty)
                    ? null
                    : _sendSosViaSms,
                icon: const Icon(Icons.sms),
                label: Text(
                  _targetContacts.isEmpty
                      ? 'Send SOS via SMS'
                      : 'Send SOS to ${_targetContacts.length} contact(s)',
                ),
              ),
            ],
          ),
        ),
      ),

      body: hasContacts
          ? SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, actionBarHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Review SOS details', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Choose the type of emergency and what information to share with your trusted contacts.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),

                  if (!_profileComplete) ...[
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text('Profile required'),
                        subtitle: const Text(
                          'Add your name + phone number before sending SOS.',
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: theme.colorScheme.primary,
                        ),
                        onTap: _ensureProfileBeforeSending,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    Text(
                      'Your profile (included in alert)',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(_profile.fullName),
                        subtitle: Text('Phone: ${_profile.phoneNumber}'),
                        trailing:
                            Icon(Icons.edit, color: theme.colorScheme.primary),
                        onTap: _ensureProfileBeforeSending,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Text('Type of emergency', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    value: _selectedEmergencyType,
                    items: _emergencyTypes
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedEmergencyType = value);
                    },
                    decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                  ),

                  const SizedBox(height: 16),

                  SwitchListTile(
                    title: const Text('Include GPS location link'),
                    subtitle: Text(
                      _includeLocation && _lastPosition != null
                          ? 'Location will be added to the message.'
                          : 'Turn on to include your current location.',
                    ),
                    value: _includeLocation,
                    onChanged: _gettingLocation ? null : _toggleIncludeLocation,
                  ),

                  if (_gettingLocation) ...[
                    const SizedBox(height: 4),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 12),
                  ],

                  if (_emergencyId != null) ...[
                    Text('ID used in SOS', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.badge),
                        title: Text(_emergencyId!.type),
                        subtitle: Text(
                          'No: ${_emergencyId!.number}\nCountry: ${_emergencyId!.country}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Text('Who will be notified',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),

                  if (_targetContacts.isEmpty)
                    const Card(
                      child: ListTile(
                        leading: Icon(Icons.warning_amber_rounded),
                        title: Text('No contacts selected'),
                        subtitle: Text(
                          'Add emergency contacts and mark at least one as primary.',
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _targetContacts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final c = _targetContacts[index];
                        return Card(
                          child: ListTile(
                            leading: Icon(
                                c.isPrimary ? Icons.star : Icons.person_outline),
                            title: Text(c.name),
                            subtitle: Text(c.phone),
                          ),
                        );
                      },
                    ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 72, color: Colors.orange),
                  const SizedBox(height: 16),
                  Text(
                    'No emergency contacts yet',
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add at least one emergency contact so SOS Identity knows who to notify.',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }
}
