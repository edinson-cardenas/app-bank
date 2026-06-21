import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/colors.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String userName = "Usuario";
        if (snapshot.hasData && snapshot.data!.exists) {
          userName = (snapshot.data!.data() as Map<String, dynamic>)['name'] ?? "Usuario";
          userName = userName.split(' ')[0];
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, userName),
              const SizedBox(height: 24),
              _buildMainBalanceCard(context),
              const SizedBox(height: 20),
              _buildFinanceCategories(context),
              const SizedBox(height: 24),
              _buildMainGoalCard(context),
              const SizedBox(height: 24),
              _buildRecentActivityHeader(context),
              const SizedBox(height: 16),
              _buildRecentActivityList(context),
              // Espacio extra al final para que el contenido no quede debajo de la barra
              const SizedBox(height: 140), 
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, String name) {
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
        Stack(
          children: [
            IconButton(
              icon: Icon(Icons.notifications_none_rounded, color: theme.iconTheme.color, size: 30),
              onPressed: () {},
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
              ),
            )
          ],
        )
      ],
    );
  }

  Widget _buildMainBalanceCard(BuildContext context) {
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
              Icon(Icons.arrow_forward_ios, color: theme.textTheme.bodyMedium?.color, size: 14),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "S/ 8,450.00",
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "▲ 5.2% este mes",
            style: TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceCategories(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          _buildCategoryItem(context, Icons.account_balance_wallet_outlined, "Ahorros", "S/ 5,000", Colors.green),
          Divider(color: theme.dividerColor.withValues(alpha: 0.1), height: 1, indent: 60),
          _buildCategoryItem(context, Icons.credit_card, "Gastos", "S/ 2,300", Colors.orange),
          Divider(color: theme.dividerColor.withValues(alpha: 0.1), height: 1, indent: 60),
          _buildCategoryItem(context, Icons.bar_chart_rounded, "Inversiones", "S/ 1,150.00", Colors.blue),
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(amount, style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 14)),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios, color: theme.textTheme.bodyMedium?.color, size: 14),
        ],
      ),
    );
  }

  Widget _buildMainGoalCard(BuildContext context) {
    final theme = Theme.of(context);
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
              const Text("Viaje", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text("S/ 10,000.00", style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 14)),
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
                widthFactor: 0.8,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(color: Colors.greenAccent, borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Faltan: S/ 2,000.00", style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12)),
              const Text("80%", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityHeader(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("Actividad reciente", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text("Ver todo", style: TextStyle(color: Colors.blueAccent, fontSize: 14)),
      ],
    );
  }

  Widget _buildRecentActivityList(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          _buildActivityItem(context, Icons.verified_user_rounded, "Aporte a meta Viaje", "Hoy", "+S/ 100.00", Colors.greenAccent),
          Divider(color: theme.dividerColor.withValues(alpha: 0.1), height: 1, indent: 60),
          _buildActivityItem(context, Icons.shopping_cart_rounded, "Supermercado", "Ayer", "-S/ 45.00", Colors.redAccent),
          Divider(color: theme.dividerColor.withValues(alpha: 0.1), height: 1, indent: 60),
          _buildActivityItem(context, Icons.star_rounded, "Ahorro automático", "Ayer", "+S/ 20.00", Colors.greenAccent),
        ],
      ),
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
