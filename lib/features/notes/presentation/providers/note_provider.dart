import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/note.dart';
import '../../data/repositories/firebase_note_repository.dart';

final noteRepositoryProvider = Provider((ref) => FirebaseNoteRepository());

final notesProvider = StreamProvider<List<Note>>((ref) {
  final repository = ref.watch(noteRepositoryProvider);
  return repository.getNotes();
});

final favoriteNotesProvider = StreamProvider<List<Note>>((ref) {
  final repository = ref.watch(noteRepositoryProvider);
  return repository.getFavoriteNotes();
});

final categoryNotesProvider =
    StreamProvider.family<List<Note>, String>((ref, category) {
  final repository = ref.watch(noteRepositoryProvider);
  return repository.getNotesByCategory(category);
});

final categoriesProvider = StreamProvider<List<String>>((ref) {
  final repository = ref.watch(noteRepositoryProvider);
  return repository.getCategories();
});
