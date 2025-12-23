import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/id_model.dart';
import '../services/image_storage.dart';
import '../services/local_storage.dart';

class IdsScreen extends StatefulWidget {
  const IdsScreen({super.key});

  @override
  State<IdsScreen> createState() => _IdsScreenState();
}

class _IdsScreenState extends State<IdsScreen> {
  List<IdModel> _ids = [];
  Map<String, String>? _emergencyIdRef;
  bool _loading = true;

  // If true: deleting an ID will also delete its image files from app storage.
  static const bool _deleteImagesWhenDeletingId = true;

  @override
  void initState() {
    super.initState();
    _loadIds();
  }

  bool _isEmergencyId(IdModel id) {
    final ref = _emergencyIdRef;
    if (ref == null) return false;
    return id.type == ref['type'] && id.number == ref['number'];
  }

  Future<void> _loadIds() async {
    final loaded = await LocalStorage.loadIds();
    final emergencyRef = await LocalStorage.getEmergencyIdRef();

    if (!mounted) return;
    setState(() {
      _ids = loaded;
      _emergencyIdRef = emergencyRef;
      _loading = false;
    });
  }

  Future<void> _addId(IdModel id) async {
    setState(() => _ids.add(id));
    await LocalStorage.saveIds(_ids);
  }

  Future<void> _updateId(int index, IdModel updated) async {
    setState(() => _ids[index] = updated);
    await LocalStorage.saveIds(_ids);
  }

  Future<void> _deleteId(int index) async {
    final removed = _ids[index];

    setState(() => _ids.removeAt(index));
    await LocalStorage.saveIds(_ids);

    if (_deleteImagesWhenDeletingId) {
      await ImageStorage.deleteIfExists(removed.frontImagePath);
      await ImageStorage.deleteIfExists(removed.backImagePath);
    }
  }

  Future<void> _setEmergencyId(IdModel id) async {
    await LocalStorage.setEmergencyId(id);
    final emergencyRef = await LocalStorage.getEmergencyIdRef();
    if (!mounted) return;

    setState(() => _emergencyIdRef = emergencyRef);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Set "${id.type}" as emergency ID.')),
    );
  }

  Future<void> _openAddIdScreen() async {
    final newId = await Navigator.of(context).push<IdModel>(
      MaterialPageRoute(builder: (_) => const AddIdScreen()),
    );

    if (newId != null) {
      await _addId(newId);
    }
  }

  Future<void> _openEditIdScreen(int index) async {
    final old = _ids[index];

    final updatedId = await Navigator.of(context).push<IdModel>(
      MaterialPageRoute(builder: (_) => AddIdScreen(initialId: old)),
    );

    if (updatedId != null) {
      // Delete old files only if replaced
      await ImageStorage.deleteOldIfReplaced(
        oldPath: old.frontImagePath,
        newPath: updatedId.frontImagePath,
      );
      await ImageStorage.deleteOldIfReplaced(
        oldPath: old.backImagePath,
        newPath: updatedId.backImagePath,
      );

      await _updateId(index, updatedId);
    }
  }

  Future<bool?> _confirmDeleteDialog(IdModel id) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete ID'),
        content: Text('Do you want to delete this ID?\n\n${id.type} (${id.number})'),
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

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Your IDs')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Your IDs')),
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

                Widget leading;
                final frontPath = id.frontImagePath;
                if (frontPath != null &&
                    frontPath.isNotEmpty &&
                    File(frontPath).existsSync()) {
                  leading = CircleAvatar(backgroundImage: FileImage(File(frontPath)));
                } else {
                  leading = const CircleAvatar(child: Icon(Icons.badge));
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
                              padding: const EdgeInsets.only(left: 6),
                              child: Icon(
                                Icons.shield,
                                color: theme.colorScheme.primary,
                                size: 18,
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        'No: ${id.number}\nCountry: ${id.country} • Exp: ${id.expiryDate.isEmpty ? "—" : id.expiryDate}',
                      ),
                      isThreeLine: true,
                      trailing: Icon(Icons.edit, color: theme.colorScheme.primary),
                      onTap: () {
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
                      onLongPress: () => _openEditIdScreen(index),
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

/// ---------- ADD / EDIT ID SCREEN (permanent images + force landscape for camera) ----------

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

  bool get _isEditing => widget.initialId != null;

  @override
  void initState() {
    super.initState();

    _typeController = TextEditingController(text: widget.initialId?.type ?? '');
    _numberController = TextEditingController(text: widget.initialId?.number ?? '');
    _countryController = TextEditingController(text: widget.initialId?.country ?? '');
    _expiryController = TextEditingController(text: widget.initialId?.expiryDate ?? '');

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

  Future<void> _lockLandscape() async {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _restoreOrientations() async {
    // Restore to all orientations for the rest of your app
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
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
                title: const Text('Take photo (landscape)'),
                subtitle: const Text('Tip: enable flash if lighting is low.'),
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

    // Best-effort: lock app to landscape before opening the camera UI
    if (source == ImageSource.camera) {
      await _lockLandscape();
    }

    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 90,
      );

      if (picked == null) return;

      // Copy to permanent storage
      final permanentPath = await ImageStorage.savePermanently(
        sourcePath: picked.path,
        prefix: isFront ? 'front' : 'back',
      );

      if (!mounted) return;

      setState(() {
        if (isFront) {
          _frontImagePath = permanentPath;
        } else {
          _backImagePath = permanentPath;
        }
      });
    } finally {
      if (source == ImageSource.camera) {
        await _restoreOrientations();
      }
    }
  }

  void _removeImage(bool isFront) {
    setState(() {
      if (isFront) _frontImagePath = null;
      else _backImagePath = null;
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

  Widget _imagePreview(String? path) {
    final has = path != null && path.isNotEmpty && File(path).existsSync();
    if (!has) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('No image selected'),
      );
    }

    return Container(
      height: 140,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.file(File(path!), fit: BoxFit.cover),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit ID' : 'Add ID')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text('ID details', style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),

              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(
                  labelText: 'ID type',
                  hintText: 'Driver\'s License, Passport, Student ID…',
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Please enter an ID type' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _numberController,
                decoration: const InputDecoration(labelText: 'ID number'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Please enter the ID number' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(labelText: 'Country / Issuer'),
                validator: (value) => (value == null || value.trim().isEmpty)
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
              Text('ID photos (optional)', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),

              const Text('Front photo'),
              const SizedBox(height: 8),
              _imagePreview(_frontImagePath),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _chooseImage(true),
                      icon: const Icon(Icons.credit_card),
                      label: Text(_frontImagePath == null ? 'Add front photo' : 'Replace front photo'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (_frontImagePath != null)
                    IconButton(
                      onPressed: () => _removeImage(true),
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Remove front',
                    ),
                ],
              ),

              const SizedBox(height: 16),

              const Text('Back photo'),
              const SizedBox(height: 8),
              _imagePreview(_backImagePath),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _chooseImage(false),
                      icon: const Icon(Icons.credit_card),
                      label: Text(_backImagePath == null ? 'Add back photo' : 'Replace back photo'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (_backImagePath != null)
                    IconButton(
                      onPressed: () => _removeImage(false),
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Remove back',
                    ),
                ],
              ),

              const SizedBox(height: 24),

              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: Text(_isEditing ? 'Save changes' : 'Save ID'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------- ID DETAIL SCREEN ----------

class IdDetailScreen extends StatelessWidget {
  final IdModel id;
  final VoidCallback onSetEmergency;
  final bool isEmergency;

  const IdDetailScreen({
    super.key,
    required this.id,
    required this.onSetEmergency,
    required this.isEmergency,
  });

  Widget _imageCard(BuildContext context, String label, String? path) {
    final hasImage = path != null && path.isNotEmpty && File(path).existsSync();

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
          ListTile(leading: const Icon(Icons.photo), title: Text(label)),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FullscreenImageView(title: label, imagePath: path!),
                ),
              );
            },
            child: SizedBox(
              height: 220,
              child: Image.file(File(path!), fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('Tap image to zoom', textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('ID Details')),
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
              subtitle: Text(id.expiryDate.isEmpty ? 'Not set' : id.expiryDate),
            ),
          ),
          const SizedBox(height: 16),

          Text('Images', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),

          _imageCard(context, 'Front side', id.frontImagePath),
          const SizedBox(height: 8),
          _imageCard(context, 'Back side', id.backImagePath),

          const SizedBox(height: 16),

          FilledButton.icon(
            onPressed: onSetEmergency,
            icon: Icon(isEmergency ? Icons.shield : Icons.shield_outlined),
            label: Text(isEmergency ? 'This is your SOS ID' : 'Use this ID in SOS alerts'),
          ),
        ],
      ),
    );
  }
}

class FullscreenImageView extends StatelessWidget {
  final String title;
  final String imagePath;

  const FullscreenImageView({
    super.key,
    required this.title,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1.0,
          maxScale: 4.0,
          child: Image.file(File(imagePath), fit: BoxFit.contain),
        ),
      ),
    );
  }
}
