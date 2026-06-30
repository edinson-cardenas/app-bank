import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DatabaseService>(context, listen: false)
          .markAllNotificationsRead()
          .catchError((_) {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Notificaciones"),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: db.notifications,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  "No se pudieron cargar las notificaciones. Verifica las reglas de Firestore o tu conexión.",
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
                  Icon(Icons.notifications_none_rounded, size: 80, color: Colors.grey.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text(
                    "No tienes notificaciones",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Aquí verás novedades sobre tus movimientos y metas.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String type = data['type'] ?? 'transaction';
              final String title = data['title'] ?? '';
              final String body = data['body'] ?? '';
              final bool read = data['read'] ?? true;
              final Timestamp? createdAt = data['createdAt'];

              final iconData = _iconForType(type);

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: read
                      ? null
                      : Border.all(color: Colors.blueAccent.withValues(alpha: 0.4), width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: iconData.$2.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(iconData.$1, color: iconData.$2, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(body, style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color)),
                          if (createdAt != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              DateFormat('dd/MM/yyyy HH:mm').format(createdAt.toDate()),
                              style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  (IconData, Color) _iconForType(String type) {
    switch (type) {
      case 'goal_contribution':
        return (Icons.savings_outlined, Colors.green);
      case 'goal_completed':
        return (Icons.emoji_events_outlined, Colors.amber);
      case 'ai_insight':
        return (Icons.auto_awesome, Colors.indigoAccent);
      case 'transaction':
      default:
        return (Icons.monetization_on_outlined, Colors.blueAccent);
    }
  }
}
