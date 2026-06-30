import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../services/settings_provider.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _filter = 'Todos';
  final List<String> _filters = ['Todos', 'ahorro', 'gasto', 'inversion'];

  String _filterLabel(String value) {
    switch (value) {
      case 'ahorro':
        return 'Ahorros';
      case 'gasto':
        return 'Gastos';
      case 'inversion':
        return 'Inversiones';
      default:
        return 'Todos';
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Actividad reciente"),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((f) {
                  final isSelected = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_filterLabel(f)),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _filter = f);
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
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: db.transactions,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data!.docs;
                if (_filter != 'Todos') {
                  docs = docs.where((d) => (d.data() as Map<String, dynamic>)['type'] == _filter).toList();
                }

                if (docs.isEmpty) {
                  return const Center(child: Text("No hay movimientos en esta categoría", style: TextStyle(color: Colors.grey)));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final type = data['type'];
                    final amount = (data['amount'] ?? 0).toDouble();
                    final category = data['category'] ?? '';
                    final description = data['description'] as String?;
                    final date = (data['date'] as Timestamp?)?.toDate();

                    Color amountColor = Colors.greenAccent;
                    String prefix = "+";
                    IconData icon = Icons.monetization_on_outlined;

                    if (type == 'gasto') {
                      amountColor = Colors.redAccent;
                      prefix = "-";
                      icon = Icons.shopping_cart_rounded;
                    } else if (type == 'inversion') {
                      amountColor = Colors.blueAccent;
                      prefix = "+";
                      icon = Icons.bar_chart_rounded;
                    }

                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: theme.colorScheme.secondary, borderRadius: BorderRadius.circular(14)),
                          child: Icon(icon, color: theme.iconTheme.color?.withValues(alpha: 0.7), size: 24),
                        ),
                        title: Text(category, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                        subtitle: Text(
                          [
                            if (date != null) "${date.day}/${date.month}/${date.year}",
                            if (description != null && description.isNotEmpty) description,
                          ].join(' · '),
                          style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12),
                        ),
                        trailing: Text(
                          "$prefix ${settings.formatAmount(amount)}",
                          style: TextStyle(color: amountColor, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
