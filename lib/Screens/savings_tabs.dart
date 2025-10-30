
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/savings_goal_service.dart';

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  const _InfoCard({required this.icon, required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0,2))],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 6),
          Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class SavingsTabs extends StatefulWidget {
  final List<SavingsGoal> goals;
  final Function(SavingsGoal) onEditGoal;
  
  const SavingsTabs({super.key, required this.goals, required this.onEditGoal});

  @override
  State<SavingsTabs> createState() => _SavingsTabsState();
}

class _SavingsTabsState extends State<SavingsTabs> {
  int selectedTab = 1; // 0: Summary, 1: My Goals, 2: Progress
  final _goalService = SavingsGoalService.instance;

  void _showAddMoneyDialog(SavingsGoal goal) {
    final amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Añadir Dinero'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Meta: ${goal.name}'),
            SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: 'Cantidad a añadir',
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
              final amountStr = amountController.text.trim();
              final amount = double.tryParse(amountStr);
              
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Por favor ingresa una cantidad válida')),
                );
                return;
              }
              
              try {
                await _goalService.addMoneyToGoal(goal.id, amount);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Dinero añadido exitosamente')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            child: Text('Añadir'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(SavingsGoal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de que deseas eliminar la meta "${goal.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _goalService.deleteGoal(goal.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Meta eliminada exitosamente')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goals = widget.goals;
    final totalSaved = goals.fold<double>(0.0, (sum, goal) => sum + goal.currentAmount);
    final totalTarget = goals.fold<double>(0.0, (sum, goal) => sum + goal.targetAmount);
    final activeGoals = goals.length;
    
    // Calcular ahorro mensual estimado (promedio de las metas que tienen progreso)
    final goalsWithProgress = goals.where((g) => g.currentAmount > 0).toList();
    final monthlySavings = goalsWithProgress.isNotEmpty
        ? goalsWithProgress.map((g) {
            final monthsSinceStart = (DateTime.now().difference(g.createdAt).inDays / 30.0).clamp(1.0, double.infinity);
            return g.currentAmount / monthsSinceStart;
          }).fold(0.0, (sum, val) => sum + val) / goalsWithProgress.length
        : 0.0;

    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(top: 18, left: 8, right: 8),
          child: Row(
            children: [
              _TabButton('Summary', selectedTab == 0, onTap: () => setState(() => selectedTab = 0)),
              _TabButton('My Goals', selectedTab == 1, onTap: () => setState(() => selectedTab = 1)),
              _TabButton('Progress', selectedTab == 2, onTap: () => setState(() => selectedTab = 2)),
            ],
          ),
        ),
        if (selectedTab == 0) ...[
          SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _InfoCard(
                icon: Icons.track_changes,
                title: 'Active Goals',
                value: '$activeGoals',
                color: Colors.blue,
              ),
              _InfoCard(
                icon: Icons.trending_up,
                title: 'Monthly Savings',
                value: monthlySavings > 0 ? "\$${monthlySavings.toStringAsFixed(0)}" : "\$0",
                color: Colors.green,
              ),
            ],
          ),
          SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text('Savings Distribution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                ),
                SizedBox(height: 32),
                Center(
                  child: Container(
                    height: 190,
                    width: 190,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.red, width: 8),
                    ),
                    child: Container(
                      margin: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey[300]!, width: 2),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sections: totalTarget > 0
                                  ? [
                                      PieChartSectionData(
                                        value: totalSaved,
                                        color: Color(0xFF06c951),
                                        radius: 70,
                                        title: '',
                                        showTitle: false,
                                      ),
                                      PieChartSectionData(
                                        value: totalTarget - totalSaved,
                                        color: Color(0xFFe0e0e0),
                                        radius: 70,
                                        title: '',
                                        showTitle: false,
                                      ),
                                    ]
                                  : [
                                      PieChartSectionData(
                                        value: 1,
                                        color: Color(0xFFe0e0e0),
                                        radius: 70,
                                        title: '',
                                        showTitle: false,
                                      ),
                                    ],
                              centerSpaceRadius: 55,
                              sectionsSpace: 0,
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "\$${totalSaved.toStringAsFixed(0)}",
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF06c951)),
                              ),
                              SizedBox(height: 2),
                              Text("Saved", style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 18),
              ],
            ),
          ),
        ],
        if (selectedTab == 1) ...[
          SizedBox(height: 18),
          if (goals.isEmpty)
            Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.track_changes, size: 64, color: Colors.grey[400]),
                    SizedBox(height: 16),
                    Text(
                      'No tienes metas de ahorro aún',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Presiona el botón + para añadir una nueva meta',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ...goals.map((goal) => Column(
                children: [
                  _GoalCard(
                    goal: goal,
                    icon: Icons.savings,
                    iconColor: Color(0xFFbde3f6),
                    onEdit: () => widget.onEditGoal(goal),
                    onDelete: () => _showDeleteConfirmation(goal),
                    onAddMoney: () => _showAddMoneyDialog(goal),
                  ),
                  SizedBox(height: 18),
                ],
              )),
        ],
        if (selectedTab == 2) ...[
          SizedBox(height: 18),
          if (goals.isEmpty)
            Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.trending_up, size: 64, color: Colors.grey[400]),
                    SizedBox(height: 16),
                    Text(
                      'No hay progreso para mostrar',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Añade metas y dinero para ver tu progreso',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ...goals.map((goal) => Column(
                children: [
                  _GoalCard(
                    goal: goal,
                    icon: Icons.savings,
                    iconColor: Color(0xFFbde3f6),
                    onEdit: () => widget.onEditGoal(goal),
                    onDelete: () => _showDeleteConfirmation(goal),
                    onAddMoney: () => _showAddMoneyDialog(goal),
                  ),
                  SizedBox(height: 18),
                ],
              )),
        ]
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabButton(this.label, this.selected, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: selected ? Colors.white : Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddMoney;

  const _GoalCard({
    required this.goal,
    required this.icon,
    required this.iconColor,
    required this.onEdit,
    required this.onDelete,
    required this.onAddMoney,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goal.progress.clamp(0.0, 1.0);
    final remaining = goal.remaining;
    
    // Calcular ahorro mensual estimado
    final monthsSinceStart = (DateTime.now().difference(goal.createdAt).inDays / 30.0).clamp(1.0, double.infinity);
    final monthlySavings = goal.currentAmount / monthsSinceStart;
    
    // Estimar meses restantes
    final estimatedMonths = monthlySavings > 0 
        ? (remaining / monthlySavings).ceil() 
        : 0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12),
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0,2))],
        border: Border.all(color: Color(0xFFe0e0e0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: iconColor,
                radius: 22,
                child: Icon(icon, color: Color(0xFF0e538f)),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('Goal: \$${goal.targetAmount.toStringAsFixed(2)}', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit, color: Colors.grey[500]),
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.grey[500]),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progress: ${(progress * 100).toStringAsFixed(0)}%', style: TextStyle(fontWeight: FontWeight.w500)),
              Text('\$${goal.currentAmount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Color(0xFFeafbe7),
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFbde3f6)),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Text('Left', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  Text('\$${remaining.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                children: [
                  Text('Monthly', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  Text('\$${monthlySavings.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                children: [
                  Text('Est. Time', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  Text(
                    estimatedMonths > 0 ? '$estimatedMonths months' : 'N/A',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFbde3f6),
                    foregroundColor: Color(0xFF0e538f),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: Icon(Icons.add),
                  label: Text('Add Money'),
                  onPressed: onAddMoney,
                ),
              ),
              SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFFeafbe7),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.all(8),
                child: Icon(Icons.calendar_today, color: Color(0xFF0e538f), size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
