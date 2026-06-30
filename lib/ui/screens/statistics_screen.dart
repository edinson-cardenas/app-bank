import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../core/theme/colors.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _selectedFilter = 'Semanal';
  final List<String> _filters = ['Diario', 'Semanal', 'Mensual', 'Anual'];

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Estadísticas"),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.calendar_month_outlined),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: db.transactions,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactions = snapshot.data!.docs;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildTimeFilter(),
                const SizedBox(height: 24),
                _buildSavingsBarChart(transactions, isDark),
                const SizedBox(height: 20),
                _buildBalanceLineChart(transactions, isDark),
                const SizedBox(height: 20),
                _buildExpensesDonutChart(transactions, isDark),
                const SizedBox(height: 120),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          bool isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedFilter = filter);
              },
              selectedColor: Colors.blueAccent.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? Colors.blueAccent : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide(color: isSelected ? Colors.blueAccent : Colors.grey.withValues(alpha: 0.2)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSavingsBarChart(List<QueryDocumentSnapshot> docs, bool isDark) {
    // Simplified logic for bar chart data
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151921) : Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Ahorro por semana", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text("Esta semana", style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text("S/ 320.00", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 5,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
                        return Text(days[value.toInt() % 7], style: const TextStyle(color: Colors.grey, fontSize: 10));
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _makeGroupData(0, 2, Colors.blueAccent.withValues(alpha: 0.3)),
                  _makeGroupData(1, 2.5, Colors.blueAccent.withValues(alpha: 0.3)),
                  _makeGroupData(2, 4.5, Colors.blueAccent),
                  _makeGroupData(3, 3, Colors.blueAccent.withValues(alpha: 0.3)),
                  _makeGroupData(4, 3.5, Colors.blueAccent.withValues(alpha: 0.3)),
                  _makeGroupData(5, 2.2, Colors.blueAccent.withValues(alpha: 0.3)),
                  _makeGroupData(6, 2.8, Colors.blueAccent.withValues(alpha: 0.3)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 16,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildBalanceLineChart(List<QueryDocumentSnapshot> docs, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151921) : Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Crecimiento del saldo", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Text("▲ 5.2% este mes", style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['1 Abr', '8 Abr', '15 Abr', '22 Abr', '29 Abr'];
                        if (value % 2 == 0 && value.toInt() ~/ 2 < days.length) {
                          return Text(days[value.toInt() ~/ 2], style: const TextStyle(color: Colors.grey, fontSize: 10));
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 3),
                      FlSpot(2, 3.5),
                      FlSpot(4, 4),
                      FlSpot(6, 4.5),
                      FlSpot(8, 5),
                    ],
                    isCurved: true,
                    color: Colors.greenAccent,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [Colors.greenAccent.withValues(alpha: 0.2), Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesDonutChart(List<QueryDocumentSnapshot> docs, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151921) : Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Distribución de gastos", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text("Este mes", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 50,
                    sections: [
                      PieChartSectionData(color: Colors.greenAccent, value: 40, showTitle: false, radius: 12),
                      PieChartSectionData(color: Colors.blueAccent, value: 25, showTitle: false, radius: 12),
                      PieChartSectionData(color: Colors.purpleAccent, value: 15, showTitle: false, radius: 12),
                      PieChartSectionData(color: Colors.orangeAccent, value: 10, showTitle: false, radius: 12),
                      PieChartSectionData(color: Colors.blueGrey, value: 10, showTitle: false, radius: 12),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildExpenseLegendItem("Alimentación", Colors.greenAccent, "40%"),
                    _buildExpenseLegendItem("Transporte", Colors.blueAccent, "25%"),
                    _buildExpenseLegendItem("Entretenimiento", Colors.purpleAccent, "15%"),
                    _buildExpenseLegendItem("Servicios", Colors.orangeAccent, "10%"),
                    _buildExpenseLegendItem("Otros", Colors.blueGrey, "10%"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseLegendItem(String label, Color color, String percent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey))),
          Text(percent, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
