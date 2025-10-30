import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'savings_tabs.dart';
import '../services/savings_goal_service.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  final _goalService = SavingsGoalService.instance;

  void _showAddGoalDialog({SavingsGoal? existingGoal}) {
    final nameController = TextEditingController(text: existingGoal?.name ?? '');
    final amountController = TextEditingController(text: existingGoal?.targetAmount.toStringAsFixed(2) ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingGoal == null ? 'Nueva Meta de Ahorro' : 'Editar Meta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nombre de la meta',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: 'Cantidad objetivo',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final amountStr = amountController.text.trim();
              
              if (name.isEmpty || amountStr.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Por favor completa todos los campos')),
                );
                return;
              }
              
              final amount = double.tryParse(amountStr);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Por favor ingresa una cantidad válida')),
                );
                return;
              }
              
              try {
                if (existingGoal == null) {
                  await _goalService.addGoal(name: name, targetAmount: amount);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Meta añadida exitosamente')),
                  );
                } else {
                  await _goalService.updateGoal(
                    goalId: existingGoal.id,
                    name: name,
                    targetAmount: amount,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Meta actualizada exitosamente')),
                  );
                }
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            child: Text(existingGoal == null ? 'Añadir' : 'Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F6FA),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGoalDialog(),
        backgroundColor: Color(0xFF0e538f),
        child: Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: StreamBuilder<List<SavingsGoal>>(
          stream: _goalService.userGoalsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            
            final goals = snapshot.data ?? [];
            
            // Calcular totales
            final totalSaved = goals.fold<double>(0.0, (sum, goal) => sum + goal.currentAmount);
            final totalTarget = goals.fold<double>(0.0, (sum, goal) => sum + goal.targetAmount);
            final totalProgress = totalTarget > 0 ? totalSaved / totalTarget : 0.0;
            
            return SingleChildScrollView(
              child: Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 24),
                    decoration: const BoxDecoration(
                      color: Color(0xFFbde3f6),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.track_changes, color: Color(0xFF0e538f), size: 32),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Savings Goals',
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0e538f)),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Reach your financial goals',
                          style: TextStyle(fontSize: 16, color: Color(0xFF0e538f)),
                        ),
                        SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('Total Progress', style: TextStyle(color: Color(0xFF0e538f), fontWeight: FontWeight.w600)),
                                  Spacer(),
                                  Icon(Icons.attach_money, color: Color(0xFF0e538f), size: 18),
                                ],
                              ),
                              SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "\$${totalSaved.toStringAsFixed(2)}",
                                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0e538f)),
                                  ),
                                  SizedBox(width: 12),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFbde3f6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${(totalProgress * 100).toStringAsFixed(0)}%',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0e538f), fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                'of \$${totalTarget.toStringAsFixed(2)} total goal',
                                style: TextStyle(color: Color(0xFF0e538f)),
                              ),
                              SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: totalProgress.clamp(0.0, 1.0),
                                  minHeight: 8,
                                  backgroundColor: Color(0xFFbde3f6),
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0e538f)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tabs con lógica de selección
                  SavingsTabs(
                    goals: goals,
                    onEditGoal: (g) => _showAddGoalDialog(existingGoal: g),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
