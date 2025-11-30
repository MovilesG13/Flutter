import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'transactions_cache_service.dart';

/// Simple domain model for a money movement (income or expense)
class MoneyMovement {
  final String id;
  final double amount;
  final String type; // 'income' | 'expense'
  final String? category;
  final String? description;
  final DateTime date;
  final String uid; // owner user id
  final DateTime createdAt;

  MoneyMovement({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
    required this.date,
    required this.uid,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'amount': amount,
        'type': type,
        'category': category,
        'description': description,
        'date': Timestamp.fromDate(date),
        'uid': uid,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  static MoneyMovement fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    Timestamp? createdAtTs;
    final rawCreated = data['createdAt'];
    if (rawCreated is Timestamp) {
      createdAtTs = rawCreated;
    }
    Timestamp? dateTs;
    final rawDate = data['date'];
    if (rawDate is Timestamp) {
      dateTs = rawDate;
    }
    return MoneyMovement(
      id: doc.id,
      amount: (data['amount'] as num).toDouble(),
      type: data['type'] as String,
      category: data['category'] as String?,
      description: data['description'] as String?,
      date: (dateTs ?? Timestamp.fromDate(DateTime.now())).toDate(),
      uid: data['uid'] as String,
      createdAt: (createdAtTs ?? Timestamp.fromDate(DateTime.now())).toDate(),
    );
  }
}

class TransactionService {
  TransactionService._();
  static final instance = TransactionService._();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Collection path now: /users/{uid}/movements
  CollectionReference<Map<String, dynamic>> _userMovementsCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('movements');

  Future<String> addIncome({
    required double amount,
    required String category,
    String? description,
    required DateTime date,
  }) async {
    final uid = _auth.currentUser!.uid;
    final col = _userMovementsCol(uid);
    final doc = await col.add({
      'amount': amount,
      'type': 'income',
      'category': category,
      'description': description,
      'date': Timestamp.fromDate(date),
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<String> addExpense({
    required double amount,
    required String category,
    String? description,
    required DateTime date,
  }) async {
    final uid = _auth.currentUser!.uid;
    final col = _userMovementsCol(uid);
    final doc = await col.add({
      'amount': amount,
      'type': 'expense',
      'category': category,
      'description': description,
      'date': Timestamp.fromDate(date),
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Stream<List<MoneyMovement>> userMovementsStream() {
    final uid = _auth.currentUser!.uid;
    return _userMovementsCol(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
          final movements = snap.docs.map(MoneyMovement.fromDoc).toList();
          // Cache transactions locally for offline access (eventual connectivity)
          TransactionsCacheService.instance.cacheTransactions(movements).catchError((e) {
            print('Error caching transactions: $e');
          });
          return movements;
        });
  }

  Future<void> deleteMovement(String id) async {
    final uid = _auth.currentUser!.uid;
    await _userMovementsCol(uid).doc(id).delete();
  }
  
  // Future with .then() handler - Add income with callback
  Future<String> addIncomeWithCallback({
    required double amount,
    required String category,
    String? description,
    required DateTime date,
    Function(String docId)? onSuccess,
    Function(dynamic error)? onError,
  }) {
    final uid = _auth.currentUser!.uid;
    final col = _userMovementsCol(uid);
    return col.add({
      'amount': amount,
      'type': 'income',
      'category': category,
      'description': description,
      'date': Timestamp.fromDate(date),
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    }).then(
      (doc) {
        if (onSuccess != null) {
          onSuccess(doc.id);
        }
        return doc.id;
      },
      onError: (error) {
        if (onError != null) {
          onError(error);
        }
        throw error;
      },
    );
  }
  
  // Future with .then() handler - Add expense with callback
  Future<String> addExpenseWithCallback({
    required double amount,
    required String category,
    String? description,
    required DateTime date,
    Function(String docId)? onSuccess,
    Function(dynamic error)? onError,
  }) {
    final uid = _auth.currentUser!.uid;
    final col = _userMovementsCol(uid);
    return col.add({
      'amount': amount,
      'type': 'expense',
      'category': category,
      'description': description,
      'date': Timestamp.fromDate(date),
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    }).then(
      (doc) {
        if (onSuccess != null) {
          onSuccess(doc.id);
        }
        return doc.id;
      },
      onError: (error) {
        if (onError != null) {
          onError(error);
        }
        throw error;
      },
    );
  }
  
  // Future with .then() handler + async/await combined
  // This method demonstrates using async/await AND .then() together
  Future<String> addIncomeWithCombinedAsync({
    required double amount,
    required String category,
    String? description,
    required DateTime date,
  }) async {
    final uid = _auth.currentUser!.uid;
    final col = _userMovementsCol(uid);
    
    // First, use async/await to get the document reference
    await Future.delayed(Duration(milliseconds: 100)); // Simulate async work
    
    // Then use .then() handler to chain operations
    return col.add({
      'amount': amount,
      'type': 'income',
      'category': category,
      'description': description,
      'date': Timestamp.fromDate(date),
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    }).then((doc) async {
      // Inside .then(), use async/await for additional operations
      await Future.delayed(Duration(milliseconds: 50));
      // Can perform additional async operations here
      return doc.id;
    }).then((docId) async {
      // Chain another .then() with async work
      await Future.delayed(Duration(milliseconds: 25));
      return docId;
    });
  }
  
  // Future with .then() handler + async/await combined
  // Process transaction and update related data
  Future<String> addExpenseWithCombinedAsync({
    required double amount,
    required String category,
    String? description,
    required DateTime date,
  }) async {
    // Start with async/await
    final uid = await Future.value(_auth.currentUser!.uid);
    final col = _userMovementsCol(uid);
    
    // Use .then() to chain the Firestore operation
    return col.add({
      'amount': amount,
      'type': 'expense',
      'category': category,
      'description': description,
      'date': Timestamp.fromDate(date),
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    }).then((doc) async {
      // Inside .then() callback, use async/await
      final docId = doc.id;
      
      // Perform additional async operations
      await Future.delayed(Duration(milliseconds: 100));
      
      // Return the document ID
      return docId;
    });
  }
}
