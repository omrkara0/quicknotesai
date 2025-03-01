import '../note.dart';

abstract class NoteRepository {
  Stream<List<Note>> getNotes();
  Stream<Note> getNoteById(String id);
  Future<void> createNote(Note note);
  Future<void> updateNote(Note note);
  Future<void> deleteNote(String id);
  Stream<List<Note>> getNotesByCategory(String category);
  Stream<List<Note>> getFavoriteNotes();
  Future<void> toggleFavorite(String id);

  // Lock management
  Future<void> lockNote(String id, String pinCode);
  Future<void> unlockNote(String id);
  Future<bool> verifyNotePin(String id, String pinCode);

  // Category management
  Stream<List<String>> getCategories();
  Future<void> addCategory(String category);
  Future<void> deleteCategory(String category);
}
