import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'savings_tabs.dart';

class SavingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F6FA),
      body: SafeArea(
        child: SingleChildScrollView(
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
                        Icon(Icons.add, color: Color(0xFF0e538f), size: 28),
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
                              Text("\$13,150.00", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0e538f))),
                              SizedBox(width: 12),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Color(0xFFbde3f6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('26%', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0e538f), fontSize: 16)),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text('of \$51,200.00 total goal', style: TextStyle(color: Color(0xFF0e538f))),
                          SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: 0.26,
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
              SavingsTabs(),
            ],
          ),
        ),
      ),
  );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  const _TabButton(this.label, this.selected);

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
            onTap: () {},
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
