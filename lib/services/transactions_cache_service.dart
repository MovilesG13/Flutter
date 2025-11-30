import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'transaction_service.dart';

/// Service to cache transactions locally in SQLite for offline access
/// Implements eventual connectivity strategy
class TransactionsCacheService {
  TransactionsCacheService._();
  static final instance = TransactionsCacheService._();

  Database? _db;

  Future<Database> _getDb() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'transactions_cache.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cached_transactions (
            id TEXT PRIMARY KEY,
            uid TEXT NOT NULL,
            amount REAL NOT NULL,
            type TEXT NOT NULL,
            category TEXT,
            description TEXT,
            date_ms INTEGER NOT NULL,
            created_at_ms INTEGER NOT NULL,
            last_updated_ms INTEGER NOT NULL
          );
        ''');
        await db.execute('CREATE INDEX idx_uid_type ON cached_transactions(uid, type);');
        await db.execute('CREATE INDEX idx_created_at ON cached_transactions(created_at_ms DESC);');
      },
    );
    return _db!;
  }

  /// Cache a list of transactions (from Firestore)
  /// This is called when online to keep local cache updated
  Future<void> cacheTransactions(List<MoneyMovement> transactions) async {
    final db = await _getDb();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final transaction in transactions) {
      batch.insert(
        'cached_transactions',
        {
          'id': transaction.id,
          'uid': uid,
          'amount': transaction.amount,
          'type': transaction.type,
          'category': transaction.category,
          'description': transaction.description,
          'date_ms': transaction.date.millisecondsSinceEpoch,
          'created_at_ms': transaction.createdAt.millisecondsSinceEpoch,
          'last_updated_ms': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Get cached expenses from local storage
  /// Used when offline to display data
  Future<List<MoneyMovement>> getCachedExpenses() async {
    final db = await _getDb();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final rows = await db.query(
      'cached_transactions',
      where: 'uid = ? AND type = ?',
      whereArgs: [uid, 'expense'],
      orderBy: 'created_at_ms DESC',
    );

    return rows.map((row) {
      return MoneyMovement(
        id: row['id'] as String,
        amount: (row['amount'] as num).toDouble(),
        type: row['type'] as String,
        category: row['category'] as String?,
        description: row['description'] as String?,
        date: DateTime.fromMillisecondsSinceEpoch(row['date_ms'] as int),
        uid: row['uid'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at_ms'] as int),
      );
    }).toList();
  }

  /// Clear cache for a specific user (on logout)
  Future<void> clearCacheForUser(String uid) async {
    final db = await _getDb();
    await db.delete(
      'cached_transactions',
      where: 'uid = ?',
      whereArgs: [uid],
    );
  }

  /// Delete a specific transaction from cache
  Future<void> deleteCachedTransaction(String transactionId) async {
    final db = await _getDb();
    await db.delete(
      'cached_transactions',
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }
}

