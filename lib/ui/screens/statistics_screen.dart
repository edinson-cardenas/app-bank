import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../services/settings_provider.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _selectedFilter = 'Semanal';
  final List<String> _filters = ['Diario', 'Semanal', 'Mensual', 'Anual'];
  DateTimeRange? _customRange;

  DateTimeRange _rangeForFilter(String filter) {
    final now = DateTime.now();
    switch (filter) {
      case 'Diario':
        final start = DateTime(now.year, now.month, now.day);
        return DateTimeRange(start: start, end: now);
      case 'Mensual':
        final start = DateTime(now.year, now.month, 1);
        return DateTimeRange(start: start, end: now);
      case 'Anual':
        final start = DateTime(now.year, 1, 1);
        return DateTimeRange(start: start, end: now);
      case 'Semanal':
      default:
        final start = now.subtract(const Duration(days: 7));
        return DateTimeRange(start: start, end: now);
    }
  }

  DateTimeRange get _activeRange => _customRange ?? _rangeForFilter(_selectedFilter);

  List<QueryDocumentSnapshot> _filterByRange(List<QueryDocumentSnapshot> docs, DateTimeRange range) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['date'] as Timestamp?)?.toDate();
      if (date == null) return false;
      return !date.isBefore(range.start) && !date.isAfter(range.end.add(const Duration(days: 1)));
    }).toList();
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _customRange,
    );
    if (picked != null) {
      setState(() => _customRange = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final settings = Provider.of<SettingsProvider>(context);
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
              icon: Icon(_customRange != null ? Icons.event_available : Icons.calendar_month_outlined),
              tooltip: "Elegir rango de fechas",
              onPressed: () => _pickDateRange(context),
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

          final allDocs = snapshot.data!.docs;

          if (allDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart_rounded, size: 80, color: Colors.grey.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text(
                    "No hay datos para mostrar",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Registra tus primeros movimientos para ver estadísticas.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final range = _activeRange;
          final filteredDocs = _filterByRange(allDocs, range);

          if (filteredDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTimeFilter(),
                  const SizedBox(height: 40),
                  Icon(Icons.filter_alt_off_outlined, size: 60, color: Colors.grey.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text(
                    "No hay movimientos en este periodo",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Baseline (saldo neto antes del periodo) para calcular el % de crecimiento real.
          double baseline = 0;
          for (final doc in allDocs) {
            final data = doc.data() as Map<String, dynamic>;
            final date = (data['date'] as Timestamp?)?.toDate();
            if (date == null || !date.isBefore(range.start)) continue;
            final amount = (data['amount'] ?? 0).toDouble();
            final type = data['type'];
            baseline += (type == 'gasto') ? -amount : amount;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildTimeFilter(),
                const SizedBox(height: 24),
                _buildSavingsBarChart(filteredDocs, isDark, settings),
                const SizedBox(height: 20),
                _buildBalanceLineChart(filteredDocs, isDark, baseline),
                const SizedBox(height: 20),
                _buildExpensesDonutChart(filteredDocs, isDark, settings),
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
          bool isSelected = _customRange == null && _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedFilter = filter;
                    _customRange = null;
                  });
                }
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

  Widget _buildSavingsBarChart(List<QueryDocumentSnapshot> docs, bool isDark, SettingsProvider settings) {
    double totalSavings = 0;
    List<double> dailySavings = List.filled(7, 0.0);

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['type'] == 'ahorro') {
        double amount = (data['amount'] ?? 0).toDouble();
        totalSavings += amount;

        if (data['date'] != null) {
          DateTime date = (data['date'] as Timestamp).toDate();
          int weekday = date.weekday - 1; // Mon=0, Sun=6
          if (weekday >= 0 && weekday < 7) {
            dailySavings[weekday] += amount;
          }
        }
      }
    }

    double maxSaving = dailySavings.reduce((curr, next) => curr > next ? curr : next);
    if (maxSaving == 0) maxSaving = 1;

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
              const Text("Ahorro acumulado", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_customRange != null ? "Personalizado" : _selectedFilter, style: const TextStyle(color: Colors.blueAccent, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(settings.formatAmount(totalSavings), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxSaving * 1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
                        if (value >= 0 && value < 7) {
                          return Text(days[value.toInt()], style: const TextStyle(color: Colors.grey, fontSize: 10));
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (i) => _makeGroupData(
                  i,
                  dailySavings[i],
                  dailySavings[i] == maxSaving && maxSaving > 0 ? Colors.blueAccent : Colors.blueAccent.withValues(alpha: 0.3),
                )),
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

  Widget _buildBalanceLineChart(List<QueryDocumentSnapshot> docs, bool isDark, double baseline) {
    List<FlSpot> spots = [];
    double periodNet = 0;
    double cumulative = baseline;
    int index = 0;

    final sortedDocs = [...docs]..sort((a, b) {
      final dateA = ((a.data() as Map<String, dynamic>)['date'] as Timestamp?)?.toDate() ?? DateTime(2000);
      final dateB = ((b.data() as Map<String, dynamic>)['date'] as Timestamp?)?.toDate() ?? DateTime(2000);
      return dateA.compareTo(dateB);
    });

    spots.add(FlSpot(0, cumulative / 1000));
    for (var doc in sortedDocs) {
      final data = doc.data() as Map<String, dynamic>;
      double amount = (data['amount'] ?? 0).toDouble();
      double change = (data['type'] == 'gasto') ? -amount : amount;
      cumulative += change;
      periodNet += change;
      index++;
      spots.add(FlSpot(index.toDouble(), cumulative / 1000));
    }

    double growthPercent = 0;
    if (baseline.abs() > 0.01) {
      growthPercent = (periodNet / baseline.abs()) * 100;
    } else if (periodNet != 0) {
      growthPercent = periodNet > 0 ? 100 : -100;
    }
    final isPositive = growthPercent >= 0;

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
              Text(
                "${isPositive ? '▲' : '▼'} ${growthPercent.abs().toStringAsFixed(1)}% en el periodo",
                style: TextStyle(color: isPositive ? Colors.greenAccent : Colors.redAccent, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
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

  Widget _buildExpensesDonutChart(List<QueryDocumentSnapshot> docs, bool isDark, SettingsProvider settings) {
    double totalExpenses = 0;
    // Map to store category totals
    Map<String, double> categoryTotals = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['type'] == 'gasto') {
        double amount = (data['amount'] ?? 0).toDouble();
        totalExpenses += amount;
        String category = data['category'] ?? 'Otros';
        categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
      }
    }

    if (totalExpenses == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151921) : Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Center(child: Text("No hay gastos registrados en este periodo")),
      );
    }

    final colors = [
      Colors.greenAccent,
      Colors.blueAccent,
      Colors.purpleAccent,
      Colors.orangeAccent,
      Colors.blueGrey,
    ];

    int colorIndex = 0;
    List<PieChartSectionData> sections = [];
    List<Widget> legendItems = [];

    categoryTotals.forEach((category, amount) {
      double percentage = (amount / totalExpenses) * 100;
      Color color = colors[colorIndex % colors.length];

      sections.add(PieChartSectionData(
        color: color,
        value: amount,
        showTitle: false,
        radius: 12,
      ));

      legendItems.add(_buildExpenseLegendItem(category, color, "${percentage.toStringAsFixed(0)}%"));
      colorIndex++;
    });

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
                child: Text(_customRange != null ? "Personalizado" : _selectedFilter, style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
                    sections: sections,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: legendItems,
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
