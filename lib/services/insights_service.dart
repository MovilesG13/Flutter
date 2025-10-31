import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'transaction_service.dart';

/// Input data for the isolate - must be serializable
class InsightsInput {
  final List<Map<String, dynamic>> movementsData;
  
  InsightsInput(this.movementsData);
  
  Map<String, dynamic> toJson() => {
    'movementsData': movementsData,
  };
  
  factory InsightsInput.fromJson(Map<String, dynamic> json) => InsightsInput(
    List<Map<String, dynamic>>.from(json['movementsData']),
  );
}

/// Result data from the isolate - must be serializable
class InsightsResult {
  final String topExpenseCategory;
  final double topExpenseAmount;
  final String topIncomeCategory;
  final double topIncomeAmount;
  final double recentExpenses;
  final double totalExpenses;
  final double percent;
  final int lastTransactionTimestamp; // Timestamp en milisegundos
  
  InsightsResult({
    required this.topExpenseCategory,
    required this.topExpenseAmount,
    required this.topIncomeCategory,
    required this.topIncomeAmount,
    required this.recentExpenses,
    required this.totalExpenses,
    required this.percent,
    required this.lastTransactionTimestamp,
  });
  
  Map<String, dynamic> toJson() => {
    'topExpenseCategory': topExpenseCategory,
    'topExpenseAmount': topExpenseAmount,
    'topIncomeCategory': topIncomeCategory,
    'topIncomeAmount': topIncomeAmount,
    'recentExpenses': recentExpenses,
    'totalExpenses': totalExpenses,
    'percent': percent,
    'lastTransactionTimestamp': lastTransactionTimestamp,
  };
  
  factory InsightsResult.fromJson(Map<String, dynamic> json) => InsightsResult(
    topExpenseCategory: json['topExpenseCategory'] as String,
    topExpenseAmount: (json['topExpenseAmount'] as num).toDouble(),
    topIncomeCategory: json['topIncomeCategory'] as String,
    topIncomeAmount: (json['topIncomeAmount'] as num).toDouble(),
    recentExpenses: (json['recentExpenses'] as num).toDouble(),
    totalExpenses: (json['totalExpenses'] as num).toDouble(),
    percent: (json['percent'] as num).toDouble(),
    lastTransactionTimestamp: json['lastTransactionTimestamp'] as int,
  );
}

/// Top-level function that runs in the isolate
/// Must be top-level (not inside a class) and take a single serializable argument
/// This function will be executed in a separate isolate thread
InsightsResult _computeInsights(Map<String, dynamic> inputJson) {
  final input = InsightsInput.fromJson(inputJson);
  final movements = input.movementsData;
  
  if (movements.isEmpty) {
    return InsightsResult(
      topExpenseCategory: 'N/A',
      topExpenseAmount: 0,
      topIncomeCategory: 'N/A',
      topIncomeAmount: 0,
      recentExpenses: 0,
      totalExpenses: 0,
      percent: 0,
      lastTransactionTimestamp: 0,
    );
  }
  
  // Calcular gastos por categoría
  final expenses = movements.where((m) => m['type'] == 'expense').toList();
  final Map<String, double> expenseByCategory = {};
  final Map<String, double> incomeByCategory = {};
  
  for (final m in movements) {
    final cat = (m['category'] ?? 'Uncategorized').toString().trim();
    final amount = (m['amount'] as num).toDouble();
    if (m['type'] == 'expense') {
      expenseByCategory[cat] = (expenseByCategory[cat] ?? 0) + amount;
    } else if (m['type'] == 'income') {
      incomeByCategory[cat] = (incomeByCategory[cat] ?? 0) + amount;
    }
  }
  
  // Encontrar categoría con mayor gasto
  String topExpenseCat = 'N/A';
  double topExpenseAmt = 0;
  expenseByCategory.forEach((k, v) {
    if (v > topExpenseAmt) {
      topExpenseAmt = v;
      topExpenseCat = k;
    }
  });
  
  // Encontrar categoría con mayor ingreso
  String topIncomeCat = 'N/A';
  double topIncomeAmt = 0;
  incomeByCategory.forEach((k, v) {
    if (v > topIncomeAmt) {
      topIncomeAmt = v;
      topIncomeCat = k;
    }
  });
  
  // Calcular últimas 5 transacciones de gastos
  // Las transacciones ya vienen ordenadas por createdAt descendente (más recientes primero)
  // Solo necesitamos tomar las primeras 5 de los gastos
  // Ordenar por createdAt para asegurar el orden correcto (más recientes primero)
  expenses.sort((a, b) {
    final createdAtA = a['createdAt'] as int? ?? 0;
    final createdAtB = b['createdAt'] as int? ?? 0;
    return createdAtB.compareTo(createdAtA); // Descendente: más recientes primero
  });
  
  // Tomar solo las últimas 5 transacciones de gastos (las más recientes)
  final last5 = expenses.length > 5 
      ? expenses.sublist(0, 5) 
      : expenses;
  
  // Sumar SOLO las últimas 5 transacciones
  final recentExpenses = last5.fold<double>(
    0.0, 
    (sum, m) => sum + (m['amount'] as num).toDouble()
  );
  final totalExpenses = expenses.fold<double>(
    0.0, 
    (sum, m) => sum + (m['amount'] as num).toDouble()
  );
  final percent = totalExpenses > 0 
      ? ((recentExpenses / totalExpenses) * 100).toDouble()
      : 0.0;
  
  // Calcular la última transacción (la más reciente por createdAt)
  int lastTransactionTimestamp = 0;
  if (movements.isNotEmpty) {
    // Encontrar la transacción con el mayor createdAt
    for (final m in movements) {
      final createdAt = m['createdAt'] as int? ?? 0;
      if (createdAt > lastTransactionTimestamp) {
        lastTransactionTimestamp = createdAt;
      }
    }
  }
  
  return InsightsResult(
    topExpenseCategory: topExpenseCat,
    topExpenseAmount: topExpenseAmt,
    topIncomeCategory: topIncomeCat,
    topIncomeAmount: topIncomeAmt,
    recentExpenses: recentExpenses,
    totalExpenses: totalExpenses,
    percent: percent,
    lastTransactionTimestamp: lastTransactionTimestamp,
  );
}

class InsightsService {
  InsightsService._();
  static final instance = InsightsService._();
  
  /// Calcula los insights usando un isolate
  /// Esto ejecuta el cálculo en un hilo separado para no bloquear el UI thread
  Future<InsightsResult> computeInsightsAsync(
    List<MoneyMovement> movements
  ) async {
    // Convertir MoneyMovement a Map serializable para poder pasarlo al isolate
    // Los isolates solo pueden recibir datos serializables (primitivos, Maps, Lists)
    final movementsData = movements.map((m) => {
      'type': m.type,
      'amount': m.amount,
      'category': m.category ?? 'Uncategorized',
      'date': m.date.millisecondsSinceEpoch,
      'createdAt': m.createdAt.millisecondsSinceEpoch, // Necesario para ordenar correctamente
    }).toList();
    
    // Crear el input para el isolate
    final input = InsightsInput(movementsData);
    
    // Ejecutar en isolate separado usando compute()
    // compute() es un helper de Flutter que crea un isolate temporal,
    // ejecuta la función, y devuelve el resultado
    return await compute(_computeInsights, input.toJson());
  }
}

