import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/gemini_provider.dart';
import '../../domain/note.dart';
import '../providers/note_provider.dart';

class CreateVoiceNotePage extends ConsumerStatefulWidget {
  const CreateVoiceNotePage({super.key});

  @override
  ConsumerState<CreateVoiceNotePage> createState() =>
      _CreateVoiceNotePageState();
}

class _CreateVoiceNotePageState extends ConsumerState<CreateVoiceNotePage> {
  final _titleController = TextEditingController();
  String _selectedCategory = 'To-do';
  Color _selectedColor = AppColors.orange;
  File? _audioFile;
  bool _isProcessing = false;
  String? _transcription;

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
    super.dispose();
  }

  Future<void> _pickAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3'],
      );

      if (result != null) {
        setState(() {
          _audioFile = File(result.files.single.path!);
          // Dosya adını başlık olarak kullan (uzantısız)
          final fileName = result.files.single.name.split('.').first;
          _titleController.text = fileName;
          _isProcessing = true;
        });

        // Ses dosyasını yazıya çevir
        final transcription =
            await ref.read(geminiServiceProvider).transcribeAudio(_audioFile!);

        if (mounted) {
          setState(() {
            _transcription = transcription;
            _isProcessing = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error processing audio file: ${e.toString()}')),
        );
      }
    }
  }

  void _createNote() async {
    if (_titleController.text.isEmpty || _transcription == null) return;

    final note = Note(
      id: const Uuid().v4(),
      title: _titleController.text,
      content: _transcription!,
      category: _selectedCategory,
      backgroundColor: _selectedColor,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isFavorite: false,
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

  @override
  Widget build(BuildContext context) {
    final categoriesAsyncValue = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Create Voice Note'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _transcription != null ? _createNote : null,
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
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  if (_audioFile == null) ...[
                    const Icon(Icons.audio_file, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Select an MP3 file to transcribe',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _pickAudioFile,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Choose MP3 File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.black,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ] else ...[
                    if (_isProcessing)
                      const Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Transcribing audio...'),
                        ],
                      )
                    else if (_transcription != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_transcription!),
                      ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _pickAudioFile,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Choose Different File'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
