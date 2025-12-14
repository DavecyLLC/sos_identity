import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/id_model.dart';
import '../services/local_storage.dart';

class IdsScreen extends StatefulWidget {
  const IdsScreen({super.key});

  @override
  State<IdsScreen> createState() => _IdsScreenState();
}

class _IdsScreenState extends State<IdsScreen> {
  List<IdModel> _ids = [];
  Map<String, String>? _emergencyIdRef;

  @override
  void initState() {
    super.initState();
    _loadIds();
  }

  bool _isEmergencyId(IdModel id) {
    if (_emergencyIdRef == null) return false;
    return id.type == _emergencyIdRef!['type'] &&
        id.number == _emergencyIdRef!['number'];
  }

  Future<void> _loadIds() async {
    final loaded = await LocalStorage.loadIds();
    final emergencyRef = await LocalStorage.getEmergencyIdRef();
    setState(() {
      _ids = loaded;
      _emergencyIdRef = emergencyRef;
    });
  }

  Future<void> _addId(IdModel id) async {
    setState(() {
      _ids.add(id);
    });
    await LocalStorage.saveIds(_ids);
  }

  Future<void> _updateId(int index, IdModel updated) async {
    setState(() {
      _ids[index] = updated;
    });
    await LocalStorage.saveIds(_ids);
  }

  Future<void> _deleteId(int index) async {
    setState(() {
      _ids.removeAt(index);
    });
    await LocalStorage.saveIds(_ids);
  }

  Future<void> _setEmergencyId(IdModel id) async {
    await LocalStorage.setEmergencyId(id);
    final emergencyRef = await LocalStorage.getEmergencyIdRef();
    setState(() {
      _emergencyIdRef = emergencyRef;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Set "${id.type}" as emergency ID.'),
        ),
      );
    }
  }

  Future<void> _openAddIdScreen() async {
    final newId = await Navigator.of(context).push<IdModel>(
      MaterialPageRoute(
        builder: (_) => const AddIdScreen(),
      ),
    );

    if (newId != null) {
      await _addId(newId);
    }
  }

  Future<void> _openEditIdScreen(int index) async {
    final idToEdit = _ids[index];

    final updatedId = await Navigator.of(context).push<IdModel>(
      MaterialPageRoute(
        builder: (_) => AddIdScreen(initialId: idToEdit),
      ),
    );

    if (updatedId != null) {
      await _updateId(index, updatedId);
    }
  }

  Future<bool?> _confirmDeleteDialog(IdModel id) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete ID'),
        content: Text(
          'Do you want to delete this ID?\n\n${id.type} (${id.number})',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your IDs'),
      ),
      body: _ids.isEmpty
          ? const Center(
              child: Text(
                'No IDs saved yet.\nTap "Add ID" to start.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _ids.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final id = _ids[index];
                final isEmergency = _isEmergencyId(id);

                // Thumbnail: front image if exists, otherwise icon
                Widget leading;
                if (id.frontImagePath != null &&
                    id.frontImagePath!.isNotEmpty &&
                    File(id.frontImagePath!).existsSync()) {
                  leading = CircleAvatar(
                    backgroundImage: FileImage(File(id.frontImagePath!)),
                  );
                } else {
                  leading = const Icon(Icons.badge);
                }

                return Dismissible(
                  key: ValueKey('${id.type}-${id.number}-$index'),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) => _confirmDeleteDialog(id),
                  onDismissed: (_) => _deleteId(index),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: Card(
                    child: ListTile(
                      leading: leading,
                      title: Row(
                        children: [
                          Expanded(child: Text(id.type)),
                          if (isEmergency)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.shield,
                                color: theme.colorScheme.primary,
                                size: 18,
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        'No: ${id.number}\nCountry: ${id.country} • Exp: ${id.expiryDate}',
                      ),
                      isThreeLine: true,
                      trailing: Icon(
                        Icons.edit,
                        color: theme.colorScheme.primary,
                      ),
                      onTap: () {
                        // View details (with emergency button)
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => IdDetailScreen(
                              id: id,
                              onSetEmergency: () => _setEmergencyId(id),
                              isEmergency: isEmergency,
                            ),
                          ),
                        );
                      },
                      onLongPress: () {
                        // Edit on long press
                        _openEditIdScreen(index);
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddIdScreen,
        icon: const Icon(Icons.add),
        label: const Text('Add ID'),
      ),
    );
  }
}

/// ---------- ADD / EDIT ID SCREEN (with images) ----------

class AddIdScreen extends StatefulWidget {
  final IdModel? initialId;

  const AddIdScreen({super.key, this.initialId});

  @override
  State<AddIdScreen> createState() => _AddIdScreenState();
}

class _AddIdScreenState extends State<AddIdScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _typeController;
  late final TextEditingController _numberController;
  late final TextEditingController _countryController;
  late final TextEditingController _expiryController;

  final ImagePicker _picker = ImagePicker();
  String? _frontImagePath;
  String? _backImagePath;

  @override
  void initState() {
    super.initState();

    _typeController = TextEditingController(
      text: widget.initialId?.type ?? '',
    );
    _numberController = TextEditingController(
      text: widget.initialId?.number ?? '',
    );
    _countryController = TextEditingController(
      text: widget.initialId?.country ?? '',
    );
    _expiryController = TextEditingController(
      text: widget.initialId?.expiryDate ?? '',
    );

    _frontImagePath = widget.initialId?.frontImagePath;
    _backImagePath = widget.initialId?.backImagePath;
  }

  @override
  void dispose() {
    _typeController.dispose();
    _numberController.dispose();
    _countryController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  Future<void> _chooseImage(bool isFront) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take photo'),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      imageQuality: 85,
    );

    if (picked == null) return;

    setState(() {
      if (isFront) {
        _frontImagePath = picked.path;
      } else {
        _backImagePath = picked.path;
      }
    });
  }

  void _save() {
    if (_formKey.currentState?.validate() != true) return;

    final id = IdModel(
      type: _typeController.text.trim(),
      number: _numberController.text.trim(),
      country: _countryController.text.trim(),
      expiryDate: _expiryController.text.trim(),
      frontImagePath: _frontImagePath,
      backImagePath: _backImagePath,
    );

    Navigator.of(context).pop(id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.initialId != null;

    Widget buildImageStatus(String label, String? path) {
      final hasImage = path != null && path.isNotEmpty;
      return Row(
        children: [
          Icon(
            hasImage ? Icons.check_circle : Icons.photo,
            color: hasImage ? Colors.green : theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasImage ? '$label added' : '$label not added',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit ID' : 'Add ID'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'ID details',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(
                  labelText: 'ID type',
                  hintText: 'Driver\'s License, Passport, Student ID…',
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Please enter an ID type'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _numberController,
                decoration: const InputDecoration(
                  labelText: 'ID number',
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Please enter the ID number'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(
                  labelText: 'Country / Issuer',
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Please enter the country / issuer'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _expiryController,
                decoration: const InputDecoration(
                  labelText: 'Expiry date',
                  hintText: 'e.g. 2028-02-12',
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'ID photos (optional)',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _chooseImage(true),
                icon: const Icon(Icons.credit_card),
                label: const Text('Add front photo'),
              ),
              const SizedBox(height: 4),
              buildImageStatus('Front photo', _frontImagePath),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _chooseImage(false),
                icon: const Icon(Icons.credit_card),
                label: const Text('Add back photo'),
              ),
              const SizedBox(height: 4),
              buildImageStatus('Back photo', _backImagePath),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: Text(isEditing ? 'Save changes' : 'Save ID'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------- ID DETAIL SCREEN WITH "USE IN SOS" BUTTON ----------

class IdDetailScreen extends StatefulWidget {
  final IdModel id;
  final VoidCallback onSetEmergency;
  final bool isEmergency;

  const IdDetailScreen({
    super.key,
    required this.id,
    required this.onSetEmergency,
    required this.isEmergency,
  });

  @override
  State<IdDetailScreen> createState() => _IdDetailScreenState();
}

class _IdDetailScreenState extends State<IdDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final id = widget.id;

    Widget buildImageCard(String label, String? path) {
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
                File(path!),
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ID Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.badge),
              title: Text(id.type),
              subtitle: Text('No: ${id.number}'),
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
            'Images',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          buildImageCard('Front side', id.frontImagePath),
          const SizedBox(height: 8),
          buildImageCard('Back side', id.backImagePath),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: widget.onSetEmergency,
            icon: Icon(
              widget.isEmergency ? Icons.shield : Icons.shield_outlined,
            ),
            label: Text(
              widget.isEmergency
                  ? 'This is your SOS ID'
                  : 'Use this ID in SOS alerts',
            ),
          ),
        ],
      ),
    );
  }
}
