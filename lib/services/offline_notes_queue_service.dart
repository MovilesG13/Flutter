import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'notes_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OfflineNotesQueueService {
  OfflineNotesQueueService._();
  static final instance = OfflineNotesQueueService._();

  Database? _db;

  Future<Database> _getDb() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'offline_notes_queue.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE pending_notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            image_path TEXT NOT NULL,
            created_at_ms INTEGER NOT NULL
          );
        ''');
      },
    );
    return _db!;
  }

  /// Enqueue a note image for later upload when online
  Future<void> enqueueNote(String imagePath) async {
    final db = await _getDb();
    await db.insert('pending_notes', {
      'image_path': imagePath,
      'created_at_ms': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Get list of pending notes (for displaying offline)
  Future<List<Map<String, dynamic>>> getPendingNotes() async {
    final db = await _getDb();
    return await db.query(
      'pending_notes',
      orderBy: 'created_at_ms DESC',
    );
  }

  /// Process pending notes queue - upload to Firebase Storage and Firestore
  Future<void> processQueue() async {
    final db = await _getDb();
    final rows = await db.query(
      'pending_notes',
      orderBy: 'created_at_ms ASC',
    );

    if (rows.isEmpty) return;

    print('Processing ${rows.length} pending notes...');

    // Process each pending note sequentially
    for (final row in rows) {
      try {
        final imagePath = row['image_path'] as String;
        final fileId = row['id'] as int;

        // Check if file still exists
        final imageFile = File(imagePath);
        if (!await imageFile.exists()) {
          print('Image file no longer exists: $imagePath');
          // Remove from queue if file doesn't exist
          await db.delete(
            'pending_notes',
            where: 'id = ?',
            whereArgs: [fileId],
          );
          continue;
        }

        // Upload to Firebase Storage
        final downloadUrl = await _uploadToFirebase(imageFile);

        // Save note to Firestore
        await NotesService.instance.addNote(downloadUrl);

        print('Successfully uploaded pending note: $imagePath');

        // Delete from queue only after successful upload
        await db.delete(
          'pending_notes',
          where: 'id = ?',
          whereArgs: [fileId],
        );
      } catch (e) {
        // If something fails, stop processing and keep the rest in queue
        print('Error processing queued note: $e');
        return; // Stop processing on error, will retry later
      }
    }
  }

  /// Upload image file to Firebase Storage
  Future<String> _uploadToFirebase(File imageFile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final fileName = "note_${DateTime.now().millisecondsSinceEpoch}_${user.uid}.jpg";
    final ref = FirebaseStorage.instance
        .ref()
        .child('users/${user.uid}/notes/$fileName');

    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  /// Delete a pending note from queue
  Future<void> deletePendingNote(int noteId) async {
    final db = await _getDb();
    await db.delete(
      'pending_notes',
      where: 'id = ?',
      whereArgs: [noteId],
    );
  }
}

