import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Estadísticas"),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: db.userData,
        builder: (context, snapshot) {
          double savings = 0.0;
          double expenses = 0.0;
          double investments = 0.0;

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            savings = (data['totalSavings'] ?? 0.0).toDouble();
            expenses = (data['totalExpenses'] ?? 0.0).toDouble();
            investments = (data['totalInvestments'] ?? 0.0).toDouble();
          }

          double total = savings + expenses + investments;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Distribución de capital",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 200,
                        child: total == 0 
                          ? const Center(child: Text("No hay datos suficientes"))
                          : PieChart(
                              PieChartData(
                                sectionsSpace: 0,
                                centerSpaceRadius: 60,
                                sections: [
                                  PieChartSectionData(
                                    color: Colors.green,
                                    value: savings,
                                    title: '${(savings/total*100).toStringAsFixed(0)}%',
                                    radius: 30,
                                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  PieChartSectionData(
                                    color: Colors.redAccent,
                                    value: expenses,
                                    title: '${(expenses/total*100).toStringAsFixed(0)}%',
                                    radius: 30,
                                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  PieChartSectionData(
                                    color: Colors.blueAccent,
                                    value: investments,
                                    title: '${(investments/total*100).toStringAsFixed(0)}%',
                                    radius: 30,
                                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                      ),
                      const SizedBox(height: 32),
                      _buildLegendItem("Ahorros", Colors.green, savings),
                      const SizedBox(height: 12),
                      _buildLegendItem("Gastos", Colors.redAccent, expenses),
                      const SizedBox(height: 12),
                      _buildLegendItem("Inversiones", Colors.blueAccent, investments),
                    ],
                  ),
                ),
                const SizedBox(height: 120),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, double amount) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label),
        const Spacer(),
        Text(
          "S/ ${amount.toStringAsFixed(2)}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
