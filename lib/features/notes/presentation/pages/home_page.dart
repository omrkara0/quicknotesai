import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/constants/constants.dart';
import '../providers/note_provider.dart';
import '../../domain/note.dart';
import 'create_note_page.dart';
import 'create_image_note_page.dart';
import 'edit_note_page.dart';
import '../widgets/animated_heart_icon.dart';
import '../widgets/add_category_dialog.dart';
import '../widgets/pin_code_dialog.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String _selectedCategory = AppConstants.allCategory;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
      AppConstants.allCategory => ref.watch(notesProvider),
      AppConstants.favoritesCategory => ref.watch(favoriteNotesProvider),
      _ => ref.watch(categoryNotesProvider(_selectedCategory))
    };

    final categoriesAsyncValue = ref.watch(categoriesProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      endDrawer: _buildEndDrawer(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppConstants.homePageTitle,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      _scaffoldKey.currentState?.openEndDrawer();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip(
                        AppConstants.allCategory,
                        AppColors.black,
                        _selectedCategory == AppConstants.allCategory),
                    _buildCategoryChip(
                        AppConstants.importantCategory,
                        AppColors.yellow,
                        _selectedCategory == AppConstants.importantCategory),
                    _buildCategoryChip(
                        AppConstants.todoCategory,
                        AppColors.orange,
                        _selectedCategory == AppConstants.todoCategory),
                    _buildCategoryChip(
                        AppConstants.dailyCategory,
                        AppColors.green,
                        _selectedCategory == AppConstants.dailyCategory),
                    _buildCategoryChip(
                        AppConstants.favoritesCategory,
                        AppColors.red,
                        _selectedCategory == AppConstants.favoritesCategory),
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
                    child:
                        Text('${AppConstants.errorPrefix}${error.toString()}'),
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

  Widget _buildEndDrawer(BuildContext context) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.7,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConstants.settingsTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                title: Text(AppConstants.themeSetting),
                subtitle: Text(isDarkMode
                    ? AppConstants.darkTheme
                    : AppConstants.lightTheme),
                trailing: Switch(
                  value: isDarkMode,
                  onChanged: (value) {
                    ref.read(themeProvider.notifier).toggleTheme();
                  },
                ),
              ),
              const Divider(),
              ListTile(
                title: Text(AppConstants.aboutSetting),
                trailing: const Icon(Icons.info_outline),
                onTap: () {
                  _showAboutDialog(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppConstants.aboutTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppConstants.appDescription),
            const SizedBox(height: 8),
            Text(AppConstants.version),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppConstants.close),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkAccent : AppColors.black,
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
    final isDarkMode = ref.watch(isDarkModeProvider);

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
                  color: isSelected
                      ? AppColors.white
                      : isDarkMode
                          ? AppColors.white
                          : AppColors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: isSelected
                  ? isDarkMode
                      ? AppColors.darkAccent
                      : AppColors.black
                  : Colors.transparent,
              side: BorderSide(
                  color: isSelected
                      ? Colors.transparent
                      : isDarkMode
                          ? Colors.grey[700]!
                          : Colors.grey[300]!),
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
          title: Text(AppConstants.deleteCategoryTitle),
          content: Text('"$category" ${AppConstants.deleteCategoryConfirm}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppConstants.cancel),
            ),
            TextButton(
              onPressed: () {
                ref.read(noteRepositoryProvider).deleteCategory(category);
                Navigator.of(context).pop();
                if (_selectedCategory == category) {
                  setState(() => _selectedCategory = AppConstants.allCategory);
                }
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

  Widget _buildNoteCard(Note note) {
    final formattedDate =
        DateFormat('MMM d, y HH:mm').format(note.updatedAt.toLocal());
    final isDarkMode = ref.watch(isDarkModeProvider);

    return GestureDetector(
      onTap: () {
        if (note.isLocked) {
          _showUnlockDialog(note);
        } else {
          _navigateToEditPage(note);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: note.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: isDarkMode
              ? Border.all(color: Colors.grey[800]!, width: 1)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (note.isLocked)
                        const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Icon(Icons.lock, size: 16),
                        ),
                      Expanded(
                        child: Text(
                          note.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? AppColors.darkCard : null,
                          ),
                        ),
                      ),
                    ],
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
              child: note.isLocked
                  ? Center(
                      child: Text(
                        AppConstants.lockedNoteMessage,
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color:
                              isDarkMode ? AppColors.darkSecondaryText : null,
                        ),
                      ),
                    )
                  : Text(
                      note.content,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? AppColors.darkCard : null,
                      ),
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
                color:
                    isDarkMode ? AppColors.darkSecondaryText : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnlockDialog(Note note) {
    showDialog(
      context: context,
      builder: (context) => VerifyPinDialog(
        onVerify: (_) {},
        onCancel: () {
          // Do nothing
        },
        onVerifyWithResult: (pinCode, callback) async {
          final isValid = await ref
              .read(noteRepositoryProvider)
              .verifyNotePin(note.id, pinCode);

          if (isValid) {
            callback(true, null);
            _navigateToEditPage(note);
          } else {
            callback(false, AppConstants.wrongPinCode);
          }
        },
      ),
    );
  }

  void _navigateToEditPage(Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditNotePage(note: note),
      ),
    );
  }
}
