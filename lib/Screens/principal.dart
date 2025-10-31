import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'income_form.dart';
import 'expense_form.dart';
import 'savings_screen.dart';
import 'notes_screen.dart';
import '../services/transaction_service.dart';
import '../services/savings_goal_service.dart';
import '../services/connectivity_service.dart';
import '../services/user_preferences_service.dart';
import '../services/app_settings_service.dart';
import '../widgets/connectivity_snack_listener.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _showOptions = false;
  final List<Color> barColors = [
    const Color(0xFF06c951),
    const Color(0xFFfa2e38),
    const Color(0xFF0e538f)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _selectedIndex == 0
          ? PreferredSize(
              preferredSize: const Size.fromHeight(120),
              child: StreamBuilder(
                stream: TransactionService.instance.userMovementsStream(),
                builder: (context, snapshot) {
                  double balance = 0;
                  if (snapshot.hasData) {
                    final movements = snapshot.data!;
                    double income = 0;
                    double expense = 0;
                    for (final m in movements) {
                      if (m.type == 'income') {
                        income += m.amount;
                      } else {
                        expense += m.amount;
                      }
                    }
                    balance = income - expense;
                  }

                  final displayName = UserPreferencesService.instance.getDisplayName();

                  const monthNames = [
                    'January',
                    'February',
                    'March',
                    'April',
                    'May',
                    'June',
                    'July',
                    'August',
                    'September',
                    'October',
                    'November',
                    'December'
                  ];
                  final currentMonth = monthNames[DateTime.now().month - 1];

                  return AppBar(
                    automaticallyImplyLeading: false,
                    backgroundColor: const Color(0xFFbde3f6),
                    toolbarHeight: 100,
                    title: Row(
                      children: [
                        Image.asset("Images/LogoIcon2.png", height: 40),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Welcome, $displayName",
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0e538f))),
                            const SizedBox(height: 5),
                            Text("Your balance for $currentMonth is",
                                style: const TextStyle(
                                    fontSize: 16,
                                    color: Color.fromRGBO(14, 83, 143, 1))),
                            const SizedBox(height: 5),
                            Text("\$${balance.toStringAsFixed(2)}",
                                style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0e538f))),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            )
          : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Home Tab
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ConnectivitySnackListener(),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 300,
                    child: StreamBuilder<List<MoneyMovement>>(
                      stream: TransactionService.instance.userMovementsStream(),
                      builder: (context, snapshot) {
                        double income = 0;
                        double expense = 0;
                        if (snapshot.hasData) {
                          for (final m in snapshot.data!) {
                            if (m.type == 'income') {
                              income += m.amount;
                            } else {
                              expense += m.amount;
                            }
                          }
                        }
                        final balance = income - expense;
                        final values = [income, expense, balance];

                        return BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            barTouchData: BarTouchData(enabled: true),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 50,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      "\$${value.toInt()}",
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  },
                                  interval: 500,
                                ),
                              ),
                              rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    switch (value.toInt()) {
                                      case 0:
                                        return const Text("Income");
                                      case 1:
                                        return const Text("Expenses");
                                      case 2:
                                        return const Text("Balance");
                                      default:
                                        return const Text("");
                                    }
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(show: true, drawHorizontalLine: true),
                            barGroups: values.asMap().entries.map((entry) {
                              final index = entry.key;
                              final value = entry.value;
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: value,
                                    color: barColors[index],
                                    width: 30,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 2))
                      ],
                      border: Border.all(color: Color(0xFFe0e0e0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.track_changes, color: Color(0xFF0e538f)),
                            SizedBox(width: 8),
                            Text('Saving Goals',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                        const SizedBox(height: 18),
                        StreamBuilder<List<SavingsGoal>>(
                          stream: SavingsGoalService.instance.userGoalsStream(),
                          builder: (context, snapshot) {
                            final goals = snapshot.data ?? [];
                            if (goals.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'You have no goals yet. Create one in Savings.',
                                  style: TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                              );
                            }
                            return Column(
                              children: goals.take(3).map((g) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 18),
                                  child: _MiniGoalCard(
                                    icon: Icons.savings,
                                    iconColor: const Color(0xFFbde3f6),
                                    title: g.name,
                                    saved: g.currentAmount,
                                    goal: g.targetAmount,
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
// Insights: Todo en un solo bloque
StreamBuilder<List<MoneyMovement>>(
  stream: TransactionService.instance.userMovementsStream(),
  builder: (context, snapshot) {
    final movements = snapshot.data ?? [];
    if (movements.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calcular gastos por categoría
    final expenses = movements.where((m) => m.type == 'expense').toList();
    final Map<String, double> expenseByCategory = {};
    final Map<String, double> incomeByCategory = {};

    for (final m in movements) {
      final cat = (m.category ?? 'Uncategorized').trim();
      if (m.type == 'expense') {
        expenseByCategory[cat] = (expenseByCategory[cat] ?? 0) + m.amount;
      } else if (m.type == 'income') {
        incomeByCategory[cat] = (incomeByCategory[cat] ?? 0) + m.amount;
      }
    }

    String topExpenseCat = 'N/A';
    double topExpenseAmt = 0;
    expenseByCategory.forEach((k, v) {
      if (v > topExpenseAmt) {
        topExpenseAmt = v;
        topExpenseCat = k;
      }
    });

    String topIncomeCat = 'N/A';
    double topIncomeAmt = 0;
    incomeByCategory.forEach((k, v) {
      if (v > topIncomeAmt) {
        topIncomeAmt = v;
        topIncomeCat = k;
      }
    });

    // Calcular últimas 5 transacciones de gastos
    final last5 = expenses.length > 5 ? expenses.sublist(expenses.length - 5) : expenses;
    final recentExpenses = last5.fold(0.0, (sum, m) => sum + m.amount);
    final totalExpenses = expenses.fold(0.0, (sum, m) => sum + m.amount);
    final percent = totalExpenses > 0 ? (recentExpenses / totalExpenses) * 100 : 0;

    final hasData = topExpenseAmt > 0 || topIncomeAmt > 0 || expenses.isNotEmpty;
    if (!hasData) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.lightbulb, color: Color(0xFF0e538f)),
              SizedBox(width: 8),
              Text('Smart Insights',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          if (topExpenseAmt > 0) ...[
            Text(
              'Your highest spending category is "$topExpenseCat" (\$${topExpenseAmt.toStringAsFixed(2)}).',
              style: const TextStyle(fontSize: 14, color: Color(0xFFfa2e38), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
          ],
          if (topIncomeAmt > 0) ...[
            Text(
              'Your highest income category is "$topIncomeCat" (\$${topIncomeAmt.toStringAsFixed(2)}).',
              style: const TextStyle(fontSize: 14, color: Color(0xFF06c951), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
          ],
          if (expenses.isNotEmpty) ...[
            Text(
              'In your last 5 expense transactions you spent \$${recentExpenses.toStringAsFixed(2)}.',
              style: const TextStyle(fontSize: 14, color: Color(0xFF0e538f), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'This represents ${percent.toStringAsFixed(0)}% of your total expenses.',
              style: const TextStyle(fontSize: 14, color: Color(0xFF0e538f), fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  },
),
                  const SizedBox(height: 16),
                  // Last Login (SharedPreferences)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFbde3f6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF0e538f).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.login, color: Color(0xFF0e538f), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Last login: ${AppSettingsService.instance.getLastConnectionText()}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF0e538f),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Last Transaction (SharedPreferences)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFbde3f6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF0e538f).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet, color: Color(0xFF0e538f), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Last transaction: ${AppSettingsService.instance.getLastTransactionText()}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF0e538f),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                ],
              ),
            ),
          ),
          const SavingsScreen(),
          const Center(
              child: Text('Reports',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0e538f)))),
          const NotesScreen(),
          _ProfileScreen(),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_showOptions) ...[
                  const SizedBox(height: 10),
                  FloatingActionButton(
                    heroTag: "BotonIncome",
                    backgroundColor: const Color(0xFF06c951),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) => Padding(
                          padding: EdgeInsets.only(
                              bottom:
                                  MediaQuery.of(context).viewInsets.bottom),
                          child: IncomeForm(),
                        ),
                      );
                    },
                    child: const Icon(Icons.trending_up),
                  ),
                  const SizedBox(height: 10),
                  FloatingActionButton(
                    heroTag: "BotonExpenses",
                    backgroundColor: const Color(0xFFfa2e38),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) => Padding(
                          padding: EdgeInsets.only(
                              bottom:
                                  MediaQuery.of(context).viewInsets.bottom),
                          child:  ExpenseForm(),
                        ),
                      );
                    },
                    child: const Icon(Icons.control_point),
                  ),
                ],
                FloatingActionButton(
                  heroTag: "Boton+",
                  backgroundColor: const Color(0xFFbde3f6),
                  onPressed: () {
                    setState(() {
                      _showOptions = !_showOptions;
                    });
                  },
                  child: const Icon(Icons.add, size: 28),
                ),
              ],
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            _showOptions = false;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.savings), label: 'Savings'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.note_alt), label: 'Notes'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _MiniGoalCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final double saved;
  final double goal;

  const _MiniGoalCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.saved,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goal > 0 ? (saved / goal).clamp(0.0, 1.0) : 0.0;
    final missing = (goal - saved).clamp(0.0, double.infinity);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: iconColor,
              radius: 18,
              child: Icon(icon, color: const Color(0xFF0e538f)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style:
                          const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                      "\$${saved.toStringAsFixed(2)} of \$${goal.toStringAsFixed(2)}",
                      style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF7bb7a6).withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 15)),
            ),
            const SizedBox(width: 10),
            Text('\$${missing.toStringAsFixed(2)} left',
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          minHeight: 7,
          backgroundColor: const Color(0xFFe0f0fa),
          valueColor:
              const AlwaysStoppedAnimation<Color>(Color(0xFFbde3f6)),
        ),
      ],
    );
  }
}

class _ProfileScreen extends StatefulWidget {
  const _ProfileScreen();

  @override
  State<_ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<_ProfileScreen> {
  final _prefsService = UserPreferencesService.instance;
  final _nameController = TextEditingController();
  String _selectedCurrency = 'USD';
  bool _notificationsEnabled = true;
  
  final List<String> _currencies = ['USD', 'EUR', 'GBP', 'MXN', 'COP', 'ARS', 'BRL'];
  
  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }
  
  void _loadPreferences() {
    setState(() {
      _selectedCurrency = _prefsService.getCurrency();
      _notificationsEnabled = _prefsService.areNotificationsEnabled();
      _nameController.text = _prefsService.getDisplayName();
    });
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0e538f),
            ),
          ),
          const SizedBox(height: 24),
          
          // User Info Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(0xFFbde3f6),
                        child: Text(
                          _prefsService.getDisplayName().isNotEmpty 
                              ? _prefsService.getDisplayName()[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0e538f),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _prefsService.getDisplayName(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? 'No email',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Display Name Edit
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Display Name',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Enter your name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_nameController.text.trim().isNotEmpty) {
                          try {
                            await _prefsService.updateDisplayName(_nameController.text.trim());
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Name updated successfully')),
                              );
                              setState(() {}); // Refresh UI
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error updating name: $e')),
                              );
                            }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0e538f),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Update Name'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Currency Selection
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Currency',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedCurrency,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    items: _currencies.map((currency) {
                      return DropdownMenuItem(
                        value: currency,
                        child: Text(currency),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      if (value != null) {
                        setState(() {
                          _selectedCurrency = value;
                        });
                        await _prefsService.setCurrency(value);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Currency set to $value')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Notifications Toggle
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Enable push notifications',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: _notificationsEnabled,
                    onChanged: (value) async {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                      await _prefsService.setNotificationsEnabled(value);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value ? 'Notifications enabled' : 'Notifications disabled',
                            ),
                          ),
                        );
                      }
                    },
                    activeColor: const Color(0xFF0e538f),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
