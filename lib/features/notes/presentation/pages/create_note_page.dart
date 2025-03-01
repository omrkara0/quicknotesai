import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/note.dart';
import '../providers/note_provider.dart';
import '../widgets/pin_code_dialog.dart';

class CreateNotePage extends ConsumerStatefulWidget {
  const CreateNotePage({super.key});

  @override
  ConsumerState<CreateNotePage> createState() => _CreateNotePageState();
}

class _CreateNotePageState extends ConsumerState<CreateNotePage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedCategory = 'To-do';
  Color _selectedColor = AppColors.orange;
  bool _isLocked = false;
  String? _pinCode;

  final List<Color> _colors = [
    AppColors.orange,
    AppColors.yellow,
    AppColors.blue,
    AppColors.green,
    AppColors.cream,
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _createNote() async {
    if (_titleController.text.isEmpty) return;

    final note = Note(
      id: const Uuid().v4(),
      title: _titleController.text,
      content: _contentController.text,
      category: _selectedCategory,
      backgroundColor: _selectedColor,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isFavorite: false,
      isLocked: _isLocked,
      pinCode: _pinCode,
    );

    try {
      await ref.read(noteRepositoryProvider).createNote(note);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating note: ${e.toString()}')),
        );
      }
    }
  }

  void _toggleLock() {
    if (_isLocked) {
      // Unlock the note
      setState(() {
        _isLocked = false;
        _pinCode = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not kilidi kaldırıldı')),
      );
    } else {
      // Lock the note
      showDialog(
        context: context,
        builder: (context) => PinCodeDialog(
          title: 'Notu Kilitle',
          confirmButtonText: 'Kilitle',
          onSubmit: (pinCode) {
            setState(() {
              _isLocked = true;
              _pinCode = pinCode;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Not kilitlendi')),
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsyncValue = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Create Note'),
        actions: [
          IconButton(
            icon: Icon(_isLocked ? Icons.lock : Icons.lock_open),
            onPressed: _toggleLock,
            tooltip: _isLocked ? 'Kilidi Kaldır' : 'Kilitle',
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _createNote,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                hintText: 'Title',
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Category: '),
                categoriesAsyncValue.when(
                  data: (categories) => DropdownButton<String>(
                    value: _selectedCategory,
                    items: [
                      'To-do',
                      'Important',
                      ...categories,
                    ]
                        .map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCategory = value);
                      }
                    },
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => DropdownButton<String>(
                    value: _selectedCategory,
                    items: ['To-do', 'Important']
                        .map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCategory = value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: _colors
                  .map(
                    (color) => GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: color == _selectedColor
                              ? Border.all(color: Colors.black, width: 2)
                              : null,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Note content',
                border: InputBorder.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
