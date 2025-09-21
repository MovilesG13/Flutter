
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'income_form.dart';
import 'expense_form.dart';
import 'savings_screen.dart';
import 'savings_tabs.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  int _selectedIndex = 0;
  bool _showOptions = false;
  final List<double> values = [2000, 1356.24, 643.76];
  final List<Color> barColors = [Color(0xFF06c951), Color(0xFFfa2e38), Color(0xFF0e538f)];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _selectedIndex == 0
          ? AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: const Color(0xFFbde3f6),
              toolbarHeight: 100,
              title: Row(
                children: [
                  Image.asset(
                    "Images/LogoIcon2.png",
                    height: 40,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Welcome, Sofia",
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0e538f))),
                      const SizedBox(height: 5),
                      const Text("Your balance for September is",
                          style: TextStyle(fontSize: 16, color: Color(0xFF0e538f))),
                      const SizedBox(height: 5),
                      Text("\$ ${values[2].toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0e538f))),
                    ],
                  ),
                ],
              ),
            )
          : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Home Tab
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 18),
                const Text(
                  "Financial Overview",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 300,
                  child: BarChart(
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
                        rightTitles:
                            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles:
                            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                  ),
                ),
                const SizedBox(height: 24),
                // Metas de ahorro
                Container(
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
                          Icon(Icons.track_changes, color: Color(0xFF0e538f)),
                          SizedBox(width: 8),
                          Text('Saving Goals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                      SizedBox(height: 18),
                      // Meta 1
                      _MiniGoalCard(
                        icon: Icons.phone_iphone,
                        iconColor: Color(0xFFbde3f6),
                        title: 'New Phone',
                        saved: 650,
                        goal: 1200,
                      ),
                      SizedBox(height: 18),
                      // Meta 2
                      _MiniGoalCard(
                        icon: Icons.home,
                        iconColor: Color(0xFFbde3f6),
                        title: 'New House',
                        saved: 12500,
                        goal: 50000,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          // Savings Tab
          SavingsScreen(),
          // Reports Tab
          Center(child: Text('Reports', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0e538f)))),
          // Profile Tab
          Center(child: Text('Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0e538f)))),
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
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom,
                              left: 20,
                              right: 20,
                              top: 20,
                            ),
                            child: IncomeForm(),
                          );
                        },
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
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom,
                              left: 20,
                              right: 20,
                              top: 20,
                            ),
                            child: ExpenseForm(),
                          );
                        },
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
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.savings),
            label: 'Savings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// MiniGoalCard para mostrar metas de ahorro en la principal
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
    final progress = saved / goal;
    final missing = goal - saved;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: iconColor,
              child: Icon(icon, color: Color(0xFF0e538f)),
              radius: 18,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("\$${saved.toStringAsFixed(2)} of \$${goal.toStringAsFixed(2)}", style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFF7bb7a6).withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${(progress*100).toStringAsFixed(0)}%', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
            ),
            SizedBox(width: 10),
            Text('\$${missing.toStringAsFixed(2)} left', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          minHeight: 7,
          backgroundColor: Color(0xFFe0f0fa),
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFbde3f6)),
        ),
      ],
    );
  }
}




