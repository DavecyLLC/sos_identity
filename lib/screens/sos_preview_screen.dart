import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

import '../models/contact_model.dart';
import '../models/user_profile.dart';
import '../models/id_model.dart';
import '../services/local_storage.dart';
import 'edit_sos_message_screen.dart';

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

  // Optional custom-edited message (if user changes text)
  String? _customEditedMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

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

    setState(() {
      _allContacts = contacts;
      _targetContacts = targets;
      _profile = profile;
      _emergencyId = emergencyId;
      _loading = false;
    });
  }

  Future<void> _toggleIncludeLocation(bool value) async {
    if (!value) {
      // User turned it OFF
      setState(() {
        _includeLocation = false;
        _lastPosition = null;
        // Optional: clear custom message if it depended on location
        // _customEditedMessage = null;
      });
      return;
    }

    // Turn ON → get location
    setState(() {
      _gettingLocation = true;
    });

    try {
      // Check if location services are enabled
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

      // Check permission
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
                  'Location permission denied. Cannot include GPS link in SOS.'),
            ),
          );
        }
        setState(() {
          _includeLocation = false;
        });
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _includeLocation = true;
        _lastPosition = position;
        // Optional: clear custom message so template refreshes
        // _customEditedMessage = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location added to SOS message.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to get location.'),
          ),
        );
      }
      setState(() {
        _includeLocation = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _gettingLocation = false;
        });
      }
    }
  }

  String _buildSosMessage() {
    final name = _profile.fullName.trim();
    final bloodType = _profile.bloodType.trim();
    final medical = _profile.medicalNotes.trim();
    final emergencyType = _selectedEmergencyType.trim();

    final buffer = StringBuffer();

    // Who + app
    if (name.isNotEmpty) {
      buffer.write(
          'This is an SOS alert from $name via the SOS Identity app. ');
    } else {
      buffer.write(
          'This is an SOS alert from your contact via the SOS Identity app. ');
    }

    buffer.write(
        'They indicated they may be in trouble and want you to check on them.');

    // Emergency type
    if (emergencyType.isNotEmpty) {
      buffer.write(' Emergency type: $emergencyType.');
    }

    // Blood type if known
    if (bloodType.isNotEmpty) {
      buffer.write(' Reported blood type: $bloodType.');
    }

    // Medical notes if present
    if (medical.isNotEmpty) {
      buffer.write(' Medical notes: $medical');
    }

    // Emergency ID if set
    if (_emergencyId != null) {
      buffer.write(
          ' Primary ID: ${_emergencyId!.type} (${_emergencyId!.number}, ${_emergencyId!.country}).');
    }

    // Location
    if (_includeLocation && _lastPosition != null) {
      final lat = _lastPosition!.latitude.toStringAsFixed(6);
      final lng = _lastPosition!.longitude.toStringAsFixed(6);
      final mapsUrl = 'https://maps.google.com/?q=$lat,$lng';
      buffer.write('\n\nLocation: $mapsUrl');
    } else {
      buffer.write('\n\nLocation: not shared');
    }

    // Placeholder for images (future)
    buffer.write('\nID image: (not attached yet)');

    return buffer.toString();
  }

  Future<void> _sendSosViaSms() async {
    if (_targetContacts.isEmpty) return;

    final phone = _targetContacts.first.phone.trim();
    if (phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('First emergency contact has no phone number.'),
          ),
        );
      }
      return;
    }

    // Use edited message if available, otherwise build default
    final message = _customEditedMessage ?? _buildSosMessage();

    final uri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: {'body': message},
    );

    if (await canLaunchUrl(uri)) {
      final ok = await launchUrl(uri);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open SMS app.'),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'SMS sending is only available on a phone. Run this app on Android/iOS to use SOS SMS.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _openEditor() async {
    final initialText = _customEditedMessage ?? _buildSosMessage();

    final edited = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => EditSosMessageScreen(initialText: initialText),
      ),
    );

    if (edited != null) {
      setState(() {
        _customEditedMessage = edited.trim();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SOS message updated.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('SOS'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final hasContacts = _allContacts.isNotEmpty;
    final hasProfile = _profile.fullName.isNotEmpty ||
        _profile.bloodType.isNotEmpty ||
        _profile.medicalNotes.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS'),
      ),
      body: hasContacts
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Review SOS details',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose the type of emergency and what information to share with your trusted contacts.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),

                  // Emergency type selector
                  Text(
                    'Type of emergency',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedEmergencyType,
                    items: _emergencyTypes
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(t),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedEmergencyType = value;
                        // Optional: clear custom message so it regenerates
                        // _customEditedMessage = null;
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // GPS toggle
                  SwitchListTile(
                    title: const Text('Include GPS location link'),
                    subtitle: Text(
                      _includeLocation && _lastPosition != null
                          ? 'Location will be added to the message.'
                          : 'Turn on to include your current location.',
                    ),
                    value: _includeLocation,
                    onChanged: _gettingLocation
                        ? null
                        : (value) => _toggleIncludeLocation(value),
                  ),
                  if (_gettingLocation) ...[
                    const SizedBox(height: 4),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 12),
                  ],

                  // Profile summary card (if any data)
                  if (hasProfile) ...[
                    Text(
                      'Your profile (included in alert)',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(
                          _profile.fullName.isEmpty
                              ? 'No name set'
                              : _profile.fullName,
                        ),
                        subtitle: Text(
                          _profile.bloodType.isEmpty
                              ? 'Blood type not set'
                              : 'Blood type: ${_profile.bloodType}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_emergencyId != null) ...[
                    Text(
                      'ID used in SOS',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
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

                  // Contacts section
                  Text(
                    'Who will be notified',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_targetContacts.isEmpty)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.warning_amber_rounded),
                        title: const Text('No contacts selected'),
                        subtitle: const Text(
                          'Add emergency contacts and mark at least one as primary.',
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _targetContacts.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final c = _targetContacts[index];
                        return Card(
                          child: ListTile(
                            leading: Icon(
                              c.isPrimary
                                  ? Icons.star
                                  : Icons.person_outline,
                            ),
                            title: Text(c.name),
                            subtitle: Text(c.phone),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 16),

                  // Edit message + send
                  FilledButton.tonalIcon(
                    onPressed: _openEditor,
                    icon: const Icon(Icons.edit),
                    label: Text(
                      _customEditedMessage == null
                          ? 'Edit message (optional)'
                          : 'Edit message (customized)',
                    ),
                  ),
                  const SizedBox(height: 16),

                  FilledButton.icon(
                    onPressed:
                        _targetContacts.isEmpty ? null : _sendSosViaSms,
                    icon: const Icon(Icons.sms),
                    label: const Text('Send SOS via SMS'),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 72,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No emergency contacts yet',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
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
