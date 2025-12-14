import 'package:flutter/material.dart';

import '../models/contact_model.dart';
import '../services/local_storage.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<ContactModel> _contacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final loaded = await LocalStorage.loadContacts();
    setState(() {
      _contacts = loaded;
    });
  }

  Future<void> _addContact(ContactModel contact) async {
    setState(() {
      _contacts.add(contact);
    });
    await LocalStorage.saveContacts(_contacts);
  }

  Future<void> _updateContact(int index, ContactModel updated) async {
    setState(() {
      _contacts[index] = updated;
    });
    await LocalStorage.saveContacts(_contacts);
  }

  Future<void> _deleteContact(int index) async {
    setState(() {
      _contacts.removeAt(index);
    });
    await LocalStorage.saveContacts(_contacts);
  }

  Future<void> _openAddContactScreen() async {
    final newContact = await Navigator.of(context).push<ContactModel>(
      MaterialPageRoute(
        builder: (_) => const AddContactScreen(),
      ),
    );

    if (newContact != null) {
      await _addContact(newContact);
    }
  }

  Future<void> _openEditContactScreen(int index) async {
    final contactToEdit = _contacts[index];

    final updated = await Navigator.of(context).push<ContactModel>(
      MaterialPageRoute(
        builder: (_) => AddContactScreen(initialContact: contactToEdit),
      ),
    );

    if (updated != null) {
      await _updateContact(index, updated);
    }
  }

  Future<bool?> _confirmDelete(ContactModel contact) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete contact'),
        content: Text('Delete ${contact.name} from emergency contacts?'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
      ),
      body: _contacts.isEmpty
          ? const Center(
              child: Text(
                'No emergency contacts yet.\nTap "Add contact" to set them up.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _contacts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final contact = _contacts[index];

                return Dismissible(
                  key: ValueKey('${contact.name}-${contact.phone}-$index'),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) => _confirmDelete(contact),
                  onDismissed: (_) => _deleteContact(index),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: Card(
                    child: ListTile(
                      leading: Icon(
                        contact.isPrimary
                            ? Icons.star
                            : Icons.person_outline,
                      ),
                      title: Text(contact.name),
                      subtitle: Text(contact.phone),
                      trailing: const Icon(Icons.edit),
                      onTap: () {
                        // maybe later: show more details
                      },
                      onLongPress: () {
                        _openEditContactScreen(index);
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddContactScreen,
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add contact'),
      ),
    );
  }
}

/// ---------- ADD / EDIT CONTACT SCREEN ----------

class AddContactScreen extends StatefulWidget {
  final ContactModel? initialContact;

  const AddContactScreen({super.key, this.initialContact});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late bool _isPrimary;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialContact?.name ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.initialContact?.phone ?? '',
    );
    _isPrimary = widget.initialContact?.isPrimary ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState?.validate() != true) return;

    final contact = ContactModel(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      isPrimary: _isPrimary,
    );

    Navigator.of(context).pop(contact);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.initialContact != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Contact' : 'Add Contact'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Contact details',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Mom, Best Friend, Partner',
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Please enter a name'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Please enter a phone number'
                        : null,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Primary emergency contact'),
                subtitle: const Text(
                    'Primary contacts may be alerted first during SOS.'),
                value: _isPrimary,
                onChanged: (value) {
                  setState(() {
                    _isPrimary = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: Text(isEditing ? 'Save changes' : 'Save contact'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
