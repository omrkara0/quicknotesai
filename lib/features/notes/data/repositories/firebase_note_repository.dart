import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/note.dart';
import '../../domain/repositories/note_repository.dart';

class FirebaseNoteRepository implements NoteRepository {
  final FirebaseFirestore _firestore;
  final String _collection = 'notes';
  final String _categoriesCollection = 'categories';

  FirebaseNoteRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<Note>> getNotes() {
    return _firestore
        .collection(_collection)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Note.fromJson(doc.data())).toList());
  }

  @override
  Stream<List<Note>> getFavoriteNotes() {
    return _firestore
        .collection(_collection)
        .where('isFavorite', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Note.fromJson(doc.data())).toList());
  }

  @override
  Stream<Note> getNoteById(String id) {
    return _firestore.collection(_collection).doc(id).snapshots().map((doc) {
      if (!doc.exists) {
        throw Exception('Note not found');
      }
      return Note.fromJson(doc.data()!);
    });
  }

  @override
  Future<void> createNote(Note note) async {
    await _firestore.collection(_collection).doc(note.id).set(note.toJson());
  }

  @override
  Future<void> updateNote(Note note) async {
    await _firestore.collection(_collection).doc(note.id).update(note.toJson());
  }

  @override
  Future<void> deleteNote(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  @override
  Stream<List<Note>> getNotesByCategory(String category) {
    return _firestore
        .collection(_collection)
        .where('category', isEqualTo: category)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Note.fromJson(doc.data())).toList());
  }

  @override
  Future<void> toggleFavorite(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) {
      throw Exception('Note not found');
    }
    final note = Note.fromJson(doc.data()!);
    await _firestore
        .collection(_collection)
        .doc(id)
        .update({'isFavorite': !note.isFavorite});
  }

  @override
  Stream<List<String>> getCategories() {
    return _firestore
        .collection(_categoriesCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  @override
  Future<void> addCategory(String category) async {
    await _firestore.collection(_categoriesCollection).doc(category).set({
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteCategory(String category) async {
    await _firestore.collection(_categoriesCollection).doc(category).delete();
  }
}
