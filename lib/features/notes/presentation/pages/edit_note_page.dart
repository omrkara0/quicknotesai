import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/gemini_provider.dart';
import '../../../../core/constants/constants.dart';
import '../../domain/note.dart';
import '../providers/note_provider.dart';
import '../widgets/pin_code_dialog.dart';

class EditNotePage extends ConsumerStatefulWidget {
  final Note note;

  const EditNotePage({super.key, required this.note});

  @override
  ConsumerState<EditNotePage> createState() => _EditNotePageState();
}

class _EditNotePageState extends ConsumerState<EditNotePage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late String _selectedCategory;
  late Color _selectedColor;
  bool _isSummarizing = false;
  bool _isAnalyzingEmotion = false;
  Map<String, dynamic>? _emotionAnalysis;
  late bool _isLocked;

  final List<Color> _colors = [
    AppColors.orange,
    AppColors.yellow,
    AppColors.blue,
    AppColors.green,
    AppColors.cream,
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
    _selectedCategory = widget.note.category;
    _selectedColor = widget.note.backgroundColor;
    _isLocked = widget.note.isLocked;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _updateNote() async {
    if (_titleController.text.isEmpty) return;

    final updatedNote = widget.note.copyWith(
      title: _titleController.text,
      content: _contentController.text,
      category: _selectedCategory,
      backgroundColor: _selectedColor,
      updatedAt: DateTime.now(),
      isLocked: _isLocked,
    );

    try {
      await ref.read(noteRepositoryProvider).updateNote(updatedNote);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${AppConstants.errorUpdatingNote}${e.toString()}')),
        );
      }
    }
  }

  void _toggleLock() {
    if (_isLocked) {
      // Unlock the note
      setState(() {
        _isLocked = false;
      });
      ref.read(noteRepositoryProvider).unlockNote(widget.note.id);
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
            });
            ref.read(noteRepositoryProvider).lockNote(widget.note.id, pinCode);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Not kilitlendi')),
            );
          },
        ),
      );
    }
  }

  Future<void> _showDeleteConfirmation() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppConstants.deleteNoteTitle),
          content: Text(AppConstants.deleteNoteConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppConstants.cancel),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteNote();
              },
              child: Text(
                AppConstants.delete,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteNote() async {
    try {
      await ref.read(noteRepositoryProvider).deleteNote(widget.note.id);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${AppConstants.errorDeletingNote}${e.toString()}')),
        );
      }
    }
  }

  Future<void> _summarizeContent() async {
    if (_contentController.text.isEmpty) return;

    setState(() => _isSummarizing = true);

    try {
      final summary = await ref
          .read(geminiServiceProvider)
          .summarizeContent(_contentController.text);

      if (mounted) {
        setState(() {
          _contentController.text = summary;
          _isSummarizing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${AppConstants.errorGeneratingSummary}${e.toString()}')),
        );
        setState(() => _isSummarizing = false);
      }
    }
  }

  Future<void> _analyzeEmotion() async {
    if (_contentController.text.isEmpty) return;

    setState(() => _isAnalyzingEmotion = true);

    try {
      final analysis = await ref
          .read(geminiServiceProvider)
          .analyzeEmotion(_contentController.text);

      if (mounted) {
        setState(() {
          _emotionAnalysis = analysis;
          _isAnalyzingEmotion = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${AppConstants.errorAnalyzingEmotion}${e.toString()}')),
        );
        setState(() => _isAnalyzingEmotion = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsyncValue = ref.watch(categoriesProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isDailyCategory = _selectedCategory == AppConstants.dailyCategory;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppConstants.editNoteTitle),
        actions: [
          IconButton(
            icon: Icon(_isLocked ? Icons.lock : Icons.lock_open),
            onPressed: _toggleLock,
            tooltip: _isLocked
                ? AppConstants.unlockTooltip
                : AppConstants.lockTooltip,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _showDeleteConfirmation,
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _updateNote,
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
                        setState(() {
                          _selectedCategory = value;
                          if (value != AppConstants.dailyCategory) {
                            _emotionAnalysis = null;
                          }
                        });
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
                        setState(() {
                          _selectedCategory = value;
                          if (value != AppConstants.dailyCategory) {
                            _emotionAnalysis = null;
                          }
                        });
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_isSummarizing)
                  const Padding(
                    padding: EdgeInsets.only(right: 16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                TextButton.icon(
                  onPressed: _isSummarizing ? null : _summarizeContent,
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(AppConstants.summarize),
                ),
                if (isDailyCategory) ...[
                  const SizedBox(width: 8),
                  if (_isAnalyzingEmotion)
                    const Padding(
                      padding: EdgeInsets.only(right: 16.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  TextButton.icon(
                    onPressed: _isAnalyzingEmotion ? null : _analyzeEmotion,
                    icon: const Icon(Icons.psychology),
                    label: Text(AppConstants.analyzeEmotion),
                  ),
                ],
              ],
            ),
            if (isDailyCategory && _emotionAnalysis != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getEmotionColor(
                                    _emotionAnalysis![AppConstants.emotion])
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getEmotionIcon(
                                _emotionAnalysis![AppConstants.emotion]),
                            color: _getEmotionColor(
                                _emotionAnalysis![AppConstants.emotion]),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _emotionAnalysis![AppConstants.emotion]
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _getEmotionColor(
                                      _emotionAnalysis![AppConstants.emotion]),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: List.generate(
                                  5,
                                  (index) => Icon(
                                    Icons.circle,
                                    size: 8,
                                    color: index <
                                            _emotionAnalysis![
                                                AppConstants.intensity]
                                        ? _getEmotionColor(_emotionAnalysis![
                                            AppConstants.emotion])
                                        : Colors.grey.withOpacity(0.3),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_emotionAnalysis![AppConstants.keywordsKey]
                        .isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        AppConstants.keywords,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.color
                              ?.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (_emotionAnalysis![AppConstants.keywordsKey]
                                as List<dynamic>)
                            .map((keyword) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getEmotionColor(_emotionAnalysis![
                                            AppConstants.emotion])
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    keyword,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getEmotionColor(_emotionAnalysis![
                                          AppConstants.emotion]),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _emotionAnalysis![AppConstants.suggestion],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 15,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              decoration: InputDecoration(
                hintText: AppConstants.noteContentHint,
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
          ],
        ),
      ),
    );
  }

  IconData _getEmotionIcon(String emotion) {
    switch (emotion) {
      case 'mutlu':
        return Icons.sentiment_very_satisfied;
      case 'üzgün':
        return Icons.sentiment_very_dissatisfied;
      case 'kızgın':
        return Icons.mood_bad;
      case 'endişeli':
        return Icons.sentiment_dissatisfied;
      case 'sakin':
        return Icons.sentiment_neutral;
      case 'enerjik':
        return Icons.bolt;
      case 'yorgun':
        return Icons.battery_alert;
      case 'motivasyonlu':
        return Icons.rocket_launch;
      case 'stresli':
        return Icons.speed;
      case 'minnettar':
        return Icons.favorite;
      default:
        return Icons.psychology;
    }
  }

  Color _getEmotionColor(String emotion) {
    switch (emotion) {
      case 'mutlu':
        return Colors.yellow.shade700;
      case 'üzgün':
        return Colors.blue.shade700;
      case 'kızgın':
        return Colors.red.shade700;
      case 'endişeli':
        return Colors.orange.shade700;
      case 'sakin':
        return Colors.green.shade700;
      case 'enerjik':
        return Colors.purple.shade700;
      case 'yorgun':
        return Colors.grey.shade700;
      case 'motivasyonlu':
        return Colors.pink.shade700;
      case 'stresli':
        return Colors.deepOrange.shade700;
      case 'minnettar':
        return Colors.teal.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}
