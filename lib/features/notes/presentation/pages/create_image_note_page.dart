import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/note.dart';
import '../providers/note_provider.dart';

class CreateImageNotePage extends ConsumerStatefulWidget {
  const CreateImageNotePage({super.key});

  @override
  ConsumerState<CreateImageNotePage> createState() =>
      _CreateImageNotePageState();
}

class _CreateImageNotePageState extends ConsumerState<CreateImageNotePage> {
  final _titleController = TextEditingController();
  String _selectedCategory = 'To-do';
  Color _selectedColor = AppColors.orange;
  final List<File> _imageFiles = [];
  final Map<File, String?> _extractedTexts = {};
  final Map<File, bool> _processingStates = {};
  final Map<File, TextEditingController> _textControllers = {};
  final _textRecognizer = TextRecognizer();

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
    _textRecognizer.close();
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _addImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);

      if (image != null) {
        final imageFile = File(image.path);
        setState(() {
          _imageFiles.add(imageFile);
          _extractedTexts[imageFile] = null;
          _processingStates[imageFile] = true;
          _textControllers[imageFile] = TextEditingController();
        });
        await _processImage(imageFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _processImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      if (mounted) {
        final extractedText = recognizedText.text;
        setState(() {
          _extractedTexts[imageFile] = extractedText;
          _processingStates[imageFile] = false;
          _textControllers[imageFile]?.text = extractedText;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing image: ${e.toString()}')),
        );
        setState(() {
          _processingStates[imageFile] = false;
        });
      }
    }
  }

  void _removeImage(File imageFile) {
    _textControllers[imageFile]?.dispose();
    setState(() {
      _imageFiles.remove(imageFile);
      _extractedTexts.remove(imageFile);
      _processingStates.remove(imageFile);
      _textControllers.remove(imageFile);
    });
  }

  Future<void> _createNote() async {
    if (_titleController.text.isEmpty || _textControllers.isEmpty) return;

    final allTexts = _textControllers.values
        .map((controller) => controller.text)
        .where((text) => text.isNotEmpty)
        .join('\n\n');

    if (allTexts.isEmpty) return;

    final note = Note(
      id: const Uuid().v4(),
      title: _titleController.text,
      content: allTexts,
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
    final hasProcessedImages =
        _extractedTexts.values.any((text) => text != null);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Create Image Note'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: hasProcessedImages ? _createNote : null,
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
                  if (_imageFiles.isEmpty) ...[
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.photo_library),
                                  title: const Text('Choose from Gallery'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _addImage(ImageSource.gallery);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.camera_alt),
                                  title: const Text('Take a Photo'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _addImage(ImageSource.camera);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.image,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text(
                              'Add images to extract text',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.touch_app, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Text(
                                  'Tap to add image',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _imageFiles.length,
                      itemBuilder: (context, index) {
                        final imageFile = _imageFiles[index];
                        final isProcessing =
                            _processingStates[imageFile] ?? false;
                        final textController = _textControllers[imageFile];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  alignment: Alignment.topRight,
                                  children: [
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Image.file(
                                          imageFile,
                                          height: 200,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                        if (isProcessing)
                                          Container(
                                            color: Colors.black54,
                                            child:
                                                const CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      AppColors.white),
                                            ),
                                          ),
                                      ],
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close,
                                          color: Colors.white),
                                      onPressed: () => _removeImage(imageFile),
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                                if (textController != null &&
                                    !isProcessing) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Extracted Text:',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () {
                                          showModalBottomSheet(
                                            context: context,
                                            builder: (context) => SafeArea(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  ListTile(
                                                    leading: const Icon(
                                                        Icons.photo_library),
                                                    title: const Text(
                                                        'Choose from Gallery'),
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      _addImage(
                                                          ImageSource.gallery);
                                                    },
                                                  ),
                                                  ListTile(
                                                    leading: const Icon(
                                                        Icons.camera_alt),
                                                    title: const Text(
                                                        'Take a Photo'),
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      _addImage(
                                                          ImageSource.camera);
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                            Icons.add_photo_alternate),
                                        label: const Text('Add Another'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: TextField(
                                      controller: textController,
                                      maxLines: null,
                                      style: const TextStyle(fontSize: 14),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
