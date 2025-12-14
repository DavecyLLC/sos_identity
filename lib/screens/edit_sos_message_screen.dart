import 'package:flutter/material.dart';

class EditSosMessageScreen extends StatefulWidget {
  final String initialText;

  const EditSosMessageScreen({
    super.key,
    required this.initialText,
  });

  @override
  State<EditSosMessageScreen> createState() => _EditSosMessageScreenState();
}

class _EditSosMessageScreenState extends State<EditSosMessageScreen> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveAndClose() {
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit SOS Message'),
        actions: [
          TextButton(
            onPressed: _saveAndClose,
            child: const Text(
              'SAVE',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'You can adjust the message before it is sent. '
              'Only edit what you understand — this text will be sent to your emergency contacts.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignLabelWithHint: true,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveAndClose,
        icon: const Icon(Icons.check),
        label: const Text('Use this message'),
      ),
    );
  }
}
