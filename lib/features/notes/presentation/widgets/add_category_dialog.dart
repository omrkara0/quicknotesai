import 'package:flutter/material.dart';

class AddCategoryDialog extends StatefulWidget {
  final Function(String) onAdd;

  const AddCategoryDialog({super.key, required this.onAdd});

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateAndAdd() {
    final category = _controller.text.trim();
    if (category.isEmpty) {
      setState(() {
        _errorText = 'Category name cannot be empty';
      });
      return;
    }
    widget.onAdd(category);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Category'),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Enter category name',
          errorText: _errorText,
        ),
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        onSubmitted: (_) => _validateAndAdd(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _validateAndAdd,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
