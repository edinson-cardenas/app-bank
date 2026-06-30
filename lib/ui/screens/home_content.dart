import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/utils/goal_style.dart';
import '../../services/ai_service.dart';
import '../../services/database_service.dart';
import '../../services/settings_provider.dart';
import 'notifications_screen.dart';
import 'transaction_history_screen.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final AiService _aiService = AiService();
  final List<String> _insights = [];
  bool _isGeneratingDiagnosis = false;

  Future<void> _generateDiagnosis(DatabaseService db) async {
    setState(() => _isGeneratingDiagnosis = true);
    try {
      final profileSummary = await db.buildFinancialProfileSummary();
      final insights = await _aiService.generateFinancialInsights(profileSummary);
      if (mounted) {
        setState(() {
          _insights.addAll(insights);
        });
      }
    } finally {
      if (mounted) setState(() => _isGeneratingDiagnosis = false);
    }
  }

  void _dismissInsight(int index, DatabaseService db) {
    final text = _insights[index];
    setState(() => _insights.removeAt(index));
    db.addNotification(
      title: "Diagnóstico financiero IA",
      body: text,
      type: 'ai_insight',
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final settings = Provider.of<SettingsProvider>(context);

    return StreamBuilder<DocumentSnapshot>(
      stream: db.userData,
      builder: (context, snapshot) {
        String userName = "Usuario";
        double balance = 0.0;
        double savings = 0.0;
        double expenses = 0.0;
        double investments = 0.0;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          userName = data['name'] ?? "Usuario";
          userName = userName.split(' ')[0];
          balance = (data['balance'] ?? 0.0).toDouble();
          savings = (data['totalSavings'] ?? 0.0).toDouble();
          expenses = (data['totalExpenses'] ?? 0.0).toDouble();
          investments = (data['totalInvestments'] ?? 0.0).toDouble();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, db, userName),
              const SizedBox(height: 24),
              _buildMainBalanceCard(context, db, settings, balance),
              const SizedBox(height: 24),
              const Text("Resúmenes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildFinanceCategories(context, settings, savings, expenses, investments),
              const SizedBox(height: 20),
              _buildAiDiagnosisButton(context, db),
              if (_insights.isNotEmpty) ...[
                const SizedBox(height: 16),
                ..._insights.asMap().entries.map(
                  (entry) => _buildInsightBubble(context, entry.value, () => _dismissInsight(entry.key, db)),
                ),
              ],
              const SizedBox(height: 24),
              _buildMainGoalSection(context, db),
              _buildRecentActivityHeader(context),
              const SizedBox(height: 16),
              _buildRecentActivityList(context, db, settings),
              // Espacio extra al final para que el contenido no quede debajo de la barra
              const SizedBox(height: 140),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAiDiagnosisButton(BuildContext context, DatabaseService db) {
    return GestureDetector(
      onTap: _isGeneratingDiagnosis ? null : () => _generateDiagnosis(db),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.indigoAccent, Colors.cyanAccent],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: _isGeneratingDiagnosis
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Generar Diagnóstico Financiero con IA",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildInsightBubble(BuildContext context, String text, VoidCallback onDismiss) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.indigoAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.auto_awesome, color: Colors.indigoAccent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          InkWell(
            onTap: onDismiss,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.close, size: 18, color: theme.textTheme.bodyMedium?.color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DatabaseService db, String name) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "¡Hola, $name! 👋",
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            Text(
              "Aquí tienes tu resumen financiero.",
              style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 16),
            ),
          ],
        ),
        StreamBuilder<QuerySnapshot>(
          stream: db.notifications,
          builder: (context, snapshot) {
            int unread = 0;
            if (snapshot.hasData) {
              unread = snapshot.data!.docs
                  .where((d) => (d.data() as Map<String, dynamic>)['read'] == false)
                  .length;
            }
            return Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.notifications_none_rounded, color: theme.iconTheme.color, size: 30),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                  ),
                ),
                if (unread > 0)
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildMainBalanceCard(BuildContext context, DatabaseService db, SettingsProvider settings, double balance) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("Saldo total", style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 14)),
              const SizedBox(width: 8),
              Icon(Icons.visibility_outlined, color: theme.textTheme.bodyMedium?.color, size: 18),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TransactionHistoryScreen()),
                ),
                child: Icon(Icons.arrow_forward_ios, color: theme.textTheme.bodyMedium?.color, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            settings.formatAmount(balance),
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: db.transactions,
            builder: (context, snapshot) {
              double growthPercent = 0;
              if (snapshot.hasData) {
                final now = DateTime.now();
                final startOfMonth = DateTime(now.year, now.month, 1);
                double monthNet = 0;
                for (final doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final date = (data['date'] as Timestamp?)?.toDate();
                  if (date == null || date.isBefore(startOfMonth)) continue;
                  final amount = (data['amount'] ?? 0).toDouble();
                  final type = data['type'];
                  monthNet += (type == 'gasto') ? -amount : amount;
                }
                final baseline = balance - monthNet;
                if (baseline.abs() > 0.01) {
                  growthPercent = (monthNet / baseline.abs()) * 100;
                } else if (monthNet != 0) {
                  growthPercent = monthNet > 0 ? 100 : -100;
                }
              }
              final isPositive = growthPercent >= 0;
              return Text(
                "${isPositive ? '▲' : '▼'} ${growthPercent.abs().toStringAsFixed(1)}% este mes",
                style: TextStyle(
                  color: isPositive ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceCategories(BuildContext context, SettingsProvider settings, double savings, double expenses, double investments) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          _buildCategoryItem(context, Icons.account_balance_wallet_outlined, "Ahorros", settings.formatAmount(savings), Colors.green),
          Divider(color: theme.dividerColor.withValues(alpha: 0.1), height: 1, indent: 60),
          _buildCategoryItem(context, Icons.credit_card, "Gastos", settings.formatAmount(expenses), Colors.orange),
          Divider(color: theme.dividerColor.withValues(alpha: 0.1), height: 1, indent: 60),
          _buildCategoryItem(context, Icons.bar_chart_rounded, "Inversiones", settings.formatAmount(investments), Colors.blue),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, IconData icon, String label, String amount, Color color) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Text(amount, style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 14)),
    );
  }

  Widget _buildMainGoalSection(BuildContext context, DatabaseService db) {
    return StreamBuilder<QuerySnapshot>(
      stream: db.goals,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data!.docs;
        QueryDocumentSnapshot topGoal = docs.first;
        double topPercent = -1;
        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final current = (data['currentAmount'] ?? 0).toDouble();
          final target = (data['targetAmount'] ?? 0).toDouble();
          final percent = target > 0 ? (current / target) : 0.0;
          if (percent < 1 && percent > topPercent) {
            topPercent = percent;
            topGoal = doc;
          }
        }

        return Column(
          children: [
            _buildMainGoalCard(context, topGoal),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildMainGoalCard(BuildContext context, QueryDocumentSnapshot goalDoc) {
    final theme = Theme.of(context);
    final data = goalDoc.data() as Map<String, dynamic>;
    final String title = data['title'] ?? 'Meta';
    final String category = data['category'] ?? 'Otros';
    final double current = (data['currentAmount'] ?? 0).toDouble();
    final double target = (data['targetAmount'] ?? 0).toDouble();
    final String currency = data['currency'] ?? 'PEN';
    final currencySymbol = currency == 'USD' ? '\$' : 'S/';
    final double percent = target > 0 ? (current / target).clamp(0, 1) : 0.0;
    final double missing = (target - current).clamp(0, double.infinity);
    final (_, color) = goalIconAndColor(category);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Meta principal", style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 14)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text("$currencySymbol ${target.toStringAsFixed(2)}", style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(color: theme.colorScheme.secondary, borderRadius: BorderRadius.circular(10)),
              ),
              FractionallySizedBox(
                widthFactor: percent,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Faltan: $currencySymbol ${missing.toStringAsFixed(2)}",
                style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12),
              ),
              Text("${(percent * 100).round()}%", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Actividad reciente", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TransactionHistoryScreen()),
          ),
          child: const Text("Ver todo", style: TextStyle(color: Colors.blueAccent, fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildRecentActivityList(BuildContext context, DatabaseService db, SettingsProvider settings) {
    return StreamBuilder<QuerySnapshot>(
      stream: db.transactions,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Center(child: Text("No hay actividad reciente")),
          );
        }

        final transactions = snapshot.data!.docs.take(5).toList();

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: transactions.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final type = data['type'];
              final amount = (data['amount'] ?? 0).toDouble();
              final category = data['category'];
              final date = (data['date'] as Timestamp).toDate();

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

              return Column(
                children: [
                  _buildActivityItem(
                    context,
                    icon,
                    category,
                    "${date.day}/${date.month}/${date.year}",
                    "$prefix ${settings.formatAmount(amount)}",
                    amountColor,
                  ),
                  if (doc != transactions.last)
                    Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.1), height: 1, indent: 60),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildActivityItem(BuildContext context, IconData icon, String title, String date, String amount, Color amountColor) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: theme.colorScheme.secondary, borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: theme.iconTheme.color?.withValues(alpha: 0.7), size: 24),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
      subtitle: Text(date, style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12)),
      trailing: Text(
        amount,
        style: TextStyle(color: amountColor, fontWeight: FontWeight.bold, fontSize: 15),
      ),
    );
  }
}
