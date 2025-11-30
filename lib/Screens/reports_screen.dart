import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/transaction_service.dart';
import '../services/offline_queue_service.dart';
import '../services/connectivity_service.dart';
import '../services/transactions_cache_service.dart';
import '../widgets/connectivity_snack_listener.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int selectedTab = 0; // 0: By Categories, 1: Monthly Reports

  // Microoptimization: Lista de colores como constante estática para evitar recrearla en cada rebuild
  static const List<Color> _categoryColors = [
    Color(0xFFfa2e38), // Red
    Color(0xFF0e538f), // Blue
    Color(0xFF06c951), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFFFFEB3B), // Yellow
    Color(0xFF9C27B0), // Purple
    Color(0xFFE91E63), // Pink
    Color(0xFF00BCD4), // Cyan
    Color(0xFF4CAF50), // Light Green
    Color(0xFFFF5722), // Deep Orange
    Color(0xFF2196F3), // Light Blue
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
    Color(0xFF3F51B5), // Indigo
    Color(0xFF00E676), // Green Accent
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
              child: ConnectivitySnackListener(),
            ),
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
                      const Icon(Icons.bar_chart, color: Color(0xFF0e538f), size: 32),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Reports',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0e538f),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Analyze your expenses',
                    style: TextStyle(fontSize: 16, color: Color(0xFF0e538f)),
                  ),
                ],
              ),
            ),
            // Tabs
            Container(
              margin: const EdgeInsets.only(top: 18, left: 8, right: 8),
              child: Row(
                children: [
                  _TabButton(
                    'By Categories',
                    selectedTab == 0,
                    onTap: () => setState(() => selectedTab = 0),
                  ),
                  _TabButton(
                    'Monthly Reports',
                    selectedTab == 1,
                    onTap: () => setState(() => selectedTab = 1),
                  ),
                ],
              ),
            ),
            // Tab Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: selectedTab == 0
                    ? _buildByCategoriesTab()
                    : _buildMonthlyReportsTab(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildByCategoriesTab() {
    return StreamBuilder<bool>(
      stream: ConnectivityService.instance.isOnlineStream,
      initialData: ConnectivityService.instance.isOnline,
      builder: (context, connectivitySnapshot) {
        final isOnline = connectivitySnapshot.data ?? true;
        
        // Eventual Connectivity Strategy:
        // - If online: use Firestore stream (real-time) + cache locally
        // - If offline: use cached data from local storage
        if (isOnline) {
          // Online: Use Firestore stream (which also caches data)
          return StreamBuilder<List<MoneyMovement>>(
            stream: TransactionService.instance.userMovementsStream(),
            builder: (context, snapshot) {
              // Get online expenses
              final onlineExpenses = snapshot.data
                      ?.where((m) => m.type == 'expense')
                      .toList() ??
                  [];

              // Get offline expenses using FutureBuilder
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: OfflineQueueService.instance.getPendingExpenses(),
                builder: (context, offlineSnapshot) {
                  final offlineExpenses = offlineSnapshot.data ?? [];

                  // Combine online and offline expenses
                  final allExpenses = <Map<String, dynamic>>[];

                  // Add online expenses (from Firestore, cached locally)
                  for (final expense in onlineExpenses) {
                    allExpenses.add({
                      'category': expense.category ?? 'Uncategorized',
                      'amount': expense.amount,
                    });
                  }

                  // Add offline expenses (pending queue)
                  allExpenses.addAll(offlineExpenses);
                  
                  return _buildExpensesChart(allExpenses, offlineExpenses.length);
                },
              );
            },
          );
        } else {
          // Offline: Use cached data from local storage (eventual connectivity)
          return FutureBuilder<List<MoneyMovement>>(
            future: TransactionsCacheService.instance.getCachedExpenses(),
            builder: (context, cachedSnapshot) {
              // Get cached expenses
              final cachedExpenses = cachedSnapshot.data ?? [];

              // Get offline expenses using FutureBuilder
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: OfflineQueueService.instance.getPendingExpenses(),
                builder: (context, offlineSnapshot) {
                  final offlineExpenses = offlineSnapshot.data ?? [];

                  // Combine cached and offline expenses
                  final allExpenses = <Map<String, dynamic>>[];

                  // Add cached expenses (from local storage)
                  for (final expense in cachedExpenses) {
                    allExpenses.add({
                      'category': expense.category ?? 'Uncategorized',
                      'amount': expense.amount,
                    });
                  }

                  // Add offline expenses (pending queue)
                  allExpenses.addAll(offlineExpenses);
                  
                  return _buildExpensesChart(allExpenses, offlineExpenses.length, isOffline: true);
                },
              );
            },
          );
        }
      },
    );
  }

  Widget _buildExpensesChart(
    List<Map<String, dynamic>> allExpenses,
    int pendingCount, {
    bool isOffline = false,
  }) {
    // Group by category and sum amounts
    final Map<String, double> expensesByCategory = {};
    for (final expense in allExpenses) {
      final category = expense['category'] as String;
      final amount = expense['amount'] as double;
      expensesByCategory[category] =
          (expensesByCategory[category] ?? 0) + amount;
    }

    // Convert to list for pie chart
    final categoryEntries = expensesByCategory.entries.toList();
    categoryEntries.sort((a, b) => b.value.compareTo(a.value));

    if (categoryEntries.isEmpty) {
      return Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pie_chart_outline,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No expenses to display',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Add some expenses to see the chart',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate total for percentages
    final totalExpenses = categoryEntries
        .fold<double>(0, (sum, entry) => sum + entry.value);

    // Create pie chart sections
    final pieChartSections = categoryEntries.asMap().entries.map((entry) {
      final index = entry.key;
      final categoryEntry = entry.value;
      final percentage = (categoryEntry.value / totalExpenses * 100);
      
      return PieChartSectionData(
        value: categoryEntry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        color: _categoryColors[index % _categoryColors.length],
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Column(
      children: [
        // Offline indicator
        if (isOffline) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_download,
                  color: Colors.blue[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Showing cached data (offline mode)',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const Text(
          'Expenses by Category',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0e538f),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Distribution of your expenses across different categories',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 24),
        // Pie Chart
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: SizedBox(
            height: 300,
            child: PieChart(
              PieChartData(
                sections: pieChartSections,
                centerSpaceRadius: 60,
                sectionsSpace: 2,
                startDegreeOffset: -90,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Legend
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Category Breakdown',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0e538f),
                ),
              ),
              const SizedBox(height: 16),
              ...categoryEntries.asMap().entries.map((entry) {
                final index = entry.key;
                final categoryEntry = entry.value;
                final percentage =
                    (categoryEntry.value / totalExpenses * 100);
                final color = _categoryColors[index % _categoryColors.length];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          categoryEntry.key,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '\$${categoryEntry.value.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0e538f),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${percentage.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Expenses',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '\$${totalExpenses.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFfa2e38),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Pending expenses indicator
        if (pendingCount > 0) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_off,
                  color: Colors.orange[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$pendingCount expense(s) pending upload',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMonthlyReportsTab() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Monthly Reports',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Coming soon',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
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
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: selected ? Colors.white : const Color(0xFFF5F6FA),
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
