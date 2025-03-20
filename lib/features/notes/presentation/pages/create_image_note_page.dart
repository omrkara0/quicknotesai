import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/constants.dart';
import '../../domain/note.dart';
import '../providers/note_provider.dart';
import '../widgets/pin_code_dialog.dart';

class CreateImageNotePage extends ConsumerStatefulWidget {
  const CreateImageNotePage({super.key});

  @override
  ConsumerState<CreateImageNotePage> createState() =>
      _CreateImageNotePageState();
}

class _CreateImageNotePageState extends ConsumerState<CreateImageNotePage> {
  final _titleController = TextEditingController();
  String _selectedCategory = AppConstants.todoCategory;
  Color _selectedColor = AppColors.orange;
  final List<File> _imageFiles = [];
  final Map<File, String?> _extractedTexts = {};
  final Map<File, bool> _processingStates = {};
  final Map<File, TextEditingController> _textControllers = {};
  final _textRecognizer = TextRecognizer();
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
          SnackBar(
              content:
                  Text('${AppConstants.errorPickingImage}${e.toString()}')),
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
          SnackBar(
              content:
                  Text('${AppConstants.errorProcessingImage}${e.toString()}')),
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

  void _createNote() async {
    if (_titleController.text.isEmpty) return;

    final note = Note(
      id: const Uuid().v4(),
      title: _titleController.text,
      content:
          _extractedTexts.values.where((text) => text != null).join('\n\n'),
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
          SnackBar(
              content:
                  Text('${AppConstants.errorCreatingNote}${e.toString()}')),
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
        const SnackBar(content: Text(AppConstants.unlockedMessage)),
      );
    } else {
      // Lock the note
      showDialog(
        context: context,
        builder: (context) => PinCodeDialog(
          title: AppConstants.lockTitle,
          confirmButtonText: AppConstants.lockButtonText,
          onSubmit: (pinCode) {
            setState(() {
              _isLocked = true;
              _pinCode = pinCode;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppConstants.lockedMessage)),
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsyncValue = ref.watch(categoriesProvider);
    final hasProcessedImages =
        _extractedTexts.values.any((text) => text != null);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppConstants.createImageNoteTitle),
        actions: [
          IconButton(
            icon: Icon(_isLocked ? Icons.lock : Icons.lock_open),
            onPressed: _toggleLock,
            tooltip: _isLocked
                ? AppConstants.unlockTooltip
                : AppConstants.lockTooltip,
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
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              decoration: InputDecoration(
                hintText: AppConstants.titleHint,
                hintStyle: TextStyle(
                  color: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.color
                      ?.withOpacity(0.6),
                ),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  AppConstants.categoryLabel,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                categoriesAsyncValue.when(
                  data: (categories) => DropdownButton<String>(
                    value: _selectedCategory,
                    items: [
                      AppConstants.todoCategory,
                      AppConstants.importantCategory,
                      AppConstants.dailyCategory,
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
                    items: [
                      AppConstants.todoCategory,
                      AppConstants.importantCategory,
                      AppConstants.dailyCategory,
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
                              ? Border.all(
                                  color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color ??
                                      Colors.black,
                                  width: 2)
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
                                  title: Text(AppConstants.chooseFromGallery),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _addImage(ImageSource.gallery);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.camera_alt),
                                  title: Text(AppConstants.takePhoto),
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
                          color: isDarkMode
                              ? Theme.of(context).colorScheme.surface
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: isDarkMode
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.image,
                                size: 64,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color
                                    ?.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            Text(
                              AppConstants.addImageText,
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color
                                      ?.withOpacity(0.5)),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.touch_app,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color
                                        ?.withOpacity(0.7)),
                                const SizedBox(width: 8),
                                Text(
                                  AppConstants.addImageHint,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color
                                        ?.withOpacity(0.7),
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
                          color: isDarkMode
                              ? Theme.of(context).colorScheme.surface
                              : null,
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
                                      Text(
                                        AppConstants.extractedTextLabel,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.color,
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
                                                    title: Text(AppConstants
                                                        .chooseFromGallery),
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      _addImage(
                                                          ImageSource.gallery);
                                                    },
                                                  ),
                                                  ListTile(
                                                    leading: const Icon(
                                                        Icons.camera_alt),
                                                    title: Text(
                                                        AppConstants.takePhoto),
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
                                        label: Text(AppConstants.addAnother),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? Theme.of(context)
                                              .colorScheme
                                              .background
                                          : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: TextField(
                                      controller: textController,
                                      maxLines: null,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color,
                                      ),
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
