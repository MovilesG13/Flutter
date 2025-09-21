import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:financeapp_flutter/Screens/income_form.dart';
import 'package:financeapp_flutter/Screens/savings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardScreen(),
    SavingsScreen(),
    const Center(child: Text("Reports")),
    const Center(child: Text("Profile")),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0e538f),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.savings), label: "Savings"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Reports"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late List<double> values;
  bool _showOptions = false;

  final List<Color> barColors = [
    Color(0xFF06c951), // Income
    Color(0xFFfa2e38),   // Expenses fa2e38
    Colors.blue,  // Balance
  ];

  @override
  void initState() {
    super.initState();
    values = [
      2500,    // Income fijo
      1856.24, // Expenses fijo
      643.76,  // Balance fijo
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
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
              children: const [
                Text("Welcome, Sofia",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0e538f))),
                SizedBox(height: 5),
                Text("Your balance for September is",
                    style: TextStyle(fontSize: 16, color: Color(0xFF0e538f))),
                SizedBox(height: 5),
                Text("\$ 643.76",
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0e538f))),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
        ],
      ),
      floatingActionButton: Column(
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const Center(child: Text("Expenses Screen")),
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
      ),
    );
  }
}




