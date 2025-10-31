import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'transaction_service.dart';
import 'app_settings_service.dart';

class OfflineQueueService {
  OfflineQueueService._();
  static final instance = OfflineQueueService._();

  Database? _db;

  Future<Database> _getDb() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'offline_queue.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE pending_movements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL, -- 'income' | 'expense'
            amount REAL NOT NULL,
            category TEXT NOT NULL,
            description TEXT,
            date_ms INTEGER NOT NULL,
            created_at_ms INTEGER NOT NULL
          );
        ''');
      },
    );
    return _db!;
  }

  Future<void> enqueueMovement({
    required String type, // 'income' or 'expense'
    required double amount,
    required String category,
    String? description,
    required DateTime date,
  }) async {
    final db = await _getDb();
    await db.insert('pending_movements', {
      'type': type,
      'amount': amount,
      'category': category,
      'description': description,
      'date_ms': date.millisecondsSinceEpoch,
      'created_at_ms': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> processQueue() async {
    final db = await _getDb();
    final rows = await db.query(
      'pending_movements',
      orderBy: 'created_at_ms ASC',
    );

    // usamos for normal con await adentro
    for (final row in rows) {
      try {
        final type = row['type'] as String;
        final amount = (row['amount'] as num).toDouble();
        final category = row['category'] as String;
        final description = row['description'] as String?;
        final date =
            DateTime.fromMillisecondsSinceEpoch(row['date_ms'] as int);

        if (type == 'income') {
          await TransactionService.instance.addIncome(
            amount: amount,
            category: category,
            description: description,
            date: date,
          );
        } else if (type == 'expense') {
          await TransactionService.instance.addExpense(
            amount: amount,
            category: category,
            description: description,
            date: date,
          );
        }
        
        // Save last transaction timestamp when processing offline queue
        await AppSettingsService.instance.setLastTransactionTimestamp(
          DateTime.now().millisecondsSinceEpoch,
        );

        // Borrar solo si se procesó correctamente
        await db.delete(
          'pending_movements',
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      } catch (e) {
        // Si algo falla, se interrumpe el procesamiento
        print('Error processing queued item: $e');
        return;
      }
    }
  }
}
