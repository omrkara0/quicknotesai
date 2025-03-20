import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';

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
        _errorText = AppConstants.categoryEmptyError;
      });
      return;
    }
    widget.onAdd(category);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppConstants.addCategoryTitle),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: AppConstants.addCategoryHint,
          errorText: _errorText,
        ),
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        onSubmitted: (_) => _validateAndAdd(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppConstants.cancel),
        ),
        TextButton(
          onPressed: _validateAndAdd,
          child: Text(AppConstants.add),
        ),
      ],
    );
  }
}
