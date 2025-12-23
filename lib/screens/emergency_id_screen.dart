import 'dart:io';

import 'package:flutter/material.dart';

import '../models/id_model.dart';
import '../services/local_storage.dart';
import '../services/sms_service.dart';

class EmergencyIdScreen extends StatefulWidget {
  const EmergencyIdScreen({super.key});

  @override
  State<EmergencyIdScreen> createState() => _EmergencyIdScreenState();
}

class _EmergencyIdScreenState extends State<EmergencyIdScreen> {
  bool _loading = true;
  IdModel? _emergencyId;
  List<IdModel> _allIds = [];

  @override
  void initState() {
    super.initState();
    _loadEmergencyId();
  }

  Future<void> _loadEmergencyId() async {
    final ids = await LocalStorage.loadIds();
    final ref = await LocalStorage.getEmergencyIdRef();

    IdModel? emergency;
    if (ref != null) {
      emergency = ids.cast<IdModel?>().firstWhere(
            (id) =>
                id != null &&
                id.type == ref['type'] &&
                id.number == ref['number'],
            orElse: () => null,
          );
    }

    setState(() {
      _allIds = ids;
      _emergencyId = emergency;
      _loading = false;
    });
  }

  Widget _buildImageCard(String label, String? path) {
    final hasImage =
        path != null && path.isNotEmpty && File(path).existsSync();

    if (!hasImage) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.photo),
          title: Text(label),
          subtitle: const Text('No image added'),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: const Icon(Icons.photo),
            title: Text(label),
          ),
          SizedBox(
            height: 220,
            child: Image.file(
              File(path),
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 1) Loading state
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Show ID'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 2) No IDs at all
    if (_allIds.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Show ID'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.badge, size: 64),
                const SizedBox(height: 16),
                Text(
                  'You have no IDs saved yet.',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Go to the IDs tab and add at least one ID.\n'
                  'Then mark one as your emergency ID.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 3) IDs exist, but none marked as emergency
    if (_emergencyId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Show ID'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield_outlined, size: 64),
                const SizedBox(height: 16),
                Text(
                  'No emergency ID selected',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Open any ID in the IDs tab and tap\n'
                  '“Use this ID in SOS alerts”.\n\n'
                  'That ID will show up here for quick access.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 4) We have an emergency ID – show it nicely
    final id = _emergencyId!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Emergency ID'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.badge),
                title: Text(
                  id.type,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('No: ${id.number}'),
                trailing: const Icon(Icons.shield),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.flag),
                title: const Text('Country / Issuer'),
                subtitle: Text(id.country),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.event),
                title: const Text('Expiry date'),
                subtitle: Text(
                  id.expiryDate.isEmpty ? 'Not set' : id.expiryDate,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ID images',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildImageCard('Front side', id.frontImagePath),
            const SizedBox(height: 8),
            _buildImageCard('Back side', id.backImagePath),
            const SizedBox(height: 16),
            Text(
              'Tip',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'You can show this screen to responders if you lose your physical ID.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
