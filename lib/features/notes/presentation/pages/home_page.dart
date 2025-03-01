import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/note_provider.dart';
import '../../domain/note.dart';
import 'create_note_page.dart';
import 'create_voice_note_page.dart';
import 'create_image_note_page.dart';
import 'edit_note_page.dart';
import '../widgets/animated_heart_icon.dart';
import '../widgets/add_category_dialog.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String _selectedCategory = 'All';

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AddCategoryDialog(
        onAdd: (category) {
          ref.read(noteRepositoryProvider).addCategory(category);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesAsyncValue = switch (_selectedCategory) {
      'All' => ref.watch(notesProvider),
      'Favorites' => ref.watch(favoriteNotesProvider),
      _ => ref.watch(categoryNotesProvider(_selectedCategory))
    };

    final categoriesAsyncValue = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My\nNotes',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 24),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip(
                        'All', AppColors.black, _selectedCategory == 'All'),
                    _buildCategoryChip('Important', AppColors.yellow,
                        _selectedCategory == 'Important'),
                    _buildCategoryChip('To-do', AppColors.orange,
                        _selectedCategory == 'To-do'),
                    _buildCategoryChip('Favorites', AppColors.red,
                        _selectedCategory == 'Favorites'),
                    ...categoriesAsyncValue.when(
                      data: (categories) => categories.map(
                        (category) => _buildCategoryChip(
                          category,
                          AppColors.blue,
                          _selectedCategory == category,
                        ),
                      ),
                      loading: () => [],
                      error: (_, __) => [],
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _showAddCategoryDialog,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: notesAsyncValue.when(
                  data: (notes) => GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children:
                        notes.map((note) => _buildNoteCard(note)).toList(),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text('Error: ${error.toString()}'),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCircularButton(
                          icon: Icons.add,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const CreateNotePage()),
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        _buildCircularButton(
                          icon: Icons.mic,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const CreateVoiceNotePage()),
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        _buildCircularButton(
                          icon: Icons.image,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const CreateImageNotePage()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.black,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.white),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildCategoryChip(String label, Color color, bool isSelected) {
    final isCustomCategory = color == AppColors.blue;

    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              label: Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.white : AppColors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor:
                  isSelected ? AppColors.black : Colors.transparent,
              side: BorderSide(
                  color: isSelected ? Colors.transparent : Colors.grey[300]!),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              deleteIcon:
                  isCustomCategory ? const Icon(Icons.close, size: 16) : null,
              onDeleted: isCustomCategory
                  ? () => _showDeleteCategoryDialog(label)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteCategoryDialog(String category) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Category'),
          content:
              Text('Are you sure you want to delete "$category" category?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                ref.read(noteRepositoryProvider).deleteCategory(category);
                Navigator.of(context).pop();
                if (_selectedCategory == category) {
                  setState(() => _selectedCategory = 'All');
                }
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNoteCard(Note note) {
    final formattedDate =
        DateFormat('MMM d, y HH:mm').format(note.updatedAt.toLocal());

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditNotePage(note: note),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: note.backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    note.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                AnimatedHeartIcon(
                  isFavorite: note.isFavorite,
                  onTap: () {
                    ref.read(noteRepositoryProvider).toggleFavorite(note.id);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                note.content,
                style: const TextStyle(fontSize: 14),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
