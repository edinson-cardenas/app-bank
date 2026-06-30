import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get uid => _auth.currentUser?.uid;

  // Stream of user data
  Stream<DocumentSnapshot> get userData {
    if (uid == null) return const Stream.empty();
    return _db.collection('users').doc(uid).snapshots();
  }

  // Stream of transactions (savings, expenses, investments)
  Stream<QuerySnapshot> get transactions {
    if (uid == null) return const Stream.empty();
    return _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Add a new transaction
  Future<void> addTransaction({
    required double amount,
    required String type, // 'ahorro', 'gasto', 'inversion'
    required String category,
    required DateTime date,
    required String currency,
    String? description,
  }) async {
    if (uid == null) return;

    final batch = _db.batch();
    final userRef = _db.collection('users').doc(uid);
    final transactionRef = userRef.collection('transactions').doc();

    batch.set(transactionRef, {
      'amount': amount,
      'type': type,
      'category': category,
      'date': Timestamp.fromDate(date),
      'currency': currency,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update user totals
    Map<String, dynamic> updates = {};
    if (type == 'ahorro') {
      updates['totalSavings'] = FieldValue.increment(amount);
    } else if (type == 'gasto') {
      updates['totalExpenses'] = FieldValue.increment(amount);
    } else if (type == 'inversion') {
      updates['totalInvestments'] = FieldValue.increment(amount);
    }

    // Update balance
    double balanceChange = (type == 'gasto') ? -amount : amount;
    updates['balance'] = FieldValue.increment(balanceChange);

    // Usamos set con merge: true para que cree los campos si no existen
    batch.set(userRef, updates, SetOptions(merge: true));

    final notifRef = userRef.collection('notifications').doc();
    final typeLabel = type == 'ahorro'
        ? 'ahorro'
        : type == 'gasto'
            ? 'gasto'
            : 'inversión';
    batch.set(notifRef, {
      'title': 'Movimiento registrado',
      'body':
          'Registraste un $typeLabel de $currency ${amount.toStringAsFixed(2)} en $category',
      'type': 'transaction',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // ----------------- Metas (Goals) -----------------

  Stream<QuerySnapshot> get goals {
    if (uid == null) return const Stream.empty();
    return _db
        .collection('users')
        .doc(uid)
        .collection('goals')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> addGoal({
    required String title,
    required double targetAmount,
    required String category,
    required String currency,
  }) async {
    if (uid == null) return;
    await _db.collection('users').doc(uid).collection('goals').add({
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': 0.0,
      'category': category,
      'currency': currency,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteGoal(String goalId) async {
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('goals')
        .doc(goalId)
        .delete();
  }

  /// Registra un aporte a una meta: crea la transacción de ahorro
  /// correspondiente, incrementa el progreso de la meta y los totales del
  /// usuario, y genera notificaciones relacionadas. Devuelve `true` si el
  /// aporte completó la meta.
  Future<bool> addGoalContribution({
    required String goalId,
    required double amount,
    required String currency,
    required DateTime date,
  }) async {
    if (uid == null) return false;

    final userRef = _db.collection('users').doc(uid);
    final goalRef = userRef.collection('goals').doc(goalId);
    final transactionRef = userRef.collection('transactions').doc();
    final contributionNotifRef = userRef.collection('notifications').doc();
    final completedNotifRef = userRef.collection('notifications').doc();

    bool goalCompleted = false;

    await _db.runTransaction((transaction) async {
      final goalSnap = await transaction.get(goalRef);
      if (!goalSnap.exists) return;

      final goalData = goalSnap.data() as Map<String, dynamic>;
      final String goalTitle = goalData['title'] ?? 'Meta';
      final double currentAmount = (goalData['currentAmount'] ?? 0).toDouble();
      final double targetAmount = (goalData['targetAmount'] ?? 0).toDouble();
      final double newAmount = currentAmount + amount;
      goalCompleted = currentAmount < targetAmount && newAmount >= targetAmount;

      transaction.set(transactionRef, {
        'amount': amount,
        'type': 'ahorro',
        'category': 'Meta',
        'date': Timestamp.fromDate(date),
        'currency': currency,
        'description': 'Aporte a la meta "$goalTitle"',
        'goalId': goalId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      transaction.update(goalRef, {
        'currentAmount': FieldValue.increment(amount),
      });

      transaction.set(
        userRef,
        {
          'totalSavings': FieldValue.increment(amount),
          'balance': FieldValue.increment(amount),
        },
        SetOptions(merge: true),
      );

      transaction.set(contributionNotifRef, {
        'title': 'Aporte registrado',
        'body':
            'Aportaste $currency ${amount.toStringAsFixed(2)} a "$goalTitle"',
        'type': 'goal_contribution',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (goalCompleted) {
        transaction.set(completedNotifRef, {
          'title': '¡Meta cumplida!',
          'body': 'Has completado tu meta "$goalTitle"',
          'type': 'goal_completed',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });

    return goalCompleted;
  }

  // ----------------- IA: Diagnóstico financiero -----------------

  /// Construye un resumen textual del estado financiero actual del usuario
  /// (saldo, metas y transacciones recientes) para usarlo como contexto en
  /// el prompt de la IA.
  Future<String> buildFinancialProfileSummary() async {
    if (uid == null) return '';

    final userDoc = await _db.collection('users').doc(uid).get();
    final data = userDoc.data() ?? <String, dynamic>{};
    final balance = (data['balance'] ?? 0).toDouble();
    final savings = (data['totalSavings'] ?? 0).toDouble();
    final expenses = (data['totalExpenses'] ?? 0).toDouble();
    final investments = (data['totalInvestments'] ?? 0).toDouble();

    final goalsSnap = await _db
        .collection('users')
        .doc(uid)
        .collection('goals')
        .orderBy('createdAt', descending: true)
        .get();
    final goalLines = goalsSnap.docs.map((d) {
      final g = d.data();
      final current = (g['currentAmount'] ?? 0).toDouble();
      final target = (g['targetAmount'] ?? 0).toDouble();
      return "- ${g['title']}: ${current.toStringAsFixed(2)} de ${target.toStringAsFixed(2)} ${g['currency'] ?? ''}";
    }).join('\n');

    final txSnap = await _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .get();
    final txLines = txSnap.docs.map((d) {
      final t = d.data();
      final date = (t['date'] as Timestamp?)?.toDate();
      final dateStr = date != null ? "${date.day}/${date.month}/${date.year}" : '';
      return "- ${t['type']}: ${t['currency'] ?? ''} ${(t['amount'] ?? 0).toStringAsFixed(2)} en ${t['category']} ($dateStr)";
    }).join('\n');

    return "Saldo total: ${balance.toStringAsFixed(2)}. Ahorros: ${savings.toStringAsFixed(2)}. "
        "Gastos: ${expenses.toStringAsFixed(2)}. Inversiones: ${investments.toStringAsFixed(2)}.\n"
        "${goalLines.isNotEmpty ? 'Metas activas:\n$goalLines' : 'No tiene metas creadas todavía.'}\n"
        "${txLines.isNotEmpty ? 'Transacciones recientes:\n$txLines' : 'Sin transacciones recientes.'}";
  }

  // ----------------- Notificaciones -----------------

  Stream<QuerySnapshot> get notifications {
    if (uid == null) return const Stream.empty();
    return _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> addNotification({
    required String title,
    required String body,
    required String type,
  }) async {
    if (uid == null) return;
    await _db.collection('users').doc(uid).collection('notifications').add({
      'title': title,
      'body': body,
      'type': type,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markNotificationRead(String notificationId) async {
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  Future<void> markAllNotificationsRead() async {
    if (uid == null) return;
    final unread = await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();

    if (unread.docs.isEmpty) return;

    final batch = _db.batch();
    for (var doc in unread.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}
