import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../core/utils/goal_style.dart';
import '../widgets/create_goal_sheet.dart';
import '../widgets/add_contribution_sheet.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  void _showCreateGoalSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const CreateGoalSheet(),
    );
  }

  void _showAddContributionSheet(BuildContext context, String goalId, String title, String currency) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AddContributionSheet(goalId: goalId, goalTitle: title, currency: currency),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String goalId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text("Eliminar meta"),
        content: Text("¿Seguro que deseas eliminar \"$title\"? Esta acción no se puede deshacer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Eliminar", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await Provider.of<DatabaseService>(context, listen: false).deleteGoal(goalId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Mis metas"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Nueva meta",
            onPressed: () => _showCreateGoalSheet(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: db.goals,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  "No se pudieron cargar tus metas. Verifica las reglas de Firestore o tu conexión.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flag_outlined, size: 80, color: Colors.grey.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text(
                    "No tienes metas aún",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Pulsa el botón + para crear tu primera meta.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                for (final doc in docs) ...[
                  _buildGoalCard(context, doc),
                  const SizedBox(height: 20),
                ],
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final String title = data['title'] ?? 'Meta';
    final String category = data['category'] ?? 'Otros';
    final double current = (data['currentAmount'] ?? 0).toDouble();
    final double target = (data['targetAmount'] ?? 0).toDouble();
    final String currency = data['currency'] ?? 'PEN';
    final currencySymbol = currency == 'USD' ? '\$' : 'S/';
    final int percentage = target > 0 ? ((current / target) * 100).clamp(0, 100).round() : 0;

    final (icon, color) = goalIconAndColor(category);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: isDark ? Colors.white70 : Colors.black54),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                "$percentage%",
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: theme.textTheme.bodyMedium?.color, size: 20),
                onPressed: () => _confirmDelete(context, doc.id, title),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage / 100,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                "$currencySymbol ${current.toStringAsFixed(2)} de $currencySymbol ${target.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showAddContributionSheet(context, doc.id, title, currency),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                foregroundColor: isDark ? Colors.white : Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text("Agregar aporte"),
            ),
          ),
        ],
      ),
    );
  }
}
