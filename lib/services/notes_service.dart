import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Model for a Note (image)
class Note {
  final String id;
  final String imageUrl;
  final DateTime createdAt;
  final String uid; // owner user id

  Note({
    required this.id,
    required this.imageUrl,
    required this.createdAt,
    required this.uid,
  });

  Map<String, dynamic> toMap() => {
        'imageUrl': imageUrl,
        'createdAt': Timestamp.fromDate(createdAt),
        'uid': uid,
      };

  static Note fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    Timestamp? createdAtTs;
    final rawCreated = data['createdAt'];
    if (rawCreated is Timestamp) {
      createdAtTs = rawCreated;
    }
    return Note(
      id: doc.id,
      imageUrl: data['imageUrl'] as String,
      createdAt: (createdAtTs ?? Timestamp.fromDate(DateTime.now())).toDate(),
      uid: data['uid'] as String,
    );
  }
}

class NotesService {
  NotesService._();
  static final instance = NotesService._();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Collection path: /users/{uid}/notes
  CollectionReference<Map<String, dynamic>> _userNotesCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('notes');

  /// Add a note (image URL) to Firestore
  Future<String> addNote(String imageUrl) async {
    final uid = _auth.currentUser!.uid;
    final col = _userNotesCol(uid);
    final doc = await col.add({
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'uid': uid,
    });
    return doc.id;
  }

  /// Get stream of notes for current user
  Stream<List<Note>> userNotesStream() {
    final uid = _auth.currentUser!.uid;
    return _userNotesCol(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
          print('Notes stream update: ${snap.docs.length} documents');
          final notes = snap.docs.map(Note.fromDoc).toList();
          print('Parsed ${notes.length} notes');
          return notes;
        });
  }

  /// Delete a note
  Future<void> deleteNote(String noteId) async {
    final uid = _auth.currentUser!.uid;
    await _userNotesCol(uid).doc(noteId).delete();
  }
}

