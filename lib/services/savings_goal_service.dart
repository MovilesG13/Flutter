import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'transaction_service.dart';

/// Modelo de dominio para una meta de ahorro
class SavingsGoal {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime createdAt;
  final String uid; // owner user id

  SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.createdAt,
    required this.uid,
  });

  double get progress => targetAmount > 0 ? currentAmount / targetAmount : 0.0;
  double get remaining => targetAmount - currentAmount;

  Map<String, dynamic> toMap() => {
        'name': name,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'createdAt': Timestamp.fromDate(createdAt),
        'uid': uid,
      };

  static SavingsGoal fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    Timestamp? createdAtTs;
    final rawCreated = data['createdAt'];
    if (rawCreated is Timestamp) {
      createdAtTs = rawCreated;
    }
    return SavingsGoal(
      id: doc.id,
      name: data['name'] as String,
      targetAmount: (data['targetAmount'] as num).toDouble(),
      currentAmount: (data['currentAmount'] as num? ?? 0.0).toDouble(),
      uid: data['uid'] as String,
      createdAt: (createdAtTs ?? Timestamp.fromDate(DateTime.now())).toDate(),
    );
  }

  SavingsGoal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? createdAt,
    String? uid,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      createdAt: createdAt ?? this.createdAt,
      uid: uid ?? this.uid,
    );
  }
}

class SavingsGoalService {
  SavingsGoalService._();
  static final instance = SavingsGoalService._();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Collection path: /users/{uid}/savingsGoals
  CollectionReference<Map<String, dynamic>> _userGoalsCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('savingsGoals');

  /// Añadir una nueva meta de ahorro
  Future<String> addGoal({
    required String name,
    required double targetAmount,
  }) async {
    final uid = _auth.currentUser!.uid;
    final col = _userGoalsCol(uid);
    final doc = await col.add({
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': 0.0,
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Actualizar una meta existente
  Future<void> updateGoal({
    required String goalId,
    String? name,
    double? targetAmount,
    double? currentAmount,
  }) async {
    final uid = _auth.currentUser!.uid;
    final docRef = _userGoalsCol(uid).doc(goalId);
    final Map<String, dynamic> updates = {};
    
    if (name != null) updates['name'] = name;
    if (targetAmount != null) updates['targetAmount'] = targetAmount;
    if (currentAmount != null) updates['currentAmount'] = currentAmount;
    
    await docRef.update(updates);
  }

  /// Eliminar una meta
  Future<void> deleteGoal(String goalId) async {
    final uid = _auth.currentUser!.uid;
    await _userGoalsCol(uid).doc(goalId).delete();
  }

  /// Obtener stream de todas las metas del usuario
  Stream<List<SavingsGoal>> userGoalsStream() {
    final uid = _auth.currentUser!.uid;
    return _userGoalsCol(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(SavingsGoal.fromDoc).toList());
  }

  /// Añadir dinero a una meta específica
  Future<void> addMoneyToGoal(String goalId, double amount) async {
    final uid = _auth.currentUser!.uid;
    final docRef = _userGoalsCol(uid).doc(goalId);

    // Leer meta para obtener el nombre (para registrar el gasto con descripción útil)
    final goalSnap = await docRef.get();
    final goalData = goalSnap.data();
    final goalName = goalData != null ? (goalData['name'] as String? ?? 'Savings Goal') : 'Savings Goal';

    // Incrementar ahorro de la meta
    await docRef.update({
      'currentAmount': FieldValue.increment(amount),
    });

    // Registrar como gasto en movimientos para que afecte a la gráfica principal
    await TransactionService.instance.addExpense(
      amount: amount,
      category: 'Savings',
      description: 'Contribution to $goalName',
      date: DateTime.now(),
    );
  }

  /// Restar dinero de una meta (si se necesita)
  Future<void> subtractMoneyFromGoal(String goalId, double amount) async {
    final uid = _auth.currentUser!.uid;
    final docRef = _userGoalsCol(uid).doc(goalId);
    
    final doc = await docRef.get();
    final current = (doc.data()?['currentAmount'] as num? ?? 0.0).toDouble();
    final newAmount = (current - amount).clamp(0.0, double.infinity);
    
    await docRef.update({
      'currentAmount': newAmount,
    });
  }
}
