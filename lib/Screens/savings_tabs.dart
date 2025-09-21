
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

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
  @override
  State<SavingsTabs> createState() => _SavingsTabsState();
}

class _SavingsTabsState extends State<SavingsTabs> {
  int selectedTab = 1; // 0: Summary, 1: My Goals, 2: Progress

  @override
  Widget build(BuildContext context) {
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
                value: '2',
                color: Colors.blue,
              ),
              _InfoCard(
                icon: Icons.trending_up,
                title: 'Monthly Savings',
                value: "\$900",
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
                              sections: [
                                PieChartSectionData(
                                  value: 13150,
                                  color: Color(0xFF06c951),
                                  radius: 70,
                                  title: '',
                                  showTitle: false,
                                ),
                                PieChartSectionData(
                                  value: 51200-13150,
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
                              Text("\$13,150", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF06c951))),
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
          _GoalCard(
            icon: Icons.phone_iphone,
            iconColor: Color(0xFFbde3f6),
            title: 'Celular Nuevo',
            goal: 1200,
            progress: 0.54,
            saved: 650,
            missing: 550,
            monthly: 100,
            months: 6,
          ),
          SizedBox(height: 18),
          _GoalCard(
            icon: Icons.home,
            iconColor: Color(0xFFbde3f6),
            title: 'Casa Sola',
            goal: 50000,
            progress: 0.12,
            saved: 6000,
            missing: 44000,
            monthly: 1200,
            months: 37,
          ),
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
  final IconData icon;
  final Color iconColor;
  final String title;
  final double goal;
  final double progress;
  final double saved;
  final double missing;
  final double monthly;
  final int months;
  const _GoalCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.goal,
    required this.progress,
    required this.saved,
    required this.missing,
    required this.monthly,
    required this.months,
  });

  @override
  Widget build(BuildContext context) {
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
                child: Icon(icon, color: Color(0xFF0e538f)),
                radius: 22,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('Goal: \$${goal.toStringAsFixed(0)}', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                  ],
                ),
              ),
              Icon(Icons.edit, color: Colors.grey[500]),
              SizedBox(width: 8),
              Icon(Icons.delete, color: Colors.grey[500]),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progress: ${(progress*100).toStringAsFixed(0)}%', style: TextStyle(fontWeight: FontWeight.w500)),
              Text('\$${saved.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  Text('Missing', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  Text('\$${missing.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                children: [
                  Text('Monthly', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  Text('\$${monthly.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                children: [
                  Text('Est. Time', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  Text('$months months', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  onPressed: () {},
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
